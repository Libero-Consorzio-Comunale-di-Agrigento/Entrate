--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cod_fiscale stripComments:false runOnChange:true 
 
create or replace function F_COD_FISCALE
(p_Cognome       IN varchar2,
 p_nome       IN varchar2,
 p_Sesso       IN varchar2,
 p_DataNascita       IN date,
 p_CodiceCatasto    IN varchar2)
RETURN varchar2
IS
   i         NUMBER(3);
   j         NUMBER(3);
   iIndice         NUMBER(3);
   iSomma         number(3)   := 0;
   sCaratteri      varchar2(36)      := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
   sMesi         varchar2(12)      := 'ABCDEHLMPRST';
   sPesiPari      varchar2(72)      := '000102030405060708091011121314151617181920212223242500010203040506070809';
   sPesiDispari      varchar2(72)      := '010005070913151719210204182011030608121416102225242301000507091315171921';
   sCognome      varchar2(60);
   sNome         varchar2(60);
   sCodiceFiscale      varchar2(16)      := '';
   dDataNascita       date;
   sCodiceCatasto      varchar2(4);
   sDummy         varchar2(60);
   sVocali         varchar2(60)      := '';
   sConsonanti      varchar2(60)      := '';
   sLett         varchar2(1);
   sAnno         varchar2(4);
   sMese         varchar2(2);
   sGiorno         varchar2(2);
