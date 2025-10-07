--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_scadenza_boll stripComments:false runOnChange:true 
 
create or replace function F_SCADENZA_BOLL
(a_tipo_trib    varchar2,
 a_anno         number,
 a_pratica      number) RETURN date
IS
--Funzione utilizzata nel bollettini COSAP
w_data_scad     date;
w_scadenza_boll date;
w_cod_istat     varchar2(6);
BEGIN
   BEGIN
      select lpad(to_char(pro_cliente), 3, '0') ||
             lpad(to_char(com_cliente), 3, '0')
        into w_cod_istat
        from dati_generali;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
   END;
   BEGIN
     select data_scadenza
       into w_data_scad
       from scadenze
      where tipo_tributo   = a_tipo_trib
        and anno      = a_anno
        and rata      = 0
        and tipo_scadenza   = 'V'
      ;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END;
   IF w_cod_istat = '048033' THEN
      BEGIN
         select decode(sign(data - w_data_scad),0,data + 30,1,data + 30,w_data_scad)
          into w_scadenza_boll
          from pratiche_tributo
         where pratica   = a_pratica
           and anno       = a_anno
         ;
      EXCEPTION
         WHEN no_data_found THEN
              w_scadenza_boll := w_data_scad;
         WHEN OTHERS THEN
              RETURN NULL;
      END;
   ELSE
      w_scadenza_boll := w_data_scad;
   END IF;
 RETURN w_scadenza_boll;
END;
/* End Function: F_SCADENZA_BOLL */
/

