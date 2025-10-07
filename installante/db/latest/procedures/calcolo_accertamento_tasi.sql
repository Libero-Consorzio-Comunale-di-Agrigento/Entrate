--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_tasi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_TASI
/*************************************************************************
 NOME:        CALCOLO_ACCERTAMENTO_TASI
 DESCRIZIONE: Calcolo accertamento TASI
 NOTE:
 Rev.    Date         Author      Note
 000     26/08/2019   VD          Prima emissione
*************************************************************************/
(a_anno                    IN     number,
 a_tipo_rapporto           IN     varchar2,
 a_tipo_oggetto            IN     number,
 a_valore                  IN     number,
 a_flag_valore_rivalutato  IN     varchar2,
 a_tipo_aliquota           IN OUT number,
 a_aliquota                IN     number,
 a_perc_possesso           IN     number,
 a_mesi_possesso           IN OUT number,
 a_mesi_esclusione         IN     number,
 a_mesi_riduzione          IN OUT number,
   a_mesi_occupato           IN OUT number,
 a_flag_riduzione          IN     varchar2,
 a_detrazione              IN     number,
 a_anno_dic                IN     number,
 a_categoria_catasto       in     varchar2,
 a_imposta                 IN OUT number,
 a_percentuale             IN OUT number)
IS
sql_errm             varchar2(100);
w_aliquota           number;
w_valore             number;
w_imposta            number;
w_perc_occupante        number;
w_occupante             varchar2(1) := 'A';
w_mesi_affitto          number;
w_mesi_affitto_1s       number;
BEGIN
  w_valore := a_valore;
-- dbms_output.put_line ('a_val: '||a_valore);
  BEGIN
    select aliq.aliquota
      into w_aliquota
      from aliquote aliq
     where aliq.anno          = a_anno
       and aliq.tipo_aliquota = a_tipo_aliquota
       and tipo_tributo       = 'TASI'
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
               where aliq.anno         = a_anno
                and aliq.tipo_aliquota = a_tipo_aliquota
                and tipo_tributo = 'TASI'
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
      (-20999,'Errore in ricerca Aliquote: '||sqlerrm);
  END;
--
-- Estrazione Percentuale Occupante
--
  begin
     select perc_occupante
       into w_perc_occupante
       from aliquote
      where anno = a_anno
        and tipo_tributo = 'TASI'
        and tipo_aliquota = 1
        ;
      if w_perc_occupante is null then
         RAISE_APPLICATION_ERROR
            (-20999,'Errore: non esiste percentuale occupante');
      end if;
  exception
     when others then
         RAISE_APPLICATION_ERROR
            (-20999,'Errore in ricerca Percentuale Occupante: '||sqlerrm);
  end;
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
      w_imposta  := f_round(w_valore * w_aliquota / 1000
                                 * a_perc_possesso / 100
                                 * (a_mesi_possesso - nvl(a_mesi_esclusione,0) - nvl(a_mesi_riduzione,0)) / 12
                     + (w_valore * w_aliquota / 1000
                                 * a_perc_possesso / 100
                                 * nvl(a_mesi_riduzione,0) / 12 / 2)
                     - nvl(a_detrazione,0), 0);
  if w_imposta < 0 then
         w_imposta := 0;
      end if;
      if a_tipo_rapporto = w_occupante then
         w_imposta := round(w_imposta * w_perc_occupante / 100, 2);
  else
         if a_mesi_occupato > 0 and
                  a_mesi_possesso > 0 then
                  w_imposta := round(w_imposta * (100 - (w_perc_occupante * a_mesi_occupato / a_mesi_possesso)) / 100, 2);
               end if;
      end if;
-- dbms_output.put_line ('a_imp: '||a_imposta);
  a_imposta     := w_imposta;
  a_percentuale := w_perc_occupante;
--
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_TASI */
/

