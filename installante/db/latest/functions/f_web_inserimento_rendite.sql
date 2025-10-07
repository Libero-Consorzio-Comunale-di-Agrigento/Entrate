--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_inserimento_rendite stripComments:false runOnChange:true 
 
create or replace function F_WEB_INSERIMENTO_RENDITE
(a_id_immobile         in number,
 a_ver_data_cessazione in date,
 a_flag_cessati        in varchar2)
  return varchar2 is
  a_messaggio             varchar2(2000);
  ret                     VARCHAR2(2000);
begin
  ret := 'OK';
--  INSERIMENTO_RENDITE(A_ID_IMMOBILE,
--                      'TR4WEB',
--                      A_VER_DATA_CESSAZIONE,
--                      A_FLAG_CESSATI);
--(VD - 27/10/2020): sostituita procedure con relativa procedure del package
--                   per modifiche a tabelle catasto
  inserimento_rendite_pkg.inserimento_rendite(a_id_immobile,
                                              'F',
                                              a_ver_data_cessazione,
                                              a_flag_cessati,
                                              'TR4',
                                              to_number(null),
                                              a_messaggio
                                             );
  commit;
  return ret;
exception
  when others then
    raise_application_error(-20999,
                            'Errore in popolamento IMU da catasto ' || ' (' ||
                            sqlerrm || ')');
end;
/* End Function: F_WEB_INSERIMENTO_RENDITE */
/

