--liquibase formatted sql
--changeset dmarotta:20250625_091145_80258_alter_prtr stripComments:false

alter table PRATICHE_TRIBUTO
  drop constraint PRATICHE_TRIB_TIPO_PRATICA_CC;
alter table PRATICHE_TRIBUTO
  add constraint PRATICHE_TRIB_TIPO_PRATICA_CC
  check (TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S','P'));
