--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4GSDps stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

create synonym Gsd_IntegrityPackage for ${gsdUsername}.IntegrityPackage;

create synonym anaana_tr4_fi 		for ${gsdUsername}.anaana_tr4_fi;
create synonym anafam_tr4_fi 		for ${gsdUsername}.anafam_tr4_fi;
create synonym arcvie_tr4_fi 		for ${gsdUsername}.arcvie_tr4_fi;

create synonym f_unita_territoriale	for ${gsdUsername}.f_unita_territoriale;
create synonym f_intestatario_interno 	for ${gsdUsername}.f_intestatario_interno;
create synonym f_stato_interno 		for ${gsdUsername}.f_stato_interno;
create synonym f_intestatario_ecografico for ${gsdUsername}.f_intestatario_ecografico;
create synonym f_stato_ecografico 	for ${gsdUsername}.f_stato_ecografico;
create synonym f_mov_fascia_al 		for ${gsdUsername}.f_mov_fascia_al;
create synonym f_matricola_md 		for ${gsdUsername}.f_matricola_md;
create synonym f_matricola_pd 		for ${gsdUsername}.f_matricola_pd;
