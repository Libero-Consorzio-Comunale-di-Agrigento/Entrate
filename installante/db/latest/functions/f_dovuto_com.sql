--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dovuto_com stripComments:false runOnChange:true 
 
create or replace function F_DOVUTO_COM
(p_ni             number
,p_anno           number
,p_titr           varchar2
,p_dic_da_anno    number
,p_tributo        number
,p_richiesta      varchar2
,p_ruolo          number default null
)
  return number
is
  /******************************************************************************
  Dati ni, anno e tipo tributo e anno da cui considerare le dichiarazioni,
  ritorna il dovuto a seconda del parametro p_richiesta
  P_richiesta:
   D  - Dovuto annuo (al netto degli sgravi)
   DR - Dovuto arrotondato x oggetto (al netto degli sgravi)
   DL - Dovuto liquidato
   S - Sgravio
  P_tributo: -1 = tutti i tributi
  ******************************************************************************/
  w_dovuto        number;
  w_sgravi        number;
  w_ruolo         number;
  w_cod_fiscale   varchar2(16);
begin
  w_ruolo  := null;
  w_dovuto := null;
  w_sgravi := null;
  -- estraggo prima il codice fiscale del soggetto
  -- per migliorare il piano d'accesso delea select successive
  select cont.cod_fiscale
    into w_cod_fiscale
    from soggetti sogg, contribuenti cont
   where sogg.ni = p_ni
     and cont.ni = sogg.ni;
  if p_titr = 'TARSU'
     and nvl(p_ruolo, -1) = -1 then -- dobbiamo gestire i ruoli totali
     w_ruolo := f_ruolo_totale(w_cod_fiscale, p_anno, p_titr, p_tributo);
  elsif nvl(p_ruolo, -1) != -1 then
     w_ruolo := p_ruolo;
  end if;
  if p_richiesta = 'DL' then -- Dovuto Liquidato
    select sum(nvl(ogim.imposta, 0))
      into w_dovuto
      from pratiche_tributo prtr
          ,tipi_tributo titr
          ,oggetti_pratica ogpr
          ,oggetti_imposta ogim
     where prtr.anno = p_anno
       and prtr.tipo_pratica = 'L'
       and nvl(prtr.stato_accertamento, 'D') = 'D'
       and prtr.pratica = ogpr.pratica
       --       and nvl(ogpr.tributo, 0) =
       --             decode(p_tributo, -1, nvl(ogpr.tributo, 0), p_tributo)
       and ogim.oggetto_pratica = ogpr.oggetto_pratica
       and prtr.tipo_tributo || '' = p_titr
       and ogim.anno = p_anno
       and ogim.cod_fiscale = w_cod_fiscale
       and ogim.anno = p_anno
       and titr.tipo_tributo = prtr.tipo_tributo
       and nvl(ogim.ruolo, -1) = nvl(w_ruolo, nvl(ogim.ruolo, -1));
  elsif p_richiesta in ('D','DR') then -- Dovuto o Dovuto Arrotondato
    if p_titr = 'TARSU' then -- se TARSU estraiamo comunque il dovuto arrotondato
                             -- perchè ha un arrotondamento particolare
      select   nvl(sum(round(imposta)), 0)
           --  + nvl(sum(round(maggiorazione_tares)), 0)
        into w_dovuto
        from (  select sum(  nvl(ogim.imposta, 0)
                           + nvl(ogim.addizionale_eca, 0)
                           + nvl(ogim.maggiorazione_eca, 0)
                           + nvl(ogim.addizionale_pro, 0)
                           + nvl(ogim.iva, 0)
                          )
                         imposta
                      ,sum(ogim.maggiorazione_tares) maggiorazione_tares
                  from pratiche_tributo prtr
                      ,tipi_tributo titr
                      ,oggetti_pratica ogpr
                      ,oggetti_imposta ogim
                      ,ruoli ruol
                 where prtr.anno >= p_dic_da_anno
                   and (decode(prtr.tipo_pratica
                              ,'D', prtr.anno - 1
                              ,ogim.anno
                              ) <> prtr.anno)
                   and decode(prtr.tipo_pratica, 'D', 'S', prtr.flag_denuncia) =
                         'S'
                   and nvl(prtr.stato_accertamento, 'D') = 'D'
                   and prtr.pratica = ogpr.pratica
                   and nvl(ogpr.tributo, 0) =
                         decode(p_tributo, -1, nvl(ogpr.tributo, 0), p_tributo)
                   and ogim.oggetto_pratica = ogpr.oggetto_pratica
                   and prtr.tipo_tributo || '' = p_titr
                   and ogim.cod_fiscale = w_cod_fiscale
                   and ogim.flag_calcolo = 'S'
                   and ogim.anno = p_anno
                   and titr.tipo_tributo = prtr.tipo_tributo
                   and ruol.ruolo = ogim.ruolo
                   and ruol.invio_consorzio is not null
                   and nvl(ogim.ruolo, -1) = nvl(w_ruolo, nvl(ogim.ruolo, -1))
              group by ogim.ruolo);
    else
    select sum(decode(p_richiesta
                     ,'DR', round(nvl(ogim.imposta, 0))
                     ,nvl(ogim.imposta, 0)
                     )
              )
      into w_dovuto
      from pratiche_tributo prtr
          ,tipi_tributo titr
          ,oggetti_pratica ogpr
          ,oggetti_imposta ogim
     where prtr.anno >= p_dic_da_anno
       and (decode(prtr.tipo_pratica, 'D', prtr.anno - 1, ogim.anno) <>
              prtr.anno)
       and decode(prtr.tipo_pratica, 'D', 'S', prtr.flag_denuncia) = 'S'
       and nvl(prtr.stato_accertamento, 'D') = 'D'
       and prtr.pratica = ogpr.pratica
       and nvl(ogpr.tributo, 0) =
             decode(p_tributo, -1, nvl(ogpr.tributo, 0), p_tributo)
       and ogim.oggetto_pratica = ogpr.oggetto_pratica
       and prtr.tipo_tributo || '' = p_titr
       and ogim.cod_fiscale = w_cod_fiscale
       and ogim.flag_calcolo = 'S'
       and ogim.anno = p_anno
       and titr.tipo_tributo = prtr.tipo_tributo
       and nvl(ogim.ruolo, -1) = nvl(w_ruolo, nvl(ogim.ruolo, -1));
    end if;
  end if;
  if p_richiesta in ('D', 'DR', 'S') then
    begin
      select sum(nvl(sgra.importo, 0)--                 - nvl(sgra.addizionale_eca, 0)
  --                 - nvl(sgra.maggiorazione_eca, 0)
  --                 - nvl(sgra.addizionale_pro, 0)
  --                 - nvl(sgra.iva, 0)
                   - nvl(sgra.maggiorazione_tares, 0)
             ) importo_sgravio
        into w_sgravi
        from sgravi sgra
       where (sgra.ruolo, sgra.sequenza, sgra.cod_fiscale) in
               (  select ruog.ruolo, ruog.sequenza, ruog.cod_fiscale
                    from pratiche_tributo prtr
                        ,tipi_tributo titr
                        ,oggetti_pratica ogpr
                        ,oggetti_imposta ogim
                        ,ruoli_oggetto ruog
                   where prtr.anno >= p_dic_da_anno
                     and (decode(prtr.tipo_pratica
                                ,'D', prtr.anno - 1
                                ,ogim.anno
                                ) <> prtr.anno)
                     and decode(prtr.tipo_pratica
                               ,'D', 'S'
                               ,prtr.flag_denuncia
                               ) = 'S'
                     and prtr.pratica = ogpr.pratica
                     and nvl(prtr.stato_accertamento, 'D') = 'D'
                     and nvl(ogpr.tributo, 0) =
                           decode(p_tributo
                                 ,-1, nvl(ogpr.tributo, 0)
                                 ,p_tributo
                                 )
                     and ogim.oggetto_pratica = ogpr.oggetto_pratica
                     and prtr.tipo_tributo || '' = p_titr
                     and ogim.cod_fiscale = w_cod_fiscale
                     and ogim.flag_calcolo = 'S'
                     and ogim.anno = p_anno
                     and titr.tipo_tributo = prtr.tipo_tributo
                     and ruog.cod_fiscale = w_cod_fiscale
                     and ruog.oggetto_imposta = ogim.oggetto_imposta
                     and ogim.ruolo = nvl(w_ruolo, ogim.ruolo)
                group by ruog.ruolo, ruog.sequenza, ruog.cod_fiscale);
    exception
      when no_data_found then
        w_sgravi := null;
    end;
  end if;
  if p_richiesta = 'S' then
    return w_sgravi;
  else
    return nvl(w_dovuto, 0) - nvl(w_sgravi, 0);
  end if;
end;
/* End Function: F_DOVUTO_COM */
/

