--liquibase formatted sql
--changeset dmarotta:20250326_152438_TRBTr4pg stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any

grant execute on integritypackage 	to ${targetUsername};
