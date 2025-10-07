--liquibase formatted sql
--changeset dmarotta:20250326_152438_codi_ins stripComments:false
--validCheckSum: 1:any

INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'1', 1, 'Proprietà', 'S', 'S', 'Il proprietario ha il diritto di godere e disporre delle cose in modo pieno ed esclusivo, entro i limiti e con l''osservanza degli obblighi stabiliti dall''ordinamento giuridico (art.832 c.c.)');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'10', 18, 'Oneri', 'S', 'S', 'Solo per le volture catastali non derivanti da note di trascrizione. Il codice dovrà essere utilizzato indicando anche la descrizione in chiaro.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'1s', 2, 'Proprietà superficiaria', 'S', 'S', 'Proprietà del fabbricato che insiste su un terreno sul quale il possessore, diverso dal proprietario del fabbricato, abbia costituito il diritto di superficie a favore di quest''ultimo.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'1t', 3, 'Proprietà per l''area', 'S', 'S', 'Diritto di colui che ha concesso il diritto di superficie di un terreno');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'2', 4, 'Nuda proprietà', '', '', 'Ciò che rimane della proprietà quando venga ceduto l''usufrutto.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'2s', 5, 'Nuda proprietà superficiaria', '', '', 'Ciò che rimane della proprietà superficiaria quando venga ceduto l''usufrutto.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'3', 6, 'Abitazione su', 'S', 'S', 'Chi ha il diritto di abitazione di una casa può abitarla limitatamente ai bisogni suoi e della sua famiglia (art. 1022 c.c.).');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'3s', 7, 'Abitazione su proprietà superficiaria', 'S', 'S', 'Diritto di abitazione costituito su di un fabbricato dal titolare della proprietà superficiaria');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'4', 8, 'Diritto del concedente', 'S', 'S', 'Diritto di colui che ha concesso ad altri l''enfiteusi.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'5', 9, 'Diritto dell''enfiteuta', 'S', 'S', 'Diritto regolato dagli artt. 957 -977 c.c.; può essere perpetuo o a tempo. Sono assimilati al diritto dell''enfiteuta il diritto del miglioratario, del locatore ad meliorandum, del colono perpetuo ecc.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'6', 10, 'Superficie', 'S', 'S', 'Il proprietario può costituire il diritto di fare e mantenere al di sopra del suolo una costruzione a favore di altri che ne acquista la proprietà (art. 952 c.c.).');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'7', 11, 'Uso', 'S', 'S', 'Chi ha il diritto d''uso di una casa può servirsi di essa e, se fruttifera, può raccogliere i frutti per quanto occorre ai bisogni suoi e della sua famiglia (art. 1021 c.c.).');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'7s', 12, 'Uso su proprietà superficiaria', 'S', 'S', 'Diritto d''uso costituito su di un fabbricato dal titolare della proprietà superficiaria.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'8', 13, 'Usufrutto', 'S', 'S', 'Diritto regolato dagli artt. 978 - 1020 c.c..');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'8a', 14, 'Usufrutto con diritto di accrescimento', 'S', 'S', 'Diritto di accrescimento della propria quota di usufrutto su un immobile quando un cointestatario per lo stesso diritto venga a mancare (art.678 c.c.).');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'8e', 15, 'Usufrutto su enfiteusi', 'S', 'S', 'Usufrutto concesso dall''enfiteuta.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'8s', 16, 'Usufrutto su proprietà superficiaria', 'S', 'S', 'Diritto di usufrutto costituito su di un fabbricato dal titolare della proprietà superficiaria.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES (
'9', 17, 'Servitù', 'S', 'S', 'Solo per le note di trascrizione (artt. 1027 - 1099 c.c.). Il codice dovrà essere utilizzato indicando contemporaneamente il nomeniuris della servitù.');
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'3 ', 101, 'Comproprietario', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'4 ', 102, 'Comproprietario per', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'7 ', 103, 'Comproprietario del fabbricato', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'8 ', 104, 'Comproprietario per l`area', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'12', 105, 'Concedente in parte', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'14', 106, 'Livellario parziale per', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'15', 107, 'Usufruttuario parziale per', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'20', 108, 'Livellario', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'21', 109, 'Livellario per', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'22', 110, 'Livellario in parte', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'25', 111, 'Enfiteuta in parte', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'26', 112, 'Colono perpetuo', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'27', 113, 'Colono perpetuo per', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'28', 114, 'Colono perpetuo in parte', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'30', 115, 'Usufruttuario parziale', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'33', 116, 'Cousufruttuario generale', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'36', 117, 'Usufruttuario generale di livello', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'37', 118, 'Usufruttuario parziale di livello', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'39', 119, 'Usufruttuario parziale di enfiteusi', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'40', 120, 'Usufruttuario generale di colonia', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'41', 121, 'Usufruttuario parziale di colonia', 'S', 'S', NULL); 
INSERT INTO CODICI_DIRITTO ( COD_DIRITTO, ORDINAMENTO, DESCRIZIONE, FLAG_TRATTA_ISCRIZIONE,
FLAG_TRATTA_CESSAZIONE, NOTE ) VALUES ( 
'42', 122, 'Usufruttuario generale di dominio diretto', 'S', 'S', NULL); 
commit;
