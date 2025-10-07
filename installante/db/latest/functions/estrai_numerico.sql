--liquibase formatted sql 
--changeset abrandolini:20250326_152438_estrai_numerico stripComments:false runOnChange:true 
 
create or replace function estrai_numerico (nStringa varchar2)
return number
is
-- LA FUNZIONE RESTITUISCE IL PRIMO GRUPPO NUMERICO CONTENUTO IN UNA STRINGA
w_valore_numerico number;
BEGIN
select
decode(sign(instr(translate(nStringa||'X'
,'0123456789','9999999999'),'9',1)
- decode(instr(nstringa,'-'),0,rpad('9',length(nStringa),'9'),instr(nStringa,'-'))
),1,'-'
,''
)
||substr(nStringa||'X',
instr(translate(nStringa||'X'
,'0123456789','9999999999'),'9',1),
instr(translate(nStringa||'X',
replace(translate(nStringa||'X'
,'0123456789','9999999999'),'9',''),
rpad('X',
length(replace(translate(
nStringa||'X'
,'0123456789','9999999999'),'9','')
),'X')
),'X'
,instr(translate(nStringa||'X'
,'0123456789','9999999999'),'9',1)
)
-instr(translate(nStringa||'X'
,'0123456789','9999999999'),'9',1)
)
into w_valore_numerico
from dual
;
RETURN w_valore_numerico;
END;
/

