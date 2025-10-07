--liquibase formatted sql
--changeset dmarotta:20250326_152438_So4_v_ott_ins stripComments:false
--validCheckSum: 1:any

Insert into SO4_V_OTTICHE
   (CODICE, AMMINISTRAZIONE, DESCRIZIONE, GESTIONE_REVISIONI, ISTITUZIONALE)
 Values
   ('IST_E', 'ENTE', 'Ottica Ente', 1, 1);
COMMIT;
