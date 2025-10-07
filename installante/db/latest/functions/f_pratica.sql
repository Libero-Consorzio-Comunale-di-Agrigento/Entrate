--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_pratica stripComments:false runOnChange:true 
 
create or replace function F_PRATICA
(a_pratica            IN number)
RETURN varchar2
IS
w_dati_pratica   varchar2(4);
errore           exception;
w_errore         varchar2(2000);
BEGIN
      BEGIN
         select   nvl(prtr.tipo_pratica,' ')
                ||nvl(prtr.tipo_evento,' ')
                ||nvl(prtr.stato_accertamento,'D')
           into w_dati_pratica
           from pratiche_tributo prtr
          where pratica    = a_pratica
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_dati_pratica := '';
         WHEN others THEN
            w_errore := 'Errore in ricerca Dati Pratica(f_pratica)'||
                        ' ('||SQLERRM||')';
            RAISE errore;
      END;
   RETURN w_dati_pratica ;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in F_PRATCA '||
       ' ('||SQLERRM||')');
END;
/* End Function: F_PRATICA */
/

