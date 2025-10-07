--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4TRBps stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any

create synonym Trb_IntegrityPackage for ${trbUsername}.IntegrityPackage;
create synonym ananre_tr4_fi 		for ${trbUsername}.ananre_tr4_fi;
create synonym ananre_tr4_pd 		for ${trbUsername}.ananre_tr4_pd;
