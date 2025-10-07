--liquibase formatted sql 
--changeset abrandolini:20250326_152423_contribuenti_cu stripComments:false runOnChange:true 
 
create or replace procedure CONTRIBUENTI_CU
/******************************************************************************
 Rev. Data       Autore    Descrizione
 ---- ---------- ------    ----------------------------------------------------
 005  20/02/2025    AB     Aggiunto il controllo per Ruoli_eccedenze
 004  10/06/2024    AB     Aggiunto il controllo per Codici_RFID
 003  17/04/2023    AB     #69103
                           Aggiunto "or OLD_NI != NEW_NI" per il lancio di depag
 002  10/04/2023    AB     #69103
                           Inserito la commit per chiudere la sessione autonoma
 001  04/03/2023    AB     #69103
                           Inserito pragma autonomous_transaction;
                           per poter utilizzare la commit del pagonline_tr4
                           altrimenti darebbe errore il trigger tiu
 000  20/09/1998    AB     Prima emissione
******************************************************************************/
(old_cod_fiscale IN varchar,
 new_cod_fiscale IN varchar,
 old_ni          IN number,
 new_ni          IN number)
is
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
   max_seq          integer;
   w_result         char(6);
   pragma autonomous_transaction;

begin

   --  Modify parent code of "CONTRIBUENTI" for all children in "OGGETTI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update OGGETTI_CONTRIBUENTE
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "MAGGIORI_DETRAZIONI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update MAGGIORI_DETRAZIONI
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Maggiori Detrazioni');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "RAPPORTI_TRIBUTO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update RAPPORTI_TRIBUTO
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "PRATICHE_TRIBUTO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update PRATICHE_TRIBUTO
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "STO_OGGETTI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update STO_OGGETTI_CONTRIBUENTE
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "STO_RAPPORTI_TRIBUTO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update STO_RAPPORTI_TRIBUTO
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "STO_PRATICHE_TRIBUTO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update STO_PRATICHE_TRIBUTO
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "RUOLI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update RUOLI_CONTRIBUENTE ruco
         set COD_FISCALE = NEW_COD_FISCALE,
             SEQUENZA    = (select nvl(max(ruco1.sequenza),0) + ruco.sequenza
		 	      from ruoli_contribuente ruco1
		             where ruco1.COD_FISCALE  = NEW_COD_FISCALE
                               and ruco1.ruolo        = ruco.ruolo)
       where COD_FISCALE = OLD_COD_FISCALE
    	;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "VERSAMENTI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update VERSAMENTI vers
         set COD_FISCALE = NEW_COD_FISCALE,
             SEQUENZA    = (select nvl(max(vers1.sequenza),0) + vers.sequenza
		 	      from versamenti vers1
		             where vers1.COD_FISCALE  = NEW_COD_FISCALE
                               and vers1.anno   	  = vers.anno
              	               and vers1.tipo_tributo = vers.tipo_tributo)
       where COD_FISCALE = OLD_COD_FISCALE
    	;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "RATE_IMPOSTA"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update RATE_IMPOSTA
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "ANOMALIE_ICI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      update ANOMALIE_ICI
       set   COD_FISCALE = NEW_COD_FISCALE
      where  COD_FISCALE = OLD_COD_FISCALE;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CONTATTI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      select nvl(max(sequenza),0)
        into max_seq
        from CONTATTI_CONTRIBUENTE
       where COD_FISCALE = NEW_COD_FISCALE
      ;

      if (max_seq is not NULL) then
         update CONTATTI_CONTRIBUENTE
            set COD_FISCALE = NEW_COD_FISCALE,
                SEQUENZA    = SEQUENZA + max_seq
          where COD_FISCALE = OLD_COD_FISCALE;
      end if;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "TERRENI_RIDOTTI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update TERRENI_RIDOTTI
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Terreni Ridotti sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "DELEGHE_BANCARIE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update DELEGHE_BANCARIE
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Deleghe Bancarie sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "NOTIFICHE_OGGETTO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update NOTIFICHE_OGGETTO
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Notifiche Oggetto sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "FATTURE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update FATTURE
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Fatture sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "COMPENSAZIONI_RUOLO"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update COMPENSAZIONI_RUOLO
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Compensazioni Ruolo sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "ALLINEAMENTO_DELEGHE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
      update ALLINEAMENTO_DELEGHE
         set COD_FISCALE = NEW_COD_FISCALE
       where COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Allineamento Deleghe sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "DETRAZIONI_FIGLI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update DETRAZIONI_FIGLI
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Detrazioni Figli sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "EVENTI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update EVENTI_CONTRIBUENTE
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Eventi Contribuente sul nuovo Contribuente');
      END;
   end if;

     --  Modify parent code of "TR4.CONTRIBUENTI" for all children in "DOCUMENTI_CONTRIBUENTE"
     if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update DOCUMENTI_CONTRIBUENTE
         set   COD_FISCALE = NEW_COD_FISCALE
        where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Documenti Contribuente sul nuovo Contribuente');
      END;
     end if;

     --  Modify parent code of "TR4.CONTRIBUENTI" for all children in "COMPENSAZIONI"
     if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update COMPENSAZIONI
         set   COD_FISCALE = NEW_COD_FISCALE
        where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Compensazioni sul nuovo Contribuente');
      END;
     end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CONFERIMENTI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update CONFERIMENTI
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Conferimenti sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CONFERIMENTI_CER"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update CONFERIMENTI_CER
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Conferimenti CER sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CONTRIBUENTI_CC_SOGGETTI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update CONTRIBUENTI_CC_SOGGETTI
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Contribunti CC Soggetti sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "DETTAGLI_ELABORAZIONE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update DETTAGLI_ELABORAZIONE
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Dettagli Elaborazione sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "SAM_INTERROGAZIONI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update SAM_INTERROGAZIONI
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono SAM Interrogazioni sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "STATI_CONTRIBUENTE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update STATI_CONTRIBUENTE
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Stati Contribuente sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CODICI_RFID"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update CODICI_RFID
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Codici RFID sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "CODICI_RFID"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update CODICI_RFID
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Codici RFID sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "RUOLI_ECCEDENZE"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE) then
      BEGIN
        update RUOLI_ECCEDENZE
           set   COD_FISCALE = NEW_COD_FISCALE
         where  COD_FISCALE = OLD_COD_FISCALE;
      EXCEPTION
        WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR
                   (-20999,'Aggiornamento non consentito: Esistono Ruoli Eccedenze sul nuovo Contribuente');
      END;
   end if;

   --  Modify parent code of "CONTRIBUENTI" for all children in "DEPAG_DOVUTI"
   if (OLD_COD_FISCALE != NEW_COD_FISCALE or OLD_NI != NEW_NI) then
      BEGIN
        w_result := PAGONLINE_TR4.AGGIORNA_DATI_ANAGRAFICI(OLD_COD_FISCALE, NEW_COD_FISCALE, OLD_NI, NEW_NI);
        IF w_result < 0 then
           RAISE_APPLICATION_ERROR
                 (-20999,'Aggiornamento non consentito: Esistono Dovuti bloccanti nel DEPAG');
        end if;
      END;
   end if;

   commit;  -- Aggiunto per chiudere la sessione autonoma

end;
/* End Procedure: CONTRIBUENTI_CU */
/
