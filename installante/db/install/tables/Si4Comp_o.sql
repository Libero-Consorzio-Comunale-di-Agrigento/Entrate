--liquibase formatted sql
--changeset dmarotta:20250326_152438_Si4Comp_o stripComments:false
--validCheckSum: 1:any

/*==============================================================*/
/* DBMS name:      Si4 for ORACLE 8                             */
/* Created on:     29/01/2004 11.50.39                          */
/*==============================================================*/


create sequence ABIL_SQ
increment by 1
start with 1
nocache
/

create sequence COMP_SQ
increment by 1
start with 1
nocache
/

create sequence TIAB_SQ
increment by 1
start with 1
nocache
/

create sequence TIOG_SQ
increment by 1
start with 1
nocache
/

/*==============================================================*/
/* Table: SI4_ABILITAZIONI                                      */
/*==============================================================*/


create table SI4_ABILITAZIONI  (
   ID_ABILITAZIONE      NUMBER(10)                       not null,
   ID_TIPO_OGGETTO      NUMBER(10),
   ID_TIPO_ABILITAZIONE NUMBER(10),
   constraint SI4_ABILITAZIONI_PK primary key (ID_ABILITAZIONE)
)
/

comment on table SI4_ABILITAZIONI is
'ABIL - Abilitazione relative agli oggetti di competenza'
/

/*==============================================================*/
/* Index: SI4_ABIL_TIOG_FK                                      */
/*==============================================================*/
create index SI4_ABIL_TIOG_FK on SI4_ABILITAZIONI (
   ID_TIPO_OGGETTO ASC
)
/

/*==============================================================*/
/* Index: SI4_ABIL_TIAB_FK                                      */
/*==============================================================*/
create index SI4_ABIL_TIAB_FK on SI4_ABILITAZIONI (
   ID_TIPO_ABILITAZIONE ASC
)
/

/*==============================================================*/
/* Table: SI4_COMPETENZE                                        */
/*==============================================================*/


create table SI4_COMPETENZE  (
   ID_COMPETENZA        NUMBER(10)                       not null,
   ID_ABILITAZIONE      NUMBER(10)                       not null,
   UTENTE               VARCHAR2(8)                      not null,
   OGGETTO              VARCHAR2(250)                    not null,
   ACCESSO              VARCHAR2(1)                      not null
         constraint SI4_COMPETENZ_ACCESSO_CC check (ACCESSO in ('S','N')),
   RUOLO                VARCHAR2(250),
   DAL                  DATE,
   AL                   DATE,
   DATA_AGGIORNAMENTO   DATE,
   UTENTE_AGGIORNAMENTO VARCHAR2(8),
   constraint SI4_COMPETENZE_PK primary key (ID_COMPETENZA)
)
/

comment on table SI4_COMPETENZE is
'COMP - Competenze su Oggetti del DataBase'
/

comment on column SI4_COMPETENZE.ACCESSO is
'Abilitazione di accesso sulla informazione'
/

/*==============================================================*/
/* Index: SI4_COMP_UTEN_FK                                      */
/*==============================================================*/
create index SI4_COMP_UTEN_FK on SI4_COMPETENZE (
   UTENTE ASC
)
/

/*==============================================================*/
/* Index: SI4_COMP_ABIL_FK                                      */
/*==============================================================*/
create index SI4_COMP_ABIL_FK on SI4_COMPETENZE (
   ID_ABILITAZIONE ASC
)
/

/*==============================================================*/
/* Index: SI4_COMP_OGGETTO                                      */
/*==============================================================*/
create index SI4_COMP_OGGETTO on SI4_COMPETENZE (
   OGGETTO ASC
)
/

/*==============================================================*/
/* Table: SI4_TIPI_ABILITAZIONE                                 */
/*==============================================================*/


create table SI4_TIPI_ABILITAZIONE  (
   ID_TIPO_ABILITAZIONE NUMBER(10)                       not null,
   TIPO_ABILITAZIONE    VARCHAR2(2)                      not null,
   DESCRIZIONE          VARCHAR2(2000),
   constraint SI4_TIPI_ABILITAZIONE_PK primary key (ID_TIPO_ABILITAZIONE)
)
/

comment on table SI4_TIPI_ABILITAZIONE is
'TIAB - Tipi di abiliazione attribuibili agli oggetti di competenza'
/

alter table SI4_TIPI_ABILITAZIONE
   add constraint TIPO_ABILITAZIONE_UK unique (TIPO_ABILITAZIONE)
/

/*==============================================================*/
/* Table: SI4_TIPI_OGGETTO                                      */
/*==============================================================*/


create table SI4_TIPI_OGGETTO  (
   ID_TIPO_OGGETTO      NUMBER(10)                       not null,
   TIPO_OGGETTO         VARCHAR2(30)                     not null,
   DESCRIZIONE          VARCHAR2(2000),
   constraint SI4_TIPI_OGGETTO_PK primary key (ID_TIPO_OGGETTO)
)
/

comment on table SI4_TIPI_OGGETTO is
'TIOG - Tipi di Oggetto per Gestione Competenze'
/

alter table SI4_TIPI_OGGETTO
   add constraint TIPO_OGGETTO_UK unique (TIPO_OGGETTO)
/

/*==============================================================*/
/* View: SI4_COMPETENZA_OGGETTI                                 */
/*==============================================================*/
create or replace force view SI4_COMPETENZA_OGGETTI as
select
   COMP.ID_COMPETENZA,
   ABIL.ID_TIPO_OGGETTO,
   COMP.OGGETTO,
   COMP.UTENTE,
   COMP.ACCESSO,
   UTEN.NOMINATIVO NOMINATIVO_UTENTE,
   ABIL.ID_TIPO_ABILITAZIONE,
   COMP.DAL,
   COMP.AL
from
   SI4_COMPETENZE COMP,
   SI4_ABILITAZIONI ABIL,
   AD4_UTENTI UTEN
where 
   COMP.ID_ABILITAZIONE = ABIL.ID_ABILITAZIONE
   and COMP.UTENTE = UTEN.UTENTE
/

alter table SI4_ABILITAZIONI
   add constraint SI4_ABIL_TIAB_FK foreign key (ID_TIPO_ABILITAZIONE)
      references SI4_TIPI_ABILITAZIONE (ID_TIPO_ABILITAZIONE)
/

alter table SI4_ABILITAZIONI
   add constraint SI4_ABIL_TIOG_FK foreign key (ID_TIPO_OGGETTO)
      references SI4_TIPI_OGGETTO (ID_TIPO_OGGETTO)
/

alter table SI4_COMPETENZE
   add constraint SI4_COMP_ABIL_FK foreign key (ID_ABILITAZIONE)
      references SI4_ABILITAZIONI (ID_ABILITAZIONE)
/

alter table SI4_COMPETENZE
   add constraint SI4_COMP_UTEN_FK foreign key (UTENTE)
      references AD4_UTENTI (UTENTE)
/
