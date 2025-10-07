--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_interessi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_INTERESSI
(a_data_inizio      IN    date,
 a_data_fine      IN    date,
 a_importo_base      IN    number,
 a_tipo_tributo      IN   varchar2,
 a_interessi      IN OUT   number)
IS
w_data_inizio      date;
w_semestri      number;
w_aliquota_1      number;
w_semestri_1      number;
BEGIN
  w_data_inizio := a_data_inizio;
  w_semestri    := trunc(months_between(a_data_fine + 1,a_data_inizio) / 6);
  WHILE w_data_inizio < a_data_fine LOOP
        BEGIN
     select aliquota,
             trunc(months_between(
         decode(sign(a_data_fine - data_fine),-1,
           a_data_fine + 1,data_fine + 1),
           a_data_inizio) / 6),
       decode(sign(a_data_fine - data_fine),-1,
         a_data_fine,data_fine)
       into w_aliquota_1,w_semestri_1,w_data_inizio
       from interessi
      where tipo_tributo   = a_tipo_tributo
          and w_data_inizio + 1 between data_inizio and data_fine
     ;
   EXCEPTION
     WHEN no_data_found THEN
          RAISE_APPLICATION_ERROR
       (-20999,'Manca il periodo in Interessi');
     WHEN others THEN
          RAISE_APPLICATION_ERROR
       (-20999,'Errore in ricerca Interessi');
   END;
        a_interessi     := f_round(nvl(a_importo_base,0)
                   * w_semestri_1
                   * w_aliquota_1
                   / 100 , 0)
                 + nvl(a_interessi,0);
  END LOOP;
END;
/* End Procedure: CALCOLO_INTERESSI */
/

