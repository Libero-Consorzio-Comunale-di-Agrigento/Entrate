--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_importi_da_scalare stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_IMPORTI_DA_SCALARE
/*************************************************************************
 NOME:        DETERMINA_IMPORTI_DA_SCALARE
 DESCRIZIONE: Ruoli suppletivi: determina tutti i tipi di importo gia' andati
              a ruolo da scalare agli importi calcolati
 NOTE:
 Rev.    Date         Author      Note
 001     23/01/2019   VD          Aggiunto parametro per ruolo gestito con
                                  tariffe precalcolate (anche in questo caso
                                  sono presenti gli importi "base").
 000     24/10/2018   VD          Prima emissione.
*************************************************************************/
(p_ruolo                          number
,p_cf                             varchar2
,p_anno                           number
,p_dal                            date
,p_al                             date
,p_titr                           varchar2
,p_ogpr                           number
,p_norm                           varchar2
,p_tratta_sgravio                 number
,p_flag_tariffa_base              varchar2
,p_flag_ruolo_tariffa             varchar2
,p_importo                    out number
,p_importo_pf                 out number
,p_importo_pv                 out number
,p_importo_base               out number
,p_importo_pf_base            out number
,p_importo_pv_base            out number
)
IS
  w_tiev                          varchar2(1) := '';
  w_al                            date;
  w_importo                       number;
  w_sgravi                        number;
  w_importo_pv                    number;
  w_importo_pf                    number;
  w_importo_base                  number;
  w_sgravi_base                   number;
  w_importo_pv_base               number;
  w_importo_pf_base               number;
