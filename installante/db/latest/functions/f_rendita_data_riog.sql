--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_rendita_data_riog stripComments:false runOnChange:true 
 
create or replace function F_RENDITA_DATA_RIOG
(p_oggetto            IN number
,p_data               IN date)
RETURN number
IS
w_rendita        NUMBER;
errore           exception;
w_errore         varchar2(2000);
BEGIN
   BEGIN
      select riog.rendita
        into w_rendita
        from riferimenti_oggetto riog
       where riog.oggetto   = p_oggetto
         and p_data >= decode(greatest(15,to_number(to_char(riog.inizio_validita,'dd')))
                                                                          ,15,to_date('01'||to_char(riog.inizio_validita,'mmyyyy'),'ddmmyyyy')
                                                                                           ,last_day(riog.inizio_validita) + 1)
         and p_data <= decode(greatest(15,to_number(to_char(nvl(riog.fine_validita,to_date('31129999','ddmmyyyy')),'dd')))
                                                                                  ,15,to_date('01'||to_char(riog.fine_validita,'mmyyyy'),'ddmmyyyy') - 1
                                                                                                         ,last_day(riog.fine_validita))
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
/* End Function: F_RENDITA_DATA_RIOG */
/

