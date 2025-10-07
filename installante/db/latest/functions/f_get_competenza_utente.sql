--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_competenza_utente stripComments:false runOnChange:true 
 
create or replace function F_GET_COMPETENZA_UTENTE
( p_utente                 varchar2
, p_tipo_tributo           varchar2
) return varchar2
is
  w_flag_competenze        varchar2(1);
  w_ritorno                varchar2(1);
begin
  begin
    select flag_competenze
      into w_flag_competenze
      from dati_generali;
  exception
    when others then
      w_flag_competenze := 'N';
  end;
--
  if w_flag_competenze = 'S' then
     begin
       select tiab.tipo_abilitazione
         into w_ritorno
         from si4_competenze        comp
            , si4_abilitazioni      abil
            , si4_tipi_abilitazione tiab
        where comp.id_abilitazione      = abil.id_abilitazione
          and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
          and comp.utente  = p_utente
          and comp.oggetto = p_tipo_Tributo
          and sysdate between nvl(comp.dal,to_date('01/01/1900','dd/mm/yyyy'))
                           and nvl(comp.al,to_date('31/12/2900','dd/mm/yyyy'))
        ;
     exception
       when others then
         w_ritorno := '';
     end;
  else
     w_ritorno := 'S';
  end if;
--
  return w_ritorno;
--
end;
/* End Function: F_GET_COMPETENZA_UTENTE */
/

