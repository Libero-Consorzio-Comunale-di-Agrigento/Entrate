--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_barcode stripComments:false runOnChange:true 
 
create or replace function F_BARCODE
(documento     varchar2
)
return varchar2
is
barcode         varchar2(2000);
numero_coppie   number(12);
coppia          number(2);
carattere       varchar2(1);
-- assegnare alla variabile documento il contenuto del Barcode ( deve essere un numero pari di cifre ) ...
begin
       numero_coppie := ( length(documento) / 2 );
       barcode := '{'; -- Carattere di Inizio
       for i in 1 .. numero_coppie
       loop
           coppia := to_number(substr(documento,(i-1)*2+1,2));
           if coppia >= 0 and coppia <= 89 then
              carattere := chr(coppia + 33);
           else
              carattere := chr(coppia + 71);
           end if;
           barcode := barcode||carattere;
       end loop;
       barcode := barcode||'}';
return barcode;
end;
/* End Function: F_BARCODE */
/

