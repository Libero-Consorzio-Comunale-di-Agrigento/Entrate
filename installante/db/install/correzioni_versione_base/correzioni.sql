--liquibase formatted sql
--changeset dmarotta:20250326_152438_correzioni stripComments:false failOnError:false
--validCheckSum: 1:any

---------------------------------------
--  Changed table ARCHIVIO_VIE_ZONA  --
---------------------------------------
alter table ARCHIVIO_VIE_ZONA modify cod_via not null;
alter table ARCHIVIO_VIE_ZONA modify sequenza not null;
alter table ARCHIVIO_VIE_ZONA modify da_num_civ not null;
alter table ARCHIVIO_VIE_ZONA
  add constraint ARCHIVIO_VIE_ZONA_PK primary key (COD_VIA, SEQUENZA)
  using index
  tablespace PAL
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );

---------------------------------------
--  Changed table archivio_vie_zone  --
---------------------------------------
-- Add/modify columns
alter table ARCHIVIO_VIE_ZONE modify cod_zona not null;
alter table ARCHIVIO_VIE_ZONE modify sequenza not null;
-- Create/Recreate primary, unique and foreign key constraints
alter table ARCHIVIO_VIE_ZONE
  add constraint ARCHIVIO_VIE_ZONE_PK primary key (COD_ZONA, SEQUENZA)
  using index
  tablespace PAL
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );

----------------------------------
--  Changed table dati_metrici  --
----------------------------------
-- Add/modify columns
alter table DATI_METRICI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI
  is 'SAME - Dati Metrici';
--------------------------------------------
--  Changed table dati_metrici_dati_atto  --
--------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_DATI_ATTO modify soggetti_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_DATI_ATTO
  is 'DMDA - Dati Metrici Dati Atto';
---------------------------------------------
--  Changed table dati_metrici_dati_nuovi  --
---------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_DATI_NUOVI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_DATI_NUOVI
  is 'DMDN - Dati Metrici Dati Nuovi';
------------------------------------------------
--  Changed table dati_metrici_esiti_agenzia  --
------------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_ESITI_AGENZIA modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_ESITI_AGENZIA
  is 'DMEA - Dati Metrici Esiti Agenzia';
-----------------------------------------------
--  Changed table dati_metrici_esiti_comune  --
-----------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_ESITI_COMUNE modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_ESITI_COMUNE
  is 'DMEC - Dati Metrici Esiti Comune';
-------------------------------------------------
--  Changed table dati_metrici_identificativi  --
-------------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_IDENTIFICATIVI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_IDENTIFICATIVI
  is 'DMID - Dati Metrici Identificativi';
--------------------------------------------
--  Changed table dati_metrici_indirizzi  --
--------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_INDIRIZZI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_INDIRIZZI
  is 'DMIN - Dati Metrici Indirizzi';
-------------------------------------------
--  Changed table dati_metrici_soggetti  --
-------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_SOGGETTI modify soggetti_id NUMBER(15);
alter table DATI_METRICI_SOGGETTI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_SOGGETTI
  is 'DMSO - DAti Metrici Soggetti';
------------------------------------------
--  Changed table dati_metrici_testate  --
------------------------------------------
-- Add comments to the table
comment on table DATI_METRICI_TESTATE
  is 'DMTE - Dati Metrici Testate';
---------------------------------------------
--  Changed table dati_metrici_ubicazioni  --
---------------------------------------------
-- Add/modify columns
alter table DATI_METRICI_UBICAZIONI modify uiu_id NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_UBICAZIONI
  is 'DMUB - Dati Metrici Ubicazioni';
--------------------------------------
--  Changed table dati_metrici_uiu  --
--------------------------------------
-- Add/modify columns
alter table DATI_METRICI_UIU modify uiu_id NUMBER(15);
alter table DATI_METRICI_UIU modify id_uiu NUMBER(15);
-- Add comments to the table
comment on table DATI_METRICI_UIU
  is 'DMUI - Dati Metrici UIU';

------------------------------------
--  Changed table moltiplicatori  --
------------------------------------
-- Add/modify columns
alter table MOLTIPLICATORI modify moltiplicatore NUMBER(5,2);

--------------------------------------
--  Changed table parametri_export  --
--------------------------------------
-- Add/modify columns
alter table PARAMETRI_EXPORT modify tipo_export not null;
alter table PARAMETRI_EXPORT modify parametro_export not null;
alter table PARAMETRI_EXPORT modify ultimo_valore VARCHAR2(2000);
alter table PARAMETRI_EXPORT modify valore_predefinito VARCHAR2(2000);
-- Create/Recreate primary, unique and foreign key constraints
alter table PARAMETRI_EXPORT
  add constraint PARAMETRI_EXPORT_PK primary key (TIPO_EXPORT, PARAMETRO_EXPORT)
  using index
  tablespace PAL
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );

---------------------------------------
--  Changed table recapiti_soggetto  --
---------------------------------------
-- Add/modify columns
alter table RECAPITI_SOGGETTO modify presso VARCHAR2(100);

--------------------------------------
--  Changed table wrk_enc_immobili  --
--------------------------------------
-- Add/modify columns
alter table WRK_ENC_IMMOBILI modify perc_possesso NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_corrispettivo_medio NUMBER(9,2);
alter table WRK_ENC_IMMOBILI modify d_costo_medio NUMBER(9,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_superficie NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_sup_gg NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_soggetti NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_sogg_gg NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_giorni NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_perc_imponibilita NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify d_rapporto_cms_cm NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_corrispettivo_medio_perc NUMBER(9,2);
alter table WRK_ENC_IMMOBILI modify a_corrispettivo_medio_prev NUMBER(9,2);
alter table WRK_ENC_IMMOBILI modify a_rapporto_superficie NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_rapporto_sup_gg NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_rapporto_soggetti NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_rapporto_sogg_gg NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_rapporto_giorni NUMBER(5,2);
alter table WRK_ENC_IMMOBILI modify a_perc_imponibilita NUMBER(5,2);

--------------------------------------
--  Changed table pratiche_tributo  --
--------------------------------------
-- Create/Recreate check constraints
alter table PRATICHE_TRIBUTO
  drop constraint PRATICHE_TRIB_TIPO_EVENTO_CC;
alter table PRATICHE_TRIBUTO
  add constraint PRATICHE_TRIB_TIPO_EVENTO_CC
  check (
            TIPO_EVENTO in ('I','V','C','U','R','T','A','S', '0', '1', '2', '3', '4'));

alter table SOGGETTI
  drop constraint soggetti_stato_cc;


-- Drop check constraints
alter table STORICO_SOGGETTI
  drop constraint STORICO_SOGGE_STATO_CC;
