--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_adatta_data stripComments:false runOnChange:true 
 
create or replace function F_ADATTA_DATA
(a_stringa in varchar2)
return date
is
--
-- Data una stringa in input di 8 caratteri
-- prevista con contenuto data nella forma
-- ddmmyyyy, restituisce la data corrispondente
-- se il contenuto e` effettivamente una data.
-- Se il contenuto e` nullo o spazio o contiene
-- caratteri non numerici, ritorna una data nulla.
-- Viene eseguita una lpad a 8 caratteri con 0;
-- del risultato gli ultimi 4 caratteri rappresentano
-- l`anno con un minimo di 1850
-- (se il valore e` minore si assume 1850);
-- relativamente all`anno ricavato si analizzano
-- il 3^ e 4^ carattere che rappresenta il mese:
-- se < 01 si assume 01, se > 12, si assume 12;
-- relativamente a anno e mese in corso si analizzano
-- i primi 2 caratteri: se < 01 si assume 01, se > del
-- giorno di fine mese, si assume il fine mese.
--
-- Esempi: stringa = 10101999 , data = 10101999
--         stringa = 10100000 , data = 10101850
--         stringa = 2000     , data = 01012000
--         stringa = 20151998 , data = 20121999
--         stringa = 101999   , data = 01101999
--         stringa = 31022000 , data = 29022000, ecc...
--
sStringa             varchar2(8);
dData                date;
sGiorno              varchar2(2);
sMese                varchar2(2);
sAnno                varchar2(4);
nStringa             number(8);
BEGIN
--
-- Caso di input vuoto.
--
   if a_stringa is null or ltrim(rtrim(a_stringa)) = '' then
      Return to_date(null);
   end if;
--
-- Caso di input non numerico.
--
   BEGIN
      nStringa := to_number(sStringa);
   EXCEPTION
      WHEN OTHERS THEN
         Return to_date(null);
   END;
--
-- Caso di input significativo.
--
   sStringa := lpad(a_stringa,8,'0');
   sAnno    := substr(sStringa,5);
--
-- Normalizzazione dell`anno a 1850, se minore.
--
   if to_number(sAnno) < 1850 then
      sAnno := '1850';
   end if;
   sMese := substr(sStringa,3,2);
--
-- Normalizzazione del mese se < 1 o > 12.
--
   if to_number(sMese) < 1 then
      sMese := '01';
   end if;
   if to_number(sMese) > 12 then
      sMese := '12';
   end if;
   sGiorno := substr(sStringa,1,2);
--
-- Normalizzazione del giorno se < 1 o > fine mese.
--
   if to_number(sGiorno) < 1 then
      sGiorno := '01';
   end if;
   if to_number(sGiorno) >
      to_number(to_char(last_day(to_date('01'||sMese||sAnno,'ddmmyyyy')),'dd')) then
      sGiorno := to_char(last_day(to_date('01'||sMese||sAnno,'ddmmyyyy')),'dd');
   end if;
--
-- Composizione della Data.
--
   dData := to_date(sGiorno||sMese||sAnno,'ddmmyyyy');
   Return dData;
END;
/* End Function: F_ADATTA_DATA */
/

