--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivio_vie_fi stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE ARCHIVIO_VIE_FI
(a_cod_via_old      IN   number,
 a_cod_via_new      IN   number,
 a_denom_uff      IN    varchar2,
 a_denom_ord      IN   varchar2)
IS
BEGIN
  IF INSERTING THEN
     BEGIN
       insert into denominazioni_via (cod_via,progr_via,descrizione)
       select a_cod_via_new,1,a_denom_uff
         from dual
       union
       select a_cod_via_new,99,a_denom_ord
         from dual
       ;
     EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in inserimento Denominazioni Vie');
     END;
  ELSIF UPDATING THEN
     BEGIN
       update denominazioni_via
      set cod_via      = a_cod_via_new,
         descrizione   = decode(progr_via,1,a_denom_uff,
                    99,a_denom_ord)
   where cod_via      = a_cod_via_old
     and progr_via      in (1,99)
       ;
     EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in aggiornamento Denominazioni Vie');
     END;
     IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR
     (-20999,'Identificazione '||a_cod_via_old||
        ' non presente in Denominazioni Vie');
     END IF;
  END IF;
END;
/* End Procedure: ARCHIVIO_VIE_FI */
/

