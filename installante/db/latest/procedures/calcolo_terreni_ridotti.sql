--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_terreni_ridotti stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_TERRENI_RIDOTTI
(a_tot_terreni_con_rid       IN     NUMBER
,a_tot_terreni_con_rid_1sem  IN     NUMBER
,a_coeff_rid                 IN     NUMBER
,a_coeff_rid_1sem            IN     NUMBER
,a_aliquota_ogim             IN     NUMBER
,a_perc_possesso             IN     NUMBER
,a_mesi_possesso             IN     NUMBER
,a_mesi_possesso_1sem        IN     NUMBER
,a_valore                    IN     NUMBER
,a_valore_1sem               IN     NUMBER
,a_aliquota_prec_ogpr        IN     NUMBER
,a_anno_ogco                 IN     NUMBER
,a_acconto_terreni           IN OUT NUMBER
,a_terreni                   IN OUT NUMBER
) is
w_fase_euro        number;
w_50000000         number;
w_120000000        number;
w_200000000        number;
w_250000000        number;
w_d50000000        number;
w_d70000000        number;
w_d80000000        number;
w_imp_fascia_030   number;
w_imp_fascia_050   number;
w_imp_fascia_075   number;
w_imp_fascia_100   number;
w_perc_1s          number;
w_aliquota         number;
w_mesi_possesso    number;
w_imp_fascia       number;
BEGIN
   BEGIN
     select fase_euro
       into w_fase_euro
       from dati_generali
     ;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
   END;
   if a_anno_ogco >= 2012 then
     w_50000000   := 6000;                          -- fascia 1
     w_120000000  := 15500;                         -- fascia 2
     w_200000000  := 25500;                         -- fascia 3
     w_250000000  := 32000;                         -- fascia 4
     w_d70000000  := w_120000000 - w_50000000;      -- differenza fascia 2 - fascia 1
     w_d80000000  := w_200000000 - w_120000000;     -- differenza fascia 3 - fascia 2
     w_d50000000  := w_250000000 - w_200000000;     -- differenza fascia 4 - fascia 3
   elsif w_fase_euro = 1 then
     w_50000000   := 50000000;
     w_120000000  := 120000000;
     w_200000000  := 200000000;
     w_250000000  := 250000000;
     w_d50000000  := 50000000;
     w_d70000000  := 70000000;
     w_d80000000  := 80000000;
   else
     w_50000000   := 25822.845;
     w_120000000  := 61974.827;
     w_200000000  := 103291.379;
     w_250000000  := 129114.224;
     w_d50000000  := 25822.845;
     w_d70000000  := 36151.982;
     w_d80000000  := 41316.552;
   end if;
   if a_coeff_rid <> 1 then
      if w_fase_euro = 1 then
         --dbms_output.put_line('Coeff '||to_char(a_coeff_rid));
         w_250000000 := round(w_250000000 * round(a_coeff_rid,4),0);
         w_200000000 := round(w_200000000 * round(a_coeff_rid,4),0);
         w_120000000 := round(w_120000000 * round(a_coeff_rid,4),0);
         w_50000000  := round(w_50000000  * round(a_coeff_rid,4),0);
      else
         w_250000000 := round(w_250000000 * round(a_coeff_rid,4),3);
         w_200000000 := round(w_200000000 * round(a_coeff_rid,4),3);
         w_120000000 := round(w_120000000 * round(a_coeff_rid,4),3);
         w_50000000  := round(w_50000000  * round(a_coeff_rid,4),3);
      end if;
      w_d50000000 := w_250000000 - w_200000000;
      w_d70000000 := w_120000000 - w_50000000;
      w_d80000000 := w_200000000 - w_120000000;
   end if;
   if a_anno_ogco > 2000 then
      w_perc_1s := 100;
   else
      w_perc_1s := 90;
   end if;
   if    a_tot_terreni_con_rid > w_250000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := w_d80000000;
      w_imp_fascia_075 := w_d50000000;
      w_imp_fascia_100 := a_tot_terreni_con_rid - w_250000000;
   elsif a_tot_terreni_con_rid > w_200000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := w_d80000000;
      w_imp_fascia_075 := a_tot_terreni_con_rid - w_200000000;
      w_imp_fascia_100 := 0;
   elsif a_tot_terreni_con_rid > w_120000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := a_tot_terreni_con_rid - w_120000000;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   elsif a_tot_terreni_con_rid > w_50000000  then
      w_imp_fascia_030 := a_tot_terreni_con_rid - w_50000000;
      w_imp_fascia_050 := 0;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   else
      w_imp_fascia_030 := 0;
      w_imp_fascia_050 := 0;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   end if;
