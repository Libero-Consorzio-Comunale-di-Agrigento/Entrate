--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_riog_data stripComments:false runOnChange:true 
 
create or replace function F_GET_RIOG_DATA(p_oggetto IN number,
                                           p_data    IN date,
                                           p_tipo    IN varchar2,
                                           p_anno    IN number default null)
  RETURN varchar2 IS
  w_categoria_catasto varchar2(3);
  w_classe_catasto    varchar2(2);
  errore              exception;
  w_errore            varchar2(2000);
BEGIN
  BEGIN
    if p_anno is not null then
      select riog.categoria_catasto, riog.classe_catasto
        into w_categoria_catasto, w_classe_catasto
        from riferimenti_oggetto riog
       where riog.oggetto = p_oggetto
         and p_anno between riog.da_anno and nvl(riog.a_anno,9999)
         and riog.inizio_validita = (select min(rio2.inizio_validita)
                                         from riferimenti_oggetto rio2
                                        where rio2.oggetto = p_oggetto
                                          and p_anno between rio2.da_anno and nvl(rio2.a_anno,9999))
      ;
    else
      select riog.categoria_catasto
                       , riog.classe_catasto
        into w_categoria_catasto
                           , w_classe_catasto
        from riferimenti_oggetto riog
       where riog.oggetto = p_oggetto
         and p_data >= decode(greatest(15,to_number(to_char(riog.inizio_validita,'dd')))
                                                                          ,15,to_date('01'||to_char(riog.inizio_validita,'mmyyyy'),'ddmmyyyy')
                                                                                           ,last_day(riog.inizio_validita) + 1)
         and p_data <= decode(greatest(15,to_number(to_char(nvl(riog.fine_validita,to_date('31129999','ddmmyyyy')),'dd')))
                                                                                  ,15,to_date('01'||to_char(riog.fine_validita,'mmyyyy'),'ddmmyyyy') - 1
                                                                                                         ,last_day(riog.fine_validita))
      ;
    end if;
  EXCEPTION
    WHEN no_data_found THEN
      w_categoria_catasto := null;
      w_classe_catasto    := null;
    WHEN others THEN
      w_categoria_catasto := null;
      w_classe_catasto    := null;
  END;
  --
  if p_tipo = 'CA' then
    return w_categoria_catasto;
  else
    return w_classe_catasto;
  end if;
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
/* End Function: F_GET_RIOG_DATA */
/
