--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_rendita_anno_riog stripComments:false runOnChange:true 
 
create or replace function F_RENDITA_ANNO_RIOG
(p_oggetto            IN number
,p_anno               IN number)
RETURN number
IS
w_rendita        NUMBER;
errore           exception;
w_errore         varchar2(2000);
BEGIN
   BEGIN
      select rire.rendita
        into w_rendita
        from riferimenti_oggetto rire
       where rire.oggetto   = p_oggetto
         and p_anno between to_number(to_char(rire.inizio_validita,'yyyy'))
                        and nvl(to_number(to_char(rire.fine_validita,'yyyy')),9999)
      ;
   EXCEPTION
      WHEN no_data_found THEN
         w_rendita := null;
      WHEN others THEN
         w_rendita := null;
   END;
   RETURN w_rendita ;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in recupero rendita '||
       ' ('||SQLERRM||')');
END;
/* End Function: F_RENDITA_ANNO_RIOG */
/