--dbms_output.put_line('-------------------------------------------------');
--dbms_output.put_line('Terreni Rid. '||to_char(a_tot_terreni_con_rid));
--dbms_output.put_line('Valore '||to_char(a_valore));
--dbms_output.put_line('Fascia 030 '||to_char(w_imp_fascia_030));
--dbms_output.put_line('Fascia 050 '||to_char(w_imp_fascia_050));
--dbms_output.put_line('Fascia 075 '||to_char(w_imp_fascia_075));
--dbms_output.put_line('Fascia 100 '||to_char(w_imp_fascia_100));
   w_aliquota        := a_aliquota_ogim;
   w_mesi_possesso   := a_mesi_possesso;
   w_imp_fascia      := w_imp_fascia_030 * a_valore        / a_tot_terreni_con_rid * 0.30
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12;
--dbms_output.put_line('Imp.Fascia 030 '||to_char(w_imp_fascia));
   w_imp_fascia      := w_imp_fascia_050 * a_valore        / a_tot_terreni_con_rid * 0.50
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12;
--dbms_output.put_line('Imp.Fascia 050 '||to_char(w_imp_fascia));
   w_imp_fascia      := w_imp_fascia_075 * a_valore        / a_tot_terreni_con_rid * 0.75
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12;
--dbms_output.put_line('Imp.Fascia 075 '||to_char(w_imp_fascia));
   w_imp_fascia      := w_imp_fascia_100 * a_valore        / a_tot_terreni_con_rid
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12;
--dbms_output.put_line('Imp.Fascia 100 '||to_char(w_imp_fascia));
   a_terreni         := w_imp_fascia_030 * a_valore        / a_tot_terreni_con_rid * 0.30
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12
                      + w_imp_fascia_050 * a_valore        / a_tot_terreni_con_rid * 0.50
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12
                      + w_imp_fascia_075 * a_valore        / a_tot_terreni_con_rid * 0.75
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12
                      + w_imp_fascia_100 * a_valore        / a_tot_terreni_con_rid
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12;
--dbms_output.put_line('Totale - Aliq. '||to_char(w_aliquota)||
--                     ' Mesi '||to_char(w_mesi_possesso)||' Imposta '||to_char(a_terreni)
--                    );
--
-- GESTIONE ACCONTO.
--
   if a_anno_ogco >= 2012 then
     w_50000000   := 6000;                          -- fascia 1
     w_120000000  := 15500;                         -- fascia 2
     w_200000000  := 25500;                         -- fascia 3
     w_250000000  := 32000;                         -- fascia 4
     w_d70000000  := w_120000000 - w_50000000;      -- differenza fascia 2 - fascia 1
     w_d80000000  := w_200000000 - w_120000000;     -- differenza fascia 3 - fascia 2
     w_d50000000  := w_250000000 - w_200000000;     -- differenza fascia 4 - fascia 3
   elsif w_fase_euro = 1 then
     w_50000000   := 50000000;
     w_120000000  := 120000000;
     w_200000000  := 200000000;
     w_250000000  := 250000000;
     w_d50000000  := 50000000;
     w_d70000000  := 70000000;
     w_d80000000  := 80000000;
   else
     w_50000000   := 25822.845;
     w_120000000  := 61974.827;
     w_200000000  := 103291.379;
     w_250000000  := 129114.224;
     w_d50000000  := 25822.845;
     w_d70000000  := 36151.982;
     w_d80000000  := 41316.552;
   end if;
   if a_coeff_rid <> 1 then
      if w_fase_euro = 1 then
         w_250000000 := round(w_250000000 * round(a_coeff_rid_1sem,4),0);
         w_200000000 := round(w_200000000 * round(a_coeff_rid_1sem,4),0);
         w_120000000 := round(w_120000000 * round(a_coeff_rid_1sem,4),0);
         w_50000000  := round(w_50000000  * round(a_coeff_rid_1sem,4),0);
      else
         w_250000000 := round(w_250000000 * round(a_coeff_rid_1sem,4),3);
         w_200000000 := round(w_200000000 * round(a_coeff_rid_1sem,4),3);
         w_120000000 := round(w_120000000 * round(a_coeff_rid_1sem,4),3);
         w_50000000  := round(w_50000000  * round(a_coeff_rid_1sem,4),3);
      end if;
      w_d50000000 := w_250000000 - w_200000000;
      w_d70000000 := w_120000000 - w_50000000;
      w_d80000000 := w_200000000 - w_120000000;
   end if;
   if    a_tot_terreni_con_rid_1sem > w_250000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := w_d80000000;
      w_imp_fascia_075 := w_d50000000;
      w_imp_fascia_100 := a_tot_terreni_con_rid_1sem - w_250000000;
   elsif a_tot_terreni_con_rid_1sem > w_200000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := w_d80000000;
      w_imp_fascia_075 := a_tot_terreni_con_rid_1sem - w_200000000;
      w_imp_fascia_100 := 0;
   elsif a_tot_terreni_con_rid_1sem > w_120000000 then
      w_imp_fascia_030 := w_d70000000;
      w_imp_fascia_050 := a_tot_terreni_con_rid_1sem - w_120000000;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   elsif a_tot_terreni_con_rid_1sem > w_50000000  then
      w_imp_fascia_030 := a_tot_terreni_con_rid_1sem - w_50000000;
      w_imp_fascia_050 := 0;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   else
      w_imp_fascia_030 := 0;
      w_imp_fascia_050 := 0;
      w_imp_fascia_075 := 0;
      w_imp_fascia_100 := 0;
   end if;
   if a_anno_ogco > 2000 then
      w_aliquota        := a_aliquota_prec_ogpr;
   end if;
   w_mesi_possesso   := a_mesi_possesso_1sem;
   a_acconto_terreni := w_imp_fascia_030 * a_valore_1sem   / a_tot_terreni_con_rid_1sem * 0.30
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12   * w_perc_1s / 100
                      + w_imp_fascia_050 * a_valore_1sem   / a_tot_terreni_con_rid_1sem * 0.50
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12   * w_perc_1s / 100
                      + w_imp_fascia_075 * a_valore_1sem   / a_tot_terreni_con_rid_1sem * 0.75
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12   * w_perc_1s / 100
                      + w_imp_fascia_100 * a_valore_1sem   / a_tot_terreni_con_rid_1sem
                                         * w_aliquota      / 1000
                                         * a_perc_possesso / 100
                                         * w_mesi_possesso / 12   * w_perc_1s / 100;
--dbms_output.put_line('Acconto - Aliq. '||to_char(w_aliquota)||
--  ' Mesi '||to_char(w_mesi_possesso)||' Imposta '||to_char(a_acconto_terreni)
--                    );
--dbms_output.put_line('-------------------------------------------------');
EXCEPTION
   WHEN others THEN
      null;
END;
/* End Procedure: CALCOLO_TERRENI_RIDOTTI */
/

