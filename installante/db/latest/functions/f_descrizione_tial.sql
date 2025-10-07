--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_tial stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_TIAL
(p_tipo_tributo     varchar2,
 p_tipo_aliquota    varchar2)
  return varchar2
is
  w_descr_tial   tipi_aliquota.descrizione%type;
BEGIN
  select descrizione
    into w_descr_tial
    from tipi_aliquota tial
   where tipo_tributo = p_tipo_tributo
     and tipo_aliquota = p_tipo_aliquota
  ;
  return w_descr_tial;
EXCEPTION
  when others then return null;
END;
/* End Function: F_DESCRIZIONE_TIAL */
/
