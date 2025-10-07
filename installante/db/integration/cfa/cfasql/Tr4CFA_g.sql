--liquibase formatted sql
--changeset abrandolini:20250331_120938_Tr4CFA_g stripComments:false context:CFA
--validCheckSum: 1:any

--
--  Grant a User TR4 delle tabelle di CFA
--

grant select on ACC_TRIBUTI					to ${targetUsername};
grant select on PROVVISORI_ENTRATA_TRIBUTI 	to ${targetUsername};
