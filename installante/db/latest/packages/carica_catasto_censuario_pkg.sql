--liquibase formatted sql 
--changeset abrandolini:20250326_152429_carica_catasto_censuario_pkg stripComments:false runOnChange:true 
 
create or replace package CARICA_CATASTO_CENSUARIO_PKG is
/******************************************************************************
 NOME:        CARICA_CATASTO_CENSUARIO
 DESCRIZIONE: Procedure e Funzioni per caricamento dati catasto censuario
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
 001   21/01/2022  VD      Adeguamento a nuovo tracciato del 21/07/2021
                           Eliminazione trattamento tabelle
                           - cc_identificativi_orig
                           - cc_indirizzi_orig
******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '0    20/06/2020';
  function VERSIONE
  return varchar2;
  procedure INSERT_ANOMALIE
  ( a_riga                      varchar2
  );
  procedure TRATTA_SOGGETTI
  ( a_riga                      varchar2
  );
  procedure TRATTA_FABBRICATI
  ( a_riga                      varchar2
  );
  procedure TRATTA_TERRENI
  ( a_riga                      varchar2
  );
  procedure TRATTA_TITOLARITA
  ( a_riga                      varchar2
  );
  procedure ESEGUI
  ( a_documento_id             number
  , a_utente                   in     varchar2
  , a_messaggio                in out varchar2
  );
end CARICA_CATASTO_CENSUARIO_PKG;
/

create or replace package body CARICA_CATASTO_CENSUARIO_PKG is
/******************************************************************************
 NOME:        CARICA_CATASTO_CENSUARIO_PKG
 DESCRIZIONE: Procedure e Funzioni per caricamento dati catasto censuario
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
 001   21/01/2022  VD      Adeguamento a nuovo tracciato del 21/07/2021
                           Eliminazione trattamento tabelle
                           - cc_identificativi_orig
                           - cc_indirizzi_orig
******************************************************************************/
-- Variabili di package
  p_da_sostituire            varchar2(1);
  p_sostituto                varchar2(1);
  p_documento_id             number;
  p_nome_documento           varchar2(255);
  p_tipo_trattamento         varchar2 (1);
  p_utente                   varchar2(8);
  p_num_separatori           number;
  p_lunghezza_riga           number;
  p_inizio                   number := 0;
  p_fine                     number;
  p_occorrenza               number;
  p_campo                    varchar2 (32767);
  p_errore                   varchar (2000) := null;
  p_conta_anomalie           number := 0;
  p_esiste                   number;
  p_soggetti_tot             number := 0;
  p_soggetti_ins             number := 0;
  p_soggetti_mess            varchar2(2000);
  p_fabbricati_tot           number := 0;
  p_fabbricati_ins           number := 0;
  p_fabbricati_mess          varchar2(2000);
  p_identificativi_tot       number := 0;
  p_identificativi_ins       number := 0;
  p_identificativi_mess      varchar2(2000);
  p_indirizzi_tot            number := 0;
  p_indirizzi_ins            number := 0;
  p_indirizzi_mess           varchar2(2000);
  p_terreni_tot              number := 0;
  p_terreni_ins              number := 0;
  p_terreni_mess             varchar2(2000);
  p_titolarita_tot           number := 0;
  p_titolarita_ins           number := 0;
  p_titolarita_mess          varchar2(2000);
  p_conta_iden               number;
  p_conta_indi               number;
  errore                     exception;
  -- Tipo record in sostituzione della tabella CC_IDENTIFICATIVI_ORIG
  type t_rec_ide_orig        is record
    ( codice_amministrativo  varchar2(4 byte),
      sezione                varchar2(1),
      id_immobile            number(15),  --Modifica del 21/01/2022
      tipo_immobile          varchar2(1),
      progressivo            number(3),
      tipi_record            number(1),
      sezione_1              varchar2(3),
      foglio_1               varchar2(4),
      numero_1               varchar2(5),
      denominatore_1         number(4),
      subalterno_1           varchar2(4),
      edificialita_1         varchar2(1),
      sezione_2              varchar2(3),
      foglio_2               varchar2(4),
      numero_2               varchar2(5),
      denominatore_2         number(4),
      subalterno_2           varchar2(4),
      edificialita_2         varchar2(1),
      sezione_3              varchar2(3),
      foglio_3               varchar2(4),
      numero_3               varchar2(5),
      denominatore_3         number(4),
      subalterno_3           varchar2(4),
      edificialita_3         varchar2(1),
      sezione_4              varchar2(3),
      foglio_4               varchar2(4),
      numero_4               varchar2(5),
      denominatore_4         number(4),
      subalterno_4           varchar2(4),
      edificialita_4         varchar2(1),
      sezione_5              varchar2(3),
      foglio_5               varchar2(4),
      numero_5               varchar2(5),
      denominatore_5         number(4),
      subalterno_5           varchar2(4),
      edificialita_5         varchar2(1),
      sezione_6              varchar2(3),
      foglio_6               varchar2(4),
      numero_6               varchar2(5),
      denominatore_6         number(4),
      subalterno_6           varchar2(4),
      edificialita_6         varchar2(1),
      sezione_7              varchar2(3),
      foglio_7               varchar2(4),
      numero_7               varchar2(5),
      denominatore_7         number(4),
      subalterno_7           varchar2(4),
      edificialita_7         varchar2(1),
      sezione_8              varchar2(3),
      foglio_8               varchar2(4),
      numero_8               varchar2(5),
      denominatore_8         number(4),
      subalterno_8           varchar2(4),
      edificialita_8         varchar2(1),
      sezione_9              varchar2(3),
      foglio_9               varchar2(4),
      numero_9               varchar2(5),
      denominatore_9         number(4),
      subalterno_9           varchar2(4),
      edificialita_9         varchar2(1),
      sezione_10             varchar2(3),
      foglio_10              varchar2(4),
      numero_10              varchar2(5),
      denominatore_10        number(4),
      subalterno_10          varchar2(4),
      edificialita_10        varchar2(1),
      sezione_ric            varchar2(3),
      foglio_ric             varchar2(4),
      numero_ric             varchar2(5),
      subalterno_ric         varchar2(4),
      estremi_catasto        varchar2(20),
      sezione_2_ric          varchar2(3),
      foglio_2_ric           varchar2(4),
      numero_2_ric           varchar2(5),
      subalterno_2_ric       varchar2(4),
      estremi_catasto_2      varchar2(20),
      sezione_3_ric          varchar2(3),
      foglio_3_ric           varchar2(4),
      numero_3_ric           varchar2(5),
      subalterno_3_ric       varchar2(4),
      estremi_catasto_3      varchar2(20),
      sezione_4_ric          varchar2(3),
      foglio_4_ric           varchar2(4),
      numero_4_ric           varchar2(5),
      subalterno_4_ric       varchar2(4),
      estremi_catasto_4      varchar2(20),
      sezione_5_ric          varchar2(3),
      foglio_5_ric           varchar2(4),
      numero_5_ric           varchar2(5),
      subalterno_5_ric       varchar2(4),
      estremi_catasto_5      varchar2(20),
      sezione_6_ric          varchar2(3),
      foglio_6_ric           varchar2(4),
      numero_6_ric           varchar2(5),
      subalterno_6_ric       varchar2(4),
      estremi_catasto_6      varchar2(20),
      sezione_7_ric          varchar2(3),
      foglio_7_ric           varchar2(4),
      numero_7_ric           varchar2(5),
      subalterno_7_ric       varchar2(4),
      estremi_catasto_7      varchar2(20),
      sezione_8_ric          varchar2(3),
      foglio_8_ric           varchar2(4),
      numero_8_ric           varchar2(5),
      subalterno_8_ric       varchar2(4),
      estremi_catasto_8      varchar2(20),
      sezione_9_ric          varchar2(3),
      foglio_9_ric           varchar2(4),
      numero_9_ric           varchar2(5),
      subalterno_9_ric       varchar2(4),
      estremi_catasto_9      varchar2(20),
      sezione_10_ric         varchar2(3),
      foglio_10_ric          varchar2(4),
      numero_10_ric          varchar2(5),
      subalterno_10_ric      varchar2(4),
      estremi_catasto_10     varchar2(20));
  -- Tipo record in sostituzione della tabella CC_INDIRIZZI_ORIG
  type t_rec_ind_orig        is record
    ( codice_amministrativo  varchar2(4),
      sezione                varchar2(1),
      id_immobile            number(15),  --Modifica del 21/01/2022
      tipo_immobile          varchar2(1),
      progressivo            number(3),
      tipo_record            number(1),
      toponimo_1             number(3),
      indirizzo_1            varchar2(50),
      civico1_1              varchar2(6),
      civico2_1              varchar2(6),
      civico3_1              varchar2(6),
      toponimo_2             number(3),
      indirizzo_2            varchar2(50),
      civico1_2              varchar2(6),
      civico2_2              varchar2(6),
      civico3_2              varchar2(6),
      toponimo_3             number(3),
      indirizzo_3            varchar2(50),
      civico1_3              varchar2(6),
      civico2_3              varchar2(6),
      civico3_3              varchar2(6),
      toponimo_4             number(3),
      indirizzo_4            varchar2(50),
      civico1_4              varchar2(6),
      civico2_4              varchar2(6),
      civico3_4              varchar2(6),
      indirizzo_ric          varchar2(50),
      cod_strada_1           number(5),
      cod_strada_2           number(5),
      cod_strada_3           number(5),
      cod_strada_4           number(5));
function VERSIONE return varchar2
is
begin
  return s_versione||'.'||s_revisione;
end versione;
-------------------------------------------------------------------------------
procedure INSERT_ANOMALIE
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        INSERT_ANOMALIE
 DESCRIZIONE: Inserimento record tabelle ANOMALIE
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
begin
  begin
    insert into anomalie_caricamento
              ( documento_id
              , sequenza
              , dati_oggetto
              , descrizione
              , note
              )
       values ( p_documento_id
              , p_conta_anomalie
              , substr(a_riga,1,1000)
              , p_nome_documento
              , p_errore
              );
  exception
    when others then
      p_errore := 'Errore in inserimento anomalie_caricamento soggetto '
               || ' ('|| sqlerrm|| ')';
      raise errore;
  end;