BEGIN
  BEGIN
    select prtr.tipo_evento
      into w_tiev
      from pratiche_tributo prtr
         , oggetti_pratica ogpr
         , oggetti_contribuente ogco
     where ogpr.pratica = prtr.pratica
       and ogpr.oggetto_pratica_rif = p_ogpr
       and ogpr.oggetto_pratica = ogco.oggetto_pratica
       and ogco.data_cessazione = p_al
       and prtr.tipo_evento     = 'C'
       ;
  EXCEPTION
     WHEN OTHERS THEN
        w_tiev := '';
  END;
  if w_tiev = 'C' then
     w_al := to_date('31/12/'||to_char(p_anno),'dd/mm/yyyy');
  else
     w_al := p_al;
  end if;
  BEGIN
    select sum(decode(ruol.importo_lordo,'S',ruco.importo - nvl(ogim.addizionale_eca,0)
                                                          - nvl(ogim.maggiorazione_eca,0)
                                                          - nvl(ogim.addizionale_pro,0)
                                                          - nvl(ogim.iva,0)
                                                          - nvl(ogim.maggiorazione_tares,0)
                                            ,ruco.importo
                     ) * f_periodo(p_anno,p_dal,w_al,'P',p_titr,p_norm)
                       * 12 / decode(nvl(ruco.mesi_ruolo,12),0,12,nvl(ruco.mesi_ruolo,12))
              )
          ,sum(decode(ruol.importo_lordo,'S',nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                                                 - nvl(sgra.maggiorazione_eca,0)
                                                                 - nvl(sgra.addizionale_pro,0)
                                                                 - nvl(sgra.iva,0)
                                                                 - nvl(sgra.maggiorazione_tares,0)
                                            ,nvl(sgra.importo,0)
                     ) * f_periodo(p_anno,p_dal,w_al,'P',p_titr,p_norm)
                       * 12 / nvl(sgra.mesi_sgravio,12)
              ) * p_tratta_sgravio
          ,sum(ogim.importo_pv)
          ,sum(ogim.importo_pf)
          ,sum(decode(ruol.importo_lordo,'S',ruco.importo_base - nvl(ogim.addizionale_eca_base,0)
                                                               - nvl(ogim.maggiorazione_eca_base,0)
                                                               - nvl(ogim.addizionale_pro_base,0)
                                                               - nvl(ogim.iva_base,0)
                                            ,ruco.importo_base
                     ) * f_periodo(p_anno,p_dal,w_al,'P',p_titr,p_norm)
                       * 12 / decode(nvl(ruco.mesi_ruolo,12),0,12,nvl(ruco.mesi_ruolo,12))
              )
          ,sum(decode(ruol.importo_lordo,'S',nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                                                 - nvl(sgra.maggiorazione_eca_base,0)
                                                                 - nvl(sgra.addizionale_pro_base,0)
                                                                 - nvl(sgra.iva_base,0)
                                            ,nvl(sgra.importo_base,0)
                     ) * f_periodo(p_anno,p_dal,w_al,'P',p_titr,p_norm)
                       * 12 / nvl(sgra.mesi_sgravio,12)
              ) * p_tratta_sgravio
          ,sum(ogim.importo_pv_base)
          ,sum(ogim.importo_pf_base)
      into w_importo
          ,w_sgravi
          ,w_importo_pv
          ,w_importo_pf
          ,w_importo_base
          ,w_sgravi_base
          ,w_importo_pv_base
          ,w_importo_pf_base
      from oggetti_pratica       ogpr
          ,oggetti_imposta       ogim
          ,oggetti_contribuente  ogco
          ,sgravi                sgra
          ,ruoli_contribuente    ruco
          ,ruoli                 ruol
          ,oggetti_validita      ogva
     where ruol.ruolo            = ruco.ruolo
       and ogim.oggetto_imposta  = ruco.oggetto_imposta
       and ogim.cod_fiscale      = p_cf
       and ogpr.oggetto_pratica  = ogim.oggetto_pratica
       and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                 = p_ogpr
                and ogva.oggetto_pratica  = ogpr.oggetto_pratica
       and ogva.cod_fiscale      = ogco.cod_fiscale
       and ogva.dal              = ogco.data_decorrenza
       and ogco.cod_fiscale      = ogim.cod_fiscale
       and ogco.oggetto_pratica  = ogim.oggetto_pratica
       and p_dal                >= nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
       and p_dal                 <
           nvl(ogco.data_cessazione,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
      --     nvl(ogva.al,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
       and ruco.ruolo            = ogim.ruolo
       and ruco.ruolo           <> p_ruolo
       and ruol.invio_consorzio is not null
       and ruol.anno_ruolo       = p_anno
       and ruco.cod_fiscale      = p_cf
       and ruol.tipo_tributo||'' = p_titr
       and sgra.ruolo        (+) = ruco.ruolo
       and sgra.cod_fiscale  (+) = ruco.cod_fiscale
       and sgra.sequenza     (+) = ruco.sequenza
--         and sgra.FLAG_AUTOMATICO  (+) = 'S'  -- tolto il 21/10/2013 per evitare di non trattare quelli manuali a Rivoli
     ;
  EXCEPTION
     WHEN OTHERS THEN
        w_importo := 0;
        w_sgravi  := 0;
        w_importo_pv := -1;
        w_importo_pf := -1;
        w_importo_base := 0;
        w_sgravi_base  := 0;
        w_importo_pv_base := -1;
        w_importo_pf_base := -1;
  END;
  w_importo      := round(nvl(w_importo,0) - nvl(w_sgravi,0),2);
  w_importo_base := round(nvl(w_importo_base,0) - nvl(w_sgravi_base,0),2);
  p_importo         := f_round(w_importo,1);
  p_importo_pv      := f_round(w_importo_pv,1);
  p_importo_pf      := f_round(w_importo_pf,1);
  if p_flag_tariffa_base = 'S' or
     p_flag_ruolo_tariffa = 'S' then
     p_importo_base    := f_round(w_importo_base,1);
     p_importo_pv_base := f_round(w_importo_pv_base,1);
     p_importo_pf_base := f_round(w_importo_pf_base,1);
  else
     p_importo_base    := to_number(null);
     p_importo_pv_base := to_number(null);
     p_importo_pf_base := to_number(null);
  end if;
END;
/* End Procedure: DETERMINA_IMPORTI_DA_SCALARE */
/

