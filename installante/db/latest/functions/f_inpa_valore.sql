--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_inpa_valore stripComments:false runOnChange:true 
 
create or replace function F_INPA_VALORE
(p_parametro in varchar2)
RETURN VARCHAR2 IS
/******************************************************************************
 NOME:        f_inpa_valore
 DESCRIZIONE: Restituisce il valore del parametro p_parametro da
                         INSTALLAZIONE_PARAMETRI.Se il parametro non esiste
                         restituisce null.
 PARAMETRI:   p_parametro IN VARCHAR2 NI parametro da cercare
 RITORNA:     Restituisce il valore del parametro p_parametro da
                         INSTALLAZIONE_PARAMETRI
 ECCEZIONI:
 ANNOTAZIONI: Se il parametro non esiste
                         restituisce null.
******************************************************************************/
retVal INSTALLAZIONE_PARAMETRI.VALORE%TYPE;
begin
 BEGIN
  retVal := NULL;
     SELECT VALORE
       INTO retVal
       FROM INSTALLAZIONE_PARAMETRI
      WHERE PARAMETRO = upper(p_parametro)
       ;
 EXCEPTION
   WHEN OTHERS THEN
        retVal := NULL;
 END;
RETURN retVal;
end;
/* End Function: F_INPA_VALORE */
/

