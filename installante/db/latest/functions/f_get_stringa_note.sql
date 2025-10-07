--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_stringa_note stripComments:false runOnChange:true 
 
create or replace function F_GET_STRINGA_NOTE
( p_pratica                number
) return varchar2
is
  w_stringa                varchar2(32767) := '';
  w_note                   varchar2(4000);
begin
  for ogpr_rif in (select oggetto_pratica_rif
                     from oggetti_pratica
                    where pratica = p_pratica)
  loop
    begin
      select note
        into w_note
        from oggetti_pratica
       where oggetto_pratica = ogpr_rif.oggetto_pratica_rif;
    exception
      when others then
        w_note := '';
    end;
    --
    if w_note is not null then
       if w_stringa is null then
          w_stringa := w_note;
       else
          w_stringa := w_stringa||'; '||w_note;
       end if;
    end if;
  end loop;
--
  return w_stringa;
--
end;
/* End Function: F_GET_STRINGA_NOTE */
/

