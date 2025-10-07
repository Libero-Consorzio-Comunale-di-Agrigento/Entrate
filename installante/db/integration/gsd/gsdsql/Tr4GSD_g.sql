--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4GSD_g stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

grant select on anaana    to ${targetUsername} with grant option;
grant select on anadev    to ${targetUsername} with grant option;
grant select on anadpr    to ${targetUsername} with grant option;
grant select on anadrp    to ${targetUsername} with grant option;
grant select on anadst    to ${targetUsername} with grant option;
grant select on anaeve    to ${targetUsername} with grant option;
grant select on anafam    to ${targetUsername} with grant option;
grant select on anaste    to ${targetUsername} with grant option;
grant select on arcvie    to ${targetUsername} with grant option;
grant select on arcint    to ${targetUsername} with grant option;
grant select on arccom    to ${targetUsername} with grant option;
grant select on arcpro    to ${targetUsername} with grant option;

-- x TributiWeb: 
grant select on anadce    to ${targetUsername} with grant option;
grant select on anamov    to ${targetUsername} with grant option;

-- x ftp trasmissioni
grant select on anaelac_v to ${targetUsername} with grant option;
grant select on tabrep    to ${targetUsername} with grant option;
