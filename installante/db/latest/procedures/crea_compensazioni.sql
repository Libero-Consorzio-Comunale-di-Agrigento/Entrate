--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_compensazioni stripComments:false runOnChange:true 
 
create or replace procedure CREA_COMPENSAZIONI
/*************************************************************************
 NOME:        CREA_COMPENSAZIONI
 DESCRIZIONE: Creazione e inserimento compensazioni per eventuali
              versamenti in eccesso
 NOTE:        Valori per il parametro a_tipo_imposta:
              1 = Imposta Calcolata
              2 = Imposta Arrotondata per Contribuente
              3 = Imposta Arrotondata per Utenza
 Rev.    Date         Author      Note
 003     20/09/2022   VM          #66699 - sostituito filtro ricerca sogg.cognome_nome
                                  con sogg.cognome_nome_ric
 002     01/04/2022   DM          Nel caso di generazione su singolo a_cod_fiscale
                                  restituisce l'id della compensazione se generata,
                                  null altrimenti
 001     10/04/2019   VD          S.Donato Milanese - Sperimentazione Poasco
                                  Emissione compensazioni per conferimenti
                                  conteggiati in ruolo suppletivo con
                                  motivo = 90
 000     02/07/2014   XX          Prima emissione
*************************************************************************/
( a_tipo_tributo          in varchar2
, a_anno                  in number
, a_cod_fiscale           in varchar2
, a_limite                in number
, a_motivo_compensazione  in number
, a_utente                in varchar2
, a_tipo_imposta          in number default 1
, a_id_compensazione      out number
) IS
d_cod_istat               varchar2(6);
d_conta                   number;
w_errore                  varchar2(2000) := null;
CURSOR sel_dove ( p_anno_rif             number
                , p_titr                 varchar2
                , p_dic_da_anno          number
                , p_tributo              number
                , p_scf                  varchar2
                , p_snome                varchar2
                , p_simp_da              number
                , p_simp_a               number
                , p_tipo_imposta         number
                , p_cod_istat            varchar2
                , p_motivo_compensazione number
                ) IS
  select cont.cod_fiscale
        ,cont.ni
        ,  nvl(max(vers.s_vers), 0)
     --    + f_importo_vers_ravv(cont.cod_fiscale, p_titr, p_anno_rif, 'U')
           versato
        ,max(tard.s_tard_vers) tardivo
        ,max(translate(sogg.cognome_nome, '/', ' ')) cogn_nom
        ,nvl(f_dovuto_com(cont.ni
                         ,p_anno_rif
                         ,p_titr
                         ,p_dic_da_anno
                         ,p_tributo
                         ,'D'
                         ,null
                         )
            ,0
            )
           dovuto
        ,round(nvl(f_dovuto_com(cont.ni
                               ,p_anno_rif
                               ,p_titr
                               ,p_dic_da_anno
                               ,p_tributo
                               ,'D'
                               ,null
                               )
                  ,0
                  )
              )
           dovuto_arr
        ,nvl(f_dovuto_com(cont.ni
                         ,p_anno_rif
                         ,p_titr
                         ,p_dic_da_anno
                         ,p_tributo
                         ,'DR'
                         ,null
                         )
            ,0
            )
           dovuto_arr_ute
        , decode(p_tipo_imposta
                ,1, - nvl(f_dovuto_com(cont.ni
                                      ,p_anno_rif
                                      ,p_titr
                                      ,p_dic_da_anno
                                      ,p_tributo
                                      ,'D'
                                      ,null
                                      )
                         ,0
                         )
                    + (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                ,2, - round(nvl(f_dovuto_com(cont.ni
                                            ,p_anno_rif
                                            ,p_titr
                                            ,p_dic_da_anno
                                            ,p_tributo
                                            ,'D'
                                            ,null
                                            )
                               ,0
                               )
                           ,0
                           )
                    + (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                ,3, - nvl(f_dovuto_com(cont.ni
                                      ,p_anno_rif
                                      ,p_titr
                                      ,p_dic_da_anno
                                      ,p_tributo
                                      ,'DR'
                                      ,null
                                      )
                         ,0
                         )
                    + (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                )  eccedenza
        ,ogim.anno
        ,max(sogg.data_nas) data_nasc
        ,max(to_number(p_dic_da_anno)) dic_da_anno
        ,max(ogpr_prec.x2) dic_prec
        ,max(liq_cont.x) liq_cont
        ,max(acc_cont.x) acc_cont
        ,upper(replace(sogg.cognome, ' ', '')) cognome
        ,upper(replace(sogg.nome, ' ', '')) nome
        ,max(titr.descrizione) des_tipo_tributo
        ,prtr.tipo_tributo
        ,f_descrizione_titr(prtr.tipo_tributo, ogim.anno) descrizione_titr
        ,max(decode(ogim.tipo_rapporto,'A','X')) occupante
        ,max(decode(ogim.tipo_rapporto,'D','X')) proprietario
    from (  select nvl(sum(nvl(versamenti.importo_versato,0) - nvl(versamenti.maggiorazione_tares,0)), 0) s_vers
                  ,versamenti.cod_fiscale cofi
                  ,max(versamenti.anno) anno
              from versamenti, pratiche_tributo
             where versamenti.anno = p_anno_rif
               and versamenti.tipo_tributo || '' = p_titr
               and versamenti.cod_fiscale like p_scf
               and pratiche_tributo.pratica(+) = versamenti.pratica
               and (versamenti.pratica is null
                 or pratiche_tributo.tipo_pratica = 'D')
          group by versamenti.cod_fiscale) vers
        ,(  select nvl(sum(nvl(versamenti.importo_versato,0) - nvl(versamenti.maggiorazione_tares,0)), 0) s_tard_vers
                  ,versamenti.cod_fiscale cofi
                  ,max(versamenti.anno) anno
              from versamenti
             where versamenti.anno = p_anno_rif
               and versamenti.tipo_tributo || '' = p_titr
               and versamenti.cod_fiscale like p_scf
               and versamenti.tipo_tributo in ('ICP', 'TARSU', 'TOSAP', 'ICI')
               and versamenti.data_pagamento > f_scadenza(versamenti.anno, versamenti.tipo_tributo, versamenti.tipo_versamento, versamenti.cod_fiscale, versamenti.rata)
               and versamenti.pratica is null
          group by versamenti.cod_fiscale) tard
        ,(select distinct 'x1' x, prtr1.cod_fiscale cf
            from oggetti_pratica ogpr1
                ,pratiche_tributo prtr1
                ,rapporti_tributo ratr1
           where prtr1.pratica = ogpr1.pratica
             and prtr1.anno = p_anno_rif
             and prtr1.tipo_pratica = 'L'
             and nvl(prtr1.stato_accertamento,'D') = 'D'
             and prtr1.tipo_tributo || '' = p_titr
             and prtr1.pratica = ratr1.pratica
             and ratr1.cod_fiscale like p_scf) liq_cont
        ,(select distinct 'x2' x2, prtr2.cod_fiscale cf
            from oggetti_pratica ogpr2
                ,pratiche_tributo prtr2
                ,rapporti_tributo ratr2
           where prtr2.pratica = ogpr2.pratica
             and prtr2.anno < p_dic_da_anno
             and prtr2.tipo_pratica = 'D'
             and prtr2.tipo_tributo || '' = p_titr
             and prtr2.pratica = ratr2.pratica
             and ratr2.cod_fiscale like p_scf) ogpr_prec
        ,(select distinct 'x3' x, prtr1.cod_fiscale cf
            from oggetti_pratica ogpr1
                ,pratiche_tributo prtr1
                ,rapporti_tributo ratr1
           where prtr1.pratica = ogpr1.pratica
             and prtr1.anno = p_anno_rif
             and prtr1.tipo_pratica = 'A'
             and nvl(prtr1.stato_accertamento,'D') = 'D'
             and prtr1.tipo_tributo || '' = p_titr
             and prtr1.pratica = ratr1.pratica
             and ratr1.cod_fiscale like p_scf) acc_cont
        ,pratiche_tributo prtr
        ,tipi_tributo titr
        ,soggetti sogg
        ,contribuenti cont
        ,dati_generali dage
        ,oggetti_pratica ogpr
        ,oggetti_imposta ogim
   where liq_cont.cf(+) = cont.cod_fiscale
     and acc_cont.cf(+) = cont.cod_fiscale
     and ogpr_prec.cf(+) = cont.cod_fiscale
     and prtr.anno >= p_dic_da_anno
     and ogim.cod_fiscale = vers.cofi(+)
     and ogim.anno = vers.anno(+)
     and ogim.cod_fiscale = tard.cofi(+)
     and ogim.anno = tard.anno(+)
     and (decode(prtr.tipo_pratica, 'D', prtr.anno - 1, ogim.anno) <> prtr.anno)
     and decode(prtr.tipo_pratica, 'D', 'S', prtr.flag_denuncia) = 'S'
     and nvl(prtr.stato_accertamento,'D') = 'D'
     and prtr.pratica = ogpr.pratica
     and nvl(ogpr.tributo, 0) =
           decode(p_tributo, -1, nvl(ogpr.tributo, 0), p_tributo)
     and ogim.oggetto_pratica = ogpr.oggetto_pratica
     and prtr.tipo_tributo || '' = p_titr
     and cont.ni = sogg.ni
     and cont.cod_fiscale = ogim.cod_fiscale
     and ogim.flag_calcolo = 'S'
     and ogim.anno = p_anno_rif
     and ogim.cod_fiscale like p_scf
     and sogg.cognome_nome_ric like p_snome
     and titr.tipo_tributo = prtr.tipo_tributo
     --
     -- (VD - 10/04/2018): Solo per S.Donato Milanese:
     --                    se il motivo compensazione e' 90, si trattano
     --                    solo i contribuenti di Poasco andati a ruolo
     --                    suppletivo a saldo;
     --                    se il motivo compensazione e' diverso da 90,
     --                    si trattano solo gli altri contribuenti
     --
     and (d_cod_istat <> '015192' or
         (d_cod_istat = '015192' and
         ((p_motivo_compensazione = 90 and
           exists (select 'x' from conferimenti conf
                   where conf.cod_fiscale = ogim.cod_fiscale
                     and conf.ruolo = f_ruolo_totale ( ogim.cod_fiscale
                                                     , p_anno_rif
                                                     , ogim.tipo_tributo
                                                     , -1)))
      or  (p_motivo_compensazione <> 90 and
           not exists (select 'x' from conferimenti conf
                        where conf.cod_fiscale = ogim.cod_fiscale
                          and conf.ruolo = f_ruolo_totale ( ogim.cod_fiscale
                                                          , p_anno_rif
                                                          , ogim.tipo_tributo
                                                          , -1))))
         ))
group by cont.cod_fiscale
        ,cont.ni
        ,ogim.anno
        ,dage.fase_euro
        ,sogg.cognome
        ,sogg.nome
        ,prtr.tipo_tributo
  having (decode(p_tipo_imposta
                ,1,   nvl(f_dovuto_com(cont.ni
                                  ,p_anno_rif
                                  ,p_titr
                                  ,p_dic_da_anno
                                  ,p_tributo
                                  ,'D'
                                  ,null
                                  )
                         ,0
                         )
                    - (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                ,2,   round(nvl(f_dovuto_com(cont.ni
                                        ,p_anno_rif
                                        ,p_titr
                                        ,p_dic_da_anno
                                        ,p_tributo
                                        ,'D'
                                        ,null
                                        )
                               ,0
                               )
                           ,0
                           )
                    - (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                ,3,   nvl(f_dovuto_com(cont.ni
                                  ,p_anno_rif
                                  ,p_titr
                                  ,p_dic_da_anno
                                  ,p_tributo
                                  ,'DR'
                                  ,null
                                  )
                         ,0
                         )
                    - (  max(nvl(vers.s_vers, 0))
--                       + f_importo_vers_ravv(cont.cod_fiscale
--                                            ,p_titr
--                                            ,p_anno_rif
--                                            ,'U'
--                                            )
                      )
                )) between to_number(p_simp_da)
                       and to_number(p_simp_a)
  ;
BEGIN
  --
  -- (VD - 10/04/2018): si seleziona il codice ISTAT dell'ente
  --
  BEGIN
    select lpad(to_char(pro_cliente),3,'0')||
           lpad(to_char(com_cliente),3,'0')
      into d_cod_istat
      from dati_generali;
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(-20999,'Errore in ricerca dati generali ('||
                                     sqlerrm||')');
  END;
  FOR rec_dove IN sel_dove( a_anno - 1    -- controlli sul versato su anno prec
                          , a_tipo_tributo
                          , 0
                          , -1
                          , a_cod_fiscale
                          , '%'
                          , -999999999999
                          , -nvl(a_limite,0.01)
                          , a_tipo_imposta
                          , d_cod_istat
                          , a_motivo_compensazione
                          ) LOOP
      begin
         select count(1)
           into d_conta
           from compensazioni
          where cod_fiscale = rec_dove.cod_fiscale
            and tipo_tributo = a_tipo_tributo
            and anno = a_anno
            ;
      end;
      if d_conta = 0 then
         begin
           select count(*)
             into d_conta
             from versamenti
            where cod_fiscale = rec_dove.cod_fiscale
              and tipo_tributo = a_tipo_tributo
              and anno in (a_anno, a_anno - 1)
              and oggetto_imposta is not null
           ;
         end;
         if d_conta = 0 then
            insert into compensazioni
                    ( cod_fiscale, tipo_tributo, anno
                    , motivo_compensazione, compensazione, flag_automatico, utente )
             values ( rec_dove.cod_fiscale, a_tipo_tributo, a_anno
                    , a_motivo_compensazione, rec_dove.eccedenza, 'S', a_utente)
             ;
             if (instr(a_cod_fiscale, '%') = 0) then
               select max(comp.id_compensazione)
                      into a_id_compensazione
               from compensazioni comp;
             end if;
         else
            w_errore := w_errore ||chr(10)||chr(13)||rec_dove.cogn_nom||' '||rec_dove.cod_fiscale;
         end if;
      end if;
  END LOOP;
  if w_errore is not null then
     w_errore := 'Compensazioni non create in presenza di versamenti su oggetti per: '||w_errore;
     commit;
     raise_application_error(-20999,w_errore);
  end if;
END;
/* End Procedure: CREA_COMPENSAZIONI */
/

