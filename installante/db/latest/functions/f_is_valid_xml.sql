--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_is_valid_xml stripComments:false runOnChange:true 
 
create or replace function F_IS_VALID_XML(xml_param blob) return int as
  scratch xmltype;
begin
  select xmltype(f_blob2clob(xml_param)) into scratch from dual;
  return 1;
exception
  when others then
    return 0;
end;
/* End Function: F_IS_VALID_XML */
/
