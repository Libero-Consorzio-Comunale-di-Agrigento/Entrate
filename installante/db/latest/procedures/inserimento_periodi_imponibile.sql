--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_periodi_imponibile stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_PERIODI_IMPONIBILE
(a_oggetto              in     number
,a_valore               in     number
,a_inizio_possesso      in     date
,a_fine_possesso        in     date
,a_inizio_possesso_1s   in     date
,a_fine_possesso_1s     in     date
,a_moltiplicatore       in     number
,a_rivalutazione        in     number
,a_tipo_oggetto         in     number
,a_anno_titr            in     number
,b_anno                 in     number
,a_imm_storico          in     varchar2
,a_oggetto_pratica      in     number
,a_cod_fiscale          in     varchar2
,a_utente               in     varchar2
,a_totale_importo       in out number
,a_totale_importo_1s    in out number
) is
errore                  exception;
w_errore                varchar2(1000);
w_totale_importo        number;
w_totale_importo_1s     number;
w_totale_mesi           number;
w_totale_mesi_1s        number;
w_valore                number;
w_ind                   number;
w_inizio_mese           date;
w_fine_mese             date;
w_valore_imp            number;
w_da_mese               number;
w_a_mese                number;
w_flag_riog             varchar(1);
w_flag_riog_ins         varchar(1);
BEGIN
   w_totale_importo        := 0;
   w_totale_importo_1s     := 0;
   w_totale_mesi           := 0;
   w_totale_mesi_1s        := 0;
   w_ind                   := 0;
   w_valore_imp            := -9999999999;
   w_da_mese               := 0;
   w_a_mese                := 0;
   w_flag_riog             := null;
   w_flag_riog_ins         := null;
   LOOP
      w_ind := w_ind + 1;
      if w_ind > 12 then
         exit;
      end if;
      w_inizio_mese := to_date('01'||
                               lpad(to_char(w_ind),2,'0')||
                               lpad(to_char(b_anno),4,'0'),'ddmmyyyy'
                              );
      w_fine_mese   := last_day(w_inizio_mese);
      if a_tipo_oggetto = 4 then
         w_valore := a_valore;
      else
         BEGIN
            select round(riog.rendita * decode(a_tipo_oggetto
                                              ,1,nvl(nvl(molt.moltiplicatore,a_moltiplicatore),1)
                                              ,3,decode(nvl(a_imm_storico,'N')||to_char(sign(2012 - b_anno))
                                                       ,'S1',100
                                                       ,nvl(nvl(molt.moltiplicatore,a_moltiplicatore),1)
                                                       )
                                                ,1
                                              )
                                      * (100 + nvl(a_rivalutazione,0)) / 100
                        ,2
                        )
                 , 'S'
              into w_valore
                 , w_flag_riog
              from riferimenti_oggetto riog
                 , moltiplicatori molt
             where riog.oggetto           = a_oggetto
               and molt.categoria_catasto (+) = riog.categoria_catasto
               and molt.anno  (+)             = b_anno
               and riog.inizio_validita  <= w_fine_mese
               and riog.fine_validita    >= w_inizio_mese
               and least(w_fine_mese,riog.fine_validita) + 1 -
                   greatest(w_inizio_mese,riog.inizio_validita)
                                         >= 15
               and riog.inizio_validita   =
                  (select max(rio2.inizio_validita)
                     from riferimenti_oggetto rio2
                    where rio2.oggetto           = riog.oggetto
                      and rio2.inizio_validita  <= w_fine_mese
                      and rio2.fine_validita    >= w_inizio_mese
                      and least(w_fine_mese,rio2.fine_validita) + 1 -
                          greatest(w_inizio_mese,rio2.inizio_validita)
                                                >= 15
                  )
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_valore := a_valore;
               w_flag_riog := null;
         END;
      end if;
      if  w_ind >= to_number(to_char(a_inizio_possesso,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso,'mm')) then
         w_totale_importo    := w_totale_importo    + w_valore;
         w_totale_mesi       := w_totale_mesi       + 1;
      end if;
      if  w_ind >= to_number(to_char(a_inizio_possesso_1s,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso_1s,'mm')) then
         w_totale_importo_1s := w_totale_importo_1s + w_valore;
         w_totale_mesi_1s    := w_totale_mesi_1s    + 1;
      end if;
      if w_ind = to_number(to_char(a_inizio_possesso,'mm')) then
         w_da_mese       := w_ind;
         w_valore_imp    := w_valore;
         w_flag_riog_ins := w_flag_riog;
      end if;
      if w_ind  > to_number(to_char(a_inizio_possesso,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso,'mm')) then
         if w_valore_imp <> w_valore then
            w_a_mese := w_ind - 1;
            BEGIN
               insert into periodi_imponibile
                       ( cod_fiscale,anno,oggetto_pratica
                       , da_mese, a_mese ,imponibile
                       , imponibile_d, flag_riog, utente)
                values ( a_cod_fiscale,b_anno,a_oggetto_pratica
                       , w_da_mese, w_a_mese, w_valore_imp
                       , a_valore, w_flag_riog_ins, a_utente)
                     ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in ins. Periodi Imponibile di '||a_cod_fiscale||
                              ' Anno '||to_char(b_anno)||
                              ' da mese '||to_char(w_da_mese)||' a mese '||to_char(w_a_mese)||
                              ' Oggetto Pratica '||to_char(a_oggetto_pratica);
               RAISE errore;
            END;
            w_da_mese       := w_ind;
            w_valore_imp    := w_valore;
            w_flag_riog_ins := w_flag_riog;
         end if;
      end if;
      if w_ind = to_number(to_char(a_fine_possesso,'mm')) then
         w_a_mese := w_ind;
         BEGIN
            insert into periodi_imponibile
                     ( cod_fiscale,anno,oggetto_pratica
                     , da_mese, a_mese ,imponibile
                     , imponibile_d, flag_riog, utente)
              values ( a_cod_fiscale,b_anno,a_oggetto_pratica
                     , w_da_mese, w_a_mese, w_valore_imp
                     , a_valore, w_flag_riog_ins, a_utente)
                   ;
         EXCEPTION
             WHEN others THEN
                w_errore := 'Errore in ins. Periodi Imponibile (2) di '||a_cod_fiscale||
                            ' Anno '||to_char(b_anno)||
                            ' da mese '||to_char(w_da_mese)||' a mese '||to_char(w_a_mese)||
                            ' Oggetto Pratica '||to_char(a_oggetto_pratica);
             RAISE errore;
         END;
      end if;
   END LOOP;
   if w_totale_mesi    = 0 then
      a_totale_importo    := 0;
   else
      a_totale_importo    := round(w_totale_importo    / w_totale_mesi   ,2);
   end if;
   if w_totale_mesi_1s = 0 then
      a_totale_importo_1s := 0;
   else
      a_totale_importo_1s := round(w_totale_importo_1s / w_totale_mesi_1s,2);
   end if;
EXCEPTION
   WHEN errore THEN
      dbms_output.put_line('w_errore '||w_errore);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore||' ('||SQLERRM||')',true);
  WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in INSERIMENTO_PERIODI_IMPONIBILE di '||a_cod_fiscale||' '||'('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_PERIODI_IMPONIBILE */
/

