--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_riog_multiplo stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_RIOG_MULTIPLO
/*************************************************************************
 Procedure che cerca di determinare la rendita media annuale
 di un oggetto posseduto da un contribuente.
 Mese per mese calcola la rendita in base al riog (se esiste),
 e la somma a quella dei mesi precedenti.
 Al termine restituisce il valore totale diviso per i mesi di possesso.
 (Se il riog non esiste considera come rendita del mese l'input a_valore.)
  Rev.    Date         Author      Note
*************************************************************************/
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
,a_imm_storico          in     varchar
,a_totale_importo       in out number
,a_totale_importo_1s    in out number
) is
w_totale_importo        number;
w_totale_importo_1s     number;
w_totale_mesi           number;
w_totale_mesi_1s        number;
w_valore                number;
w_ind                   number;
w_inizio_mese           date;
w_fine_mese             date;
BEGIN
   w_totale_importo        := 0;
   w_totale_importo_1s     := 0;
   w_totale_mesi           := 0;
   w_totale_mesi_1s        := 0;
   w_ind                   := 0;
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
              into w_valore
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
         END;
      end if;
      if  w_ind >= to_number(to_char(a_inizio_possesso,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso,'mm')) then
         w_totale_importo    := w_totale_importo    + w_valore;
         --dbms_output.put_line('CALCOLO RIOG MULTIPLO - Valore Tot '||to_char(w_valore)||' '||to_char(w_ind));
         w_totale_mesi       := w_totale_mesi       + 1;
      end if;
      if  w_ind >= to_number(to_char(a_inizio_possesso_1s,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso_1s,'mm')) then
         --dbms_output.put_line('CALCOLO RIOG MULTIPLO - Valore Acc '||to_char(w_valore)||' '||to_char(w_ind));
         w_totale_importo_1s := w_totale_importo_1s + w_valore;
         w_totale_mesi_1s    := w_totale_mesi_1s    + 1;
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
END;
/* End Procedure: CALCOLO_RIOG_MULTIPLO */
/

