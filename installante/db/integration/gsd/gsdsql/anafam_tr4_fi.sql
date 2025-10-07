--liquibase formatted sql
--changeset abrandolini:20250514_123300_anafam_tr4_fi_su_GSD stripComments:false runOnChange:true context:"TRG2 or TRV2"

--	Creata il: 	28/01/1999

create or replace procedure ANAFAM_TR4_FI
(a_cod_fam_old		number,
 a_cod_fam_new		number,
 a_fascia_new		number,
 a_cod_via_new		number,
 a_num_civ_new		number,
 a_suffisso_new		varchar2,
 a_interno_new		number,
 a_scala_new		varchar2,
 a_piano_new		varchar2,
 a_via_aire_new		varchar2,
 a_cod_pro_aire_new	number,
 a_cod_com_aire_new	number,
 a_intestatario_new	varchar2,
 a_zipcode_new		varchar2)

IS

w_pro_cliente		number;
w_com_cliente		number;
w_cap			varchar2(5);
w_cap_cliente		varchar2(5);

BEGIN
  IF a_fascia_new = 1 THEN
BEGIN
select pro_cliente, com_cliente, lpad(cap,5,'0')
into w_pro_cliente,w_com_cliente,w_cap_cliente
from ad4_comuni,dati_generali
where provincia_stato 	= pro_cliente
  and comune    	= com_cliente
;
EXCEPTION
       WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Manca record in Dati Generali o in ARCCOM');
WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Dati Generali '||
	     	   '('||SQLERRM||')');
END;
BEGIN
select decode(instr(dst.descrizione,' '),0,
              dst.descrizione,
              substr(dst.descrizione,1,instr(dst.descrizione,' ')-1))
into w_cap
from anadst dst,anaste ste
where dst.cod_ut 	= ste.cod_ut
  and dst.cod_st 	= ste.cod_st
  and ste.cod_ut 	= 99
  and ste.cod_via 	= a_cod_via_new
  and lpad(a_num_civ_new,6,' ')||a_suffisso_new
    between lpad(ste.civico_inf,6,' ')||ste.suffisso_inf
    and lpad(ste.civico_sup,6,' ')||nvl(ste.suffisso_sup,'}}}')
  and (ste.pari_dispari = decode(mod(a_num_civ_new,2),1,'D','P')
    or
       ste.pari_dispari is null)
  and rownum  = 1
;
EXCEPTION
       WHEN no_data_found THEN
   	    w_cap := w_cap_cliente;
WHEN others THEN
            RAISE_APPLICATION_ERROR
              (-20999,'Errore in ricerca CAP '||
		          '('||SQLERRM||')');
END;
END IF;
  IF a_fascia_new in (1,3) THEN
     IF UPDATING THEN
update soggetti
set cod_fam			= a_cod_fam_new,
    cod_via			= a_cod_via_new,
    num_civ			= a_num_civ_new,
    suffisso			= a_suffisso_new,
    interno			= a_interno_new,
    scala			= a_scala_new,
    piano 			= a_piano_new,
    denominazione_via        = substr(a_via_aire_new,1,60),
    cod_pro_res		= nvl(a_cod_pro_aire_new,cod_pro_res),
    cod_com_res		= nvl(a_cod_com_aire_new,cod_com_res),
    utente			= 'GSD',
    cap			= w_cap,
    intestatario_fam		= a_intestatario_new,
    zipcode                  = a_zipcode_new
where cod_fam			= a_cod_fam_old
  and fascia			= a_fascia_new
;
END IF;
END IF;
END;
/* End Procedure: ANAFAM_TR4_FI */
/

