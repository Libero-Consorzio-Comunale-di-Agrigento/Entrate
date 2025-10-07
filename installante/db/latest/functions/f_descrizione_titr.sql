--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_titr stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_TITR
(a_tipo_tributo in varchar2
,a_anno          in number
,a_titr_scelta_rapida in varchar2 default NULL)
RETURN varchar2
IS
  w_valore_inpa varchar2(200);
  w_titr             varchar2(100);
  w_anno_dal         number;
  w_anno_al          number;
BEGIN
  IF a_titr_scelta_rapida is null then
      begin
         select inpa.valore
           into w_valore_inpa
           from installazione_parametri inpa
          where inpa.parametro = 'DES_'||a_tipo_tributo
             ;
      exception
         when others then
           return a_tipo_tributo;
      end;
      --TARSU=1980-2005 TIA=2006-2012 TARES=2013-2099
      WHILE (length(w_valore_inpa) > 10)
      LOOP
         w_titr := substr(w_valore_inpa,1,instr(w_valore_inpa,'=') -1);
         w_anno_dal := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'=') + 1, 4));
         w_anno_al  := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'-') + 1, 4));
         if a_anno between w_anno_dal and w_anno_al then
            return w_titr;
         end if;
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa);
    --    ICI=1990-2011 IMU=2012-2099
              w_valore_inpa := substr(w_valore_inpa,instr(w_valore_inpa,'-') + 6);
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa||' '||w_titr||' '||w_Anno_dal||' '||w_anno_al);
      END LOOP;
      return a_tipo_tributo;
  ELSE
      begin
         select inpa.valore
           into w_valore_inpa
           from installazione_parametri inpa
          where inpa.parametro = 'DESR_'||a_tipo_tributo
             ;
      exception
         when others then
           return a_titr_scelta_rapida;
      end;
      WHILE (length(w_valore_inpa) > 10)
      LOOP
         w_titr := substr(w_valore_inpa,1,instr(w_valore_inpa,'=') -1);
         w_anno_dal := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'=') + 1, 4));
         w_anno_al  := to_number(substr(w_valore_inpa,instr(w_valore_inpa,'-') + 1, 4));
         if a_anno between w_anno_dal and w_anno_al then
            return w_titr;
         end if;
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa);
    --    ICI=1990-2011 IMU=2012-2099
              w_valore_inpa := substr(w_valore_inpa,instr(w_valore_inpa,'-') + 6);
    --     RAISE_APPLICATION_ERROR('-20666', w_valore_inpa||' '||w_titr||' '||w_Anno_dal||' '||w_anno_al);
      END LOOP;
       return a_titr_scelta_rapida;
  END IF;
END;
/* End Function: F_DESCRIZIONE_TITR */
/

