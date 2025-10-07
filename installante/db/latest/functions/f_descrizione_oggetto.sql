--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_oggetto stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_OGGETTO
( p_oggetto                number
, p_tipo                   varchar2 default null
)
return varchar2 is
  w_descrizione            varchar2(200);
begin
  begin
    select decode(ogge.cod_via
                 ,null, substr(ogge.indirizzo_localita,1,25)
                 ,substr(arvi.denom_uff,1,25)
                 )
           ||decode(ogge.num_civ
                   ,null, ''
                   ,', ' || to_char(ogge.num_civ)
                   )
           ||decode(ogge.suffisso
                   ,null, ''
                   ,'/' || ogge.suffisso)
      into w_descrizione
      from oggetti ogge,
           archivio_vie arvi
     where ogge.oggetto = p_oggetto
       and ogge.cod_via = arvi.cod_via(+);
  exception
    when others then
      w_descrizione := 'Non identificato';
  end;
--
  return w_descrizione;
--
end;
/* End Function: F_DESCRIZIONE_OGGETTO */
/

