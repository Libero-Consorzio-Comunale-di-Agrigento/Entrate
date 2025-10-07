--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcolo_interessi_gg stripComments:false runOnChange:true 
 
create or replace function F_CALCOLO_INTERESSI_GG
(a_importo          in     number
,a_dal              in     date
,a_al               in     date
,a_gg_anno          in     number
) Return number is
w_dal               date;
w_interessi         number;
w_anno              number(4);
w_mese              number(2);
w_temp              varchar2(4);
w_interesse_singolo number;
cursor sel_periodo(p_dal date,p_al date) is
select inte.aliquota
      ,greatest(inte.data_inizio,p_dal) dal
      ,least(inte.data_fine,p_al) al
  from interessi inte
 where inte.tipo_tributo      = 'TARSU'
   and inte.data_inizio      <= p_al
   and inte.data_fine        >= p_dal
   and inte.tipo_interesse    = 'L'
;
--Questa funzione viene usata solo per il Ravvedimento TARSU e si applica l'interesse Legale
--Il valore a_dal di ingresso non è la data di scadenza ma la data di scadenza +1
--i giorni di interesse si contano dal giorno dopo la data di scadenza
--Occorre ricordarsi di richiamare questa funzione passando data_scadenza +1 come secondo parametro
BEGIN
   w_interessi := 0;
   FOR rec_periodo IN sel_periodo(a_dal,a_al)
   LOOP
      w_interesse_singolo := nvl(a_importo,0) * nvl(rec_periodo.aliquota,0) / 100 *
                             (rec_periodo.al + 1 - rec_periodo.dal) / a_gg_anno;
      w_interessi := w_interessi + w_interesse_singolo;
--dbms_output.put_line('Importo = '||to_char(a_importo)||' Aliquota = '||to_char(rec_periodo.aliquota)||
--' Al = '||to_char(rec_periodo.al,'dd/mm/yyyy')||' Dal = '||to_char(rec_periodo.dal,'dd/mm/yyyy')||
--' Giorni = '||to_char(rec_periodo.al - rec_periodo.dal + 1));
   END LOOP;
   Return w_interessi;
END;
/* End Function: F_CALCOLO_INTERESSI_GG */
/

