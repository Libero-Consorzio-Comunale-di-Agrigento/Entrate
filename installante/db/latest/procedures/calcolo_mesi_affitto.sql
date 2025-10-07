--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_mesi_affitto stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_MESI_AFFITTO
(a_anno_rif         IN     NUMBER
,a_anno             IN     NUMBER
,a_data_scadenza    IN     DATE
,a_dep_mesi_affitto IN     NUMBER
,a_mesi_affitto     IN OUT NUMBER
,a_mesi_affitto_1s  IN OUT NUMBER
) IS
w_data_scadenza            date;
w_aa                       number;
w_mm                       number;
w_dep_mm                   number;
w_dep_mesi_affitto         number;
w_anno                     number;
w_mesi_affitto             number;
w_mesi_affitto_1s          number;
BEGIN
   w_data_scadenza    := a_data_scadenza;
--   w_dep_mesi_affitto := a_dep_mesi_affitto;
   w_anno             := a_anno;
   w_mesi_affitto     := a_mesi_affitto;
   w_mesi_affitto_1s  := a_mesi_affitto_1s;
--
-- Se anno = anno di riferimento, la data di inizio affitto si ricava
-- dalla differenza tra la data di scadenza o di fine anno se la scadenza
-- non e` dell`esercizio di riferimento e numero di mesi di affitto;
-- se anno < anno di riferimento e
-- la scadenza e` dell`anno di riferimento, la data di inizio affitto e`
-- l`inizio anno; se data di scadenza e anno non sono dell`anno di riferimento,
-- le date rispettive sono quelle di inizio e fine anno.
-- Il numero dei mesi di affitto e` riferito solo al primo anno di affitto;
-- per gli altri anni i mesi di affitto sono quelli tra inizio anno e data di
-- scadenza per l`ultimo anno o 12 per gli anni diversi dal primo e ultimo.
--
   if w_anno < a_anno_rif then
      if to_number(to_char(w_data_scadenza,'yyyy')) > a_anno_rif then
         w_data_scadenza := to_date('3112'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy');
         w_dep_mesi_affitto := 12;
      else
         w_dep_mesi_affitto := to_number(to_char(w_data_scadenza,'mm'));
      end if;
   else
      if to_number(to_char(w_data_scadenza,'yyyy')) > a_anno_rif then
         w_data_scadenza := to_date('3112'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy');
         w_dep_mesi_affitto := a_dep_mesi_affitto;
      else
         w_dep_mesi_affitto := a_dep_mesi_affitto;
      end if;
   end if;
--
-- Si considerano i mesi di affitto per anno di riferimento
-- a partire dalla Data di Scadenza e procedendo a ritroso mese
-- per mese.
--
   w_aa     := to_number(to_char(w_data_scadenza,'yyyy'));
   w_mm     := to_number(to_char(w_data_scadenza,'mm'));
--
-- Si inizializzano le variabili di lavoro al loro valore + 1
-- per uniformare il trattamento nel loop.
--
   w_mm     := w_mm + 1;
   if w_mm   = 13 then
      w_mm  := 1;
      w_aa  := w_aa + 1;
   end if;
   w_dep_mm := w_dep_mesi_affitto + 1;
   LOOP
--
-- Si analizza il mese precedente; se esauriti, finisce il trattamento.
--
      w_dep_mm := w_dep_mm - 1;
      if w_dep_mm = 0 then
         exit;
      end if;
--
-- Si decrementa il mese che inizialmente era della data di scadenza;
-- Se risulta azzerato, si cambia anche anno e si riporta il mese a 12.
--
      w_mm := w_mm - 1;
      if w_mm = 0 then
         w_mm := 12;
         w_aa := w_aa - 1;
      end if;
--
-- Se si sta esaminando un anno inferiore a quello di riferimento,
-- i mesi di affitto rimanenti si riferiscono a periodi precedenti
-- e non interessano, per cui si termina il trattamento.
--
      if w_aa < a_anno_rif then
         exit;
      end if;
--
-- Se si sta esaminando l`anno di riferimento, si tratta di un mese di affitto
-- che se poi non raggiunge il settimo si considera del primo semestre.
--
      if w_aa = a_anno_rif then
         w_mesi_affitto := w_mesi_affitto + 1;
         if w_mm < 7 then
            w_mesi_affitto_1s := w_mesi_affitto_1s + 1;
         end if;
      end if;
   END LOOP;
   a_mesi_affitto    := w_mesi_affitto;
   a_mesi_affitto_1s := w_mesi_affitto_1s;
END;
/* End Procedure: CALCOLO_MESI_AFFITTO */
/

