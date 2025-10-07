--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_ici stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_ICI
(a_anno                    IN     number,
 a_tipo_oggetto            IN     number,
 a_valore                  IN     number,
 a_flag_valore_rivalutato  IN     varchar2,
 a_tipo_aliquota           IN OUT number,
 a_aliquota                IN     number,
 a_perc_possesso           IN     number,
 a_mesi_possesso           IN OUT number,
 a_mesi_esclusione         IN     number,
 a_mesi_riduzione          IN OUT number,
 a_flag_riduzione          IN     varchar2,
 a_detrazione              IN     number,
 a_anno_dic                IN     number,
 a_categoria_catasto       in     varchar2,
 a_imposta                 IN OUT number)
IS
  /******************************************************************************
   NOME:        CALCOLO_ACCERTAMENTO_ICI
   DESCRIZIONE: Calcolo accertamento su singolo immobile ICI/IMU

   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   001   04/12/2023  RV      #61151
                             Modificato per gestione mesi esclusione su terreni
   000   XX/XX/XXXX  XX      Prima emissione
  ******************************************************************************/
--
sql_errm            varchar2(100);
w_aliquota           number;
w_aliquota_rire      number;
w_aliquota_rire_dic  number;
w_valore             number;
w_mesi_senza_rid     number;
w_mesi_possesso      number;
w_terreni_senza_rid  number;
w_terreni_con_rid    number;
w_fase_euro          number;
w_50000000           number;
w_70000000           number;
w_80000000           number;
w_120000000          number;
w_200000000          number;
w_250000000          number;
--
w_terreni_con_rid_1s      number;
w_tot_terreni_con_rid     number;
w_tot_terreni_con_rid_1s  number;
w_perc_terreni_con_rid    number;
w_perc_terreni_con_rid_1s number;
w_mesi_possesso_1s        number;
w_valore_1s               number;
--
BEGIN
  w_valore := a_valore;
