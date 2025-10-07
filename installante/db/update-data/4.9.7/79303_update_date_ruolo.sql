--liquibase formatted sql
--changeset dmarotta:20250718_154346_79303_update_date_ruolo stripComments:false

 update ruoli ruol set
 ruol.data_emissione = trunc(ruol.data_emissione),
 ruol.invio_consorzio = trunc(ruol.invio_consorzio);
