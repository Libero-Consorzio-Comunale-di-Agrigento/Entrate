--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_da_scalare_sem stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_DA_SCALARE_SEM
/*************************************************************************
 NOME:        F_IMPORTO_DA_SCALARE_SEM
 DESCRIZIONE: Determina gli importi gia' andati a ruolo nel primo semestre.
              Personalizzazione per Bovezzo.
 RITORNA:     number              Importo da scalare
 NOTE:        Valori tipo_importo PF - Quota fissa
                                  PV - Quota variabile
                                  TOT - Importo totale
                                  PFB - Quota fissa alla tariffa base
                                  PVB - Quota variabile alla tariffa base
                                  TOTB - Importo totale alla tariffa base
 Rev.    Date         Author      Note
 001     06/11/2018   VD          Selezione importi calcolati con tariffa
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
,p_tratta_sgravio                 number
) RETURN   number
IS
w_importo                         number  := 0;
w_importo_calc                    number;
w_sgravi                          number  := 0;
w_sgravi_calc                     number;
w_importo_pv                      number  := 0;
w_importo_pv_calc                 number;
w_importo_pf                      number  := 0;
w_importo_pf_calc                 number;
w_tiev                            varchar2(1) := '';
w_al                              date;
w_da_mese_ruolo                   number;
w_a_mese_ruolo                    number;
w_mese                            number;
-- (VD - 06/11/2018): Gestione importi calcolati con tariffa base
w_importo_base                    number  := 0;
w_importo_calc_base               number;
w_sgravi_base                     number  := 0;
w_sgravi_calc_base                number;
w_importo_pv_base                 number  := 0;
w_importo_pv_calc_base            number;
w_importo_pf_base                 number  := 0;
w_importo_pf_calc_base            number;
BEGIN  -- f_importo_da_scalare_sem
   w_da_mese_ruolo  := to_number(to_char(
                          greatest(
                              nvl(p_dal
                                 ,to_date('0101'||to_char(p_anno),'ddmmyyyy'))
                                  ,to_date('0101'||to_char(p_anno),'ddmmyyyy'))
                                        ,'mm'));
   w_a_mese_ruolo   := to_number(to_char(
                          least(
                             nvl(p_al
                                ,to_date('3112'||to_char(p_anno),'ddmmyyyy'))
                               ,to_date('3112'||to_char(p_anno),'ddmmyyyy'))
                                        ,'mm'));
   w_mese :=  w_da_mese_ruolo;
   WHILE w_mese <= w_a_mese_ruolo  LOOP
     BEGIN
      select nvl(sum(decode(ruol.importo_lordo
                           ,'S',nvl(ruco.importo,0) - nvl(ogim.addizionale_eca,0)
                                                    - nvl(ogim.maggiorazione_eca,0)
                                                    - nvl(ogim.maggiorazione_tares,0)
                                                    - nvl(ogim.addizionale_pro,0)
                                                    - nvl(ogim.iva,0)
                           ,nvl(ruco.importo,0)
                           )  / (ruco.a_mese - ruco.da_mese + 1)
                ),0)
           , nvl(sum(nvl(importo_pv,0) / (ruco.a_mese - ruco.da_mese + 1) ),0)
           , nvl(sum(nvl(importo_pf,0) / (ruco.a_mese - ruco.da_mese + 1) ),0)
           , nvl(sum(decode(ruol.importo_lordo
                           ,'S',nvl(ruco.importo_base,0) - nvl(ogim.addizionale_eca_base,0)
                                                         - nvl(ogim.maggiorazione_eca_base,0)
                                                         - nvl(ogim.addizionale_pro_base,0)
                                                         - nvl(ogim.iva_base,0)
                           ,nvl(ruco.importo_base,0)
                           )  / (ruco.a_mese - ruco.da_mese + 1)
                ),0)
           , nvl(sum(nvl(importo_pv_base,0) / (ruco.a_mese - ruco.da_mese + 1) ),0)
           , nvl(sum(nvl(importo_pf_base,0) / (ruco.a_mese - ruco.da_mese + 1) ),0)
        into w_importo_calc
           , w_importo_pv_calc
           , w_importo_pf_calc
           , w_importo_calc_base
           , w_importo_pv_calc_base
           , w_importo_pf_calc_base
        from oggetti_pratica       ogpr
            ,oggetti_imposta       ogim
            ,oggetti_contribuente  ogco
            ,ruoli_contribuente    ruco
            ,ruoli                 ruol
       where ruol.ruolo            = ruco.ruolo
         and ogim.oggetto_imposta  = ruco.oggetto_imposta
         and ogim.cod_fiscale      = p_cf
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
         and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                   = p_ogpr
         and ogco.cod_fiscale      = ogim.cod_fiscale
         and ogco.oggetto_pratica  = ogim.oggetto_pratica
         and p_dal                >= nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
         and p_dal                 <
             nvl(ogco.data_cessazione,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ruco.ruolo            = ogim.ruolo
         and ruco.ruolo           <> p_ruolo
         and ruol.invio_consorzio is not null
         and ruol.anno_ruolo       = p_anno
         and ruco.cod_fiscale      = p_cf
         and ruol.tipo_tributo||'' = p_titr
         and w_mese between nvl(ruco.da_mese,0)
                        and nvl(ruco.a_mese,0)
         and (ruco.a_mese - ruco.da_mese + 1) > 0
      ;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_importo_calc := 0;
         w_importo_pv_calc := 0;
         w_importo_pf_calc := 0;
         w_importo_calc_base := 0;
         w_importo_pv_calc_base := 0;
         w_importo_pf_calc_base := 0;
      WHEN OTHERS THEN
         RETURN -1;
     END;
     -- Sgravi ---------------
     BEGIN
      select nvl(sum(decode(ruol.importo_lordo
                           ,'S',nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                                    - nvl(sgra.maggiorazione_eca,0)
                                                    - nvl(sgra.maggiorazione_tares,0)
                                                    - nvl(sgra.addizionale_pro,0)
                                                    - nvl(sgra.iva,0)
                           ,nvl(sgra.importo,0)
                           ) / (sgra.a_mese - sgra.da_mese + 1)
                    ),0) * p_tratta_sgravio
           , nvl(sum(decode(ruol.importo_lordo
                           ,'S',nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                                    - nvl(sgra.maggiorazione_eca_base,0)
                                                    - nvl(sgra.addizionale_pro_base,0)
                                                    - nvl(sgra.iva_base,0)
                           ,nvl(sgra.importo_base,0)
                           ) / (sgra.a_mese - sgra.da_mese + 1)
                    ),0) * p_tratta_sgravio
        into w_sgravi_calc
           , w_sgravi_calc_base
        from oggetti_pratica       ogpr
            ,oggetti_imposta       ogim
            ,oggetti_contribuente  ogco
            ,sgravi                sgra
            ,ruoli_contribuente    ruco
            ,ruoli                 ruol
       where ruol.ruolo            = ruco.ruolo
         and ogim.oggetto_imposta  = ruco.oggetto_imposta
         and ogim.cod_fiscale      = p_cf
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
         and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                   = p_ogpr
         and ogco.cod_fiscale      = ogim.cod_fiscale
         and ogco.oggetto_pratica  = ogim.oggetto_pratica
         and p_dal                >= nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
         and p_dal                 <
             nvl(ogco.data_cessazione,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ruco.ruolo            = ogim.ruolo
         and ruco.ruolo           <> p_ruolo
         and ruol.invio_consorzio is not null
         and ruol.anno_ruolo       = p_anno
         and ruco.cod_fiscale      = p_cf
         and ruol.tipo_tributo||'' = p_titr
         and sgra.ruolo            = ruco.ruolo
         and sgra.cod_fiscale      = ruco.cod_fiscale
         and sgra.sequenza         = ruco.sequenza
         and sgra.FLAG_AUTOMATICO  = 'S'
         and w_mese between nvl(sgra.da_mese,0)
                        and nvl(sgra.a_mese,0)
         and (sgra.a_mese - sgra.da_mese + 1) > 0
      ;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_sgravi_calc  := 0;
         w_sgravi_calc_base  := 0;
      WHEN OTHERS THEN
         RETURN -1;
     END;
     w_importo := w_importo + w_importo_calc;
     w_sgravi  := w_sgravi  + w_sgravi_calc;
     w_importo_pv := w_importo_pv + w_importo_pv_calc;
     w_importo_pf := w_importo_pf + w_importo_pf_calc;
     -- (VD - 06/11/2018): Gestione importi calcolati con tariffa base
     w_importo_base := w_importo_base + w_importo_calc_base;
     w_sgravi_base  := w_sgravi_base  + w_sgravi_calc_base;
     w_importo_pv_base := w_importo_pv_base + w_importo_pv_calc_base;
     w_importo_pf_base := w_importo_pf_base + w_importo_pf_calc_base;
     w_mese := w_mese + 1;
   end loop;
   w_importo := round(nvl(w_importo,0) - nvl(w_sgravi,0),2);
   -- (VD - 06/11/2018): Gestione importi calcolati con tariffa base
   w_importo_base := round(nvl(w_importo_base,0) - nvl(w_sgravi_base,0),2);
   if p_tipo_importo = 'PV' then
      RETURN round(w_importo_pv,2);
   elsif p_tipo_importo = 'PF' then
      RETURN round(w_importo_pf,2);
   elsif p_tipo_importo = 'TOT' then
      RETURN w_importo;
   elsif p_tipo_importo = 'PVB' then
      RETURN round(w_importo_pv_base,2);
   elsif p_tipo_importo = 'PFB' then
      RETURN round(w_importo_pf_base,2);
   else
      RETURN w_importo_base;
   end if;
END;
/* End Function: F_IMPORTO_DA_SCALARE_SEM */
/

