--liquibase formatted sql
--changeset dmarotta:20250326_152438_tiex_ins_elifis stripComments:false  context:ER
--validCheckSum: 1:any

ALTER TABLE tipi_export DISABLE ALL TRIGGERS
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 151, 'ELIFIS Anagrafica dei Soggetti', 'TR4ER_ELIFIS.ANAGRAFICHE_SOGGETTI', 'wrk_trasmissioni', 'anagrafiche_soggetti_', 
    201, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 151)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 152, 'ELIFIS Anagrafica degli Oggetti', 'TR4ER_ELIFIS.ANAGRAFICHE_OGGETTI', 'wrk_trasmissioni', 'anagrafiche_oggetti_', 
    202, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 152)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 153, 'ELIFIS Comuni', 'TR4ER_ELIFIS.TRACCIATO_COMUNI', 'wrk_trasmissioni', 'comuni_', 
    203, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 153)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 154, 'ELIFIS Nazioni', 'TR4ER_ELIFIS.TRACCIATO_NAZIONI', 'wrk_trasmissioni', 'nazioni_', 
    204, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 154)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 155, 'ELIFIS Strade', 'TR4ER_ELIFIS.SIT_STRADE', 'wrk_trasmissioni', 'strade_', 
    205, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 155)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 156, 'ELIFIS Civici', 'TR4ER_ELIFIS.SIT_CIVICI', 'wrk_trasmissioni', 'civici_', 
    206, 'TRASV', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 156)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 157, 'ELIFIS Denunce ICI', 'TR4ER_ELIFIS.DENUNCE_ICI', 'wrk_trasmissioni', 'denunce_ici_', 
    207, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 157)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 158, 'ELIFIS Aliquote Speciali ICI', 'TR4ER_ELIFIS.ALIQUOTE_SPECIALI_ICI', 'wrk_trasmissioni', 'aliquote_speciali_ici_', 
    208, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 158)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 159, 'ELIFIS Detrazioni ICI', 'TR4ER_ELIFIS.DETRAZIONI_ICI', 'wrk_trasmissioni', 'detrazioni_ici_', 
    209, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 159)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 160, 'ELIFIS Versamenti ICI', 'TR4ER_ELIFIS.VERSAMENTI_ICI', 'wrk_trasmissioni', 'versamenti_ici_', 
    210, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 160)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 161, 'ELIFIS Provvedimenti ICI', 'TR4ER_ELIFIS.PROVVEDIMENTI_ICI', 'wrk_trasmissioni', 'provvedimenti_ici_', 
    211, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 161)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 162, 'ELIFIS Dovuti ICI', 'TR4ER_ELIFIS.DOVUTI_ICI', 'wrk_trasmissioni', 'dovuti_ici_', 
    212, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 162)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 163, 'ELIFIS Aliquote ICI', 'TR4ER_ELIFIS.ALIQUOTE_ICI', 'wrk_trasmissioni', 'aliquote_ici_', 
    213, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 163)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 164, 'ELIFIS Agevolazioni ICI', 'TR4ER_ELIFIS.AGEVOLAZIONI_ICI', 'wrk_trasmissioni', 'agevolazioni_ici_', 
    214, 'ICI', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 164)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 165, 'ELIFIS Denunce RSU', 'TR4ER_ELIFIS.DENUNCE_RSU', 'wrk_trasmissioni', 'denunce_rsu_', 
    215, 'TARSU', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 165)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 166, 'ELIFIS Provvedimenti RSU', 'TR4ER_ELIFIS.PROVVEDIMENTI_RSU', 'wrk_trasmissioni', 'provvedimenti_rsu_', 
    216, 'TARSU', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 166)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 167, 'ELIFIS Classe Tariffa RSU', 'TR4ER_ELIFIS.CLASSE_TARIFFA_RSU', 'wrk_trasmissioni', 'classe_tariffa_rsu_', 
    217, 'TARSU', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 167)
/

Insert into TIPI_EXPORT
   (TIPO_EXPORT, DESCRIZIONE, NOME_PROCEDURA, TABELLA_TEMPORANEA, NOME_FILE, 
    ORDINAMENTO, TIPO_TRIBUTO, SUFFISSO_NOME_FILE, ESTENSIONE_NOME_FILE)
select 168, 'ELIFIS Tipi Oggetto RSU', 'TR4ER_ELIFIS.TIPI_OGGETTO_RSU', 'wrk_trasmissioni', 'tipi_oggetto_rsu_', 
    218, 'TARSU', 'TIMESTAMP', '.txt' 
  from dual
 where not exists (select 'x' from TIPI_EXPORT
                    where TIPO_EXPORT  = 168)
/

ALTER TABLE tipi_export ENABLE ALL TRIGGERS
/
