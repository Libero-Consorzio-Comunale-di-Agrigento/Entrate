--liquibase formatted sql
--changeset abrandolini:20250331_122738_CFATr4_g stripComments:false context:CFA
--validCheckSum: 1:any
--
--  Grant a User CFA delle tabelle di TR4
--

grant execute 	on ELABORAZIONE_FORNITURE_AE		to ${cfaUsername}
/
