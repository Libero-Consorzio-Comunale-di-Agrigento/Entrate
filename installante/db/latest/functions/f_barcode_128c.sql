--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_barcode_128c stripComments:false runOnChange:true 
 
create or replace function F_BARCODE_128C
(documento     varchar2
)
return varchar2
is
dato              varchar2(100);
barcode           varchar2(2000);
numero_coppie     number(12);
coppia            number(2);
carattere         varchar2(1);
checkdigit        number := 0;
ultimo_carattere  varchar2(1) := null;
-- assegnare alla variabile documento il contenuto del Barcode
begin
       if mod(length(documento),2) = 1 then
          dato := substr(documento,1,length(documento) -1);
          ultimo_carattere := substr(documento,length(documento),1);
       else
          dato := documento;
       end if;
       numero_coppie := ( length(dato) / 2 );
       barcode := chr(210); -- Carattere di Inizio
       checkdigit := 105;
       for i in 1 .. numero_coppie
       loop
           coppia := to_number(substr(dato,(i-1)*2+1,2));
           if coppia >= 0 and coppia <= 94 then   -- 94
              carattere := chr(coppia + 32);
           else
              carattere := chr(coppia + 105);    -- 105
           end if;
           barcode := barcode||carattere;
           checkdigit :=  checkdigit + i * coppia;
       end loop;
       if ultimo_carattere is not null then
          -- gestione dell'ultimo carattere in caso di lunghezza dispari
          -- si aggiunge il carattere speciale "code B"  (100)
          barcode := barcode||chr(205);
          checkdigit :=  checkdigit + (numero_coppie + 1) * 100;
          -- si aggiunge l'ultimo caratte come singolo carattere
          barcode := barcode||ultimo_carattere;
          checkdigit :=  checkdigit + (numero_coppie + 2) * (16 + to_number(ultimo_carattere));
       end if;
       checkdigit := mod(checkdigit , 103);
       if checkdigit >= 0 and checkdigit <= 94 then   --94
          carattere := chr(checkdigit + 32);
       else
          carattere := chr(checkdigit + 105);    -- 105
       end if;
       barcode := barcode||carattere;
       barcode := barcode||chr(211);  -- Carattere di stop
return barcode;
end;
/* End Function: F_BARCODE_128C */
/