end INSERT_ANOMALIE;
-------------------------------------------------------------------------------
procedure INSERT_CC_IDENTIFICATIVI
( a_rec_ide_orig           t_rec_ide_orig
, a_riga                   varchar2
, a_progr_iden             number
) is
/******************************************************************************
 NOME:        INSERT_CC_IDENTIFICATIVI
 DESCRIZIONE: Inserimento record tabella CC_IDENTIFICATIVI(nuova versione)
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  rec_ide                  cc_identificativi%rowtype;
begin
  rec_ide                       := null;
  rec_ide.codice_amm            := a_rec_ide_orig.codice_amministrativo;
  rec_ide.sezione_amm           := a_rec_ide_orig.sezione;
  rec_ide.id_immobile           := a_rec_ide_orig.id_immobile;
  rec_ide.tipo_immobile         := a_rec_ide_orig.tipo_immobile;
  rec_ide.progressivo           := a_rec_ide_orig.progressivo;
  rec_ide.tipo_record           := a_rec_ide_orig.tipi_record;
  rec_ide.progr_identificativo  := (p_conta_iden * 10) + a_progr_iden;
  rec_ide.documento_id          := p_documento_id;
  rec_ide.utente                := p_utente;
  rec_ide.data_variazione       := trunc(sysdate);
  if rec_ide.id_immobile = 244868 then
     dbms_output.put_line('a_conta_iden: '||p_conta_iden);
  end if;
--
  if a_progr_iden = 1 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_1;
     rec_ide.foglio             := a_rec_ide_orig.foglio_1;
     rec_ide.numero             := a_rec_ide_orig.numero_1;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_1;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_1;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_1;
  elsif
     a_progr_iden = 2 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_2;
     rec_ide.foglio             := a_rec_ide_orig.foglio_2;
     rec_ide.numero             := a_rec_ide_orig.numero_2;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_2;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_2;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_2;
  elsif
     a_progr_iden = 3 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_3;
     rec_ide.foglio             := a_rec_ide_orig.foglio_3;
     rec_ide.numero             := a_rec_ide_orig.numero_3;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_3;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_3;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_3;
  elsif
     a_progr_iden = 4 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_4;
     rec_ide.foglio             := a_rec_ide_orig.foglio_4;
     rec_ide.numero             := a_rec_ide_orig.numero_4;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_4;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_4;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_4;
  elsif
     a_progr_iden = 5 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_5;
     rec_ide.foglio             := a_rec_ide_orig.foglio_5;
     rec_ide.numero             := a_rec_ide_orig.numero_5;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_5;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_5;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_5;
  elsif
     a_progr_iden = 6 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_6;
     rec_ide.foglio             := a_rec_ide_orig.foglio_6;
     rec_ide.numero             := a_rec_ide_orig.numero_6;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_6;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_6;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_6;
  elsif
     a_progr_iden = 7 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_7;
     rec_ide.foglio             := a_rec_ide_orig.foglio_7;
     rec_ide.numero             := a_rec_ide_orig.numero_7;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_7;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_7;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_7;
  elsif
     a_progr_iden = 8 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_8;
     rec_ide.foglio             := a_rec_ide_orig.foglio_8;
     rec_ide.numero             := a_rec_ide_orig.numero_8;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_8;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_8;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_8;
  elsif
     a_progr_iden = 9 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_9;
     rec_ide.foglio             := a_rec_ide_orig.foglio_9;
     rec_ide.numero             := a_rec_ide_orig.numero_9;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_9;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_9;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_9;
  elsif
     a_progr_iden = 10 then
     rec_ide.sezione            := a_rec_ide_orig.sezione_10;
     rec_ide.foglio             := a_rec_ide_orig.foglio_10;
     rec_ide.numero             := a_rec_ide_orig.numero_10;
     rec_ide.denominatore       := a_rec_ide_orig.denominatore_10;
     rec_ide.subalterno         := a_rec_ide_orig.subalterno_10;
     rec_ide.edificialita       := a_rec_ide_orig.edificialita_10;
  end if;
  -- Si controlla se l'identificativo esiste gia'
  begin
    select 1
      into p_esiste
      from cc_identificativi iden
     where iden.codice_amm              = rec_ide.codice_amm
       and nvl(iden.sezione_amm,'*')    = nvl(rec_ide.sezione_amm,'*')
       and iden.id_immobile             = rec_ide.id_immobile
       and iden.tipo_immobile           = rec_ide.tipo_immobile
       and iden.progressivo             = rec_ide.progressivo
       and iden.tipo_record             = rec_ide.tipo_record
       and iden.progr_identificativo    = rec_ide.progr_identificativo
       and nvl(iden.sezione,'*')        = nvl(rec_ide.sezione,'*')
       and nvl(iden.foglio,'*')         = nvl(rec_ide.foglio,'*')
       and nvl(iden.numero,'*')         = nvl(rec_ide.numero,'*')
       and nvl(iden.denominatore,-1)    = nvl(rec_ide.denominatore,-1)
       and nvl(iden.subalterno,'*')     = nvl(rec_ide.subalterno,'*')
       and nvl(iden.edificialita,'*')   = nvl(rec_ide.edificialita,'*');
  exception
    when no_data_found then
      p_esiste := 0;
    when too_many_rows then
      p_errore := 'Esistono piu'' identificativi uguali - Id: '||rec_ide.id_immobile
               || '/' ||rec_ide.progressivo;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_IDENTIFICATIVI ('
               ||rec_ide.id_immobile||'/'||rec_ide.progressivo
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
  if p_esiste = 0 then
     begin
       insert into cc_identificativi
       values rec_ide;
     exception
       when others then
         p_errore := substr('Ins. CC_IDENTIFICATIVI ('
                  ||rec_ide.id_immobile||'/'
                  ||rec_ide.progressivo||'/'
                  ||rec_ide.progr_identificativo
                  ||') - '
                  || sqlerrm,1,2000);
         raise errore;
     end;
  end if;
end INSERT_CC_IDENTIFICATIVI;
-------------------------------------------------------------------------------
procedure INSERT_CC_INDIRIZZI
( a_rec_ind_orig           t_rec_ind_orig --cc_indirizzi_orig%rowtype
, a_riga                   varchar2
, a_progr_ind              number
) is
/******************************************************************************
 NOME:        INSERT_CC_INDIRIZZI
 DESCRIZIONE: Inserimento record tabella CC_INDIRIZZI (nuova versione)
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  rec_ind                  cc_indirizzi%rowtype;
begin
  rec_ind                       := null;
  rec_ind.codice_amm            := a_rec_ind_orig.codice_amministrativo;
  rec_ind.sezione_amm           := a_rec_ind_orig.sezione;
  rec_ind.id_immobile           := a_rec_ind_orig.id_immobile;
  rec_ind.tipo_immobile         := a_rec_ind_orig.tipo_immobile;
  rec_ind.progressivo           := a_rec_ind_orig.progressivo;
  rec_ind.tipo_record           := a_rec_ind_orig.tipo_record;
  rec_ind.progr_indirizzo       := (p_conta_indi * 10) + a_progr_ind;
  rec_ind.documento_id          := p_documento_id;
  rec_ind.utente                := p_utente;
  rec_ind.data_variazione       := trunc(sysdate);
  if a_progr_ind = 1 then
     rec_ind.toponimo   := a_rec_ind_orig.toponimo_1;
     rec_ind.indirizzo  := a_rec_ind_orig.indirizzo_1;
     rec_ind.civico1    := a_rec_ind_orig.civico1_1;
     rec_ind.civico2    := a_rec_ind_orig.civico2_1;
     rec_ind.civico3    := a_rec_ind_orig.civico3_1;
     rec_ind.cod_strada := a_rec_ind_orig.cod_strada_1;
  elsif
     a_progr_ind = 2 then
     rec_ind.toponimo   := a_rec_ind_orig.toponimo_2;
     rec_ind.indirizzo  := a_rec_ind_orig.indirizzo_2;
     rec_ind.civico1    := a_rec_ind_orig.civico1_2;
     rec_ind.civico2    := a_rec_ind_orig.civico2_2;
     rec_ind.civico3    := a_rec_ind_orig.civico3_2;
     rec_ind.cod_strada := a_rec_ind_orig.cod_strada_2;
  elsif
     a_progr_ind = 3 then
     rec_ind.toponimo   := a_rec_ind_orig.toponimo_3;
     rec_ind.indirizzo  := a_rec_ind_orig.indirizzo_3;
     rec_ind.civico1    := a_rec_ind_orig.civico1_3;
     rec_ind.civico2    := a_rec_ind_orig.civico2_3;
     rec_ind.civico3    := a_rec_ind_orig.civico3_3;
     rec_ind.cod_strada := a_rec_ind_orig.cod_strada_3;
  elsif
     a_progr_ind = 4 then
     rec_ind.toponimo   := a_rec_ind_orig.toponimo_4;
     rec_ind.indirizzo  := a_rec_ind_orig.indirizzo_4;
     rec_ind.civico1    := a_rec_ind_orig.civico1_4;
     rec_ind.civico2    := a_rec_ind_orig.civico2_4;
     rec_ind.civico3    := a_rec_ind_orig.civico3_4;
     rec_ind.cod_strada := a_rec_ind_orig.cod_strada_4;
  end if;
-- Si controlla che l'indirizzo non esista
  begin
    select 1
      into p_esiste
      from cc_indirizzi ccin
     where ccin.codice_amm            = rec_ind.codice_amm
       and nvl(ccin.sezione_amm,'*')  = nvl(rec_ind.sezione_amm,'*')
       and ccin.id_immobile           = rec_ind.id_immobile
       and ccin.tipo_immobile         = rec_ind.tipo_immobile
       and ccin.progressivo           = rec_ind.progressivo
       and ccin.tipo_record           = rec_ind.tipo_record
       and ccin.progr_indirizzo       = rec_ind.progr_indirizzo
       and nvl(ccin.toponimo,-1)      = nvl(rec_ind.toponimo,-1)
       and nvl(ccin.indirizzo,'*')    = nvl(rec_ind.indirizzo,'*')
       and nvl(ccin.civico1,'*')      = nvl(rec_ind.civico1,'*')
       and nvl(ccin.civico2,'*')      = nvl(rec_ind.civico2,'*')
       and nvl(ccin.civico3,'*')      = nvl(rec_ind.civico3,'*')
       and nvl(ccin.cod_strada,-1)    = nvl(rec_ind.cod_strada,-1);
  exception
    when no_data_found then
      p_esiste := 0;
    when too_many_rows then
      p_errore := 'Esistono piu'' indirizzi uguali - Id: '||rec_ind.id_immobile
               || '/' ||rec_ind.progressivo;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_INDIRIZZI ('
               ||rec_ind.id_immobile||'/'||rec_ind.progressivo
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
  if p_esiste = 0 then
     begin
       insert into cc_indirizzi
       values rec_ind;
     exception
       when others then
         p_errore := substr('Ins. CC_INDIRIZZI ('
                  ||rec_ind.id_immobile||'/'
                  ||rec_ind.progressivo||'/'
                  ||rec_ind.progr_indirizzo
                  ||') - '
                  || sqlerrm,1,2000);
         raise errore;
     end;
  end if;
end INSERT_CC_INDIRIZZI;
-------------------------------------------------------------------------------
function F_ISNULL_PERSONA_FISICA
( a_rec_sog                cc_soggetti%rowtype
) return number is
/******************************************************************************
 NOME:        F_ISNULL_PERSONA_FISICA
 DESCRIZIONE: Controlla che ci sia almeno un valore valido nella riga
              di un soggetto di tipo persona fisica
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_sog.codice_amm is not null
  or a_rec_sog.sezione_amm is not null
  or a_rec_sog.id_soggetto is not null
  or a_rec_sog.tipo_soggetto is not null
  or a_rec_sog.cognome is not null
  or a_rec_sog.nome is not null
  or a_rec_sog.sesso is not null
  or a_rec_sog.data_nascita is not null
  or a_rec_sog.luogo_nascita is not null
  or a_rec_sog.codice_fiscale is not null
  or a_rec_sog.indicazioni_supplementari is not null then
     w_result := 1;
  end if;
--
  return w_result;
end F_ISNULL_PERSONA_FISICA;
-------------------------------------------------------------------------------
function F_ISNULL_PERSONA_GIURIDICA
( a_rec_sog                cc_soggetti%rowtype
) return number is
/******************************************************************************
 NOME:        F_ISNULL_PERSONA_GIURIDICA
 DESCRIZIONE: Controlla che ci sia almeno un valore valorizzato nella riga
              di un soggetto di tipo persona giuridica
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_sog.codice_amm_2 is not null
  or a_rec_sog.sezione_amm_2 is not null
  or a_rec_sog.id_soggetto_2 is not null
  or a_rec_sog.tipo_soggetto_2 is not null
  or a_rec_sog.denominazione is not null
  or a_rec_sog.sede is not null
  or a_rec_sog.codice_fiscale_2 is not null then
     w_result := 1;
  end if;
--
  return w_result;
end F_ISNULL_PERSONA_GIURIDICA;
-------------------------------------------------------------------------------
function F_ISNULL_FABBRICATO
( a_rec_fab                cc_fabbricati%rowtype
) return number is
/******************************************************************************
 NOME:        F_ISNULL_FABBRICATO
 DESCRIZIONE: Controlla che ci sia almeno un campo valorizzato nella riga
              di un fabbricato
              File .FAB e tipo record 1
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_fab.codice_amm is not null
  or a_rec_fab.sezione_amm is not null
  or a_rec_fab.id_immobile is not null
  or a_rec_fab.tipo_immobile is not null
  or a_rec_fab.progressivo is not null
  or a_rec_fab.tipo_record is not null
  or a_rec_fab.zona is not null
  or a_rec_fab.categoria is not null
  or a_rec_fab.classe is not null
  or a_rec_fab.consistenza is not null
  or a_rec_fab.superficie is not null
  or a_rec_fab.rendita_lire is not null
  or a_rec_fab.rendita_euro is not null
  or a_rec_fab.lotto is not null
  or a_rec_fab.edificio is not null
  or a_rec_fab.scala is not null
  or a_rec_fab.interno_1 is not null
  or a_rec_fab.interno_2 is not null
  or a_rec_fab.piano_1 is not null
  or a_rec_fab.piano_2 is not null
  or a_rec_fab.piano_3 is not null
  or a_rec_fab.piano_4 is not null
  or a_rec_fab.data_efficacia is not null
  or a_rec_fab.data_registrazione_atti is not null
  or a_rec_fab.tipo_nota is not null
  or a_rec_fab.numero_nota is not null
  or a_rec_fab.progressivo_nota is not null
  or a_rec_fab.anno_nota is not null
  or a_rec_fab.data_efficacia_2 is not null
  or a_rec_fab.data_registrazione_atti_2 is not null
  or a_rec_fab.tipo_nota_2 is not null
  or a_rec_fab.numero_nota_2 is not null
  or a_rec_fab.progressivo_nota_2 is not null
  or a_rec_fab.anno_nota_2 is not null
  or a_rec_fab.partita is not null
  or a_rec_fab.annotazione is not null
  or a_rec_fab.id_mutazione_iniziale is not null
  or a_rec_fab.id_mutazione_finale is not null
  or a_rec_fab.protocollo_notifica is not null
  or a_rec_fab.data_notifica is not null
  or a_rec_fab.cod_causale_atto_generante is not null
  or a_rec_fab.des_atto_generante is not null
  or a_rec_fab.cod_causale_atto_conclusivo is not null
  or a_rec_fab.des_atto_conclusivo is not null
  or a_rec_fab.flag_classamento is not null then
     w_result := 1;
  end if;
--
  return w_result;
end F_ISNULL_FABBRICATO;
-------------------------------------------------------------------------------
function F_ISNULL_IDENTIFICATIVO
( a_rec_ide_orig            t_rec_ide_orig --cc_identificativi_orig%rowtype
, a_progr_iden              number
) return number is
/******************************************************************************
 NOME:        F_ISNULL_IDENTIFICATIVO
 DESCRIZIONE: Controlla che ci sia almeno un campo valorizzato nella riga
              degli identificativi di un fabbricato
              File .FAB e tipo record 2
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_ide_orig.codice_amministrativo is not null
  --or a_rec_ide_orig.sezione is not null
  and a_rec_ide_orig.id_immobile is not null
  and a_rec_ide_orig.tipo_immobile is not null
  and a_rec_ide_orig.progressivo is not null
  and a_rec_ide_orig.tipi_record is not null then
     if a_progr_iden = 0 and
       (a_rec_ide_orig.sezione_1 is not null or
        a_rec_ide_orig.foglio_1 is not null or
        a_rec_ide_orig.numero_1 is not null or
        a_rec_ide_orig.denominatore_1 is not null or
        a_rec_ide_orig.subalterno_1 is not null or
        a_rec_ide_orig.edificialita_1 is not null or
        a_rec_ide_orig.sezione_2 is not null or
        a_rec_ide_orig.foglio_2 is not null or
        a_rec_ide_orig.numero_2 is not null or
        a_rec_ide_orig.denominatore_2 is not null or
        a_rec_ide_orig.subalterno_2 is not null or
        a_rec_ide_orig.edificialita_2 is not null or
        a_rec_ide_orig.sezione_3 is not null or
        a_rec_ide_orig.foglio_3 is not null or
        a_rec_ide_orig.numero_3 is not null or
        a_rec_ide_orig.denominatore_3 is not null or
        a_rec_ide_orig.subalterno_3 is not null or
        a_rec_ide_orig.edificialita_3 is not null or
        a_rec_ide_orig.sezione_4 is not null or
        a_rec_ide_orig.foglio_4 is not null or
        a_rec_ide_orig.numero_4 is not null or
        a_rec_ide_orig.denominatore_4 is not null or
        a_rec_ide_orig.subalterno_4 is not null or
        a_rec_ide_orig.edificialita_4 is not null or
        a_rec_ide_orig.sezione_5 is not null or
        a_rec_ide_orig.foglio_5 is not null or
        a_rec_ide_orig.numero_5 is not null or
        a_rec_ide_orig.denominatore_5 is not null or
        a_rec_ide_orig.subalterno_5 is not null or
        a_rec_ide_orig.edificialita_5 is not null or
        a_rec_ide_orig.sezione_6 is not null or
        a_rec_ide_orig.foglio_6 is not null or
        a_rec_ide_orig.numero_6 is not null or
        a_rec_ide_orig.denominatore_6 is not null or
        a_rec_ide_orig.subalterno_6 is not null or
        a_rec_ide_orig.edificialita_6 is not null or
        a_rec_ide_orig.sezione_7 is not null or
        a_rec_ide_orig.foglio_7 is not null or
        a_rec_ide_orig.numero_7 is not null or
        a_rec_ide_orig.denominatore_7 is not null or
        a_rec_ide_orig.subalterno_7 is not null or
        a_rec_ide_orig.edificialita_7 is not null or
        a_rec_ide_orig.sezione_8 is not null or
        a_rec_ide_orig.foglio_8 is not null or
        a_rec_ide_orig.numero_8 is not null or
        a_rec_ide_orig.denominatore_8 is not null or
        a_rec_ide_orig.subalterno_8 is not null or
        a_rec_ide_orig.edificialita_8 is not null or
        a_rec_ide_orig.sezione_9 is not null or
        a_rec_ide_orig.foglio_9 is not null or
        a_rec_ide_orig.numero_9 is not null or
        a_rec_ide_orig.denominatore_9 is not null or
        a_rec_ide_orig.subalterno_9 is not null or
        a_rec_ide_orig.edificialita_9 is not null or
        a_rec_ide_orig.sezione_10 is not null or
        a_rec_ide_orig.foglio_10 is not null or
        a_rec_ide_orig.numero_10 is not null or
        a_rec_ide_orig.denominatore_10 is not null or
        a_rec_ide_orig.subalterno_10 is not null or
        a_rec_ide_orig.edificialita_10 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 1 and
       (a_rec_ide_orig.sezione_1 is not null or
        a_rec_ide_orig.foglio_1 is not null or
        a_rec_ide_orig.numero_1 is not null or
        a_rec_ide_orig.denominatore_1 is not null or
        a_rec_ide_orig.subalterno_1 is not null or
        a_rec_ide_orig.edificialita_1 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 2 and
       (a_rec_ide_orig.sezione_2 is not null or
        a_rec_ide_orig.foglio_2 is not null or
        a_rec_ide_orig.numero_2 is not null or
        a_rec_ide_orig.denominatore_2 is not null or
        a_rec_ide_orig.subalterno_2 is not null or
        a_rec_ide_orig.edificialita_2 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 3 and
       (a_rec_ide_orig.sezione_3 is not null or
        a_rec_ide_orig.foglio_3 is not null or
        a_rec_ide_orig.numero_3 is not null or
        a_rec_ide_orig.denominatore_3 is not null or
        a_rec_ide_orig.subalterno_3 is not null or
        a_rec_ide_orig.edificialita_3 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 4 and
       (a_rec_ide_orig.sezione_4 is not null or
        a_rec_ide_orig.foglio_4 is not null or
        a_rec_ide_orig.numero_4 is not null or
        a_rec_ide_orig.denominatore_4 is not null or
        a_rec_ide_orig.subalterno_4 is not null or
        a_rec_ide_orig.edificialita_4 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 5 and
       (a_rec_ide_orig.sezione_5 is not null or
        a_rec_ide_orig.foglio_5 is not null or
        a_rec_ide_orig.numero_5 is not null or
        a_rec_ide_orig.denominatore_5 is not null or
        a_rec_ide_orig.subalterno_5 is not null or
        a_rec_ide_orig.edificialita_5 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 6 and
       (a_rec_ide_orig.sezione_6 is not null or
        a_rec_ide_orig.foglio_6 is not null or
        a_rec_ide_orig.numero_6 is not null or
        a_rec_ide_orig.denominatore_6 is not null or
        a_rec_ide_orig.subalterno_6 is not null or
        a_rec_ide_orig.edificialita_6 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 7 and
       (a_rec_ide_orig.sezione_7 is not null or
        a_rec_ide_orig.foglio_7 is not null or
        a_rec_ide_orig.numero_7 is not null or
        a_rec_ide_orig.denominatore_7 is not null or
        a_rec_ide_orig.subalterno_7 is not null or
        a_rec_ide_orig.edificialita_7 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 8 and
       (a_rec_ide_orig.sezione_8 is not null or
        a_rec_ide_orig.foglio_8 is not null or
        a_rec_ide_orig.numero_8 is not null or
        a_rec_ide_orig.denominatore_8 is not null or
        a_rec_ide_orig.subalterno_8 is not null or
        a_rec_ide_orig.edificialita_8 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 9 and
       (a_rec_ide_orig.sezione_9 is not null or
        a_rec_ide_orig.foglio_9 is not null or
        a_rec_ide_orig.numero_9 is not null or
        a_rec_ide_orig.denominatore_9 is not null or
        a_rec_ide_orig.subalterno_9 is not null or
        a_rec_ide_orig.edificialita_9 is not null) then
        w_result := 1;
     elsif
        a_progr_iden = 10 and
       (a_rec_ide_orig.sezione_10 is not null or
        a_rec_ide_orig.foglio_10 is not null or
        a_rec_ide_orig.numero_10 is not null or
        a_rec_ide_orig.denominatore_10 is not null or
        a_rec_ide_orig.subalterno_10 is not null or
        a_rec_ide_orig.edificialita_10 is not null) then
        w_result := 1;
     end if;
  end if;
--
  return w_result;
end F_ISNULL_IDENTIFICATIVO;
-------------------------------------------------------------------------------
function F_ISNULL_INDIRIZZO
( a_rec_ind_orig           t_rec_ind_orig --cc_indirizzi_orig%rowtype
, a_progr_ind              number
) return number is
/******************************************************************************
 NOME:        F_ISNULL_INDIRIZZO
 DESCRIZIONE: Controlla che ci sia almeno un campo valorizzato nella riga
              degli indirizzi di un fabbricato
              File .FAB e tipo record 3
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_ind_orig.codice_amministrativo is not null
  --and a_rec_ind_orig.sezione is not null
  and a_rec_ind_orig.id_immobile is not null
  and a_rec_ind_orig.tipo_immobile is not null
  and a_rec_ind_orig.progressivo is not null
  and a_rec_ind_orig.tipo_record is not null then
     if a_progr_ind = 0 and
       (a_rec_ind_orig.toponimo_1 is not null or
        a_rec_ind_orig.indirizzo_1 is not null or
        a_rec_ind_orig.civico1_1 is not null or
        a_rec_ind_orig.civico2_1 is not null or
        a_rec_ind_orig.civico3_1 is not null or
        a_rec_ind_orig.cod_strada_1 is not null or
        a_rec_ind_orig.toponimo_2 is not null or
        a_rec_ind_orig.indirizzo_2 is not null or
        a_rec_ind_orig.civico1_2 is not null or
        a_rec_ind_orig.civico2_2 is not null or
        a_rec_ind_orig.civico3_2 is not null or
        a_rec_ind_orig.cod_strada_2 is not null or
        a_rec_ind_orig.toponimo_3 is not null or
        a_rec_ind_orig.indirizzo_3 is not null or
        a_rec_ind_orig.civico1_3 is not null or
        a_rec_ind_orig.civico2_3 is not null or
        a_rec_ind_orig.civico3_3 is not null or
        a_rec_ind_orig.cod_strada_3 is not null or
        a_rec_ind_orig.toponimo_4 is not null or
        a_rec_ind_orig.indirizzo_4 is not null or
        a_rec_ind_orig.civico1_4 is not null or
        a_rec_ind_orig.civico2_4 is not null or
        a_rec_ind_orig.civico3_4 is not null or
        a_rec_ind_orig.cod_strada_4 is not null) then
        w_result := 1;
     elsif
        a_progr_ind = 1 and
       (a_rec_ind_orig.toponimo_1 is not null or
        a_rec_ind_orig.indirizzo_1 is not null or
        a_rec_ind_orig.civico1_1 is not null or
        a_rec_ind_orig.civico2_1 is not null or
        a_rec_ind_orig.civico3_1 is not null or
        a_rec_ind_orig.cod_strada_1 is not null) then
        w_result := 1;
     elsif
        a_progr_ind = 2 and
       (a_rec_ind_orig.toponimo_2 is not null or
        a_rec_ind_orig.indirizzo_2 is not null or
        a_rec_ind_orig.civico1_2 is not null or
        a_rec_ind_orig.civico2_2 is not null or
        a_rec_ind_orig.civico3_2 is not null or
        a_rec_ind_orig.cod_strada_2 is not null) then
        w_result := 1;
     elsif a_progr_ind = 3 and
       (a_rec_ind_orig.toponimo_3 is not null or
        a_rec_ind_orig.indirizzo_3 is not null or
        a_rec_ind_orig.civico1_3 is not null or
        a_rec_ind_orig.civico2_3 is not null or
        a_rec_ind_orig.civico3_3 is not null or
        a_rec_ind_orig.cod_strada_3 is not null) then
        w_result := 1;
     elsif a_progr_ind = 4 and
       (a_rec_ind_orig.toponimo_4 is not null or
        a_rec_ind_orig.indirizzo_4 is not null or
        a_rec_ind_orig.civico1_4 is not null or
        a_rec_ind_orig.civico2_4 is not null or
        a_rec_ind_orig.civico3_4 is not null or
        a_rec_ind_orig.cod_strada_4 is not null) then
        w_result := 1;
     end if;
  end if;
--
  return w_result;
end F_ISNULL_INDIRIZZO;
-------------------------------------------------------------------------------
function F_ISNULL_TERRENO
( a_rec_ter                cc_particelle%rowtype
) return number is
/******************************************************************************
 NOME:        F_ISNULL_TERRENO
 DESCRIZIONE: Controlla che ci sia almeno un campo valorizzato nella riga
              di un terreno
              File .TER e tipo record 1
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_ter.codice_amm is not null
  or a_rec_ter.sezione_amm is not null
  or a_rec_ter.id_immobile is not null
  or a_rec_ter.tipo_immobile is not null
  or a_rec_ter.progressivo is not null
  or a_rec_ter.tipo_record is not null
  or a_rec_ter.foglio is not null
  or a_rec_ter.numero is not null
  or a_rec_ter.denominatore is not null
  or a_rec_ter.subalterno is not null
  or a_rec_ter.edificialita is not null
  or a_rec_ter.qualita is not null
  or a_rec_ter.classe is not null
  or a_rec_ter.ettari is not null
  or a_rec_ter.are is not null
  or a_rec_ter.centiare is not null
  or a_rec_ter.flag_reddito is not null
  or a_rec_ter.flag_porzione is not null
  or a_rec_ter.flag_deduzioni is not null
  or a_rec_ter.reddito_dominicale_lire is not null
  or a_rec_ter.reddito_agrario_lire is not null
  or a_rec_ter.reddito_dominicale_euro is not null
  or a_rec_ter.reddito_agrario_euro is not null
  or a_rec_ter.data_efficacia is not null
  or a_rec_ter.data_registrazione_atti is not null
  or a_rec_ter.tipo_nota is not null
  or a_rec_ter.numero_nota is not null
  or a_rec_ter.progressivo_nota is not null
  or a_rec_ter.anno_nota is not null
  or a_rec_ter.data_efficacia_1 is not null
  or a_rec_ter.data_registrazione_atti_1 is not null
  or a_rec_ter.tipo_nota_1 is not null
  or a_rec_ter.numero_nota_1 is not null
  or a_rec_ter.progressivo_nota_1 is not null
  or a_rec_ter.anno_nota_1 is not null
  or a_rec_ter.partita is not null
  or a_rec_ter.annotazione is not null
  or a_rec_ter.id_mutazione_iniziale is not null
  or a_rec_ter.id_mutazione_finale is not null
  or a_rec_ter.cod_causale_atto_generante is not null
  or a_rec_ter.des_atto_generante is not null
  or a_rec_ter.cod_causale_atto_conclusivo is not null
  or a_rec_ter.des_atto_conclusivo is not null then
     w_result := 1;
  end if;
--
  return w_result;
end F_ISNULL_TERRENO;
-------------------------------------------------------------------------------
function F_ISNULL_TITOLARITA
( a_rec_tit                cc_titolarita%rowtype
) return number is
/******************************************************************************
 NOME:        F_ISNULL_TITOLARITA
 DESCRIZIONE: Controlla che ci sia almeno un campo valorizzato nella riga
              di una titolarita
              File .TIT, tipo record unico
 RITORNA:     0 - Nessun campo valorizzato
              1 - Almeno un campo valorizzato
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number := 0;
begin
  if a_rec_tit.codice_amm is not null
  or a_rec_tit.sezione_amm is not null
  or a_rec_tit.id_soggetto is not null
  or a_rec_tit.tipo_soggetto is not null
  or a_rec_tit.id_immobile is not null
  or a_rec_tit.tipo_immobile is not null
  or a_rec_tit.codice_diritto is not null
  or a_rec_tit.titolo_non_codificato is not null
  or a_rec_tit.quota_numeratore is not null
  or a_rec_tit.quota_denominatore is not null
  or a_rec_tit.regime is not null
  or a_rec_tit.soggetto_riferimento is not null
  or a_rec_tit.data_validita is not null
  or a_rec_tit.tipo_nota is not null
  or a_rec_tit.numero_nota is not null
  or a_rec_tit.progressivo_nota is not null
  or a_rec_tit.anno_nota is not null
  or a_rec_tit.data_registrazione_atti is not null
  or a_rec_tit.partita is not null
  or a_rec_tit.data_validita_2 is not null
  or a_rec_tit.tipo_nota_2 is not null
  or a_rec_tit.numero_nota_2 is not null
  or a_rec_tit.progressivo_nota_2 is not null
  or a_rec_tit.anno_nota_2 is not null
  or a_rec_tit.data_registrazione_atti_2 is not null
  or a_rec_tit.id_mutazione_iniziale is not null
  or a_rec_tit.id_mutazione_finale is not null
  or a_rec_tit.id_titolarita is not null
  or a_rec_tit.cod_causale_atto_generante is not null
  or a_rec_tit.des_atto_generante is not null
  or a_rec_tit.cod_causale_atto_conclusivo is not null
  or a_rec_tit.des_atto_conclusivo is not null then
     w_result := 1;
  end if;
--
  return w_result;
end F_ISNULL_TITOLARITA;
-------------------------------------------------------------------------------
function F_ESISTE_FABBRICATO
( a_riga                   varchar2
, a_rec_fab                cc_fabbricati%rowtype
) return number is
/******************************************************************************
 NOME:        F_ESISTE_FABBRICATO
 DESCRIZIONE: Verifica se il fabbricato esiste gia' nella tabella CC_FABBRICATI
              File .FAB e tipo record 1
 RITORNA:     0 - Il fabbricato non esiste
              1 - Il fabbricato esiste
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number;
begin
  -- Si controlla se il fabbricato esiste gia
  begin
    select 1
      into w_result
      from cc_fabbricati fabb
     where fabb.codice_amm = a_rec_fab.codice_amm
       and nvl(fabb.sezione_amm,'*') = nvl(a_rec_fab.sezione_amm,'*')
       and fabb.id_immobile = a_rec_fab.id_immobile
       and fabb.tipo_immobile  = a_rec_fab.tipo_immobile
       and fabb.progressivo  = a_rec_fab.progressivo
       and nvl(fabb.tipo_record,0) = nvl(a_rec_fab.tipo_record,0)
       and nvl(fabb.zona,'*') = nvl(a_rec_fab.zona,'*')
       and nvl(fabb.categoria,'*') = nvl(a_rec_fab.categoria,'*')
       and nvl(fabb.classe,'*') = nvl(a_rec_fab.classe,'*')
       and nvl(fabb.consistenza,0) = nvl(a_rec_fab.consistenza,0)
       and nvl(fabb.superficie,0) = nvl(a_rec_fab.superficie,0)
       and nvl(fabb.rendita_lire,0) = nvl(a_rec_fab.rendita_lire,0)
       and nvl(fabb.rendita_euro,0) = nvl(a_rec_fab.rendita_euro,0)
       and nvl(fabb.lotto,'*') = nvl(a_rec_fab.lotto,'*')
       and nvl(fabb.edificio,'*')  = nvl(a_rec_fab.edificio,'*')
       and nvl(fabb.scala,'*')  = nvl(a_rec_fab.scala,'*')
       and nvl(fabb.interno_1,'*')  = nvl(a_rec_fab.interno_1,'*')
       and nvl(fabb.interno_2,'*')  = nvl(a_rec_fab.interno_2,'*')
       and nvl(fabb.piano_1,'*') = nvl(a_rec_fab.piano_1,'*')
       and nvl(fabb.piano_2,'*') = nvl(a_rec_fab.piano_2,'*')
       and nvl(fabb.piano_3,'*') = nvl(a_rec_fab.piano_3,'*')
       and nvl(fabb.piano_4,'*') = nvl(a_rec_fab.piano_4,'*')
       and nvl(fabb.data_efficacia,'*') = nvl(a_rec_fab.data_efficacia,'*')
       and nvl(fabb.data_registrazione_atti,'*') = nvl(a_rec_fab.data_registrazione_atti,'*')
       and nvl(fabb.tipo_nota,'*') = nvl(a_rec_fab.tipo_nota,'*')
       and nvl(fabb.numero_nota,'*') = nvl(a_rec_fab.numero_nota,'*')
       and nvl(fabb.progressivo_nota,'*') = nvl(a_rec_fab.progressivo_nota,'*')
       and nvl(fabb.anno_nota,0)  = nvl(a_rec_fab.anno_nota,0)
       and nvl(fabb.data_efficacia_2,'*') = nvl(a_rec_fab.data_efficacia_2,'*')
       and nvl(fabb.data_registrazione_atti_2,'*') = nvl(a_rec_fab.data_registrazione_atti_2,'*')
       and nvl(fabb.tipo_nota_2,'*') = nvl(a_rec_fab.tipo_nota_2,'*')
       and nvl(fabb.numero_nota_2,'*') = nvl(a_rec_fab.numero_nota_2,'*')
       and nvl(fabb.progressivo_nota_2,'*') = nvl(a_rec_fab.progressivo_nota_2,'*')
       and nvl(fabb.anno_nota_2,0) = nvl(a_rec_fab.anno_nota_2,0)
       and nvl(fabb.partita,'*') = nvl(a_rec_fab.partita,'*')
       and nvl(fabb.annotazione,'*') = nvl(a_rec_fab.annotazione,'*')
       and nvl(fabb.id_mutazione_iniziale,0) = nvl(a_rec_fab.id_mutazione_iniziale,0)
       and nvl(fabb.id_mutazione_finale,0) = nvl(a_rec_fab.id_mutazione_finale,0)
       and nvl(fabb.protocollo_notifica,'*') = nvl(a_rec_fab.protocollo_notifica,'*')
       and nvl(fabb.data_notifica,'*') = nvl(a_rec_fab.data_notifica,'*')
       and nvl(fabb.cod_causale_atto_generante,'*') = nvl(a_rec_fab.cod_causale_atto_generante,'*')
       and nvl(fabb.des_atto_generante,'*') = nvl(a_rec_fab.des_atto_generante,'*')
       and nvl(fabb.cod_causale_atto_conclusivo,'*') = nvl(a_rec_fab.cod_causale_atto_conclusivo,'*')
       and nvl(fabb.des_atto_conclusivo,'*') = nvl(a_rec_fab.des_atto_conclusivo,'*')
       and nvl(fabb.flag_classamento,'*') = nvl(a_rec_fab.flag_classamento,'*');
  exception
    when no_data_found then
      w_result := 0;
    when too_many_rows then
      w_result := 2;
      p_errore := 'Esistono piu'' fabbricati uguali - Id: '||a_rec_fab.id_immobile
               || '/' ||a_rec_fab.progressivo;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_FABBRICATI ('
               ||a_rec_fab.id_immobile||'/'||a_rec_fab.progressivo
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
--
  return w_result;
end F_ESISTE_FABBRICATO;
-------------------------------------------------------------------------------
/*function F_ESISTE_IDENTIFICATIVO
( a_riga                   varchar2
, a_rec_ide_orig           cc_identificativi_orig%rowtype
, a_progr_ide              number
) return number is
/******************************************************************************
 NOME:        F_ESISTE_IDENTIFICATIVO
 DESCRIZIONE: Verifica se gli identificativi del fabbricato esistono gia'
              nella tabella CC_IDENTIFICATIVI
              File .FAB e tipo record 2
 RITORNA:     0 - La riga di identificativi non esiste
              1 - La riga di identificativi fabbricato esiste
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   22/01/2022  VD      NON PIU' USATO
 000   13/07/2020  VD      Prima emissione.
******************************************************************************
  w_result                 number;
begin
  -- Si controlla se l'identificativo esiste gia'
  begin
    select 1
      into w_result
      from cc_identificativi_orig iden
     where iden.codice_amministrativo   = a_rec_ide_orig.codice_amministrativo
       and nvl(iden.sezione,'*')        = nvl(a_rec_ide_orig.sezione,'*')
       and iden.id_immobile             = a_rec_ide_orig.id_immobile
       and iden.tipo_immobile           = a_rec_ide_orig.tipo_immobile
       and iden.progressivo             = a_rec_ide_orig.progressivo
       and nvl(iden.tipi_record,-1)     = nvl(a_rec_ide_orig.tipi_record,-1)
       and nvl(iden.sezione_1,'*')      = nvl(a_rec_ide_orig.sezione_1,'*')
       and nvl(iden.foglio_1,'*')       = nvl(a_rec_ide_orig.foglio_1,'*')
       and nvl(iden.numero_1,'*')       = nvl(a_rec_ide_orig.numero_1,'*')
       and nvl(iden.denominatore_1,-1)  = nvl(a_rec_ide_orig.denominatore_1,-1)
       and nvl(iden.subalterno_1,'*')   = nvl(a_rec_ide_orig.subalterno_1,'*')
       and nvl(iden.edificialita_1,'*') = nvl(a_rec_ide_orig.edificialita_1,'*')
       and nvl(iden.sezione_2,'*')      = nvl(a_rec_ide_orig.sezione_2,'*')
       and nvl(iden.foglio_2,'*')       = nvl(a_rec_ide_orig.foglio_2,'*')
       and nvl(iden.numero_2,'*')       = nvl(a_rec_ide_orig.numero_2,'*')
       and nvl(iden.denominatore_2,-1)  = nvl(a_rec_ide_orig.denominatore_2,-1)
       and nvl(iden.subalterno_2,'*')   = nvl(a_rec_ide_orig.subalterno_2,'*')
       and nvl(iden.edificialita_2,'*') = nvl(a_rec_ide_orig.edificialita_2,'*')
       and nvl(iden.sezione_3,'*')      = nvl(a_rec_ide_orig.sezione_3,'*')
       and nvl(iden.foglio_3,'*')       = nvl(a_rec_ide_orig.foglio_3,'*')
       and nvl(iden.numero_3,'*')       = nvl(a_rec_ide_orig.numero_3,'*')
       and nvl(iden.denominatore_3,-1)  = nvl(a_rec_ide_orig.denominatore_3,-1)
       and nvl(iden.subalterno_3,'*')   = nvl(a_rec_ide_orig.subalterno_3,'*')
       and nvl(iden.edificialita_3,'*') = nvl(a_rec_ide_orig.edificialita_3 ,'*')
       and nvl(iden.sezione_4,'*')      = nvl(a_rec_ide_orig.sezione_4,'*')
       and nvl(iden.foglio_4,'*')       = nvl(a_rec_ide_orig.foglio_4,'*')
       and nvl(iden.numero_4,'*')       = nvl(a_rec_ide_orig.numero_4,'*')
       and nvl(iden.denominatore_4,-1)  = nvl(a_rec_ide_orig.denominatore_4,-1)
       and nvl(iden.subalterno_4,'*')   = nvl(a_rec_ide_orig.subalterno_4,'*')
       and nvl(iden.edificialita_4,'*') = nvl(a_rec_ide_orig.edificialita_4,'*')
       and nvl(iden.sezione_5,'*')      = nvl(a_rec_ide_orig.sezione_5,'*')
       and nvl(iden.foglio_5,'*')       = nvl(a_rec_ide_orig.foglio_5,'*')
       and nvl(iden.numero_5,'*')       = nvl(a_rec_ide_orig.numero_5,'*')
       and nvl(iden.denominatore_5,-1)  = nvl(a_rec_ide_orig.denominatore_5,-1)
       and nvl(iden.subalterno_5,'*')   = nvl(a_rec_ide_orig.subalterno_5,'*')
       and nvl(iden.edificialita_5,'*') = nvl(a_rec_ide_orig.edificialita_5,'*')
       and nvl(iden.sezione_6,'*')      = nvl(a_rec_ide_orig.sezione_6,'*')
       and nvl(iden.foglio_6,'*')       = nvl(a_rec_ide_orig.foglio_6,'*')
       and nvl(iden.numero_6,'*')       = nvl(a_rec_ide_orig.numero_6,'*')
       and nvl(iden.denominatore_6,-1)  = nvl(a_rec_ide_orig.denominatore_6,-1)
       and nvl(iden.subalterno_6,'*')   = nvl(a_rec_ide_orig.subalterno_6,'*')
       and nvl(iden.edificialita_6,'*') = nvl(a_rec_ide_orig.edificialita_6,'*')
       and nvl(iden.sezione_7,'*')      = nvl(a_rec_ide_orig.sezione_7,'*')
       and nvl(iden.foglio_7,'*')       = nvl(a_rec_ide_orig.foglio_7,'*')
       and nvl(iden.numero_7,'*')       = nvl(a_rec_ide_orig.numero_7,'*')
       and nvl(iden.denominatore_7,-1)  = nvl(a_rec_ide_orig.denominatore_7,-1)
       and nvl(iden.subalterno_7,'*')   = nvl(a_rec_ide_orig.subalterno_7,'*')
       and nvl(iden.edificialita_7,'*') = nvl(a_rec_ide_orig.edificialita_7,'*')
       and nvl(iden.sezione_8,'*')      = nvl(a_rec_ide_orig.sezione_8,'*')
       and nvl(iden.foglio_8,'*')       = nvl(a_rec_ide_orig.foglio_8,'*')
       and nvl(iden.numero_8,'*')       = nvl(a_rec_ide_orig.numero_8,'*')
       and nvl(iden.denominatore_8,-1)  = nvl(a_rec_ide_orig.denominatore_8,-1)
       and nvl(iden.subalterno_8,'*')   = nvl(a_rec_ide_orig.subalterno_8,'*')
       and nvl(iden.edificialita_8,'*') = nvl(a_rec_ide_orig.edificialita_8,'*')
       and nvl(iden.sezione_9,'*')      = nvl(a_rec_ide_orig.sezione_9,'*')
       and nvl(iden.foglio_9,'*')       = nvl(a_rec_ide_orig.foglio_9,'*')
       and nvl(iden.numero_9,'*')       = nvl(a_rec_ide_orig.numero_9,'*')
       and nvl(iden.denominatore_9,-1)  = nvl(a_rec_ide_orig.denominatore_9,-1)
       and nvl(iden.subalterno_9,'*')   = nvl(a_rec_ide_orig.subalterno_9,'*')
       and nvl(iden.edificialita_9,'*') = nvl(a_rec_ide_orig.edificialita_9,'*')
       and nvl(iden.sezione_10,'*')     = nvl(a_rec_ide_orig.sezione_10,'*')
       and nvl(iden.foglio_10,'*')      = nvl(a_rec_ide_orig.foglio_10,'*')
       and nvl(iden.numero_10,'*')      = nvl(a_rec_ide_orig.numero_10,'*')
       and nvl(iden.denominatore_10,-1) = nvl(a_rec_ide_orig.denominatore_10,-1)
       and nvl(iden.subalterno_10,'*')  = nvl(a_rec_ide_orig.subalterno_10,'*')
       and nvl(iden.edificialita_10,'*')= nvl(a_rec_ide_orig.edificialita_10,'*')
      ;
  exception
    when no_data_found then
      w_result := 0;
    when too_many_rows then
      w_result := 2;
      p_errore := 'Esistono piu'' identificativi uguali - Id: '||a_rec_ide_orig.id_immobile
               || '/' ||a_rec_ide_orig.progressivo;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_IDENTIFICATIVI ('
               ||a_rec_ide_orig.id_immobile||'/'||a_rec_ide_orig.progressivo
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
--
  return w_result;
end F_ESISTE_IDENTIFICATIVO; */
-------------------------------------------------------------------------------
function F_ESISTE_TERRENO
( a_riga                   varchar2
, a_rec_ter                cc_particelle%rowtype
) return number is
/******************************************************************************
 NOME:        F_ESISTE_TERRENO
 DESCRIZIONE: Verifica se il terreno esiste gia' nella tabella CC_PARTICELLE
              File .TER e tipo record 1
 RITORNA:     0 - Il terreno non esiste
              1 - Il terreno esiste
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number;
begin
  -- Si controlla se il terreno esiste gia
  begin
    select 1
      into w_result
      from cc_particelle part
     where part.codice_amm = a_rec_ter.codice_amm
       and nvl(part.sezione_amm,'*') = nvl(a_rec_ter.sezione_amm,'*')
       and part.id_immobile = a_rec_ter.id_immobile
       and part.tipo_immobile = a_rec_ter.tipo_immobile
       and part.progressivo = a_rec_ter.progressivo
       and part.tipo_record = a_rec_ter.tipo_record
       and nvl(part.foglio,'*') = nvl(a_rec_ter.foglio,'*')
       and nvl(part.numero,'*') = nvl(a_rec_ter.numero,'*')
       and nvl(part.denominatore,0) = nvl(a_rec_ter.denominatore,0)
       and nvl(part.subalterno,'*') = nvl(a_rec_ter.subalterno,'*')
       and nvl(part.edificialita,'*') = nvl(a_rec_ter.edificialita,'*')
       and nvl(part.qualita,0) = nvl(a_rec_ter.qualita,0)
       and nvl(part.classe,'*') = nvl(a_rec_ter.classe,'*')
       and nvl(part.ettari,0) = nvl(a_rec_ter.ettari,0)
       and nvl(part.are,0) = nvl(a_rec_ter.are,0)
       and nvl(part.centiare,0) = nvl(a_rec_ter.centiare,0)
       and nvl(part.flag_reddito,'*') = nvl(a_rec_ter.flag_reddito,'*')
       and nvl(part.flag_porzione,'*') = nvl(a_rec_ter.flag_porzione,'*')
       and nvl(part.flag_deduzioni,'*') = nvl(a_rec_ter.flag_deduzioni,'*')
       and nvl(part.reddito_dominicale_lire,0) = nvl(a_rec_ter.reddito_dominicale_lire,0)
       and nvl(part.reddito_agrario_lire,0) = nvl(a_rec_ter.reddito_agrario_lire,0)
       and nvl(part.reddito_dominicale_euro,0) = nvl(a_rec_ter.reddito_dominicale_euro,0)
       and nvl(part.reddito_agrario_euro,0) = nvl(a_rec_ter.reddito_agrario_euro,0)
       and nvl(part.data_efficacia,'*') = nvl(a_rec_ter.data_efficacia,'*')
       and nvl(part.data_registrazione_atti,'*') = nvl(a_rec_ter.data_registrazione_atti,'*')
       and nvl(part.tipo_nota,'*') = nvl(a_rec_ter.tipo_nota,'*')
       and nvl(part.numero_nota,'*') = nvl(a_rec_ter.numero_nota,'*')
       and nvl(part.progressivo_nota,'*') = nvl(a_rec_ter.progressivo_nota,'*')
       and nvl(part.anno_nota,0) = nvl(a_rec_ter.anno_nota,0)
       and nvl(part.data_efficacia_1,'*') = nvl(a_rec_ter.data_efficacia_1,'*')
       and nvl(part.data_registrazione_atti_1,'*') = nvl(a_rec_ter.data_registrazione_atti_1,'*')
       and nvl(part.tipo_nota_1,'*') = nvl(a_rec_ter.tipo_nota_1,'*')
       and nvl(part.numero_nota_1,'*') = nvl(a_rec_ter.numero_nota_1,'*')
       and nvl(part.progressivo_nota_1,'*') = nvl(a_rec_ter.progressivo_nota_1,'*')
       and nvl(part.anno_nota_1,0) = nvl(a_rec_ter.anno_nota_1,0)
       and nvl(part.partita,'*') = nvl(a_rec_ter.partita,'*')
       and nvl(part.annotazione,'*') = nvl(a_rec_ter.annotazione,'*')
       and nvl(part.id_mutazione_iniziale,0) = nvl(a_rec_ter.id_mutazione_iniziale,0)
       and nvl(part.id_mutazione_finale,0) = nvl(a_rec_ter.id_mutazione_finale,0)
       and nvl(part.foglio_ric,'*') = nvl(a_rec_ter.foglio_ric,'*')
       and nvl(part.numero_ric,'*') = nvl(a_rec_ter.numero_ric,'*')
       and nvl(part.subalterno_ric,'*') = nvl(a_rec_ter.subalterno_ric,'*')
       and nvl(part.sezione_ric,'*') = nvl(a_rec_ter.sezione_ric,'*')
       and nvl(part.estremi_catasto,'*') = nvl(a_rec_ter.estremi_catasto,'*')
       and nvl(part.cod_causale_atto_generante,'*') = nvl(a_rec_ter.cod_causale_atto_generante,'*')
       and nvl(part.des_atto_generante,'*') = nvl(a_rec_ter.des_atto_generante,'*')
       and nvl(part.cod_causale_atto_conclusivo,'*') = nvl(a_rec_ter.cod_causale_atto_conclusivo,'*')
       and nvl(part.des_atto_conclusivo,'*') = nvl(a_rec_ter.des_atto_conclusivo,'*');
  exception
    when no_data_found then
      w_result := 0;
    when too_many_rows then
      w_result := 2;
      p_errore := 'Esistono piu'' particelle uguali per il terreno '||
                  a_rec_ter.id_immobile;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_PARTICELLE ('
               ||a_rec_ter.id_immobile
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
--
  return w_result;
end F_ESISTE_TERRENO;
-------------------------------------------------------------------------------
function F_ESISTE_TITOLARITA
( a_riga                   varchar2
, a_rec_tit                cc_titolarita%rowtype
) return number is
/******************************************************************************
 NOME:        F_ESISTE_TITOLARITA
 DESCRIZIONE: Verifica se la titolarita' esiste gia' nella tabella CC_TITOLARITA
              File .TIT, tipo record unico
 RITORNA:     0 - La titolarita non esiste
              1 - La titolarita esiste
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  w_result                 number;
begin
  -- Si controlla se il terreno esiste gia
  begin
    select 1
      into w_result
      from cc_titolarita tito
     where tito.codice_amm = a_rec_tit.codice_amm
       and nvl(tito.sezione_amm,'*') = nvl(a_rec_tit.sezione_amm,'*')
       and tito.id_soggetto = a_rec_tit.id_soggetto
       and tito.tipo_soggetto = a_rec_tit.tipo_soggetto
       and tito.id_immobile = a_rec_tit.id_immobile
       and tito.tipo_immobile = a_rec_tit.tipo_immobile
       and nvl(tito.codice_diritto,'*') = nvl(a_rec_tit.codice_diritto,'*')
       and nvl(tito.titolo_non_codificato,'*') = nvl(a_rec_tit.titolo_non_codificato,'*')
       and nvl(tito.quota_numeratore,-1) = nvl(a_rec_tit.quota_numeratore,-1)
       and nvl(tito.quota_denominatore,-1) = nvl(a_rec_tit.quota_denominatore,-1)
       and nvl(tito.regime,'*') =  nvl(a_rec_tit.regime,'*')
       and nvl(tito.soggetto_riferimento,-1) = nvl(a_rec_tit.soggetto_riferimento,-1)
       and nvl(tito.data_validita,'*') = nvl(a_rec_tit.data_validita,'*')
       and nvl(tito.tipo_nota,'*') = nvl(a_rec_tit.tipo_nota,'*')
       and nvl(tito.numero_nota,'*') = nvl(a_rec_tit.numero_nota,'*')
       and nvl(tito.progressivo_nota,'*') = nvl(a_rec_tit.progressivo_nota,'*')
       and nvl(tito.anno_nota,-1) = nvl(a_rec_tit.anno_nota,-1)
       and nvl(tito.data_registrazione_atti,'*') = nvl(a_rec_tit.data_registrazione_atti,'*')
       and nvl(tito.partita,-1) = nvl(a_rec_tit.partita,-1)
       and nvl(tito.data_validita_2,'*') = nvl(a_rec_tit.data_validita_2,'*')
       and nvl(tito.tipo_nota_2,'*') = nvl(a_rec_tit.tipo_nota_2,'*')
       and nvl(tito.numero_nota_2,'*') = nvl(a_rec_tit.numero_nota_2,'*')
       and nvl(tito.progressivo_nota_2,'*') = nvl(a_rec_tit.progressivo_nota_2,'*')
       and nvl(tito.anno_nota_2,-1) = nvl(a_rec_tit.anno_nota_2,-1)
       and nvl(tito.data_registrazione_atti_2,'*') = nvl(a_rec_tit.data_registrazione_atti_2,'*')
       and nvl(tito.id_mutazione_iniziale,-1) = nvl(a_rec_tit.id_mutazione_iniziale,-1)
       and nvl(tito.id_mutazione_finale,-1) = nvl(a_rec_tit.id_mutazione_finale,-1)
       and nvl(tito.id_titolarita,-1) = nvl(a_rec_tit.id_titolarita,-1)
       and nvl(tito.cod_causale_atto_generante,'*') = nvl(a_rec_tit.cod_causale_atto_generante,'*')
       and nvl(tito.des_atto_generante,'*') = nvl(a_rec_tit.des_atto_generante,'*')
       and nvl(tito.cod_causale_atto_conclusivo,'*') = nvl(a_rec_tit.cod_causale_atto_conclusivo,'*')
       and nvl(tito.des_atto_conclusivo,'*') = nvl(a_rec_tit.des_atto_conclusivo,'*');
  exception
    when no_data_found then
      w_result := 0;
    when too_many_rows then
      w_result := 2;
      p_errore := 'Esistono piu'' titolarita'' uguali per il soggetto '||
                            a_rec_tit.id_soggetto||' e l''immobile '||a_rec_tit.id_immobile;
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
    when others then
      p_errore := substr('Sel. CC_TITOLARITA ('
               ||a_rec_tit.id_soggetto||'/'||a_rec_tit.id_immobile
               ||') - '
               || sqlerrm,1,2000);
      raise errore;
  end;
--
  return w_result;
end F_ESISTE_TITOLARITA;
-------------------------------------------------------------------------------
procedure PERSONE_FISICHE
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        PERSONE_FISICHE
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai soggetti
              File .SOG, tipo soggetto 'P' - Persone fisiche
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  rec_sog                    cc_soggetti%rowtype;
begin
--
-- Si inizializzano tutti i campi della riga a null
--
  rec_sog                    := null;
  rec_sog.documento_id       := p_documento_id;
  rec_sog.utente             := p_utente;
  rec_sog.data_variazione    := trunc(sysdate);
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := rtrim(substr(a_riga,p_inizio,p_fine - p_inizio));
      if p_occorrenza = 1 then
         rec_sog.codice_amm := trim(p_campo);
      elsif
         p_occorrenza = 2 then
         rec_sog.sezione_amm := trim(p_campo);
      elsif
         p_occorrenza = 3 then
         rec_sog.id_soggetto := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_sog.tipo_soggetto := trim(p_campo);
      elsif
         p_occorrenza = 5 then
         rec_sog.cognome := trim(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_sog.nome := trim(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_sog.sesso := trim(p_campo);
      elsif
         p_occorrenza = 8 then
         rec_sog.data_nascita := trim(p_campo);
      elsif
         p_occorrenza = 9 then
         rec_sog.luogo_nascita := trim(p_campo);
      elsif
         p_occorrenza = 10 then
         rec_sog.codice_fiscale := trim(p_campo);
      elsif
         p_occorrenza = 11 then
         rec_sog.indicazioni_supplementari := trim(p_campo);
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Soggetto - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
  end;
--
-- Inserimento riga tabella CC_SOGGETTI
--
  if f_isnull_persona_fisica(rec_sog) = 1 then
     -- Si controlla se il soggetto esiste gia
     begin
       select 1
         into p_esiste
         from cc_soggetti x
        where x.codice_amm = rec_sog.codice_amm
          and nvl(x.sezione_amm,'*') = nvl(rec_sog.sezione_amm,'*')
          and x.id_soggetto = rec_sog.id_soggetto
          and x.tipo_soggetto = rec_sog.tipo_soggetto;
     exception
       when no_data_found then
         p_esiste := 0;
       when too_many_rows then
         p_errore := 'Esistono piu'' soggetti di tipo '||rec_sog.tipo_soggetto||
                     'uguali - Id: '||rec_sog.id_soggetto;
         p_conta_anomalie := p_conta_anomalie + 1;
         carica_catasto_censuario_pkg.insert_anomalie ( a_riga );
       when others then
         p_errore := substr('Sel. CC_SOGGETTI ('
                  ||rec_sog.id_soggetto
                  ||') - '
                  || sqlerrm,1,2000);
         raise errore;
     end;
     if p_esiste = 0 then
        p_soggetti_ins := p_soggetti_ins + 1;
        begin
          insert into cc_soggetti
          values rec_sog;
        exception
          when others then
            p_errore := substr('Ins. CC_SOGGETTI ('
                     ||rec_sog.codice_fiscale
                     ||') - '
                     || sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
end PERSONE_FISICHE;
-------------------------------------------------------------------------------
procedure PERSONE_GIURIDICHE
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        PERSONE_GIURIDICHE
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai soggetti
              File .SOG, tipo soggetto 'P' - Persone fisiche
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  rec_sog                    cc_soggetti%rowtype;
begin
--
-- Si inizializzano tutti i campi della riga a null
--
  rec_sog                    := null;
  rec_sog.documento_id       := p_documento_id;
  rec_sog.utente             := p_utente;
  rec_sog.data_variazione    := trunc(sysdate);
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := rtrim(substr(a_riga,p_inizio,p_fine - p_inizio));
      if p_occorrenza = 1 then
         rec_sog.codice_amm_2 := p_campo;
      elsif
         p_occorrenza = 2 then
         rec_sog.sezione_amm_2 := p_campo;
      elsif
         p_occorrenza = 3 then
         rec_sog.id_soggetto_2 := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_sog.tipo_soggetto_2 := p_campo;
      elsif
         p_occorrenza = 5 then
         rec_sog.denominazione := p_campo;
      elsif
         p_occorrenza = 6 then
         rec_sog.sede := p_campo;
      elsif
         p_occorrenza = 7 then
         rec_sog.codice_fiscale_2 := to_number(p_campo);
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Soggetto - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie (a_riga);
  end;
--
-- Inserimento riga tabella CC_SOGGETTI
--
  if f_isnull_persona_giuridica(rec_sog) = 1 then
     -- Si controlla se il soggetto esiste gia
     begin
       select 1
         into p_esiste
         from cc_soggetti x
        where x.codice_amm_2 = rec_sog.codice_amm_2
          and nvl(x.sezione_amm_2,'*') = nvl(rec_sog.sezione_amm_2,'*')
          and x.id_soggetto_2 = rec_sog.id_soggetto_2
          and x.tipo_soggetto_2 = rec_sog.tipo_soggetto_2;
     exception
       when no_data_found then
         p_esiste := 0;
       when too_many_rows then
         p_errore := 'Esistono piu'' soggetti di tipo '||rec_sog.tipo_soggetto||
                     'uguali - Id: '||rec_sog.id_soggetto;
         p_conta_anomalie := p_conta_anomalie + 1;
         carica_catasto_censuario_pkg.insert_anomalie (a_riga);
       when others then
         p_errore := substr('Sel. CC_SOGGETTI ('
                  ||rec_sog.id_soggetto
                  ||') - '
                  || sqlerrm,1,2000);
         raise errore;
     end;
     if p_esiste = 0 then
        p_soggetti_ins := p_soggetti_ins + 1;
        begin
          insert into cc_soggetti
          values rec_sog;
        exception
          when others then
            p_errore := substr('Ins. CC_SOGGETTI ('
                     ||rec_sog.codice_fiscale_2
                     ||') - '
                     || sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
end PERSONE_GIURIDICHE;
-------------------------------------------------------------------------------
procedure FABBRICATI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        FABBRICATI
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai fabbricati
              File .FAB, tipo record 1
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  rec_fab                    cc_fabbricati%rowtype;
begin
--
-- Si inizializzano tutti i campi della riga a null
--
  p_fabbricati_tot           := p_fabbricati_tot + 1;
  rec_fab                    := null;
  rec_fab.documento_id       := p_documento_id;
  rec_fab.utente             := p_utente;
  rec_fab.data_variazione    := trunc(sysdate);
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := rtrim(substr(a_riga,p_inizio,p_fine - p_inizio));
      if p_occorrenza = 1 then
         rec_fab.codice_amm := p_campo;
      elsif
         p_occorrenza = 2 then
         rec_fab.sezione_amm := p_campo;
      elsif
         p_occorrenza = 3 then
         rec_fab.id_immobile := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_fab.tipo_immobile := p_campo;
      elsif
         p_occorrenza = 5 then
         rec_fab.progressivo := to_number(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_fab.tipo_record  := to_number(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_fab.zona := p_campo;
      elsif
         p_occorrenza = 8 then
         rec_fab.categoria  := p_campo;
      elsif
         p_occorrenza = 9 then
         rec_fab.classe := rtrim(p_campo);
      elsif
         p_occorrenza = 10 then
         rec_fab.consistenza := to_number(translate(p_campo,p_da_sostituire,p_sostituto));
      elsif
         p_occorrenza = 11 then
         rec_fab.superficie := to_number(p_campo);
      elsif
         p_occorrenza = 12 then
         rec_fab.rendita_lire := to_number(p_campo);
      elsif
         p_occorrenza = 13 then
         rec_fab.rendita_euro := to_number(translate(p_campo,p_da_sostituire,p_sostituto));
      elsif
         p_occorrenza = 14 then
         rec_fab.lotto := p_campo;
      elsif
         p_occorrenza = 15 then
         rec_fab.edificio := p_campo;
      elsif
         p_occorrenza = 16 then
         rec_fab.scala := p_campo;
      elsif
         p_occorrenza = 17 then
         rec_fab.interno_1 := p_campo;
      elsif
         p_occorrenza = 18 then
         rec_fab.interno_2 := p_campo;
      elsif
         p_occorrenza = 19 then
         rec_fab.piano_1 := p_campo;
      elsif
         p_occorrenza = 20 then
         rec_fab.piano_2 := p_campo;
      elsif
         p_occorrenza = 21 then
         rec_fab.piano_3 := p_campo;
      elsif
         p_occorrenza = 22 then
         rec_fab.piano_4 := p_campo;
      elsif
         p_occorrenza = 23 then
         rec_fab.data_efficacia := p_campo;
      elsif
         p_occorrenza = 24 then
         rec_fab.data_registrazione_atti := p_campo;
      elsif
         p_occorrenza = 25 then
         rec_fab.tipo_nota := p_campo;
      elsif
         p_occorrenza = 26 then
         rec_fab.numero_nota := p_campo;
      elsif
         p_occorrenza = 27 then
         rec_fab.progressivo_nota := p_campo;
      elsif
         p_occorrenza = 28 then
         rec_fab.anno_nota := to_number(p_campo);
      elsif
         p_occorrenza = 29 then
         rec_fab.data_efficacia_2 := p_campo;
      elsif
         p_occorrenza = 30 then
         rec_fab.data_registrazione_atti_2 := p_campo;
      elsif
         p_occorrenza = 31 then
         rec_fab.tipo_nota_2 := p_campo;
      elsif
         p_occorrenza = 32 then
         rec_fab.numero_nota_2 := p_campo;
      elsif
         p_occorrenza = 33 then
         rec_fab.progressivo_nota_2 := p_campo;
      elsif
         p_occorrenza = 34 then
         rec_fab.anno_nota_2 := to_number(p_campo);
      elsif
         p_occorrenza = 35 then
         rec_fab.partita := p_campo;
      elsif
         p_occorrenza = 36 then
         rec_fab.annotazione := p_campo;
      elsif
         p_occorrenza = 37 then
         rec_fab.id_mutazione_iniziale := to_number(p_campo);
      elsif
         p_occorrenza = 38 then
         rec_fab.id_mutazione_finale := to_number(p_campo);
      elsif
         p_occorrenza = 39 then
         rec_fab.protocollo_notifica := p_campo;
      elsif
         p_occorrenza = 40 then
         rec_fab.data_notifica := p_campo;
      elsif
         p_occorrenza = 41 then
         rec_fab.cod_causale_atto_generante := p_campo;
      elsif
         p_occorrenza = 42 then
         rec_fab.des_atto_generante := p_campo;
      elsif
         p_occorrenza = 43 then
         rec_fab.cod_causale_atto_conclusivo := p_campo;
      elsif
         p_occorrenza = 44 then
         rec_fab.des_atto_conclusivo := p_campo;
      elsif
         p_occorrenza = 45 then
         rec_fab.flag_classamento := p_campo;
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Fabbricato - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie (a_riga);
  end;
--
  if f_isnull_fabbricato(rec_fab) = 1 then
     -- Si controlla se il fabbricato esiste gia
     if f_esiste_fabbricato(a_riga,rec_fab) = 0 then
        p_fabbricati_ins := p_fabbricati_ins + 1;
        begin
          insert into cc_fabbricati
          values rec_fab;
        exception
          when others then
            p_errore := substr('Ins. CC_FABBRICATI ('
                     ||rec_fab.id_immobile
                     ||') - '
                     || sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
end FABBRICATI;
-------------------------------------------------------------------------------
procedure IDENTIFICATIVI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        IDENTIFICATIVI
 DESCRIZIONE: Caricamento dati catasto censuario relativi agli identificativi
              File .FAB, tipo record 2
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  rec_ide_orig             t_rec_ide_orig; --cc_identificativi_orig%rowtype;
begin
--
-- Si inizializzano tutti i campi della riga a null
--
  p_identificativi_tot       := p_identificativi_tot + 1;
  rec_ide_orig                := null;
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := rtrim(substr(a_riga,p_inizio,p_fine - p_inizio));
      if p_occorrenza = 1 then
         rec_ide_orig.codice_amministrativo := p_campo;
      elsif
         p_occorrenza = 2 then
         rec_ide_orig.sezione := p_campo;
      elsif
         p_occorrenza = 3 then
         rec_ide_orig.id_immobile := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_ide_orig.tipo_immobile := p_campo;
      elsif
         p_occorrenza = 5 then
         rec_ide_orig.progressivo := to_number(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_ide_orig.tipi_record  := to_number(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_ide_orig.sezione_1 := p_campo;
      elsif
         p_occorrenza = 8 then
         rec_ide_orig.foglio_1 := p_campo;
      elsif
         p_occorrenza = 9 then
         rec_ide_orig.numero_1 := p_campo;
      elsif
         p_occorrenza = 10 then
         rec_ide_orig.denominatore_1 := to_number(p_campo);
      elsif
         p_occorrenza = 11 then
         rec_ide_orig.subalterno_1 := p_campo;
      elsif
         p_occorrenza = 12 then
         rec_ide_orig.edificialita_1 := p_campo;
      elsif
         p_occorrenza = 13 then
         rec_ide_orig.sezione_2 := p_campo;
      elsif
         p_occorrenza = 14 then
         rec_ide_orig.foglio_2 := p_campo;
      elsif
         p_occorrenza = 15 then
         rec_ide_orig.numero_2 := p_campo;
      elsif
         p_occorrenza = 16 then
         rec_ide_orig.denominatore_2 := to_number(p_campo);
      elsif
         p_occorrenza = 17 then
         rec_ide_orig.subalterno_2 := p_campo;
      elsif
         p_occorrenza = 18 then
         rec_ide_orig.edificialita_2 := p_campo;
      elsif
         p_occorrenza = 19 then
         rec_ide_orig.sezione_3 := p_campo;
      elsif
         p_occorrenza = 20 then
         rec_ide_orig.foglio_3 := p_campo;
      elsif
         p_occorrenza = 21 then
         rec_ide_orig.numero_3 := p_campo;
      elsif
         p_occorrenza = 22 then
         rec_ide_orig.denominatore_3 := to_number(p_campo);
      elsif
         p_occorrenza = 23 then
         rec_ide_orig.subalterno_3 := p_campo;
      elsif
         p_occorrenza = 24 then
         rec_ide_orig.edificialita_3 := p_campo;
      elsif
         p_occorrenza = 25 then
         rec_ide_orig.sezione_4 := p_campo;
      elsif
         p_occorrenza = 26 then
         rec_ide_orig.foglio_4 := p_campo;
      elsif
         p_occorrenza = 27 then
         rec_ide_orig.numero_4 := p_campo;
      elsif
         p_occorrenza = 28 then
         rec_ide_orig.denominatore_4 := to_number(p_campo);
      elsif
         p_occorrenza = 29 then
         rec_ide_orig.subalterno_4 := p_campo;
      elsif
         p_occorrenza = 30 then
         rec_ide_orig.edificialita_4 := p_campo;
      elsif
         p_occorrenza = 31 then
         rec_ide_orig.sezione_5 := p_campo;
      elsif
         p_occorrenza = 32 then
         rec_ide_orig.foglio_5 := p_campo;
      elsif
         p_occorrenza = 33 then
         rec_ide_orig.numero_5 := p_campo;
      elsif
         p_occorrenza = 34 then
         rec_ide_orig.denominatore_5 := to_number(p_campo);
      elsif
         p_occorrenza = 35 then
         rec_ide_orig.subalterno_5 := p_campo;
      elsif
         p_occorrenza = 36 then
         rec_ide_orig.edificialita_5 := p_campo;
      elsif
         p_occorrenza = 37 then
         rec_ide_orig.sezione_6 := p_campo;
      elsif
         p_occorrenza = 38 then
         rec_ide_orig.foglio_6 := p_campo;
      elsif
         p_occorrenza = 39 then
         rec_ide_orig.numero_6 := p_campo;
      elsif
         p_occorrenza = 40 then
         rec_ide_orig.denominatore_6 := to_number(p_campo);
      elsif
         p_occorrenza = 41 then
         rec_ide_orig.subalterno_6 := p_campo;
      elsif
         p_occorrenza = 42 then
         rec_ide_orig.edificialita_6 := p_campo;
      elsif
         p_occorrenza = 43 then
         rec_ide_orig.sezione_7 := p_campo;
      elsif
         p_occorrenza = 44 then
         rec_ide_orig.foglio_7 := p_campo;
      elsif
         p_occorrenza = 45 then
         rec_ide_orig.numero_7 := p_campo;
      elsif
         p_occorrenza = 46 then
         rec_ide_orig.denominatore_7 := to_number(p_campo);
      elsif
         p_occorrenza = 47 then
         rec_ide_orig.subalterno_7 := p_campo;
      elsif
         p_occorrenza = 48 then
         rec_ide_orig.edificialita_7 := p_campo;
      elsif
         p_occorrenza = 49 then
         rec_ide_orig.sezione_8 := p_campo;
      elsif
         p_occorrenza = 50 then
         rec_ide_orig.foglio_8 := p_campo;
      elsif
         p_occorrenza = 51 then
         rec_ide_orig.numero_8 := p_campo;
      elsif
         p_occorrenza = 52 then
         rec_ide_orig.denominatore_8 := to_number(p_campo);
      elsif
         p_occorrenza = 53 then
         rec_ide_orig.subalterno_8 := p_campo;
      elsif
         p_occorrenza = 54 then
         rec_ide_orig.edificialita_8 := p_campo;
      elsif
         p_occorrenza = 55 then
         rec_ide_orig.sezione_9 := p_campo;
      elsif
         p_occorrenza = 56 then
         rec_ide_orig.foglio_9 := p_campo;
      elsif
         p_occorrenza = 57 then
         rec_ide_orig.numero_9 := p_campo;
      elsif
         p_occorrenza = 58 then
         rec_ide_orig.denominatore_9 := to_number(p_campo);
      elsif
         p_occorrenza = 59 then
         rec_ide_orig.subalterno_9 := p_campo;
      elsif
         p_occorrenza = 60 then
         rec_ide_orig.edificialita_9 := p_campo;
      elsif
         p_occorrenza = 61 then
         rec_ide_orig.sezione_10 := p_campo;
      elsif
         p_occorrenza = 62 then
         rec_ide_orig.foglio_10 := p_campo;
      elsif
         p_occorrenza = 63 then
         rec_ide_orig.numero_10 := p_campo;
      elsif
         p_occorrenza = 64 then
         rec_ide_orig.denominatore_10 := to_number(p_campo);
      elsif
         p_occorrenza = 65 then
         rec_ide_orig.subalterno_10 := p_campo;
      elsif
         p_occorrenza = 66 then
         rec_ide_orig.edificialita_10 := p_campo;
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Identificativo - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie (a_riga);
  end;
  if f_isnull_identificativo(rec_ide_orig,0) = 1 then
     p_identificativi_ins := p_identificativi_ins + 1;
  end if;
--
-- (VD - 21/01/2022: Eliminato trattamento tabella CC_IDENTIFICATIVI_ORIG
  /* begin
       insert into cc_identificativi_orig
       values rec_ide_orig;
     exception
       when others then
         p_errore := substr('Ins. CC_IDENTIFICATIVI_ORIG ('
                  ||rec_ide_orig.id_immobile||'/'||rec_ide_orig.progressivo
                  ||') - '
                  || sqlerrm,1,2000);
       raise errore;
     end;
  end if;*/
