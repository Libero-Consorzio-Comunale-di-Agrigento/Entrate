--liquibase formatted sql
--changeset abrandolini:20250514_122300_anaana_tr4_fi_su_GSD stripComments:false runOnChange:true context:"TRG2 or TRV2"

--	Creata il: 	29/12/1998

create or replace procedure ANAANA_TR4_FI
(a_matricola_old		IN 	number,
 a_matricola_new		IN	number,
 a_cognome_nome                 IN	varchar2,
 a_fascia                       IN	number,
 a_stato                        IN	number,
 a_data_ult_eve			IN	number,
 a_sesso                        IN	varchar2,
 a_cod_prof                     IN	number,
 a_pensionato                   IN	number,
 a_cod_fam                      IN	number,
 a_rapporto_par                 IN	varchar2,
 a_sequenza_par                 IN	number,
 a_cod_pro_nas                  IN	number,
 a_cod_com_nas                  IN	number,
 a_data_nas	                IN	number,
 a_cod_pro_mor			IN	number,
 a_cod_com_mor			IN	number,
 a_cod_fiscale                  IN	varchar2,
 a_data_reg              	IN	number,
 a_cf_calcolato            	IN	varchar2)

IS

w_pro_cliente		number;
w_com_cliente		number;
w_cod_via		number;
w_num_civ		number;
w_suffisso		varchar2(10);
w_interno		number;
w_scala			varchar2(3);
w_piano			varchar2(3);
w_via_aire		varchar2(60);
w_cod_pro_aire		number;
w_cod_com_aire		number;
w_cod_pro_eve		number;
w_cod_com_eve		number;
w_controllo		varchar(1);
w_cap			varchar2(5);
w_cap_cliente		varchar2(5);
w_intestatario		varchar2(60);
w_indirizzo_emi		varchar2(60);
w_denom_uff		varchar2(60);
w_zipcode		varchar2(10);

BEGIN
BEGIN
select pro_cliente, com_cliente, lpad(cap,5,'0')
into w_pro_cliente,w_com_cliente,w_cap_cliente
from ad4_comuni,dati_generali
where provincia_stato 	= pro_cliente
  and comune    		= com_cliente
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
select fam.cod_via,fam.num_civ,fam.suffisso,fam.interno,
       fam.scala,fam.piano,
       substr(fam.via_aire,1,60),fam.cod_pro_aire,fam.cod_com_aire,
       NULL,fam.intestatario,vie.denom_uff,fam.zipcode
into w_cod_via,w_num_civ,w_suffisso,w_interno,
    w_scala,w_piano,
    w_via_aire,w_cod_pro_aire,w_cod_com_aire,
    w_cap,w_intestatario,w_denom_uff,w_zipcode
from arcvie vie,anafam fam
where vie.cod_via (+) = fam.cod_via
  and fam.cod_fam		= a_cod_fam
  and ((fam.fascia	in (1,2) and a_fascia in (1,2)) or
       (fam.fascia	in (3,4) and a_fascia in (3,4)))
;
EXCEPTION
    WHEN no_data_found THEN
	 null;
WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca Famiglie: Fascia '||a_fascia||' Cod_fam: '||
		a_cod_fam||' Matr.: '||a_matricola_new||' '||
		'('||SQLERRM||')');
END;
  IF a_stato = 1 THEN
     w_cod_pro_eve := a_cod_pro_nas;
     w_cod_com_eve := a_cod_com_nas;
  ELSIF a_stato = 50 THEN
     w_cod_pro_eve := a_cod_pro_mor;
     w_cod_com_eve := a_cod_com_mor;
ELSE
BEGIN
select eve.cod_pro_eve,eve.cod_com_eve
into w_cod_pro_eve,w_cod_com_eve
from anaeve eve
where eve.data_eve	= a_data_ult_eve
  and eve.cod_eve	= a_stato
  and eve.cod_mov	= a_fascia
  and eve.matricola	= a_matricola_new
  and rownum		= 1
;
EXCEPTION
       WHEN no_data_found THEN
	      null;
WHEN others THEN
            RAISE_APPLICATION_ERROR
              (-20999,'Errore in ricerca Evento Matr. '||a_matricola_new||' '||
		          '('||SQLERRM||')');
