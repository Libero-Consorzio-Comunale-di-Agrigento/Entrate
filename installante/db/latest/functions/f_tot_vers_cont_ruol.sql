--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_tot_vers_cont_ruol stripComments:false runOnChange:true 
 
create or replace function F_TOT_VERS_CONT_RUOL
/*************************************************************************
 NOME:        F_TOT_VERS_CONT_RUOL
 DESCRIZIONE: Dati anno, ruolo, tipo tributo, codice fiscale e tipo importo,
              restituisce il relativo totale.
 RITORNA:     number              Importo totale
 NOTE:        Valori previsti per parametro p_calcolo:
              V               Versamenti
              V+              Versamenti positivi
              VC              Versamenti su compensazione
              VC+             Versamenti su compensazione positivi
              VS              Versamenti spontanei
              VS+             Versamenti spontanei positivi
              M               Versamenti maggiorazione TARES
              VN              Versamenti al netto della maggiorazione TARES
              VN+             Versamenti positivi al netto della magg. TARES
              S               Sgravi (lordo - comprensivo di addizionali)
              SN              Sgravi netti (detratte le addizionali)
              SM              Sgravi - importo maggiorazione TARES
              C               Compensazioni
              CN              Compensazioni al netto delle addizionali
              VI              Versamenti Imposta (TARI)
              VI+             Versamenti Imposta (TARI) positivi
              VP              Versamenti Addizionale Provinciale (TEFA)
              VP+             Versamenti Addizionale Provinciale (TEFA) positivi
              SP              Sgravi Addizionale Provinciale
              CP              Compensazioni di Addizionale Provinciale
 Rev.    Date         Author      Note
 08      10/01/2024   DM          #77577
                                  Eliminato vincolo >= 2021 su addizionali.
 07      04/03/2021   VE          Aggiunti tipo calcolo P e P +: restituiscono
                                  rispettivamente il totale dei versamenti
                                  di addizionale provinciale e dei versamenti
                                  positivi di addizionale provinciale.
 06      09/10/2017   VD          Aggiunto tipo calcolo CN: restituisce il
                                  totale delle compensazioni al netto delle
                                  addizionale
 05      20/01/2017   VD          Aggiunto tipo calcolo SN: restituisce lo
                                  sgravio al netto di tutte le addizionali
 04      11/11/2016   VD          Aggiunti tipi calcolo:
                                  VC/VC+: restituisce il versato da compensazione
                                  VS/VS+: restituisce il versato spontaneo
 03      14/01/2014   Betta T.    Aggiunto test per escludere sgravi auto da ruoli acconto
 02      06/11/2014   Betta T.    Aggiunta gestione dei versamenti solo positivi (V+)
 01      05/11/2014   Betta T.    Aggiunta gestione dei versamenti netti
                                  solo positivi (VN+)
 00      06/11/2012   XX          Prima emissione.
*************************************************************************/
(p_anno     number
,p_cf       varchar2
,p_titr     varchar2
,p_ruolo    varchar2
,p_calcolo  varchar2  default 'V'
)
return number
IS
w_tot_cont             number;
w_cod_istat            varchar2(6);
w_add_pro              number;
BEGIN
  begin
    select lpad(pro_cliente,3,'0')||
           lpad(com_cliente,3,'0')
      into w_cod_istat
      from dati_generali;
  exception
    when others then
      raise_application_error(-20999,'Dati generali non presenti o multipli');
  end;
  --
  -- Selezione percentuali addizionali da CARICHI_TARSU
  --
   BEGIN
     select cata.addizionale_pro
       into w_add_pro
       from carichi_tarsu  cata
      where cata.anno = p_anno;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca carichi TARSU'||
                ' ('||SQLERRM||')');
   END;
   --
   if p_calcolo in ('V','V+') then
