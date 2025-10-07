--liquibase formatted sql
--changeset rvattolo:20250212_095712_web_anadce stripComments:false runOnChange:true

CREATE OR REPLACE FORCE VIEW WEB_ANADCE
(cod_ev, descrizione, tipo_evento, anagrafe)
AS
SELECT cod_eve, descrizione, tipo_evento, anagrafe
  FROM anadce
/
