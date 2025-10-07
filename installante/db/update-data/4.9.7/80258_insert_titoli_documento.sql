--liquibase formatted sql
--changeset dmarotta:20250617_123923_80258_insert_titoli_documento stripComments:false


INSERT INTO titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
SELECT 40, 'Acquisizione da portale', null, null, null, null, null
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM titoli_documento WHERE TITOLO_DOCUMENTO = 40);


