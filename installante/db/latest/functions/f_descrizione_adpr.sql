--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_adpr stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_ADPR
(a_anno          in number)
RETURN varchar2
IS
  w_add_pro_std      varchar2(50) := '  ADD. PROV.';
  w_valore_inpa      varchar2(200);
  w_add_pro          varchar2(100);
  w_anno_dal         number;
  w_anno_al          number;
BEGIN
      begin
         select inpa.valore
           into w_valore_inpa
           from installazione_parametri inpa
          where inpa.parametro = 'DES_ADPR'
             ;
      exception
         when others then
           return w_add_pro_std;
      end;
      WHILE (length(w_valore_inpa) > 10)
      LOOP
         w_add_pro := substr(w_valore_inpa,1,instr(w_valore_inpa,'=') -1);
         w_anno_dal := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'=') + 1, 4));
         w_anno_al  := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'-') + 1, 4));
         if a_anno between w_anno_dal and w_anno_al then
            return w_add_pro;
         end if;
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa);
         w_valore_inpa := substr(w_valore_inpa,instr(w_valore_inpa,'-') + 6);
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa||' '||w_add_pro||' '||w_Anno_dal||' '||w_anno_al);
      END LOOP;
      return w_add_pro_std;
END;
/* End Function: F_DESCRIZIONE_ADPR */
/