--
  if f_isnull_identificativo(rec_ide_orig,1) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,1);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,2) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,2);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,3) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,3);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,4) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,4);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,5) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,5);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,6) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,6);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,7) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,7);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,8) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,8);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,9) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,9);
  end if;
--
  if f_isnull_identificativo(rec_ide_orig,10) = 1 then
     insert_cc_identificativi(rec_ide_orig,a_riga,10);
  end if;
end IDENTIFICATIVI;
-------------------------------------------------------------------------------
procedure INDIRIZZI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        INDIRIZZI
 DESCRIZIONE: Caricamento dati catasto censuario relativi agli indirizzi
              File .FAB, tipo record 3
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
 001   21/01/2022  VD      Eliminazione tabella CC_INDIRIZZI_ORIG
******************************************************************************/
  rec_ind_orig             t_rec_ind_orig; --cc_indirizzi_orig%rowtype;
begin
--
-- Si inizializzano tutti i campi della riga a null
--
  p_indirizzi_tot := p_indirizzi_tot + 1;
  rec_ind_orig    := null;
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := rtrim(substr(a_riga,p_inizio,p_fine - p_inizio));
      if p_occorrenza = 1 then
         rec_ind_orig.codice_amministrativo := p_campo;
      elsif
         p_occorrenza = 2 then
         rec_ind_orig.sezione := p_campo;
      elsif
         p_occorrenza = 3 then
         rec_ind_orig.id_immobile := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_ind_orig.tipo_immobile := p_campo;
      elsif
         p_occorrenza = 5 then
         rec_ind_orig.progressivo := to_number(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_ind_orig.tipo_record  := to_number(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_ind_orig.toponimo_1 := to_number(p_campo);
      elsif
         p_occorrenza = 8 then
         rec_ind_orig.indirizzo_1 := p_campo;
      elsif
         p_occorrenza = 9 then
         rec_ind_orig.civico1_1 := p_campo;
      elsif
         p_occorrenza = 10 then
         rec_ind_orig.civico2_1 := p_campo;
      elsif
         p_occorrenza = 11 then
         rec_ind_orig.civico3_1 := p_campo;
      elsif
         p_occorrenza = 12 then
         rec_ind_orig.cod_strada_1 := to_number(p_campo);
      elsif
         p_occorrenza = 13 then
         rec_ind_orig.toponimo_2 := to_number(p_campo);
      elsif
         p_occorrenza = 14 then
         rec_ind_orig.indirizzo_2 := p_campo;
      elsif
         p_occorrenza = 15 then
         rec_ind_orig.civico1_2 := p_campo;
      elsif
         p_occorrenza = 16 then
         rec_ind_orig.civico2_2 := p_campo;
      elsif
         p_occorrenza = 17 then
         rec_ind_orig.civico3_2 := p_campo;
      elsif
         p_occorrenza = 18 then
         rec_ind_orig.cod_strada_2 := to_number(p_campo);
      elsif
         p_occorrenza = 19 then
         rec_ind_orig.toponimo_3 := to_number(p_campo);
      elsif
         p_occorrenza = 20 then
         rec_ind_orig.indirizzo_3 := p_campo;
      elsif
         p_occorrenza = 21 then
         rec_ind_orig.civico1_3 := p_campo;
      elsif
         p_occorrenza = 22 then
         rec_ind_orig.civico2_3 := p_campo;
      elsif
         p_occorrenza = 23 then
         rec_ind_orig.civico3_3 := p_campo;
      elsif
         p_occorrenza = 24 then
         rec_ind_orig.cod_strada_3 := to_number(p_campo);
      elsif
         p_occorrenza = 25 then
         rec_ind_orig.toponimo_4 := to_number(p_campo);
      elsif
         p_occorrenza = 26 then
         rec_ind_orig.indirizzo_4 := p_campo;
      elsif
         p_occorrenza = 27 then
         rec_ind_orig.civico1_4 := p_campo;
      elsif
         p_occorrenza = 28 then
         rec_ind_orig.civico2_4 := p_campo;
      elsif
         p_occorrenza = 29 then
         rec_ind_orig.civico3_4 := p_campo;
      elsif
         p_occorrenza = 30 then
         rec_ind_orig.cod_strada_4 := to_number(p_campo);
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Indirizzo - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie (a_riga);
  end;
  if f_isnull_indirizzo(rec_ind_orig,0) = 1 then
     p_indirizzi_ins := p_indirizzi_ins + 1;
  end if;
--
-- (VD - 21/01/2022): eliminazione tabella CC_INDIRIZZI_ORIG
  /*   begin
       insert into cc_indirizzi_orig
       values rec_ind_orig;
     exception
       when others then
         p_errore := substr('Ins. cc_indirizzi_orig ('
                  ||rec_ind_orig.id_immobile
                  ||') - '
                  || sqlerrm,1,2000);
         raise errore;
     end;
  end if;*/
--
  if f_isnull_indirizzo(rec_ind_orig,1) = 1 then
     insert_cc_indirizzi(rec_ind_orig,a_riga,1);
  end if;
--
  if f_isnull_indirizzo(rec_ind_orig,2) = 1 then
     insert_cc_indirizzi(rec_ind_orig,a_riga,2);
  end if;
--
  if f_isnull_indirizzo(rec_ind_orig,3) = 1 then
     insert_cc_indirizzi(rec_ind_orig,a_riga,3);
  end if;
--
  if f_isnull_indirizzo(rec_ind_orig,4) = 1 then
     insert_cc_indirizzi(rec_ind_orig,a_riga,4);
  end if;
--
end INDIRIZZI;
-------------------------------------------------------------------------------
procedure TERRENI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        TERRENI
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai terreni
              File .TER, tipo record 1
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   13/07/2020  VD      Prima emissione.
******************************************************************************/
  rec_ter                  cc_particelle%rowtype;
begin--
-- Si inizializzano tutti i campi della riga a null
--
  p_terreni_tot              := p_terreni_tot + 1;
  rec_ter                    := null;
  rec_ter.documento_id       := p_documento_id;
  rec_ter.utente             := p_utente;
  rec_ter.data_variazione    := trunc(sysdate);
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := substr(a_riga,p_inizio,p_fine - p_inizio);
      if p_occorrenza = 1 then
         rec_ter.codice_amm := p_campo;
      elsif
         p_occorrenza = 2 then
         rec_ter.sezione_amm := p_campo;
      elsif
         p_occorrenza = 3 then
         rec_ter.id_immobile := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_ter.tipo_immobile := p_campo;
      elsif
         p_occorrenza = 5 then
         rec_ter.progressivo := to_number(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_ter.tipo_record := to_number(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_ter.foglio := to_number(p_campo);
      elsif
         p_occorrenza = 8 then
         rec_ter.numero := p_campo;
      elsif
         p_occorrenza = 9 then
         rec_ter.denominatore := to_number(p_campo);
      elsif
         p_occorrenza = 10 then
         rec_ter.subalterno := p_campo;
      elsif
         p_occorrenza = 11 then
         rec_ter.edificialita := p_campo;
      elsif
         p_occorrenza = 12 then
         rec_ter.qualita := to_number(p_campo);
      elsif
         p_occorrenza = 13 then
         rec_ter.classe := p_campo;
      elsif
         p_occorrenza = 14 then
         rec_ter.ettari := to_number(p_campo);
      elsif
         p_occorrenza = 15 then
         rec_ter.are := to_number(p_campo);
      elsif
         p_occorrenza = 16 then
         rec_ter.centiare := to_number(p_campo);
      elsif
         p_occorrenza = 17 then
         rec_ter.flag_reddito := p_campo;
      elsif
         p_occorrenza = 18 then
         rec_ter.flag_porzione := p_campo;
      elsif
         p_occorrenza = 19 then
         rec_ter.flag_deduzioni := p_campo;
      elsif
         p_occorrenza = 20 then
         rec_ter.reddito_dominicale_lire := to_number(p_campo);
      elsif
         p_occorrenza = 21 then
         rec_ter.reddito_agrario_lire := to_number(p_campo);
      elsif
         p_occorrenza = 22 then
         rec_ter.reddito_dominicale_euro := to_number(translate(p_campo,p_da_sostituire,p_sostituto));
      elsif
         p_occorrenza = 23 then
         rec_ter.reddito_agrario_euro := to_number(translate(p_campo,p_da_sostituire,p_sostituto));
      elsif
         p_occorrenza = 24 then
         rec_ter.data_efficacia := p_campo;
      elsif
         p_occorrenza = 25 then
         rec_ter.data_registrazione_atti := p_campo;
      elsif
         p_occorrenza = 26 then
         rec_ter.tipo_nota := p_campo;
      elsif
         p_occorrenza = 27 then
         rec_ter.numero_nota := p_campo;
      elsif
         p_occorrenza = 28 then
         rec_ter.progressivo_nota := p_campo;
      elsif
         p_occorrenza = 29 then
         rec_ter.anno_nota := to_number(p_campo);
      elsif
         p_occorrenza = 30 then
         rec_ter.data_efficacia_1 := p_campo;
      elsif
         p_occorrenza = 31 then
         rec_ter.data_registrazione_atti_1 := p_campo;
      elsif
         p_occorrenza = 32 then
         rec_ter.tipo_nota_1 := p_campo;
      elsif
         p_occorrenza = 33 then
         rec_ter.numero_nota_1 := p_campo;
      elsif
         p_occorrenza = 34 then
         rec_ter.progressivo_nota_1 := p_campo;
      elsif
         p_occorrenza = 35 then
         rec_ter.anno_nota_1 := to_number(p_campo);
      elsif
         p_occorrenza = 36 then
         rec_ter.partita := p_campo;
      elsif
         p_occorrenza = 37 then
         rec_ter.annotazione := p_campo;
      elsif
         p_occorrenza = 38 then
         rec_ter.id_mutazione_iniziale := to_number(p_campo);
      elsif
         p_occorrenza = 39 then
         rec_ter.id_mutazione_finale := to_number(p_campo);
      elsif
         p_occorrenza = 40 then
         rec_ter.cod_causale_atto_generante := p_campo;
      elsif
         p_occorrenza = 41 then
         rec_ter.des_atto_generante := p_campo;
      elsif
         p_occorrenza = 42 then
         rec_ter.cod_causale_atto_conclusivo := p_campo;
      elsif
         p_occorrenza = 43 then
         rec_ter.des_atto_conclusivo := p_campo;
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Terreno - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie(a_riga);
  end;
--
  if f_isnull_terreno(rec_ter) = 1 then
     if f_esiste_terreno(a_riga,rec_ter) = 0 then
        p_terreni_ins := p_terreni_ins + 1;
        begin
          insert into cc_particelle
          values rec_ter;
        exception
          when others then
            p_errore := substr('Ins. CC_TERRENI ('
                     ||rec_ter.id_immobile
                     ||') - '
                     || sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
end TERRENI;
-------------------------------------------------------------------------------
procedure TRATTA_SOGGETTI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        TRATTA_SOGGETTI
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai soggetti
              File .SOG
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  w_inizio_tipo              number := 0;
  w_fine_tipo                number;
  sog_tipo_soggetto          cc_soggetti.tipo_soggetto%type;
begin
--
-- Si estrae prima il quarto elemento della riga, cioè il tipo soggetto
-- (P=persona fisica, G=persona giuridica)
-- per capire quali campi devono essere trattati
--
  w_inizio_tipo     := instr(a_riga,'|',1,3) + 1;
  w_fine_tipo       := instr(a_riga,'|',1,4);
  sog_tipo_soggetto := rtrim(substr(a_riga,w_inizio_tipo,w_fine_tipo - w_inizio_tipo));
--
-- Si inizializzano tutti i campi della riga a null
--
  p_soggetti_tot := p_soggetti_tot + 1;
  if sog_tipo_soggetto = 'P' then
     -- Trattamento persone fisiche
     carica_catasto_censuario_pkg.persone_fisiche(a_riga);
  elsif
     sog_tipo_soggetto = 'G' then
     -- Trattamento persone giuridiche
     carica_catasto_censuario_pkg.persone_giuridiche(a_riga);
  end if;
end TRATTA_SOGGETTI;
-------------------------------------------------------------------------------
procedure TRATTA_FABBRICATI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        TRATTA_FABBRICATI
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai fabbricati
              File .FAB
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/06/2020  VD      Prima emissione.
******************************************************************************/
  w_inizio_tipo              number := 0;
  w_fine_tipo                number;
  fab_tipo_record            cc_fabbricati.tipo_record%type;
begin
  --
  -- Si estrae prima il sesto elemento della riga, cioè il tipo record
  -- Il caricamento tratta i tipi record = 1, 2, 3
  --
  w_inizio_tipo                 := instr(a_riga,'|',1,5) + 1;
  w_fine_tipo                   := instr(a_riga,'|',1,6);
  fab_tipo_record := substr(a_riga,w_inizio_tipo,w_fine_tipo - w_inizio_tipo);
  --
  if fab_tipo_record = 1 then
     p_conta_iden := -1;
     p_conta_indi := -1;
     carica_catasto_censuario_pkg.fabbricati(a_riga);
  elsif
     fab_tipo_record = 2 then
     p_conta_iden := p_conta_iden + 1;
     --dbms_output.put_line('w_conta_iden: '||w_conta_iden);
     carica_catasto_censuario_pkg.identificativi(a_riga);
  elsif
     fab_tipo_record = 3 then
     p_conta_indi := p_conta_indi + 1;
     carica_catasto_censuario_pkg.indirizzi(a_riga);
  end if;
end TRATTA_FABBRICATI;
-------------------------------------------------------------------------------
procedure TRATTA_TERRENI
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        TRATTA_TERRENI
 DESCRIZIONE: Caricamento dati catasto censuario relativi ai terreni
              File .TER
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   17/07/2020  VD      Prima emissione.
******************************************************************************/
  w_inizio_tipo              number := 0;
  w_fine_tipo                number;
  ter_tipo_record            cc_particelle.tipo_record%type;
begin
--
-- Si estrae prima il sesto elemento della riga, cioè il tipo record
-- Il caricamento tratta solo i tipi record = 1
--
  w_inizio_tipo                 := instr(a_riga,'|',1,5) + 1;
  w_fine_tipo                   := instr(a_riga,'|',1,6);
  ter_tipo_record := substr(a_riga,w_inizio_tipo,w_fine_tipo - w_inizio_tipo);
  if ter_tipo_record = 1 then
     carica_catasto_censuario_pkg.terreni(a_riga);
  end if;
end TRATTA_TERRENI;
-------------------------------------------------------------------------------
procedure TRATTA_TITOLARITA
( a_riga                      varchar2
) is
/******************************************************************************
 NOME:        TRATTA_TITOLARITA
 DESCRIZIONE: Caricamento dati catasto censuario relativi alle titolarita
              File .TIT
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   17/07/2020  VD      Prima emissione.
******************************************************************************/
  rec_tit                    cc_titolarita%rowtype;
begin
  p_titolarita_tot           := p_titolarita_tot + 1;
  rec_tit                     := null;
  rec_tit.documento_id       := p_documento_id;
  rec_tit.utente             := p_utente;
  rec_tit.data_variazione    := trunc(sysdate);
  begin
    while p_occorrenza <= p_num_separatori
    loop
      p_fine := instr(a_riga,'|',p_inizio,1);
      p_campo := substr(a_riga,p_inizio,p_fine - p_inizio);
      if p_occorrenza = 1 then
         rec_tit.codice_amm := trim(substr(p_campo,1,4));
      elsif
         p_occorrenza = 2 then
         rec_tit.sezione_amm := trim(substr(p_campo,1,1));
      elsif
         p_occorrenza = 3 then
         rec_tit.id_soggetto := to_number(p_campo);
      elsif
         p_occorrenza = 4 then
         rec_tit.tipo_soggetto := trim(substr(p_campo,1,1));
      elsif
         p_occorrenza = 5 then
         rec_tit.id_immobile := to_number(p_campo);
      elsif
         p_occorrenza = 6 then
         rec_tit.tipo_immobile := trim(p_campo);
      elsif
         p_occorrenza = 7 then
         rec_tit.codice_diritto := p_campo;
      elsif
         p_occorrenza = 8 then
         rec_tit.titolo_non_codificato := trim(p_campo);
      elsif
         p_occorrenza = 9 then
         rec_tit.quota_numeratore := to_number(p_campo);
      elsif
         p_occorrenza = 10 then
         rec_tit.quota_denominatore := to_number(p_campo);
      elsif
         p_occorrenza = 11 then
         rec_tit.regime := trim(p_campo);
      elsif
         p_occorrenza = 12 then
         rec_tit.soggetto_riferimento := to_number(p_campo);
      elsif
         p_occorrenza = 13 then
         rec_tit.data_validita := trim(p_campo);
      elsif
         p_occorrenza = 14 then
         rec_tit.tipo_nota := trim(p_campo);
      elsif
         p_occorrenza = 15 then
         rec_tit.numero_nota := trim(p_campo);
      elsif
         p_occorrenza = 16 then
         rec_tit.progressivo_nota := trim(p_campo);
      elsif
         p_occorrenza = 17 then
         rec_tit.anno_nota := to_number(p_campo);
      elsif
         p_occorrenza = 18 then
         rec_tit.data_registrazione_atti := trim(p_campo);
      elsif
         p_occorrenza = 19 then
         rec_tit.partita := trim(p_campo);
      elsif
         p_occorrenza = 20 then
         rec_tit.data_validita_2 := trim(p_campo);
      elsif
         p_occorrenza = 21 then
         rec_tit.tipo_nota_2 := trim(p_campo);
      elsif
         p_occorrenza = 22 then
         rec_tit.numero_nota_2 := trim(p_campo);
      elsif
         p_occorrenza = 23 then
         rec_tit.progressivo_nota_2 := trim(p_campo);
      elsif
         p_occorrenza = 24 then
         rec_tit.anno_nota_2 := to_number(p_campo);
      elsif
         p_occorrenza = 25 then
         rec_tit.data_registrazione_atti_2 := trim(p_campo);
      elsif
         p_occorrenza = 26 then
         rec_tit.id_mutazione_iniziale := to_number(p_campo);
      elsif
         p_occorrenza = 27 then
         rec_tit.id_mutazione_finale := to_number(p_campo);
      elsif
         p_occorrenza = 28 then
         rec_tit.id_titolarita := to_number(p_campo);
      elsif
         p_occorrenza = 29 then
         rec_tit.cod_causale_atto_generante := trim(p_campo);
      elsif
         p_occorrenza = 30 then
         rec_tit.des_atto_generante := trim(p_campo);
      elsif
         p_occorrenza = 31 then
         rec_tit.cod_causale_atto_conclusivo := trim(p_campo);
      elsif
         p_occorrenza = 32 then
         rec_tit.des_atto_conclusivo := trim(p_campo);
      end if;
      p_occorrenza := p_occorrenza + 1;
      p_inizio := instr(a_riga,'|',p_inizio,1) + 1;
    end loop;
  exception
    when others then
      p_errore := substr('Titolarita'' - Campo '||p_occorrenza||': '||sqlerrm,1,2000);
      p_conta_anomalie := p_conta_anomalie + 1;
      carica_catasto_censuario_pkg.insert_anomalie (a_riga);
  end;
--
  if f_isnull_titolarita(rec_tit) = 1 then
     if f_esiste_titolarita(a_riga,rec_tit) = 0 then
        p_titolarita_ins := p_titolarita_ins + 1;
        begin
           insert into cc_titolarita
           values rec_tit;
        exception
          when others then
            p_errore := substr('Ins. CC_TITOLARITA (Soggetto: '
                     ||rec_tit.id_soggetto||', Immobile: '||rec_tit.id_immobile
                     ||') - '
                     || sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
end TRATTA_TITOLARITA;
-------------------------------------------------------------------------------
procedure ESEGUI
( a_documento_id             number
, a_utente                   in     varchar2
, a_messaggio                in out varchar2
)
is
  w_documento_blob           blob;
  w_documento_clob           clob;
  w_documento_multi_id       documenti_caricati_multi.documento_multi_id%type;
  dest_offset                number := 1;
  src_offset                 number := 1;
  amount                     integer := DBMS_LOB.lobmaxsize;
  blob_csid                  number := DBMS_LOB.default_csid;
  lang_ctx                   integer := DBMS_LOB.default_lang_ctx;
  warning                    integer;
  w_dimensione_file          number;
  w_posizione                number;
  w_posizione_old            number;
  w_riga                     varchar2 (32767);
  w_vuota_tabella            number;
begin
  a_messaggio          := '';
  p_documento_id       := a_documento_id;
  p_utente             := a_utente;
  w_documento_multi_id := -1;
-- Azzeramento variabili di package
  p_conta_anomalie := 0;
  p_soggetti_tot  := 0;
  p_soggetti_ins  := 0;
  p_soggetti_mess := '';
  p_fabbricati_tot  := 0;
  p_fabbricati_ins  := 0;
  p_fabbricati_mess := '';
  p_identificativi_tot  := 0;
  p_identificativi_ins  := 0;
  p_identificativi_mess := '';
  p_indirizzi_tot  := 0;
  p_indirizzi_ins  := 0;
  p_indirizzi_mess := '';
  p_terreni_tot  := 0;
  p_terreni_ins  := 0;
  p_terreni_mess := '';
  p_titolarita_tot  := 0;
  p_titolarita_ins  := 0;
  p_titolarita_mess := '';
--
-- (VD - 05/06/2020): Selezione del parametro NLS_NUMERIC_CHARACTERS
--
  begin
    select decode(substr(value,1,1)
                 ,'.',',','.')
         , substr(value,1,1)
      into p_da_sostituire
         , p_sostituto
      from nls_session_parameters
     where parameter = 'NLS_NUMERIC_CHARACTERS';
  exception
    when others then
      p_da_sostituire := ',';
      p_sostituto := '.';
  end;
--
-- Controllo tipo trattamento: si seleziona il documento principale
-- per verificare se si tratta di un attualita' oppure di un
-- aggiornamento
--
  begin
    select contenuto
         , nome_documento
      into w_documento_blob
         , p_nome_documento
      from documenti_caricati
     where documento_id = a_documento_id;
  exception
    when no_data_found then
      p_errore := substr('Documento '||a_documento_id||' non esistente',1,2000);
      raise errore;
    when others then
      p_errore := substr('Errore in selezione documento principale '
               || a_documento_id
               || ' ('
               || sqlerrm
               || ')',1,2000);
      raise errore;
  end;
-- Verifica blob documento principale
  w_dimensione_file:= DBMS_LOB.getlength (w_documento_blob);
  if nvl (w_dimensione_file, 0) = 0 then
     p_errore := 'Attenzione File '||p_nome_documento||' caricato Vuoto - Verificare Client Oracle';
     raise errore;
  end if;
--
  dest_offset := 1;
  src_offset  := 1;
--
  begin
   DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob
                            ,cache =>     true
                            ,dur =>       DBMS_LOB.session
                            );
   DBMS_LOB.converttoclob (w_documento_clob
                          ,w_documento_blob
                          ,amount
                          ,dest_offset
                          ,src_offset
                          ,blob_csid
                          ,lang_ctx
                          ,warning
                          );
  exception
    when others then
      p_errore := substr('Errore in trasformazione Blob in Clob file '
               || p_nome_documento
               || ' ('
               || sqlerrm
               || ')',1,2000);
      raise errore;
  end;
-- Si verifica il tipo di estrazione dati catasto effettuato:
-- se presente la dicitura "Data selezione" significa che si tratta di
-- attualita', se presente la dicitura "Date registrazione"
-- significa che si tratta di aggiornamento
  if instr(w_documento_clob,'Data selezione') > 0 then
     p_tipo_trattamento := 'I';
  else
     p_tipo_trattamento := 'A';
  end if;
--
-- Se il tipo trattamento e' I (attualita') si svuotano le tabelle
-- prima di procedere - solo se si tratta di fabbricati
--
  w_vuota_tabella := 0;
  if p_tipo_trattamento = 'I' then
     begin
       select 1
         into w_vuota_tabella
         from documenti_caricati_multi
        where documento_id = a_documento_id
          and upper(nome_documento) like '%FAB';
     exception
       when too_many_rows then
         w_vuota_tabella := 1;
       when others then
         w_vuota_tabella := 0;
     end;
  end if;
--
  if w_vuota_tabella = 1 then
     si4.sql_execute('truncate table cc_soggetti');
     si4.sql_execute('truncate table cc_fabbricati');
     si4.sql_execute('truncate table cc_identificativi');
     si4.sql_execute('truncate table cc_indirizzi');
     si4.sql_execute('truncate table cc_particelle');
     si4.sql_execute('truncate table cc_titolarita');
  end if;
--
-- Estrazione BLOB: si esegue l'estrazione di tutti i file
-- collegati al documento principale
--
  for doca in (select contenuto
                    , documento_multi_id
                    , nome_documento
                 from documenti_caricati_multi
                where documento_id = a_documento_id
                order by documento_multi_id)
  loop
--
-- Verifica dimensione file caricato
--
    p_nome_documento := doca.nome_documento;
    w_documento_multi_id := doca.documento_multi_id;
    w_documento_blob := doca.contenuto;
    w_dimensione_file:= DBMS_LOB.getlength (w_documento_blob);
    if nvl (w_dimensione_file, 0) = 0 then
       p_errore := 'Attenzione File '||doca.nome_documento||' caricato Vuoto - Verificare Client Oracle';
       raise errore;
    end if;
--
    dest_offset := 1;
    src_offset  := 1;
--
    begin
     DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob
                              ,cache =>     true
                              ,dur =>       DBMS_LOB.session
                              );
     DBMS_LOB.converttoclob (w_documento_clob
                            ,w_documento_blob
                            ,amount
                            ,dest_offset
                            ,src_offset
                            ,blob_csid
                            ,lang_ctx
                            ,warning
                            );
    exception
      when others then
        p_errore := substr('Errore in trasformazione Blob in Clob file '
                 || doca.nome_documento
                 || ' ('
                 || sqlerrm
                 || ')',1,2000);
        raise errore;
    end;
--
    w_posizione_old     := 1;
    w_posizione         := 1;
--
    while w_posizione < w_dimensione_file
    loop
      w_posizione := instr (w_documento_clob, chr (10), w_posizione_old);
      w_riga      := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
      w_posizione_old := w_posizione + 1;
--
-- Si determina il numero di delimitatori presenti nella riga
--
      p_num_separatori := length(w_riga) - length(replace(w_riga,'|',''));
      p_lunghezza_riga := length(w_riga);
      p_inizio := 1;
      p_occorrenza := 1;
      --
      -- Trattamento file soggetti
      --
      if upper(doca.nome_documento) like '%SOG' then
         carica_catasto_censuario_pkg.tratta_soggetti (w_riga);
      end if;
      --
      -- Trattamento file fabbricati
      --
      if upper(doca.nome_documento) like '%FAB' then
         carica_catasto_censuario_pkg.tratta_fabbricati (w_riga);
      end if;
      --
      -- Trattamento file terreni
      --
      if upper(doca.nome_documento) like '%TER' then
         carica_catasto_censuario_pkg.tratta_terreni (w_riga);
      end if;
      --
      -- Trattamento file titolarita'
      --
      if upper(doca.nome_documento) like '%TIT' then
         carica_catasto_censuario_pkg.tratta_titolarita (w_riga);
      end if;
    end loop; -- loop riga
--
-- Aggiornamento note documento multi
--
    if upper(doca.nome_documento) like '%SOG' then
       p_soggetti_mess := 'Soggetti inseriti: '||p_soggetti_ins||' su '||p_soggetti_tot||' totali';
       p_errore := p_soggetti_mess;
    elsif
       upper(doca.nome_documento) like '%FAB' then
       p_fabbricati_mess := 'Fabbricati inseriti: '||p_fabbricati_ins||' su '||p_fabbricati_tot||' totali';
       p_identificativi_mess := 'Identificativi inseriti: '||p_identificativi_ins||' su '||p_identificativi_tot||' totali';
       p_indirizzi_mess := 'Indirizzi inseriti: '||p_indirizzi_ins||' su '||p_indirizzi_tot||' totali';
       p_errore := substr(p_fabbricati_mess||'/'||p_identificativi_mess||'/'||p_indirizzi_mess,1,2000);
    elsif
       upper(doca.nome_documento) like '%TER' then
       p_terreni_mess := 'Terreni inseriti: '||p_terreni_ins||' su '||p_terreni_tot||' totali';
       p_errore := p_terreni_mess;
    elsif
       upper(doca.nome_documento) like '%TIT' then
       p_titolarita_mess := 'Titolarita'' inserite: '||p_titolarita_ins||' su '||p_titolarita_tot||' totali';
       p_errore := p_titolarita_mess;
    end if;
--
    begin
      update documenti_caricati_multi
         set note = p_errore
       where documento_id = a_documento_id
         and documento_multi_id = doca.documento_multi_id;
    exception
      when others then
        p_errore := substr(sqlerrm,1,2000);
        raise errore;
    end;
  end loop;  -- loop doc. multi
--
  a_messaggio := p_soggetti_mess||chr(13)||chr(10);
--
  if p_fabbricati_mess is not null then
     a_messaggio := a_messaggio||p_fabbricati_mess||chr(13)||chr(10);
  end if;
--
  if p_identificativi_mess is not null then
     a_messaggio := a_messaggio ||p_identificativi_mess||chr(13)||chr(10);
  end if;
--
  if p_indirizzi_mess is not null then
     a_messaggio := a_messaggio ||p_indirizzi_mess||chr(13)||chr(10);
  end if;
--
  if p_terreni_mess is not null then
     a_messaggio := a_messaggio ||p_terreni_mess||chr(13)||chr(10);
  end if;
--
  a_messaggio := a_messaggio||p_titolarita_mess||chr(13)||chr(10)||
                 'Anomalie inserite: '||p_conta_anomalie;
--
  if w_documento_multi_id = -1 then
    begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Nessun file collegato da caricare.'
       where documento_id = a_documento_id
     ;
    end;
    a_messaggio :=  'Nessun file collegato da caricare';
  else
    begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = a_messaggio
       where documento_id = a_documento_id
     ;
    end;
  end if;
exception
  when errore then
    rollback;
    raise_application_error (-20999, nvl (p_errore, 'vuoto'));
end ESEGUI;
end CARICA_CATASTO_CENSUARIO_PKG;
/

