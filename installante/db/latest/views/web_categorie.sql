--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_categorie stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW WEB_CATEGORIE AS
SELECT
 TRIBUTO
,CATEGORIA
,DESCRIZIONE
,CATEGORIA_RIF
,DESCRIZIONE_PREC
,FLAG_DOMESTICA
,FLAG_GIORNI
,FLAG_NO_DEPAG
, id_categoria
--, to_number(lpad(TRIBUTO, 4, '0') || lpad(CATEGORIA, 4, '0')) id_categoria
FROM categorie
;
comment on table WEB_CATEGORIE is 'WEB_CATEGORIE';

