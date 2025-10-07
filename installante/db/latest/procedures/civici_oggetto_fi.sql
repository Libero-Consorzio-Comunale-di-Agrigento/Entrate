--liquibase formatted sql 
--changeset abrandolini:20250326_152423_civici_oggetto_fi stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE CIVICI_OGGETTO_FI
(a_oggetto      IN    number,
 a_indirizzo_localita   IN      varchar2,
 a_cod_via      IN   number,
 a_num_civ      IN    number,
 a_suffisso      IN   varchar2)
IS
w_controllo      varchar2(1);
BEGIN
  select 'x'
    into w_controllo
    from oggetti
   where oggetto                = a_oggetto
     and nvl(indirizzo_localita,' ') = nvl(a_indirizzo_localita,' ')
     and nvl(cod_via,0)                = nvl(a_cod_via,0)
     and nvl(num_civ,0)                = nvl(a_num_civ,0)
     and nvl(suffisso,' ')        = nvl(a_suffisso,' ')
  ;
  RAISE too_many_rows;
EXCEPTION
  WHEN no_data_found THEN
    null;
  WHEN too_many_rows THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Eliminazione non consentita: civico presente in Oggetti');
END;
/* End Procedure: CIVICI_OGGETTO_FI */
/

