--liquibase formatted sql
--changeset abrandolini:20250331_124838_Tr4TRB_g stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any
--
--  Grant a User TR4 delle tabelle di TRB
--

grant all on ananre    to ${targetUsername} with grant option;
grant all on n01       to ${targetUsername} with grant option;
