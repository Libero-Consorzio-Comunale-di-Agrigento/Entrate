--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4Tr4ps stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

create synonym Gsd_IntegrityPackage for IntegrityPackage;