/* Versato Totale                                       */
      BEGIN
         select nvl(sum(vers.importo_versato ),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'V'
                or (p_calcolo = 'V+'
                   and vers.importo_versato > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo in ('VC','VC+') then
/* Versato Totale da Compensazione                      */
      BEGIN
         select nvl(sum(vers.importo_versato ),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.id_compensazione          is not null
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'VC'
                or (p_calcolo = 'VC+'
                   and vers.importo_versato > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo in ('VS','VS+') then
/* Versato Totale spontaneo                             */
      BEGIN
         select nvl(sum(vers.importo_versato ),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.id_compensazione          is null
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'VS'
                or (p_calcolo = 'VS+'
                   and vers.importo_versato > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
      elsif p_calcolo = 'S' then
/* Sgravi */
-- la select degli sgravi per ora viene usata solo dalla stampa dell'f24
-- per i ruoli in acconto dobbiamo ignorare gli sgravi auto
      BEGIN
         select nvl(sum(nvl(sgra.importo,0)),0)
           into w_tot_cont
           from sgravi sgra
               ,ruoli  ruol
          where ruol.ruolo                       = sgra.ruolo
            and ruol.invio_consorzio            is not null
            and ruol.anno_ruolo                  = p_anno
            and ruol.tipo_tributo                = p_titr
            and sgra.cod_fiscale                 = p_cf
            and (nvl(ruol.tipo_emissione,'T') != 'A'
                or (nvl(ruol.tipo_emissione,'T') = 'A'
                   and sgra.motivo_sgravio != 99))
            and (ruol.ruolo     = p_ruolo or p_ruolo is null)
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
      elsif p_calcolo = 'SN' then
/* Sgravi al netto delle addizionali*/
      BEGIN
         select nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                            - nvl(sgra.maggiorazione_eca,0)
                                            - nvl(sgra.addizionale_pro,0)
                                            - nvl(sgra.iva,0)),0)
           into w_tot_cont
           from sgravi sgra
               ,ruoli  ruol
          where ruol.ruolo                       = sgra.ruolo
            and ruol.invio_consorzio            is not null
            and ruol.anno_ruolo                  = p_anno
            and ruol.tipo_tributo                = p_titr
            and sgra.cod_fiscale                 = p_cf
            and (nvl(ruol.tipo_emissione,'T') != 'A'
                or (nvl(ruol.tipo_emissione,'T') = 'A'
                   and sgra.motivo_sgravio != 99))
            and (ruol.ruolo     = p_ruolo or p_ruolo is null)
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'SM' then
/* Sgravi di Maggiorazione TARES*/
      BEGIN
         select nvl(sum(nvl(sgra.maggiorazione_tares ,0)),0)
           into w_tot_cont
           from sgravi sgra
               ,ruoli  ruol
          where ruol.ruolo                       = sgra.ruolo
            and ruol.invio_consorzio            is not null
            and ruol.anno_ruolo                  = p_anno
            and ruol.tipo_tributo                = p_titr
            and sgra.cod_fiscale                 = p_cf
            and (nvl(ruol.tipo_emissione,'T') != 'A'
                or (nvl(ruol.tipo_emissione,'T') = 'A'
                   and sgra.motivo_sgravio != 99))
            and (ruol.ruolo     = p_ruolo or p_ruolo is null)
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'M' then
/* Versamenti di Maggiorazione TARES */
       BEGIN
         select nvl(sum(vers.maggiorazione_tares),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo IN ('VN','VN+') then
/* Versato meno Maggiorazione TARES */
       BEGIN
         select nvl(sum(vers.importo_versato),0) - nvl(sum(vers.maggiorazione_tares),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
            and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'VN'
                or (p_calcolo = 'VN+'
                   and nvl(vers.importo_versato,0) - nvl(vers.maggiorazione_tares,0) > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'C' then
/* Compensazione*/
       BEGIN
         select nvl(sum(coru.compensazione),0)
           into w_tot_cont
           from compensazioni_ruolo coru
          where coru.cod_fiscale               = p_cf
            and coru.anno                      = p_anno
             and coru.ruolo     = p_ruolo
             and motivo_compensazione = 99
          group by
                coru.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'CN' then
/* Compensazione netta*/
       BEGIN
         select nvl(sum(round((coru.compensazione * 100) / (100 + w_add_pro),2)),0)
           into w_tot_cont
           from compensazioni_ruolo coru
          where coru.cod_fiscale               = p_cf
            and coru.anno                      = p_anno
            and coru.ruolo     = p_ruolo
            and motivo_compensazione = 99
          group by
                coru.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo in ('VI','VI+') then
/* Versato Imposta (TARI) - Solo per anni >= 2021    */
      BEGIN
         select nvl(sum(vers.importo_versato - nvl(vers.addizionale_pro,0)),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and p_anno                         >= 2021
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'VI'
                or (p_calcolo = 'VI+'
                   and vers.importo_versato - nvl(vers.addizionale_pro,0) > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo in ('VP','VP+') then
/* Versato Addizionale Provinciale (TEFA) - Solo per anni >= 2021    */
      BEGIN
         select nvl(sum(vers.addizionale_pro ),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and p_anno                         >= 2021
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
             and (vers.ruolo     = p_ruolo or p_ruolo is null)
            and (p_calcolo = 'VP'
                or (p_calcolo = 'VP+'
                   and vers.addizionale_pro > 0
                   )
                )
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'SP' then
/* Sgravi di Addizionale Provinciale*/
      BEGIN
         select nvl(sum(nvl(sgra.addizionale_pro ,0)),0)
           into w_tot_cont
           from sgravi sgra
               ,ruoli  ruol
          where ruol.ruolo                       = sgra.ruolo
            and ruol.invio_consorzio            is not null
            and ruol.anno_ruolo                  = p_anno
            -- #77577            
            -- and p_anno                          >= 2021
            and ruol.tipo_tributo                = p_titr
            and sgra.cod_fiscale                 = p_cf
            and (nvl(ruol.tipo_emissione,'T') != 'A'
                or (nvl(ruol.tipo_emissione,'T') = 'A'
                   and sgra.motivo_sgravio != 99))
            and (ruol.ruolo     = p_ruolo or p_ruolo is null)
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'CP' then
/* Compensazione addizionale provinciale - Solo per anni >= 2021*/
      BEGIN
         select nvl(sum(round(coru.compensazione * w_add_pro / (100 + w_add_pro),2)),0)
           into w_tot_cont
           from compensazioni_ruolo coru
          where coru.cod_fiscale               = p_cf
            and coru.anno                      = p_anno
            and p_anno                        >= p_anno
            and coru.ruolo                     = p_ruolo
            and motivo_compensazione           = 99
          group by
                coru.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   else
      w_tot_cont := 0;
   end if;
   RETURN w_tot_cont;
EXCEPTION
   WHEN others THEN
      RETURN NULL;
END;
/* End Function: F_TOT_VERS_CONT_RUOL */
/
