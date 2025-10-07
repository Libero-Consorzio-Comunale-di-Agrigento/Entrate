--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcolo_interessi stripComments:false runOnChange:true 
 
create or replace function F_CALCOLO_INTERESSI
(a_tipo_tributo varchar2,
 a_importo      number,
 a_dal         date,
 a_al         date,
 a_semestri in out number)
RETURN number
IS
   w_dal            date;
   w_interessi      number;
   w_anno      number(4);
   w_mese      number(2);
   sTemp      varchar2(4);
   w_interesse_singolo    number;
   CURSOR sel_periodo (p_titr varchar2, p_dal date, p_al date)
   IS
     SELECT ALIQUOTA, GREATEST(data_inizio,p_dal) DAL, LEAST(data_fine,p_al) AL
       FROM INTERESSI
      WHERE TIPO_TRIBUTO = p_titr
        AND DATA_INIZIO <= p_al
        AND DATA_FINE   >= p_dal
        AND TIPO_INTERESSE = 'S'
     ;
BEGIN
    a_semestri:= 0;
    sTemp := to_char(a_dal,'ddmm');
    IF (sTemp <> '0101') AND (sTemp <> '0107') AND a_tipo_tributo <> 'TOSAP' THEN
       w_mese := to_number(to_char(a_dal,'mm'));
       w_anno := to_number(to_char(a_dal,'yyyy'));
       IF w_mese > 6 THEN
          w_dal := to_date('01/01/'||(w_anno + 1),'dd/mm/yyyy');
       ELSE
          w_dal := to_date('01/07/'||w_anno,'dd/mm/yyyy');
       END IF;
       IF (sTemp = '0201') OR (stemp = '0207') THEN
      w_dal := a_dal-1;
       END IF;
    ELSE
       w_dal := a_dal;
    END IF;
    w_interessi   := 0;
    FOR rec_periodo IN sel_periodo(a_tipo_tributo,w_dal,a_al) LOOP
       a_semestri       := a_semestri + trunc(months_between(rec_periodo.al + 1, rec_periodo.dal)/6);
        w_interesse_singolo := nvl((a_importo * trunc(months_between(rec_periodo.al + 1, rec_periodo.dal)/6)
            * rec_periodo.aliquota / 100),0);
   w_interessi := w_interessi + w_interesse_singolo;
    END LOOP;
    RETURN w_interessi;
END;
/* End Function: F_CALCOLO_INTERESSI */
/

