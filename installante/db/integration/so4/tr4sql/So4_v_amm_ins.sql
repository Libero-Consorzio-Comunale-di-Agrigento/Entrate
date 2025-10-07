--liquibase formatted sql
--changeset dmarotta:20250326_152438_So4_v_amm_ins stripComments:false
--validCheckSum: 1:any

Insert into SO4_V_AMMINISTRAZIONI
   (CODICE, ENTE, ID_SOGGETTO)
 Values
   ('ENTE', 1, 1);
COMMIT;
