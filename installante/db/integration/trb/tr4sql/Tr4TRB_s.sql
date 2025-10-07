--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4TRB_s stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any

create synonym ananre    for ${trbUsername}.ananre;
create synonym n01       for ${trbUsername}.n01;
