--liquibase formatted sql 
--changeset abrandolini:20250326_152401_sottocategorie stripComments:false runOnChange:true 
 
create or replace force view sottocategorie as
select CATEGORIE.TRIBUTO, CATEGORIE.CATEGORIA_RIF categoria,
CATEGORIE.CATEGORIA sottocategoria, CATEGORIE.DESCRIZIONE
from CATEGORIE
where categoria_rif is not null;
comment on table SOTTOCATEGORIE is 'SOCA - Sottocategorie';

