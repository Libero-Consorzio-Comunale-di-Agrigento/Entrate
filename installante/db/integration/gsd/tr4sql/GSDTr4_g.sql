--liquibase formatted sql
--changeset dmarotta:20250326_152438_GSDTr4_g stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

grant select 	on dati_generali		to ${gsdUsername} with grant option;
grant all 		on soggetti   		to ${gsdUsername} with grant option;
grant all 		on archivio_vie    	to ${gsdUsername} with grant option;
grant all 		on denominazioni_via   	to ${gsdUsername} with grant option;
grant select	on contribuenti   	to ${gsdUsername} with grant option;
grant select	on oggetti			to ${gsdUsername} with grant option;