END;
BEGIN
select indirizzo_emi
into w_indirizzo_emi
from anacp4 cp4,anacpm cpm,anaeve eve
where cp4.anno_dic		= cpm.anno_dic
  and cp4.numero_dic  	= cpm.numero_dic
  and cpm.matricola 		= eve.matricola
  and cp4.anno_pratica	= eve.anno_pratica
  and cp4.pratica		= eve.pratica
  and eve.data_eve		= a_data_ult_eve
  and eve.cod_eve		= a_stato
  and eve.cod_mov		= a_fascia
  and eve.matricola		= a_matricola_new
  and rownum			= 1
;
EXCEPTION
       WHEN no_data_found THEN
	      w_indirizzo_emi := null;
WHEN others THEN
            RAISE_APPLICATION_ERROR
              (-20999,'Errore in ricerca Indirizzo EMI '||a_matricola_new||' '||
		          '('||SQLERRM||')');
END;
END IF;
  IF a_fascia = 1 THEN
BEGIN
select decode(instr(dst.descrizione,' '),0,
              dst.descrizione,
              substr(dst.descrizione,1,instr(dst.descrizione,' ')-1))
into w_cap
from anadst dst,anaste ste
where dst.cod_ut 	= ste.cod_ut
  and dst.cod_st 	= ste.cod_st
  and ste.cod_ut 	= 99
  and ste.cod_via 	= w_cod_via
  and lpad(w_num_civ,6,' ')||w_suffisso
    between lpad(ste.civico_inf,6,' ')||ste.suffisso_inf
    and lpad(ste.civico_sup,6,' ')||nvl(ste.suffisso_sup,'}}}')
  and (ste.pari_dispari = decode(mod(w_num_civ,2),1,'D','P')
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
  IF INSERTING THEN
BEGIN
select 'x'
into w_controllo
from soggetti sogg
where sogg.tipo_residente = 0
  and sogg.matricola	  = a_matricola_new
;
EXCEPTION
       WHEN no_data_found THEN BEGIN
      	   insert into soggetti
		  (tipo_residente,matricola,cod_fiscale,
  		   cognome_nome,fascia,stato,
		   data_ult_eve,cod_pro_eve,cod_com_eve,
		   sesso,cod_fam,rapporto_par,sequenza_par,
		   data_nas,cod_pro_nas,cod_com_nas,
		   cod_pro_res,cod_com_res,
	           cod_prof,pensionato,
		   denominazione_via,
		   cod_via,num_civ,suffisso,interno,
		   scala,piano,
		   tipo,flag_cf_calcolato,
                   utente,cap,intestatario_fam,zipcode)
           values (0,a_matricola_new,a_cod_fiscale,
 	           a_cognome_nome,a_fascia,a_stato,
		   to_date(a_data_ult_eve,'j'),w_cod_pro_eve,w_cod_com_eve,
		   a_sesso,
	           a_cod_fam,a_rapporto_par,a_sequenza_par,
	           to_date(a_data_nas,'j'),a_cod_pro_nas,a_cod_com_nas,
		   nvl(w_cod_pro_aire,w_pro_cliente),
		   nvl(w_cod_com_aire,w_com_cliente),
	           a_cod_prof,a_pensionato,
		   w_via_aire,
	           w_cod_via,w_num_civ,w_suffisso,w_interno,
	           w_scala,w_piano,
		   0,a_cf_calcolato,
                   'GSD',nvl(w_cap,w_cap_cliente),w_intestatario,
		   decode(a_fascia,3,w_zipcode,4,w_zipcode,null))
	   ;
EXCEPTION
           WHEN others THEN
             RAISE_APPLICATION_ERROR
	       (-20999,'Errore in inserimento Soggetti '||
		       '('||SQLERRM||')');
END;
WHEN others THEN
         null;
END;
  ELSIF UPDATING THEN
BEGIN
update soggetti
set matricola		= a_matricola_new,
    cod_fiscale		= a_cod_fiscale,
    cognome_nome	= a_cognome_nome,
    fascia		= a_fascia,
    stato			= a_stato,
    data_ult_eve	= to_date(a_data_ult_eve,'j'),
    cod_pro_eve		= w_cod_pro_eve,
    cod_com_eve		= w_cod_com_eve,
    sesso			= a_sesso,
    cod_fam		= a_cod_fam,
    rapporto_par	= a_rapporto_par,
    sequenza_par	= a_sequenza_par,
    data_nas    	= to_date(a_data_nas,'j'),
    cod_pro_nas		= a_cod_pro_nas,
    cod_com_nas		= a_cod_com_nas,
    cod_pro_res		= decode(fascia,1,
                                decode(a_fascia,2,
                                       decode(a_stato,51,w_cod_pro_eve,w_pro_cliente),
                                       3,w_cod_pro_aire,w_pro_cliente),
                                2,
                                decode(a_fascia,2,cod_pro_res,
                                       3,w_cod_pro_aire,w_pro_cliente),
                                decode(a_fascia,3,w_cod_pro_aire,
                                       4,w_cod_pro_aire,w_pro_cliente)),
    cod_com_res		= decode(fascia,1,
                                decode(a_fascia,2,
                                       decode(a_stato,51,w_cod_com_eve,w_com_cliente),
                                       3,w_cod_com_aire,w_com_cliente),
                                2,
                                decode(a_fascia,2,cod_com_res,
                                       3,w_cod_com_aire,w_com_cliente),
                                decode(a_fascia,3,w_cod_com_aire,
                                       4,w_cod_com_aire,w_com_cliente)),
    cod_prof		= a_cod_prof,
    pensionato		= a_pensionato,
    denominazione_via	= decode(fascia,1,
                                  decode(a_fascia,2,
                                         decode(a_stato,51,w_indirizzo_emi,null),
                                         3,w_via_aire,null),
                                  2,
                                  decode(a_fascia,2,denominazione_via,
                                         3,w_via_aire,null),
                                  decode(a_fascia,3,w_via_aire,
                                         4,w_via_aire,null)),
    cod_via 		= decode(a_fascia,1,w_cod_via,
                            decode(fascia,1,
                                   decode(a_fascia,2,
                                          decode(a_stato,51,null,w_cod_via),
                                          null),
                                   2,
                                   decode(a_fascia,2,cod_via,null),
                                   null)),
    num_civ		= decode(a_fascia,1,w_num_civ,
                            decode(fascia,1,
                                   decode(a_fascia,2,
                                          decode(a_stato,51,null,num_civ),
                                          null),
                                   2,
                                   decode(a_fascia,2,num_civ,null),
                                   null)),
    suffisso		= decode(a_fascia,1,w_suffisso,
                             decode(fascia,1,
                                    decode(a_fascia,2,
                                           decode(a_stato,51,null,suffisso),
                                           null),
                                    2,
                                    decode(a_fascia,2,suffisso,null),
                                    null)),
    interno		= decode(a_fascia,1,w_interno,
                            decode(fascia,1,
                                   decode(a_fascia,2,
                                          decode(a_stato,51,null,interno),
                                          null),
                                   2,
                                   decode(a_fascia,2,interno,null),
                                   null)),
    scala			= decode(a_fascia,1,w_scala,
                              decode(fascia,1,
                                     decode(a_fascia,2,
                                            decode(a_stato,51,null,scala),
                                            null),
                                     2,
                                     decode(a_fascia,2,scala,null),
                                     null)),
    piano			= decode(a_fascia,1,w_piano,
                              decode(fascia,1,
                                     decode(a_fascia,2,
                                            decode(a_stato,51,null,piano),
                                            null),
                                     2,
                                     decode(a_fascia,2,piano,null),
                                     null)),
    flag_cf_calcolato = a_cf_calcolato,
    utente		= 'GSD',
    cap		= nvl(w_cap,w_cap_cliente),
    intestatario_fam	= w_intestatario,
    zipcode		= decode(a_fascia,3,w_zipcode,
                            4,w_zipcode,null)
where tipo_residente	= 0
  and matricola		= a_matricola_old
;
EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in aggiornamento Soggetti (Generale)'||
		   '('||SQLERRM||')');
END;
     IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR
	  (-20999,'Identificazione '||a_matricola_old||
                  ' non presente in archivio Soggetti');
END IF;
BEGIN
update soggetti
set cap = (select cap
           from arccom
           where cod_provincia = cod_pro_res
             and cod_comune    = cod_com_res)
where tipo_residente	= 0
  and matricola		= a_matricola_old
  and fascia 		in (2,3,4)
;
EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in aggiornamento Soggetti (Cap) '||
		   '('||SQLERRM||')');
END;
  ELSIF DELETING THEN
BEGIN
       delete soggetti
        where tipo_residente	= 0
          and matricola 	= a_matricola_old
       ;
EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in cancellazione Soggetti '||
		   '('||SQLERRM||')');
END;
END IF;
END;
/* End Procedure: anaana_tr4_fi.sql */
/
