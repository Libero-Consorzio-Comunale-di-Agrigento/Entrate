--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_terreni stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_TERRENI
/*************************************************************************
  Rev.    Date         Author      Note
  3       17/02/2022   VD          Codigoro: in presenza di perc.possesso
                                   molto piccola e valore terreno molto basso
                                   il calcolo dell'imposta arrotondata a 2
                                   decimali da come risultato 0.
                                   Questo fa sì che in fase finale venga
                                   attribuito il tipo aliquota ridotta anziche
                                   il tipo aliquota normale.
                                   Aggiunto calcolo importi senza riduzioni
                                   con tutti i decimali possibili.
                                   Aggiunto test finale sui mesi senza riduzione
                                   per determinare il tipo_aliquota corretto.
  2       23/10/2020   VD          Modifiche per calcolo IMU a saldo 2020
                                   (D.L. 14 agosto 2020)
  1       28/08/2015   VD          Aggiunta totalizzazione importi dovuti
                                   in acconto e azzeramento relative
                                   variabili
*************************************************************************/
(
a_anno_rif                  IN number,
a_cod_fiscale               IN varchar2,
a_oggetto_pratica           IN number,
a_valore                    IN number,
a_valore_1s                 IN number,
a_valore_d                  IN number,
a_data_inizio_possesso      IN date,
a_data_fine_possesso        IN date,
a_data_inizio_possesso_1s   IN date,
a_data_fine_possesso_1s     IN date,
a_mesi_possesso             IN number,
a_mesi_possesso_1s          IN number,
a_mesi_riduzione            IN number,
a_mesi_riduzione_1s         IN number,
a_perc_possesso             IN number,
a_tipo_aliquota             IN number,
a_aliquota_terreni          IN number,
a_aliquota_terreni_prec     IN number,
a_tipo_aliquota_rid         IN number,
a_aliquota_terreni_rid      IN number,
a_aliquota_terreni_rid_prec IN number,
a_aliquota_terreni_erar     IN number,
a_aliquota_terreni_rid_erar IN number,
a_aliquota_terreni_rid_std  IN number,
a_utente                    IN varchar2,
a_tipo_tributo              IN varchar2
)
IS
errore                         exception;
w_errore                       varchar2(200);
w_tipo_pratica                 varchar2(1);
w_flag_calcolo                 varchar2(1);
w_flag_possesso_prec           varchar2(1);
w_flag_riduzione_prec          varchar2(1);
w_oggetto_prec                 number;
w_oggetto                      number;
w_valore                       number;
w_valore_1s                    number;
w_valore_d                     number;
w_valore_d_1s                  number;
w_tipo_al                      number;
w_al                           number;
w_al_erar                      number;
w_inizio_possesso              date;
w_fine_possesso                date;
w_inizio_possesso_1s           date;
w_fine_possesso_1s             date;
w_perc_acconto                 number;
w_mesi_possesso                number;
w_mesi_possesso_1s             number;
w_mesi_senza_rid               number;
w_mesi_senza_rid_1s            number;
w_mesi_riduzione_1s            number;
w_terreni                      number;
w_terreni_1s                   number;
w_terreni_con_rid              number;
w_terreni_con_rid_1s           number;
w_terreni_senza_rid            number;
w_terreni_senza_rid_1s         number;
w_perc_terreni_con_rid         number;
w_perc_terreni_con_rid_1s      number;
w_tot_terreni_con_rid          number;
w_tot_terreni_con_rid_1s       number;
w_importo                      number;
w_importo_1s                   number;
w_totale_importo               number;
w_totale_importo_1s            number;
w_totale_mesi                  number;
w_totale_mesi_1s               number;
--    Aggiunta gestione del Dovuto (wd) in caso di
--   Riferimenti_Oggetto valorizzato
wd_terreni                     number;
wd_terreni_1s                  number;
wd_terreni_con_rid             number;
wd_terreni_con_rid_1s          number;
wd_terreni_senza_rid           number;
wd_terreni_senza_rid_1s        number;
wd_perc_terreni_con_rid        number;
wd_perc_terreni_con_rid_1s     number;
wd_tot_terreni_con_rid         number;
wd_tot_terreni_con_rid_1s      number;
wd_totale_importo              number;
wd_totale_importo_1s           number;
w_mesi_riduzione               number;
w_terreni_erar                 number;
w_terreni_erar_1s              number;
w_terreni_senza_rid_erar       number;
w_terreni_senza_rid_erar_1s    number;
w_terreni_con_rid_erar         number;
w_terreni_con_rid_erar_1s      number;
wd_terreni_erar                number;
wd_terreni_erar_1s             number;
wd_terreni_senza_rid_erar      number;
wd_terreni_senza_rid_erar_1s   number;
wd_terreni_con_rid_erar        number;
wd_terreni_con_rid_erar_1s     number;
w_terreni_con_rid_std          number;
wd_terreni_con_rid_std         number;
w_terreni_con_rid_1s_std       number;
wd_terreni_con_rid_1s_std      number;
w_al_std                       number;
w_perc_saldo                   number;
w_imposta_saldo                number;
w_imposta_saldo_erar           number;
w_note_saldo                   varchar2(200);
-- (VD - 17/02/2022): Variabili per importi non arrotondati
w_terreni_senza_rid_na         number;
w_terreni_senza_rid_1s_na      number;
-- Cursore aggiunto per calcolare correttamente i valori dei terreni
-- se indicati piu` volte (si esegue la sommatoria del valore per i mesi di possesso
-- divisa per la sommatoria dei mesi di possesso per ogni oggetto: in pratica si
-- esegue la media ponderata dei valori rispetto ai mesi di possesso).
-- Questi singoli valori per oggetto vanno poi sommati per ottenere il montante dei
-- terreni ridotti rispetto al quale ed all`eventuale montante dei valori dei terreni
-- in altri comuni si ricava il coefficiente di riduzione.
cursor sel_terreni_rid is
select ogge.oggetto oggetto
--      ,round(nvl(ogpr.valore,0) / (100 + decode(sign(prtr.anno - 1996)
--                                        ,1,nvl(rire.aliquota,0)
--                                          ,0
--                                        )
--                           ) * (100 + nvl(rire.aliquota,0)),2
--            )                        valore
      ,f_valore(ogpr.valore,1
               ,ogco.anno,a_anno_rif
               ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
               ,prtr.tipo_pratica,ogpr.flag_valore_rivalutato
               )                                                                valore
      ,decode(ogco.anno
             ,a_anno_rif,decode(ogco.flag_riduzione
                               ,'S',nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12))
                                   ,nvl(ogco.mesi_riduzione,0)
                               )
                        ,decode(ogco.flag_riduzione,'S',12,0)
             )                       mesi_riduzione
      ,decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
                                     mesi_possesso
      ,ogco.flag_possesso            flag_possesso
      ,ogco.flag_riduzione           flag_riduzione
      ,nvl(molt.moltiplicatore,1)    moltiplicatore
      ,nvl(rire.aliquota,0)          rivalutazione
      ,ogco.anno                     anno
      ,ogpr.oggetto_pratica          oggetto_pratica
  from moltiplicatori        molt
      ,rivalutazioni_rendita rire
      ,oggetti               ogge
      ,oggetti_pratica       ogpr
      ,pratiche_tributo      prtr
      ,oggetti_contribuente  ogco
 where molt.anno                = a_anno_rif
   and molt.categoria_catasto   = f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
   and rire.anno          (+)   = a_anno_rif
   and rire.tipo_oggetto  (+)   = ogpr.tipo_oggetto
   and ogpr.tipo_oggetto        = 1
   and prtr.pratica             = ogpr.pratica
   and ogge.oggetto             = ogpr.oggetto
   and ogco.anno||ogco.tipo_rapporto
                                =
      (select max(b.anno||b.tipo_rapporto)
         from pratiche_tributo     c
             ,oggetti_contribuente b
             ,oggetti_pratica      a
        where(    c.data_notifica              is not null
              and c.tipo_pratica||''            = 'A'
              and nvl(c.stato_accertamento,'D') = 'D'
              and c.anno                        < a_anno_rif
              or  c.data_notifica              is null
              and c.tipo_pratica||''            = 'D'
             )
         and c.anno              <= a_anno_rif
         and c.pratica            = a.pratica
         and a.oggetto            = ogpr.oggetto
         and a.oggetto_pratica    = b.oggetto_pratica
         and b.cod_fiscale     = ogco.cod_fiscale
      )
   and ogpr.oggetto_pratica = ogco.oggetto_pratica
   and decode(ogco.anno
             ,a_anno_rif,decode(ogco.flag_riduzione
                               ,'S',nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12))
                                   ,ogco.mesi_riduzione
                               )
                        ,decode(ogco.flag_riduzione,'S',12,0)
            )         between 1 and
                                decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
   and ogco.flag_esclusione is null
   and ogco.cod_fiscale        = a_cod_fiscale
 order by
       ogge.oggetto
