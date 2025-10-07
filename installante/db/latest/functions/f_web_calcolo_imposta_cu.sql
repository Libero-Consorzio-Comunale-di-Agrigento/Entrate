--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_calcolo_imposta_cu stripComments:false runOnChange:true 
 
create or replace function F_WEB_CALCOLO_IMPOSTA_CU
(A_ANNO                  number DEFAULT NULL
,A_COD_FISCALE           varchar2 DEFAULT NULL
,A_TIPO_TRIBUTO          varchar2 DEFAULT NULL
,A_OGPR                  number DEFAULT NULL
,A_UTENTE                varchar2 DEFAULT NULL
,A_FLAG_NORMALIZZATO     char DEFAULT NULL
,A_FLAG_RICHIAMO         varchar2 DEFAULT NULL
,A_CHK_RATE              number DEFAULT NULL
,A_LIMITE                number DEFAULT NULL
,A_PRATICA               number DEFAULT NULL
,a_ravvedimento          varchar2 default null
,a_gruppo_tributo        varchar2 default null
,a_scadenza_rata_1       date default null
,a_scadenza_rata_2       date default null
,a_scadenza_rata_3       date default null
,a_scadenza_rata_4       date default null
)
return varchar2
/******************************************************************************
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   19/03/2021  RV      Prima emissione, basato su F_WEB_CALCOLO_IMPOSTA (VD)
 002   14/12/2023  RV      #54732
                           Aggiunto parametri a_gruppo_tributo e a_scadenza_rata_x
******************************************************************************/
IS
   ret   VARCHAR2 (2000);
BEGIN
   ret := 'OK';
   CALCOLO_IMPOSTA_CU ( A_ANNO, A_COD_FISCALE, A_TIPO_TRIBUTO, A_OGPR, A_UTENTE, A_FLAG_NORMALIZZATO, A_FLAG_RICHIAMO,
                        A_CHK_RATE, A_LIMITE, A_PRATICA, a_ravvedimento, a_gruppo_tributo,
                        a_scadenza_rata_1, a_scadenza_rata_2, a_scadenza_rata_3, a_scadenza_rata_4 );
   COMMIT;
   RETURN ret;
EXCEPTION
   WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20999,'Errore in calcolo imposta '|| ' ('||SQLERRM||')');
END;
/* End Function: F_WEB_CALCOLO_IMPOSTA_CU */
/