-- dbms_output.put_line ('a_val: '||a_valore);
  BEGIN
     select fase_euro
       into w_fase_euro
       from dati_generali
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
  END;
  if w_fase_euro = 1 then
     w_50000000  := 50000000;
     w_70000000  := 70000000;
     w_80000000  := 80000000;
     w_120000000 := 120000000;
     w_200000000 := 200000000;
     w_250000000 := 250000000;
  else
     w_50000000  := 25822.845;
     w_70000000  := 36151.983;
     w_80000000  := 41316.552;
     w_120000000 := 61974.827;
     w_200000000 := 103291.379;
     w_250000000 := 129114.224;
  end if;
  BEGIN
    select aliq.aliquota
      into w_aliquota
      from aliquote aliq
     where aliq.anno      = a_anno
       and aliq.tipo_aliquota    = a_tipo_aliquota
       and tipo_tributo = 'ICI'
    ;
  EXCEPTION
    WHEN no_data_found THEN
       if a_tipo_aliquota in (1,2) then
         RAISE_APPLICATION_ERROR
              (-20999,'Manca l''aliquota per l''anno indicato');
       else
         if a_tipo_aliquota is not null then
            a_tipo_aliquota := 1;
            BEGIN
              select aliq.aliquota
                into w_aliquota
                from aliquote aliq
               where aliq.anno      = a_anno
                and aliq.tipo_aliquota    = a_tipo_aliquota
                and tipo_tributo = 'ICI'
              ;
            EXCEPTION
              WHEN no_data_found THEN
            RAISE_APPLICATION_ERROR
                (-20999,'Manca l''aliquota base per l''anno indicato');
            END;
         end if;
       end if;
    WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in ricerca Aliquote');
  END;
  IF a_flag_valore_rivalutato is null and nvl(a_tipo_oggetto,0) <> 2 THEN
     -- Passo come anno_dic sempre l'anno di accertamento perchè in questo caso il valore indicato a maschera
     -- va solo rivalutato se non è nullo il flag_valore_rivalutato
     -- e non vanno mai applicati i moltiplicatori dell'anno rispetto a quelli di denuncia
     -- va fatta una pura rivalutazione per l'anno di accertamento  (Piero 10/04/2012)
     BEGIN
       select f_valore(a_valore,a_tipo_oggetto,a_anno,a_anno,a_categoria_catasto,'A',a_flag_valore_rivalutato)
         into w_valore
         from dual
       ;
     EXCEPTION
       WHEN no_data_found THEN
            null;
       WHEN others THEN
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in rivalutazione rendita ');
     END;
  END IF;
  IF a_anno_dic is not null THEN
     BEGIN
       select decode(a_anno_dic
                    ,a_anno,decode(a_flag_riduzione
                                  ,'S',nvl(a_mesi_riduzione,nvl(a_mesi_possesso,12))
                                  ,a_mesi_riduzione
                                  )
                    ,decode(a_flag_riduzione,'S',12,0)
                    )
            , decode(a_anno_dic,a_anno,nvl(a_mesi_possesso,12),12)
         into a_mesi_riduzione
            , a_mesi_possesso
         from dual
       ;
     EXCEPTION
       WHEN no_data_found THEN
       null;
       WHEN others THEN
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in selezione mesi possesso e riduzione');
     END;
  END IF;

  -- se l'aliquota viene passata si utilizza quella per il calcolo
  w_aliquota := nvl(a_aliquota,w_aliquota);

  IF a_tipo_oggetto = 1 THEN
     w_mesi_possesso := a_mesi_possesso - nvl(a_mesi_esclusione,0);
     --
     w_mesi_senza_rid := w_mesi_possesso - nvl(a_mesi_riduzione,0);
     IF w_mesi_senza_rid > 0 THEN
        w_terreni_senza_rid := f_round(((((((w_valore
                     * w_aliquota) / 1000)
                     * a_perc_possesso) / 100)
                     * w_mesi_senza_rid) / 12),0);
     END IF;
     IF nvl(a_mesi_riduzione,0) between 1 and w_mesi_possesso THEN
        w_mesi_possesso := a_mesi_riduzione;
        if a_anno <= 2012 then
           BEGIN

             select decode(sign(w_valore - w_50000000),-1,0,0,0,
                      decode(sign(w_valore - w_120000000),-1,
                        ((((((((((w_valore - w_50000000)
                         * w_valore)
                         / w_valore) * 0.30)
                         * w_aliquota) / 1000)
                         * a_perc_possesso) / 100)
                         * w_mesi_possesso) / 12),0,
                        (((((((((w_70000000 * w_valore)
                         / w_valore) * 0.30)
                         * w_aliquota) / 1000)
                         * a_perc_possesso) / 100)
                         * w_mesi_possesso) / 12),1,
                        ((((((((((w_70000000 * w_valore)
                         / w_valore) * 0.30)
                         * w_aliquota) / 1000)
                         * a_perc_possesso) / 100)
                         * w_mesi_possesso) / 12) +
                         decode(sign(w_valore - w_200000000),-1,
                           ((((((((((w_valore - w_120000000)
                            * w_valore)
                            / w_valore) * 0.50)
                            * w_aliquota) / 1000)
                            * a_perc_possesso) / 100)
                            * w_mesi_possesso) / 12),0,
                           (((((((((w_80000000 * w_valore)
                            / w_valore) * 0.50)
                            * w_aliquota) / 1000)
                            * a_perc_possesso) / 100)
                            * w_mesi_possesso) / 12),1,
                           ((((((((((w_80000000 * w_valore)
                            / w_valore) * 0.50)
                            * w_aliquota) / 1000)
                            * a_perc_possesso) / 100)
                            * w_mesi_possesso) / 12) +
                            decode(sign(w_valore - w_250000000),-1,
                              ((((((((((w_valore - w_200000000)
                               * w_valore)
                               / w_valore) * 0.75)
                               * w_aliquota) / 1000)
                               * a_perc_possesso) / 100)
                               * w_mesi_possesso) / 12),0,
                              (((((((((w_50000000 * w_valore)
                               / w_valore) * 0.75)
                               * w_aliquota) / 1000)
                               * a_perc_possesso) / 100)
                               * w_mesi_possesso) / 12),1,
                              ((((((((((w_50000000 * w_valore)
                               / w_valore) * 0.75)
                               * w_aliquota) / 1000)
                               * a_perc_possesso) / 100)
                               * w_mesi_possesso) / 12) +
                              (((((((((w_valore - w_250000000)
                               * w_valore)
                               / w_valore)
                               * w_aliquota) / 1000)
                               * a_perc_possesso) / 100)
                               * w_mesi_possesso) / 12))))))))
                into w_terreni_con_rid
                from dual
                   ;
           EXCEPTION
             WHEN others THEN
              null;
           END;
        else
            w_tot_terreni_con_rid     := 0;
            w_tot_terreni_con_rid_1s  := 0;
            w_perc_terreni_con_rid    := 1;
            w_perc_terreni_con_rid_1s := 1;
            w_mesi_possesso_1s        := 0;
            w_valore_1s               := 0;
            CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid_1s
                                   ,w_perc_terreni_con_rid,w_perc_terreni_con_rid_1s
                                   ,w_aliquota,a_perc_possesso,w_mesi_possesso
                                   ,w_mesi_possesso_1s,w_valore,w_valore_1s
                                   ,w_aliquota,a_anno
                                   ,w_terreni_con_rid_1s,w_terreni_con_rid
                                   );
        end if;
     END IF;
     a_imposta := f_round(nvl(w_terreni_senza_rid,0) +
                          nvl(w_terreni_con_rid,0),0);
  ELSE
 dbms_output.put_line ('rire: '||w_aliquota_rire);
 dbms_output.put_line ('rire_dic: '||w_aliquota_rire_dic);
 dbms_output.put_line ('w_val: '||w_valore);
 dbms_output.put_line ('w_ali: '||w_aliquota);
 dbms_output.put_line ('a_mep: '||a_mesi_possesso);
 dbms_output.put_line ('a_mee: '||a_mesi_esclusione);
 dbms_output.put_line ('a_mer: '||a_mesi_riduzione);
 dbms_output.put_line ('a_det: '||a_detrazione);
     BEGIN
       select decode(sign(
              f_round(w_valore
                * w_aliquota / 1000
           * a_perc_possesso / 100
           * (a_mesi_possesso -
              nvl(a_mesi_esclusione,0) -
              nvl(a_mesi_riduzione,0)) / 12
              +
          (w_valore
           * w_aliquota / 1000
           * a_perc_possesso / 100
           * nvl(a_mesi_riduzione,0) / 12 / 2)
         -
          nvl(a_detrazione,0),0)),
              1,
              f_round(w_valore
                * w_aliquota / 1000
           * a_perc_possesso / 100
           * (a_mesi_possesso -
              nvl(a_mesi_esclusione,0) -
              nvl(a_mesi_riduzione,0)) / 12
              +
          (w_valore
           * w_aliquota / 1000
           * a_perc_possesso / 100
           * nvl(a_mesi_riduzione,0) / 12 / 2)
         -
          nvl(a_detrazione,0), 0),0)
         into a_imposta
         from dual
       ;
     EXCEPTION
       WHEN others THEN
       RAISE_APPLICATION_ERROR
         (-20999,'Errore nel calcolo dell''Imposta Accertata');
     END;
  END IF;
-- dbms_output.put_line ('a_imp: '||a_imposta);
--  a_imposta := round((a_imposta / 1000),0) * 1000;
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_ICI */
/
