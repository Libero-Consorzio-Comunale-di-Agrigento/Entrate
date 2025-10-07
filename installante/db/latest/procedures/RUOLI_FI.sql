--liquibase formatted sql 
--changeset abrandolini:20250326_152423_RUOLI_FI stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure RUOLI_FI
(a_ruolo	          IN number,
 a_tipo_emissione_old IN varchar2,
 a_tipo_emissione_new IN varchar2
)

IS

w_controllo	varchar2(1);

BEGIN
  IF UPDATING THEN
    IF nvl(a_tipo_emissione_old,'T') != nvl(a_tipo_emissione_new,'T') THEN
      BEGIN
        select 'x'
          into w_controllo
          from compensazioni_ruolo coru
         where coru.ruolo = a_ruolo
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Modifica del Tipo emissione non consentita: '||
               'esistono riferimenti in Compensazioni Ruolo');
        WHEN no_data_found THEN
         null;
        WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Compensazioni Ruolo');
      END;
    END IF;
  END IF;
END;
/* End Procedure: RUOLI_FI */
/
