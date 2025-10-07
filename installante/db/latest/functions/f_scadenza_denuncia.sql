--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_scadenza_denuncia stripComments:false runOnChange:true 
 
create or replace function F_SCADENZA_DENUNCIA
(a_tipo_trib    varchar2,
 a_anno    number
)
RETURN date
IS
w_data_scad date;
BEGIN
  select data_scadenza
    into w_data_scad
    from scadenze
   where tipo_tributo   = a_tipo_trib
     and anno      = a_anno
     and tipo_scadenza   = 'D'
   ;
   RETURN w_data_scad;
EXCEPTION
   WHEN OTHERS THEN
        RETURN NULL;
END;
/* End Function: F_SCADENZA_DENUNCIA */
/

