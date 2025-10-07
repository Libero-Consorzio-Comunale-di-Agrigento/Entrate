--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_paut_valore stripComments:false runOnChange:true 
 
create or replace function F_PAUT_VALORE
( p_utente                 in varchar2
, p_parametro              in varchar2
, p_tipo_parametro         in varchar2 default null)
return varchar2 is
/******************************************************************************
 NOME:                   f_paut_valore
 DESCRIZIONE:            Restituisce il valore del parametro p_parametro da
                         PARAMETRI_UTENTE.Se il parametro non esiste
                         restituisce null.
                         Se indicato anche il tipo parametro, restituisce
                         la substr del valore relativo al tipo parametro
                         indicato
 PARAMETRI:              p_utente             utente dell'applicativo
                         p_parametro          parametro da cercare
                         p_tipo_parametro     stringa parziale del campo
                                              valore
 RITORNA:                Restituisce il valore del parametro p_parametro da
                         parametri_utente
 ECCEZIONI:
 ANNOTAZIONI:            Se il parametro non esiste restituisce null.
******************************************************************************/
w_return                 varchar2(2000);
w_inizio                 number;
w_lunghezza              number;
begin
  begin
    w_return := null;
      select valore
        into w_return
        from parametri_utente
       where utente = nvl(upper(p_utente),'XXX')
         and tipo_parametro = upper(p_parametro)
        ;
  exception
    when others then
      w_return := null;
  end;
--
  if p_tipo_parametro is not null and
     w_return is not null then
     w_inizio := instr(w_return,p_tipo_parametro)+length(p_tipo_parametro)+2;
     w_lunghezza := instr(w_return,'"',w_inizio,2) - instr(w_return,'"',w_inizio,1) + 1;
     w_return := ltrim(rtrim(substr(w_return,w_inizio,w_lunghezza),'"'),'"');
     if p_tipo_parametro = 'annoOggetti' and
        w_return = 'Tutti' then
        w_return := '9999';
     end if;
  else -- w_return is null, non si è trovato alcun record
    if p_parametro = 'SIT_CONTR' and
       p_tipo_parametro = 'annoOggetti' then
       w_return := '9999';
    end if;
  end if;
return w_return;
end;
/* End Function: F_PAUT_VALORE */
/