--  Generazione codice fiscale secondo
--  le caratteristiche standard adottate dal Ministero delle Finanze.
--  Il Codice e generato soltanto se tutti i parametri passati:
--
--     - Cognome           (string)
--     - Nome              (string)
--     - Sesso             (string)
--     - Data di Nascita   (Date)
--     - Codice Catasto del
--       Comune di Nascita (string)
--
--  sono non nulli e significativi
--
--  Se il codice viene generato e passato come risultato della
--  funzione, altrimenti viene restituita una stringa vuota ''
-- Se almeno uno dei dati introdotti non e significativo,
-- non si genera il codice fiscale
BEGIN
        IF p_cognome       is null
        OR p_nome          is null
        OR p_sesso         is null
        OR p_datanascita   is null
        OR p_codicecatasto is null THEN
          RETURN 'Manca Dato x CF!';
        END IF;
   -- Toglie i caratteri non significativi del nome e del cognome
   sDummy      := Upper(p_cognome);
   j         := length(p_cognome);
   FOR i IN 1 .. j LOOP
      sLett := substr(sDummy,i,1);
      IF nvl(inStr(sCaratteri,sLett),0) > 0 THEN
         sCognome := sCognome||sLett;
      END IF;
   END LOOP;
   sDummy      := Upper(p_nome);
   j         := length(p_nome);
   FOR i IN 1 .. j LOOP
      sLett := substr(sDummy,i,1);
      IF nvl(inStr(sCaratteri,sLett),0) > 0 THEN
         sNome := sNome||sLett;
      END IF;
   END LOOP;
   -- Memorizzazione delle consonanti e delle vocali separatamente
   -- del COGNOME
   j  := length(sCognome);
   if length(sCognome) > 0 then
      FOR iIndice IN 1 .. j LOOP
         sLett := substr(sCognome,iIndice,1);
         IF nvl(instr('AEIOU',sLett),0) > 0 THEN
            sVocali := sVocali||sLett;
         ELSE
           sConsonanti := sConsonanti||sLett;
         END IF;
      END LOOP;
   end if;
   i   := nvl(length(sConsonanti),0);
   j   := nvl(length(sVocali),0);
   IF i > 2 THEN
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,3);
   ELSIF i = 2 AND j > 0 THEN
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,2)||substr(sVocali,1,1);
   ELSIF i = 2 AND j = 0 THEN
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,2)||'X';
   ELSIF i = 1 AND j > 1 THEN
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,1)||substr(sVocali,1,2);
   ELSIF i = 1 AND j = 1 THEN
      sCodiceFiscale := sCodiceFiscale||sConsonanti||sVocali||'X';
   ELSIF i = 1 AND j = 0 THEN
      sCodiceFiscale := sCodiceFiscale||sConsonanti||'XX';
   ELSIF i = 0 AND j = 1 THEN
      sCodiceFiscale := sCodiceFiscale||sVocali||'XX';
   ELSIF i = 0 AND j = 2 THEN
      sCodiceFiscale := sCodiceFiscale||sVocali||'X';
   ELSIF i = 0 AND j > 2 THEN
      sCodiceFiscale := sCodiceFiscale||substr(sVocali,1,3);
   ELSE
      sCodiceFiscale := sCodiceFiscale||'XXX';
   END IF;
   -- Memorizzazione delle consonanti e delle vocali separatamente
   -- del NOME
   sVocali     := '';
   sConsonanti := '';
   j  := length(sNome);
   if length(sNome) > 0 then
      FOR iIndice IN 1 .. j LOOP
         sLett := substr(sNome,iIndice,1);
         IF nvl(instr('AEIOU',sLett),0) > 0 THEN
            sVocali := sVocali||sLett;
         ELSE
           sConsonanti := sConsonanti||sLett;
         END IF;
      END LOOP;
   end if;
   iIndice := length(sVocali);
   IF iIndice < 3 THEN
      sVocali := Rpad(sVocali,3,'X');
   END IF;
   i := length(sConsonanti);
   if i > 3 then
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,1)||substr(sConsonanti,3,2);
   elsif i = 3 then
      sCodiceFiscale := sCodiceFiscale||sConsonanti;
   elsif i = 2 then
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,2)||substr(sVocali,1,1);
   elsif i = 1 then
      sCodiceFiscale := sCodiceFiscale||substr(sConsonanti,1,1)||substr(sVocali,1,2);
   else
      sCodiceFiscale := sCodiceFiscale||sVocali;
   end if;
   -- Determinazione anno, mese, giorno e carattere del mese
   dDataNascita     := trunc(p_DataNascita);
   sCodiceFiscale     := sCodiceFiscale||to_char(dDataNascita,'yy')||
                   substr(sMesi,to_char(dDataNascita,'mm'),1);
   if p_Sesso = 'F' then
      sCodiceFiscale := sCodiceFiscale||to_char(to_number(to_char(dDataNascita,'dd'))+40);
   else
      sCodiceFiscale := sCodiceFiscale||to_char(dDataNascita,'dd');
   end if;
   -- Assegnazione Codice Catasto
   sCodiceCatasto   := substr(p_CodiceCatasto,1,4);
   sCodiceFiscale   := sCodiceFiscale||sCodiceCatasto;
   -- Determinazione ultimo carattere (check di controllo)
   FOR i IN 1 .. 15 LOOP
       iIndice := 1;
       WHILE substr(sCodiceFiscale,i,1) <> substr(sCaratteri,iIndice,1) LOOP
          iIndice := iIndice + 1;
       END LOOP;
       if Mod(i,2) = 0 then -- Pari
          iSomma := iSomma + to_number(substr(sPesiPari,((iIndice - 1) * 2 + 1),2));
       else                 -- Dispari
          iSomma := iSomma + to_number(substr(sPesiDispari,((iIndice -1) * 2 + 1),2));
       end if;
   END LOOP;
   iSomma   := iSomma - TRUNC(iSomma/26,0)*26;
   iIndice   := 1;
   WHILE to_number(substr(sPesiPari,(iIndice - 1)*2+1,2)) <> iSomma LOOP
      iIndice := iIndice + 1;
   END LOOP;
   sCodiceFiscale := sCodiceFiscale||substr(sCaratteri,iIndice,1);
   RETURN sCodiceFiscale;
END;
/* End Function: F_COD_FISCALE */
/