;
BEGIN
    if a_anno_rif > 2000 then
       w_perc_acconto := 100;
    else
       w_perc_acconto := 90;
    end if;
    BEGIN
       select ogpr.oggetto
             ,prtr.tipo_pratica
         into w_Oggetto
             ,w_tipo_pratica
         from oggetti_pratica  ogpr
             ,pratiche_tributo prtr
        where ogpr.oggetto_pratica = a_oggetto_pratica
          and prtr.pratica         = ogpr.pratica
       ;
    EXCEPTION
       WHEN OTHERS THEN
          w_errore := 'Errore in Recupero Oggetto da Oggetti Pratica';
          RAISE ERRORE;
    END;
    if w_tipo_pratica = 'V' then
       w_flag_calcolo := null;
    else
       w_flag_calcolo := 'S';
    end if;
    w_mesi_senza_rid    := a_mesi_possesso           - nvl(a_mesi_riduzione,0);
    w_mesi_senza_rid_1s := nvl(a_mesi_possesso_1s,0) - nvl(a_mesi_riduzione_1s,0);
    w_mesi_riduzione := a_mesi_riduzione;
    IF w_mesi_senza_rid > 0 THEN
       <<terreno_senza_rid>>
       w_terreni_senza_rid := f_round(((((((a_valore
                    * a_aliquota_terreni) / 1000)
                    * a_perc_possesso) / 100)
                    * w_mesi_senza_rid) / 12),0);
       w_terreni_senza_rid_na := ((((((a_valore
                    * a_aliquota_terreni) / 1000)
                    * a_perc_possesso) / 100)
                    * w_mesi_senza_rid) / 12);
       wd_terreni_senza_rid := f_round(((((((a_valore_d
                    * a_aliquota_terreni) / 1000)
                    * a_perc_possesso) / 100)
                    * w_mesi_senza_rid) / 12),0);
       w_terreni_senza_rid_erar := f_round(((((((a_valore
                                               * a_aliquota_terreni_erar)  / 1000)
                                               * a_perc_possesso) / 100)
                                               * w_mesi_senza_rid) / 12),0);
       wd_terreni_senza_rid_erar := f_round(((((((a_valore_d
                                               * a_aliquota_terreni_erar)  / 1000)
                                               * a_perc_possesso) / 100)
                                               * w_mesi_senza_rid) / 12),0);
    END IF;
    IF w_mesi_senza_rid_1s > 0 THEN
       <<terreno_senza_rid_1s>>
       if a_anno_rif <= 2000 then
          w_terreni_senza_rid_1s := f_round((((((((a_valore_1s
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12) * 0.9),0);
          w_terreni_senza_rid_1s_na := (((((((a_valore_1s
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12) * 0.9);
          wd_terreni_senza_rid_1s := f_round((((((((a_valore_d
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12) * 0.9),0);
       else
          w_terreni_senza_rid_1s := f_round(((((((a_valore_1s
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12),0);
          w_terreni_senza_rid_1s_na := ((((((a_valore_1s
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12);
          wd_terreni_senza_rid_1s := f_round(((((((a_valore_d
                 * a_aliquota_terreni_prec) / 1000)
                 * a_perc_possesso) / 100)
                 * w_mesi_senza_rid_1s) / 12),0);
       end if;
       w_terreni_senza_rid_erar_1s := f_round(((((((a_valore_1s
                                                  * a_aliquota_terreni_erar) / 1000)
                                                  * a_perc_possesso) / 100)
                                                  * w_mesi_senza_rid_1s) / 12),0);
       wd_terreni_senza_rid_erar_1s := f_round(((((((a_valore_d
                                                  * a_aliquota_terreni_erar) / 1000)
                                                  * a_perc_possesso) / 100)
                                                  * w_mesi_senza_rid_1s) / 12),0);
    END IF;
    IF nvl(w_mesi_riduzione,0) between 1 and a_mesi_possesso THEN
       <<terreno_con_rid>>
       w_tot_terreni_con_rid     := 0;
       w_tot_terreni_con_rid_1s  := 0;
       wd_tot_terreni_con_rid    := 0;
       --
       -- (VD - 28/08/2015): aggiunto azzeramento variabile dovuto primo semestre
       --
       wd_tot_terreni_con_rid_1s := 0;
       w_valore                  := 0;
       w_Valore_d                := 0;
       w_oggetto_prec            := 0;
       for rec_terreni_rid in sel_terreni_rid
       loop
          if w_oggetto_prec = 0 then
             w_oggetto_prec       := rec_terreni_rid.oggetto;
             w_totale_importo     := 0;
             w_totale_importo_1s  := 0;
             w_totale_mesi        := 0;
             w_totale_mesi_1s     := 0;
             wd_totale_importo    := 0;
             --
             -- (VD - 28/08/2015): aggiunto azzeramento variabile dovuto primo semestre
             --
             wd_totale_importo_1s := 0;
            --dbms_output.put_line('###');
            --dbms_output.put_line('Oggetto '||to_char(w_oggetto_prec));
          end if;
          if rec_terreni_rid.oggetto <> w_oggetto_prec then
             if w_totale_mesi    > 0 then
                w_tot_terreni_con_rid     := w_tot_terreni_con_rid
                                           + round(w_totale_importo    / w_totale_mesi    ,2);
                wd_tot_terreni_con_rid    := wd_tot_terreni_con_rid
                                           + round(wd_totale_importo   / w_totale_mesi    ,2);
                if w_oggetto_prec = w_oggetto then
                   w_valore     := w_valore  + round(w_totale_importo    / w_totale_mesi  ,2);
                   w_valore_d   := w_valore_d + round(wd_totale_importo   / w_totale_mesi ,2);
                end if;
             end if;
             if w_totale_mesi_1s > 0 then
                w_tot_terreni_con_rid_1s  := w_tot_terreni_con_rid_1s
                                           + round(w_totale_importo_1s / w_totale_mesi_1s ,2);
                wd_tot_terreni_con_rid_1s := wd_tot_terreni_con_rid_1s
                                          + round(wd_totale_importo_1s / w_totale_mesi_1s ,2);
                if w_oggetto_prec = w_oggetto then
                   w_valore_1s   := nvl(w_valore_1s,0) + round(w_totale_importo_1s / w_totale_mesi_1s ,2);
                   w_valore_d_1s := nvl(w_valore_d_1s,0) + round(wd_totale_importo_1s / w_totale_mesi_1s ,2);
                end if;
             end if;
--            dbms_output.put_line('---');
--            dbms_output.put_line('Tot terreni con Rid. '||to_char(w_tot_terreni_con_rid));
--            dbms_output.put_line('1s  terreni con Rid. '||to_char(w_tot_terreni_con_rid_1s));
             w_oggetto_prec       := rec_terreni_rid.oggetto;
             w_totale_importo     := 0;
             w_totale_importo_1s  := 0;
             w_totale_mesi        := 0;
             w_totale_mesi_1s     := 0;
             wd_totale_importo    := 0;
             --
             -- (VD - 28/08/2015): aggiunto azzeramento variabile dovuto primo semestre
             --
             wd_totale_importo_1s := 0;
            --dbms_output.put_line('===');
            --dbms_output.put_line('Oggetto '||to_char(w_oggetto_prec));
          end if;
          BEGIN
             select ltrim(max(nvl(ogco.flag_possesso,' ')))
                   ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_riduzione),2,1)
               into w_flag_possesso_prec
                   ,w_flag_riduzione_prec
               from oggetti_contribuente      ogco
                   ,oggetti_pratica           ogpr
                   ,pratiche_tributo          prtr
              where ogco.cod_fiscale                        = a_cod_fiscale
                and ogpr.oggetto                            = rec_terreni_rid.oggetto
                and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
                and prtr.pratica                            = ogpr.pratica
                and prtr.tipo_tributo||''                   = 'ICI'
                and prtr.anno                               < rec_terreni_rid.anno
                and ogco.anno||ogco.tipo_rapporto||nvl(ogco.flag_possesso,'N')
                                                            =
                   (select max(b.anno||b.tipo_rapporto||nvl(b.flag_possesso,'N'))
                      from pratiche_tributo     c,
                           oggetti_contribuente b,
                           oggetti_pratica      a
                     where(    c.data_notifica             is not null
                           and c.tipo_pratica||''            = 'A'
                           and nvl(c.stato_accertamento,'D') = 'D'
                           and nvl(c.flag_denuncia,' ')      = 'S'
                           or  c.data_notifica              is null
                           and c.tipo_pratica||''            = 'D'
                          )
                       and c.pratica                         = a.pratica
                       and a.oggetto_pratica                 = b.oggetto_pratica
                       and c.tipo_tributo||''                = 'ICI'
                       and c.anno                            < rec_terreni_rid.anno
                       and b.cod_fiscale                     = ogco.cod_fiscale
                       and a.oggetto                         = rec_terreni_rid.oggetto
                   )
              group by rec_terreni_rid.oggetto
             ;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                w_flag_possesso_prec   := null;
                w_flag_riduzione_prec  := null;
          END;
          if rec_terreni_rid.flag_possesso = 'S'
          or w_flag_possesso_prec         is null then
             w_inizio_possesso    :=
             add_months(to_date('3112'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy') + 1
                       ,rec_terreni_rid.mesi_riduzione * -1
                       );
             w_fine_possesso      :=
             to_date('3112'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy');
          else
             w_inizio_possesso    :=
             to_date('0101'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy');
             w_fine_possesso      :=
             add_months(to_date('0101'||lpad(to_char(a_anno_rif),4,'0'),'ddmmyyyy') - 1
                       ,rec_terreni_rid.mesi_riduzione
                       );
          end if;
          if to_number(to_char(w_inizio_possesso,'mm')) < 7 then
             w_inizio_possesso_1s := w_inizio_possesso;
             w_fine_possesso_1s   := least(to_date('3006'||lpad(to_char(a_anno_rif),4,'0')
                                                  ,'ddmmyyyy'
                                                  )
                                          ,w_fine_possesso
                                          );
          else
             w_inizio_possesso_1s := null;
             w_fine_possesso_1s   := null;
          end if;
          if rec_terreni_rid.mesi_riduzione > 6 then
             if rec_terreni_rid.flag_riduzione = 'S'
             or rec_terreni_rid.mesi_riduzione = 12 then
                w_mesi_riduzione_1s  := rec_terreni_rid.mesi_riduzione - 6;
             else
                if w_flag_riduzione_prec = 'S' then
                   w_mesi_riduzione_1s  := 6;
                else
                   w_mesi_riduzione_1s  := rec_terreni_rid.mesi_riduzione - 6;
                end if;
             end if;
          else
             if rec_terreni_rid.flag_riduzione = 'S' then
                w_mesi_riduzione_1s  := 0;
             else
                if w_flag_riduzione_prec = 'S' then
                   w_mesi_riduzione_1s := rec_terreni_rid.mesi_riduzione;
                else
                   w_mesi_riduzione_1s := 0;
                end if;
             end if;
          end if;
         --
         -- Routine per gestire i Riferimenti Oggetto Multipli.
         --
          CALCOLO_RIOG_MULTIPLO(w_oggetto_prec
                               ,rec_terreni_rid.valore
                               ,w_inizio_possesso
                               ,w_fine_possesso
                               ,w_inizio_possesso_1s
                               ,w_fine_possesso_1s
                               ,rec_terreni_rid.moltiplicatore
                               ,rec_terreni_rid.rivalutazione
                               ,1
                               ,rec_terreni_rid.anno
                               ,a_anno_rif
                               ,'N'
                               ,w_importo
                               ,w_importo_1s
                               )
                               ;
          w_totale_importo      := w_totale_importo    + w_importo     *
                                                        rec_terreni_rid.mesi_riduzione;
          wd_totale_importo     := wd_totale_importo   + rec_terreni_rid.valore  *
                                                        rec_terreni_rid.mesi_riduzione;
          w_totale_importo_1s   := w_totale_importo_1s + w_importo_1s  * w_mesi_riduzione_1s;
          --
          -- (VD - 28/08/2015): aggiunta totalizzazione variabile dovuto primo semestre
          --
          wd_totale_importo_1s  := wd_totale_importo_1s + w_importo_1s  * w_mesi_riduzione_1s;
          w_totale_mesi         := w_totale_mesi       + rec_terreni_rid.mesi_riduzione;
          w_totale_mesi_1s      := w_totale_mesi_1s    + w_mesi_riduzione_1s;
--         dbms_output.put_line('Importo '||to_char(w_importo)||' Mesi '||
--         to_char(rec_terreni_rid.mesi_riduzione));
--         dbms_output.put_line('Totale '||to_char(w_totale_importo)||' Mesi '||
--         to_char(w_totale_mesi));
--         dbms_output.put_line('Importo 1s '||to_char(w_importo_1s)||' Mesi '||
--         to_char(w_mesi_riduzione_1s));
--         dbms_output.put_line('Totale '||to_char(w_totale_importo_1s)||' Mesi '||
--         to_char(w_totale_mesi_1s));
       end loop;
       if w_oggetto_prec <> 0 then
          if w_totale_mesi    > 0 then
             w_tot_terreni_con_rid     := w_tot_terreni_con_rid
                                        + round(w_totale_importo     / w_totale_mesi  ,2);
             wd_tot_terreni_con_rid    := wd_tot_terreni_con_rid
                                        + round(wd_totale_importo    / w_totale_mesi  ,2);
             if w_oggetto_prec = w_oggetto then
                w_valore     := w_valore  + round(w_totale_importo   / w_totale_mesi  ,2);
                w_valore_d   := w_valore_d + round(wd_totale_importo / w_totale_mesi  ,2);
             end if;
          end if;
          if w_totale_mesi_1s > 0 then
             w_tot_terreni_con_rid_1s  := w_tot_terreni_con_rid_1s
                                        + round(w_totale_importo_1s / w_totale_mesi_1s ,2);
             wd_tot_terreni_con_rid_1s  := wd_tot_terreni_con_rid_1s
                                        + round(wd_totale_importo_1s / w_totale_mesi_1s ,2);
             if w_oggetto_prec = w_oggetto then
                w_valore_1s := nvl(w_valore_1s,0) + round(w_totale_importo_1s / w_totale_mesi_1s ,2);
                w_valore_d_1s := nvl(w_valore_d_1s,0) + round(wd_totale_importo_1s / w_totale_mesi_1s ,2);
             end if;
          end if;
         --dbms_output.put_line('---');
         --dbms_output.put_line('Tot terreni con Rid. '||to_char(w_tot_terreni_con_rid));
         --dbms_output.put_line('1s  terreni con Rid. '||to_char(w_tot_terreni_con_rid_1s));
          w_oggetto_prec       := 0;
          w_totale_importo     := 0;
          w_totale_importo_1s  := 0;
          w_totale_mesi        := 0;
          w_totale_mesi_1s     := 0;
          wd_totale_importo    := 0;
          --
          -- (VD - 28/08/2015): aggiunto azzeramento variabile dovuto primo semestre
          --
          wd_totale_importo_1s := 0;
       end if;
       BEGIN
          select decode(nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid,0)
                       ,0,0
                       ,nvl(w_tot_terreni_con_rid,0) /
                          (nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid,0))
                       )
                ,decode(nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid_1s,0)
                       ,0,0
                       ,nvl(w_tot_terreni_con_rid_1s,0) /
                          (nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid_1s,0))
                       )
                ,decode(nvl(teri.valore,0) + nvl(wd_tot_terreni_con_rid,0)
                       ,0,0
                       ,nvl(wd_tot_terreni_con_rid,0) /
                          (nvl(teri.valore,0) + nvl(wd_tot_terreni_con_rid,0))
                       )
                ,decode(nvl(teri.valore,0) + nvl(wd_tot_terreni_con_rid_1s,0)
                       ,0,0
                       ,nvl(wd_tot_terreni_con_rid_1s,0) /
                          (nvl(teri.valore,0) + nvl(wd_tot_terreni_con_rid_1s,0))
                       )
            into w_perc_terreni_con_rid
                ,w_perc_terreni_con_rid_1s
                ,wd_perc_terreni_con_rid
                ,wd_perc_terreni_con_rid_1s
            from terreni_ridotti teri
           where teri.cod_fiscale    (+)   = a_cod_fiscale
             and teri.anno           (+)   = a_anno_rif
         ;
       EXCEPTION
          WHEN no_data_found THEN
             w_perc_terreni_con_rid     := 1;
             w_perc_terreni_con_rid_1s  := 1;
             wd_perc_terreni_con_rid    := 1;
             --
             -- (VD - 28/05/2015): aggiunta valorizzazione percentuale dovuto primo semestre
             --
             wd_perc_terreni_con_rid_1s := 1;
          WHEN others THEN
             w_errore := 'Errore calcolo totale terreni con rid. (2)';
             RAISE errore;
       END;
      --dbms_output.put_line('---');
      --dbms_output.put_line('% Rid '||to_char(w_perc_terrenin_rid)||' 1s '||
      --to_char(w_perc_terreni_con_rid_1s));
       w_mesi_possesso    := a_mesi_riduzione;
       w_mesi_possesso_1s := a_mesi_riduzione_1s;
       BEGIN
           if a_anno_rif = 2013 then  -- Inserito per la Mini IMU (9/1/14) AB
              -- Imposta
              CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid_1s
                                     ,w_perc_terreni_con_rid,w_perc_terreni_con_rid_1s
                                     ,a_aliquota_terreni_rid_std,a_perc_possesso,w_mesi_possesso
                                     ,w_mesi_possesso_1s,w_valore,w_valore_1s
                                     ,0,a_anno_rif
                                     ,w_terreni_con_rid_1s_std,w_terreni_con_rid_std
                                     );
              -- Imposta Dovuta
              CALCOLO_TERRENI_RIDOTTI(wd_tot_terreni_con_rid,wd_tot_terreni_con_rid_1s
                                     ,wd_perc_terreni_con_rid,wd_perc_terreni_con_rid_1s
                                     ,a_aliquota_terreni_rid_std,a_perc_possesso,w_mesi_possesso
                                     ,w_mesi_possesso_1s,w_valore_d,w_valore_d_1s
                                     ,0,a_anno_rif
                                     ,wd_terreni_con_rid_1s_std,wd_terreni_con_rid_std
                                     );
           else
              w_terreni_con_rid_1s_std    := null;
              w_terreni_con_rid_std       := null;
              wd_terreni_con_rid_1s_std   := null;
              wd_terreni_con_rid_std      := null;
           end if;
           -- Imposta
            CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid_1s
                                   ,w_perc_terreni_con_rid,w_perc_terreni_con_rid_1s
                                   ,a_aliquota_terreni_rid,a_perc_possesso,w_mesi_possesso
                                   ,w_mesi_possesso_1s,w_valore,w_valore_1s
                                   ,a_aliquota_terreni_rid_prec,a_anno_rif
                                   ,w_terreni_con_rid_1s,w_terreni_con_rid
                                   );
            -- Imposta Dovuta
            CALCOLO_TERRENI_RIDOTTI(wd_tot_terreni_con_rid,wd_tot_terreni_con_rid_1s
                                   ,wd_perc_terreni_con_rid,wd_perc_terreni_con_rid_1s
                                   ,a_aliquota_terreni_rid,a_perc_possesso,w_mesi_possesso
                                   ,w_mesi_possesso_1s,w_valore_d,w_valore_d_1s
                                   ,a_aliquota_terreni_rid_prec,a_anno_rif
                                   ,wd_terreni_con_rid_1s,wd_terreni_con_rid
                                   );
            -- Imposta Erariale
            CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid_1s
                                   ,w_perc_terreni_con_rid,w_perc_terreni_con_rid_1s
                                   ,a_aliquota_terreni_rid_erar,a_perc_possesso,w_mesi_possesso
                                   ,w_mesi_possesso_1s,w_valore,w_valore_1s
                                   ,a_aliquota_terreni_rid_erar,a_anno_rif
                                   ,w_terreni_con_rid_erar_1s,w_terreni_con_rid_erar
                                   );
            -- Imposta Erariale Dovuta
            CALCOLO_TERRENI_RIDOTTI(wd_tot_terreni_con_rid,wd_tot_terreni_con_rid_1s
                                   ,wd_perc_terreni_con_rid,wd_perc_terreni_con_rid_1s
                                   ,a_aliquota_terreni_rid_erar,a_perc_possesso,w_mesi_possesso
                                   ,w_mesi_possesso_1s,w_valore_d,w_valore_d_1s
                                   ,a_aliquota_terreni_rid_erar,a_anno_rif
                                   ,wd_terreni_con_rid_erar_1s,wd_terreni_con_rid_erar
                                   );
--         dbms_output.put_line('Anno Rif.           = '||to_char(a_anno_rif));
--         dbms_output.put_line('Perc.Possesso       = '||to_char(a_perc_possesso));
--         dbms_output.put_line('Mesi Possesso       = '||to_char(w_mesi_possesso));
--         dbms_output.put_line('Mesi Possesso 1S    = '||to_char(w_mesi_possesso_1s));
--         dbms_output.put_line('Aliquota Terreni    = '||to_char(a_aliquota_terreni));
--         dbms_output.put_line('Aliq.Terreni Pr.    = '||to_char(a_aliquota_terreni_prec));
--         dbms_output.put_line('-');
--         dbms_output.put_line('Valore Terreno      = '||to_char(w_valore));
--         dbms_output.put_line('Tot.Terreni Rid.    = '||to_char(w_tot_terreni_con_rid));
--         dbms_output.put_line('Coeff. di Rid.      = '||to_char(w_Perc_terreni_con_rid));
--         dbms_output.put_line('Acc.Terreni Rid.    = '||to_char(w_terreni_con_rid_1s));
--         dbms_output.put_line('Tot.Terreni Rid.    = '||to_char(w_terreni_con_rid));
--         dbms_output.put_line('Valore Terreno   D. = '||to_char(w_valore_d));
--         dbms_output.put_line('-');
--         dbms_output.put_line('Tot.Terreni Rid. D. = '||to_char(wd_tot_terreni_con_rid));
--         dbms_output.put_line('Coeff. di Rid.   D. = '||to_char(wd_Perc_terreni_con_rid));
--         dbms_output.put_line('Acc.Terreni Rid. D. = '||to_char(wd_terreni_con_rid_1s));
--         dbms_output.put_line('Tot.Terreni Rid. D. = '||to_char(wd_terreni_con_rid));
--         dbms_output.put_line('-----------------------------------------------');
       END;
    END IF;
--   dbms_output.put_line ('1) w_ter_r '||w_terreni_con_rid||' wd_ter_r '||wd_terreni_con_rid||' w_ter_r_1s '||w_terreni_con_rid_1s||' wd_ter_r_1s '||wd_terreni_con_rid_1s||' ');
    w_terreni     := f_round(nvl(w_terreni_senza_rid,0) +
                     nvl(w_terreni_con_rid,0),0);
    w_terreni_1s  := f_round(nvl(w_terreni_senza_rid_1s,0) +
                     nvl(w_terreni_con_rid_1s,0),0);
    wd_terreni    := f_round(nvl(wd_terreni_senza_rid,0) +
                     nvl(wd_terreni_con_rid,0),0);
    wd_terreni_1s := f_round(nvl(wd_terreni_senza_rid_1s,0) +
                     nvl(wd_terreni_con_rid_1s,0),0);
    w_terreni_erar    := f_round(nvl(w_terreni_senza_rid_erar,0) +
                         nvl(w_terreni_con_rid_erar,0),0);
    w_terreni_erar_1s := f_round(nvl(w_terreni_senza_rid_erar_1s,0) +
                         nvl(w_terreni_con_rid_erar_1s,0),0);
    wd_terreni_erar    := f_round(nvl(wd_terreni_senza_rid_erar,0) +
                         nvl(w_terreni_con_rid_erar,0),0);
    wd_terreni_erar_1s := f_round(nvl(wd_terreni_senza_rid_erar_1s,0) +
                         nvl(wd_terreni_con_rid_erar_1s,0),0);
    -- (VD - 17/02/2022): modificato test su importi relativi ai terreni senza
    --                    riduzione. Ora si testa l'importo non arrotondato.
    --                    L'importo dei terreni ridotti non e' arrotondato
    --                    all'origine.
    --                    Aggiunto anche test sui mesi senza riduzione.
    --if nvl(w_terreni_senza_rid,0)    <> 0 and nvl(w_terreni_con_rid,0)    <> 0
    --or nvl(w_terreni_senza_rid_1s,0) <> 0 and nvl(w_terreni_con_rid_1s,0) <> 0 then
    if ((nvl(w_terreni_senza_rid_na,0) <> 0 or nvl(w_mesi_senza_rid,0) > 0)
    and (nvl(w_terreni_con_rid,0)      <> 0 or nvl(w_mesi_riduzione,0) > 0))
    or ((nvl(w_terreni_senza_rid_1s_na,0) <> 0 or nvl(w_mesi_senza_rid_1s,0) > 0)
    and (nvl(w_terreni_con_rid_1s,0)      <> 0 or nvl(w_mesi_riduzione_1s,0) > 0)) then
       w_tipo_al := null;
       w_al      := null;
       w_al_erar := null;
       w_al_std  := null;
    --elsif nvl(w_terreni_senza_rid,0) <> 0 or nvl(w_terreni_senza_rid_1s,0) <> 0 then
    elsif nvl(w_terreni_senza_rid_na,0) <> 0 or
          nvl(w_mesi_senza_rid,0) > 0 or
          nvl(w_terreni_senza_rid_1s_na,0) <> 0 or
          nvl(w_mesi_senza_rid_1s,0) > 0then
       w_tipo_al := a_tipo_aliquota;
       w_al      := a_aliquota_terreni;
       w_al_erar := a_aliquota_terreni_erar;
       w_al_std  := null;
    else
       w_tipo_al := a_tipo_aliquota_rid;
       w_al      := a_aliquota_terreni_rid;
       w_al_erar := a_aliquota_terreni_rid_erar;
       w_al_std  := a_aliquota_terreni_rid_std;
    end if;
    -- (VD - 23/10/2020): calcolo imposta a saldo (D.L. 14 agosto 2020)
    if a_tipo_tributo = 'ICI' then
       calcolo_imu_saldo ( a_tipo_tributo
                         , a_anno_rif
                         , w_tipo_al
                         , nvl(w_terreni,0)
                         , nvl(w_terreni_1s,0)
                         , w_terreni_erar
                         , w_terreni_erar_1s
                         , w_perc_saldo
                         , w_imposta_saldo
                         , w_imposta_saldo_erar
                         , w_note_saldo
                         );
       if w_perc_saldo is not null then
          w_terreni      := w_imposta_saldo;
          w_terreni_erar := w_imposta_saldo_erar;
       end if;
    end if;
    BEGIN
        insert into oggetti_imposta
               (cod_fiscale,anno,oggetto_pratica
               ,imposta,imposta_acconto
               ,imposta_dovuta,imposta_dovuta_acconto
               ,imposta_erariale,imposta_erariale_acconto
               ,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
               ,tipo_aliquota,aliquota
               ,aliquota_erariale
               ,aliquota_std
               ,imposta_std, imposta_dovuta_std
               ,flag_calcolo,utente, tipo_tributo
               ,note)
        values (a_cod_fiscale,a_anno_rif,a_oggetto_pratica
               ,nvl(w_terreni,0),nvl(w_terreni_1s,0)
               ,nvl(wd_terreni,0),nvl(wd_terreni_1s,0)
               ,w_terreni_erar,w_terreni_erar_1s
               ,wd_terreni_erar,wd_terreni_erar_1s
               ,w_tipo_al,w_al
               ,w_al_erar
               ,w_al_std
               ,w_terreni_con_rid_std, wd_terreni_con_rid_std
               ,w_flag_calcolo,a_utente, a_tipo_tributo
               ,w_note_saldo)
        ;
    EXCEPTION
       WHEN others THEN
         w_errore := 'Errore in inserimento Oggetti Imposta (Terreni)';
       RAISE errore;
    END;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore);
END;
/* End Procedure: CALCOLO_TERRENI */
/

