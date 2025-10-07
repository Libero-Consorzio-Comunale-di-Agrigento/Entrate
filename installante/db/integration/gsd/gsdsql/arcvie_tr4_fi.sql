--liquibase formatted sql
--changeset abrandolini:20250514_123600_arcvie_tr4_fi_su_GSD stripComments:false runOnChange:true context:"TRG2 or TRV2"

/*	DATA	: 30/12/1998	*/

create or replace procedure ARCVIE_TR4_FI
(a_cod_via_old		IN 	number,
 a_cod_via_new		IN	number,
 a_denom_uff            IN	varchar2,
 a_denom_ric            IN	varchar2,
 a_denom_ord        	IN	varchar2,
 a_inizia               IN	varchar2,
 a_termina              IN	varchar2
)
IS
w_controllo		varchar2(1);
w_errore		varchar2(2000);
errore			exception;

BEGIN
  IF INSERTING THEN
BEGIN
select 'x'
into w_controllo
from archivio_vie arvi
where arvi.cod_via = a_cod_via_new
;
EXCEPTION
       WHEN no_data_found THEN
BEGIN
insert into archivio_vie
(cod_via,denom_uff,denom_ord,utente,note)
values (a_cod_via_new,a_denom_uff,
        a_denom_ord,'GSD',
        a_inizia||' '||a_termina)
;
EXCEPTION
              WHEN others THEN
	           w_errore := 'Errore in inserimento Archivio_vie'||
		               '('||SQLERRM||')';
                   RAISE errore;
END;
BEGIN
insert into denominazioni_via (cod_via,progr_via,descrizione)
select a_cod_via_new,2,a_denom_ric
from dual
;
EXCEPTION
              WHEN others THEN
                   w_errore := 'Errore in inserimento Denominazioni Vie'||
		               '('||SQLERRM||')';
                   RAISE errore;
END;
END;
  ELSIF UPDATING THEN
BEGIN
update archivio_vie
set cod_via		= a_cod_via_new,
    denom_uff		= a_denom_uff,
    denom_ord		= a_denom_ord,
    utente		= 'GSD',
    note		= decode(ltrim(note),a_inizia||' '||a_termina,note,
                         rtrim(note)||decode(a_inizia,null,null,
                                             ' '||a_inizia)||
                         decode(a_termina,null,null,
                                ' '||a_termina))
where cod_via		= a_cod_via_old
;
IF SQL%NOTFOUND THEN
	  w_errore := 'Identificazione '||a_cod_via_old||
		      ' non presente in archivio_vie';
	  RAISE errore;
END IF;
EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in aggiornamento Archivio Vie '||
		        '('||SQLERRM||')';
            RAISE errore;
END;
BEGIN
update denominazioni_via
set cod_via		= a_cod_via_new,
    descrizione	= a_denom_ric
where cod_via		= a_cod_via_old
  and progr_via		= 2
;
IF SQL%NOTFOUND THEN
BEGIN
insert into denominazioni_via (cod_via,progr_via,descrizione)
select a_cod_via_new,2,a_denom_ric
from dual
;
EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in inserimento Denominazioni Vie'||
	                     '('||SQLERRM||')';
                 RAISE errore;
END;
END IF;
EXCEPTION
        WHEN others THEN
             w_errore := 'Errore in aggiornamento Denominazioni Via '||
	                 '('||SQLERRM||')';
             RAISE errore;
END;
  ELSIF DELETING THEN
BEGIN
      delete archivio_vie
       where cod_via = a_cod_via_old
      ;
EXCEPTION
      WHEN others THEN
           w_errore := 'Errore in cancellazione Archivio Vie '||
	               '('||SQLERRM||')';
           RAISE errore;
END;
END IF;
EXCEPTION
  WHEN errore THEN
       RAISE_APPLICATION_ERROR
	 (-20999,w_errore);
WHEN others THEN
       RAISE_APPLICATION_ERROR
	 (-20999,SQLERRM);
END;
/* End Procedure: ARCVIE_TR4_FI */
/
