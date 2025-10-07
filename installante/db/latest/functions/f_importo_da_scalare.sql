--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_da_scalare stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_DA_SCALARE
/*************************************************************************
 NOME:        F_IMPORTO_DA_SCALARE
 DESCRIZIONE: Ruoli suppletivi: determina l'importo gia' andato a ruolo
              da scalare dall'importo calcolato
 RITORNA:     number              Importo da scalare
 NOTE:        Valori tipo_importo PF - Quota fissa
                                  PV - Quota variabile
                                  TOT - Importo totale
                                  PFB - Quota fissa alla tariffa base
                                  PVB - Quota variabile alla tariffa base
                                  TOTB - Importo totale alla tariffa base
 Rev.    Date         Author      Note
 001     24/10/2018   VD          Selezione importi calcolati con tariffa
                                  base.
 000     01/12/2008   XX          Prima emissione.
*************************************************************************/
(p_ruolo                          number
,p_cf                             varchar2
,p_anno                           number
,p_dal                            date
,p_al                             date
,p_titr                           varchar2
,p_ogpr                           number
,p_norm                           varchar2
,p_tipo_importo                   varchar2
,p_tratta_sgravio                 number)
RETURN number
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
BEGIN  -- f_importo_da_scalare
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
     WHEN NO_DATA_FOUND THEN
        w_importo := 0;
        w_sgravi  := 0;
        w_importo_pv := -1;
        w_importo_pf := -1;
        w_importo_base := 0;
        w_sgravi_base  := 0;
        w_importo_pv_base := -1;
        w_importo_pf_base := -1;
     WHEN OTHERS THEN
        RETURN -1;
  END;
   w_importo := round(nvl(w_importo,0) - nvl(w_sgravi,0),2);
   w_importo_base := round(nvl(w_importo_base,0) - nvl(w_sgravi_base,0),2);
   if p_tipo_importo = 'PV' then
      RETURN w_importo_pv;
   elsif p_tipo_importo = 'PF' then
      RETURN w_importo_pf;
   elsif p_tipo_importo = 'TOT' then
      RETURN w_importo;
   elsif p_tipo_importo = 'PVB' then
      RETURN w_importo_pv_base;
   elsif p_tipo_importo = 'PFB' then
      RETURN w_importo_pf_base;
   else
      RETURN w_importo_base;
   end if;
END;
/* End Function: F_IMPORTO_DA_SCALARE */
/

