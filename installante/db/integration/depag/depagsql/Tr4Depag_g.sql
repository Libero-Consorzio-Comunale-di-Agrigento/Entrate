--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4Depag_g stripComments:false context:DEPAG
--validCheckSum: 1:any

grant select on depag_dovuti 				to ${targetUsername};
grant select on depag_dovuti_annullabili 	to ${targetUsername};
grant select on depag_dovuti_pagati 		to ${targetUsername};
grant execute on service_pkg				to ${targetUsername};

