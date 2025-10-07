--liquibase formatted sql 
--changeset abrandolini:20250326_152429_carica_dic_enc_ecpf stripComments:false runOnChange:true 
 
CREATE OR REPLACE package CARICA_DIC_ENC_ECPF is
/******************************************************************************
 NOME:        CARICA_DIC_ENC_ECPF
 DESCRIZIONE: Procedure e Funzioni per caricamento dichiarazioni ENC ed ECPF.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 003   24/05/2024  VM      Modifiche ECPF 2022
 002   05/04/2023  VM      Pkg creato dal vecchio pkg CARICA_DIC_ENC per trattare anche le denunce ECPF
 001   14/03/2022  DM      Gestione stato Caricamento in Corso
 000   20/04/2018  VD      Prima emissione.
 *****************************************************************************/
  -- Revisione del Package
  s_revisione constant afc.t_revision := 'V1.01';
  function F_GET_TIPO_QUALITA
  ( a_descrizione            varchar2
  ) return number;
  function F_GET_OGGETTO_PRATICA
  ( a_pratica                        number
  , a_oggetto                        number
  ) return number;
  procedure CARICA_DICHIARAZIONI
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure TRATTA_SOGGETTI
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure TRATTA_TIPI_QUALITA
  ( a_documento_id           number
  );
  procedure TRATTA_CATEGORIE_CATASTO
  ( a_documento_id           number
  );
  procedure TRATTA_OGGETTI
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure TRATTA_PRATICHE
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure ESEGUI
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure ESEGUI_WEB
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
end CARICA_DIC_ENC_ECPF;
/
CREATE OR REPLACE package body     CARICA_DIC_ENC_ECPF is
/******************************************************************************
  NOME:        CARICA_DIC_ENC_ECPF.
  DESCRIZIONE: Procedure e Funzioni per caricamento dichiarazioni ENC.
  ANNOTAZIONI: .
  REVISIONI: .
  Rev.  Data        Autore  Descrizione.
  10    19/06/2025  DM      #80258 aggiunta gestione denunce da portale.
  09    21/08/2024  AB      #74453 sistemato errore di valorizzazione w_flag_cessione
                            corretto indirizzo_imm al posto di indirizzo
                            gestito la caratteristica riportandola a tipo_oggetto corretto
                            acquisito anche la data_evento
                            sistemato la gestione degli oggetti per il record D relativo a ecpf_v6
  08    18/12/2023  AB      Sostituito il continue con la goto perche in Ora 10 non va
  07    05/04/2023  VM      Pkg creato dal vecchio pkg CARICA_DIC_ENC per trattare anche le denunce ECPF.
  06    13/02/2023  AB      Aggiunti i controlli relativi al valore che puo assumere nel campo 39
  05    20/12/2021  VD      Correzione errore di tracciato su immobili imponibili
                            (tipo record C) e esenti (tipo record D).
  04    09/01/2020  VD      Aggiunta archiviazione denunce inserite.
  03    07/11/2018  VD      Corretta gestione flag firma dichiarazione.
  02    28/08/2019  VD      Migliorata gestione anomalie: ora non vengono più
                            segnalati i dati completamente a zero.
                            L'inserimento delle pratiche avviene solo in
                            presenza di righe di dettaglio.
                            Corretto trattamento oggetti (per progr_immobile e
                            non per num_ordine).
                            Corretta estrapolazione numero civico per soggetti.
  01    01/08/2018  VD      Modifiche per gestione tracciati diversi
                            a seconda dell'anno di dichiarazione.
  00    20/04/2018  VD      Prima emissione.
******************************************************************************/
  s_revisione_body   constant afc.t_revision := '002';
  w_fonte                     number;
  w_contarighe                number := 0;
  w_conta_soggetti            number := 0;
  w_conta_oggetti             number := 0;
  w_conta_pratiche_ici        number := 0;
  w_conta_pratiche_tasi       number := 0;
  w_conta_anomalie_car        number := 0;
  w_conta_anomalie_ici        number := 0;
  w_tipo_pratica              varchar2(1) := 'D';
  w_messaggio                 varchar2(32767);
  w_riga                      varchar2(32767);
  w_errore                    varchar2(32767);
  errore                      exception;
----------------------------------------------------------------------------------
function versione return varchar2 is
/******************************************************************************
  NOME:        versione.
  DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
  RITORNA:     VARCHAR2 stringa contenente versione e revisione.
  NOTE:        Primo numero  : versione compatibilita del Package.
               Secondo numero: revisione del Package specification.
               Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return s_revisione || '.' || s_revisione_body;
end versione;
----------------------------------------------------------------------------------
function f_get_fonte
/*************************************************************************
  NOME:        f_get_fonte
  DESCRIZIONE: Restituisce la fonte del il documento
**************************************************************************/
( a_documento_id number
) return number is
  w_codice_tracciato varchar(50);
  w_fonte            varchar(200);
begin
  begin
  select codice_tracciato
    into w_codice_tracciato
    from wrk_enc_testata
   where rownum = 1
   and documento_id = a_documento_id
   ;
  exception
    when no_data_found then
      w_codice_tracciato := null;
      w_errore := substr('Codice tracciato non trovato x doc_id: '
               || a_documento_id
               || ' ('||sqlerrm||')',1,2000);
      raise errore;
    when others then
      w_codice_tracciato  := null;
/*      w_errore := substr('Errore in ricerca qualita'' terreno '
                         || a_descrizione
                         || ' ('||sqlerrm||')',1,2000);
      raise errore;*/
  end;

  --
  case w_codice_tracciato
    when 'ENC' then
      w_fonte := F_INPA_VALORE('FONT_DIENC');
      w_tipo_pratica := 'D';
    when 'ECPF' then
      w_fonte := F_INPA_VALORE('FONT_DECPF');
      w_tipo_pratica := 'D';
    when 'PWEB' then
      w_fonte := F_INPA_VALORE('FONT_PWEB');
      w_tipo_pratica := 'P';
  end case;
  --
  return w_fonte;
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
 --
end f_get_fonte;
----------------------------------------------------------------------------------
function F_GET_TIPO_QUALITA
/*************************************************************************
  NOME:        F_GET_TIPO_QUALITA
  DESCRIZIONE: Restituisce il codice del tipo qualita partendo dalla
               descrizione
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_descrizione               varchar2
) return number is
  w_tipo_qualita              tipi_qualita.tipo_qualita%type;
begin

  if (a_descrizione is null) then
     return to_number(null);
  end if;

  begin
    select tipo_qualita
      into w_tipo_qualita
      from tipi_qualita
     where descrizione = a_descrizione;
  exception
    when no_data_found then
      w_tipo_qualita := to_number(null);
      w_errore := substr('Qualita'' terreno non codificata '
               || a_descrizione
               || ' ('||sqlerrm||')',1,2000);
      raise errore;
    when others then
      w_tipo_qualita := to_number(null);
/*      w_errore := substr('Errore in ricerca qualita'' terreno '
                         || a_descrizione
                         || ' ('||sqlerrm||')',1,2000);
      raise errore;*/
  end;
  --
  return w_tipo_qualita;
  --
end f_get_tipo_qualita;
----------------------------------------------------------------------------------
function F_ESISTE_PRATICA
/*************************************************************************
  NOME:        F_ESISTE_PRATICA
  DESCRIZIONE: Acquisto
               Si controlla se esiste gia' una dichiarazione per stesso
               anno, stesso contribuente e stesso oggetto.
  NOTE:        Restituisce:
               0 - denuncia non esistente
               1 - denuncia esistente con dati di possesso uguali
               2 - denuncia esistente con dati di possesso diversi
  Rev.    Date         Author      Note
  000     24/09/2018   VD          Prima emissione
**************************************************************************/
( a_tipo_tributo                   varchar2
, a_cod_fiscale                    varchar2
, a_anno                           number
, a_oggetto                        number
, a_flag_possesso                  varchar2
, a_mesi_possesso                  number
, a_mesi_possesso_1s               number
, a_perc_possesso                  number
, a_flag_esclusione                varchar2
, a_mesi_esclusione                number
) return number is
  w_flag_denuncia                  number;
begin
  select max(1)
    into w_flag_denuncia
    from pratiche_tributo     prtr,
         oggetti_pratica      ogpr,
         oggetti_contribuente ogco
   where ogco.oggetto_pratica          = ogpr.oggetto_pratica
     and ogpr.oggetto                  = a_oggetto
     and ogco.cod_fiscale              = a_cod_fiscale
     and nvl(ogco.flag_possesso,'N')   = nvl(a_flag_possesso,'N')
     and ogco.mesi_possesso            = a_mesi_possesso
     and ogco.mesi_possesso_1sem       = a_mesi_possesso_1s
     and ogco.perc_possesso            = a_perc_possesso
     and nvl(ogco.flag_esclusione,'N') = nvl(a_flag_esclusione,'N')
     and ogco.mesi_esclusione          = a_mesi_esclusione
     and ogpr.pratica                  = prtr.pratica
     and prtr.tipo_tributo || ''       = a_tipo_tributo
     and prtr.tipo_pratica             = 'D'
     and prtr.tipo_evento              = 'I'
     and prtr.anno                     = a_anno;
--
-- Se non esiste una denuncia identica, si ricerca una denuncia con dati di possesso diversi
--
  if w_flag_denuncia is null then
     select max(2)
       into w_flag_denuncia
       from pratiche_tributo     prtr,
            oggetti_pratica      ogpr,
            oggetti_contribuente ogco
      where ogco.oggetto_pratica          = ogpr.oggetto_pratica
        and ogpr.oggetto                  = a_oggetto
        and ogco.cod_fiscale              = a_cod_fiscale
        and ogpr.pratica                  = prtr.pratica
        and prtr.tipo_tributo || ''       = a_tipo_tributo
        and prtr.tipo_pratica             = 'D'
        and prtr.tipo_evento              = 'I'
        and prtr.anno                     = a_anno;
  end if;
--
  return nvl(w_flag_denuncia,0);
--
end f_esiste_pratica;
----------------------------------------------------------------------------------
function F_GET_OGGETTO_PRATICA
/*************************************************************************
  NOME:        F_GET_OGGETTO_PRATICA
  DESCRIZIONE: Cessazione/Variazione
               Si controlla se l'oggetto da cessare/variare e' stato
               acquisito nella stessa pratica.
               Se la ricerca fallisce, si restituisce null
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_pratica                        number
, a_oggetto                        number
) return number is
  w_oggetto_pratica                oggetti_pratica.oggetto_pratica%type;
begin
  begin
    select max(oggetto_pratica)
      into w_oggetto_pratica
      from oggetti_pratica
     where pratica = a_pratica
       and oggetto = a_oggetto
     group by pratica;
  exception
    when no_data_found then
      w_oggetto_pratica := to_number(null);
    when others then
      w_oggetto_pratica := to_number(null);
  end;
  --
  return w_oggetto_pratica;
  --
end f_get_oggetto_pratica;
----------------------------------------------------------------------------------
PROCEDURE GET_DATI_OGPR_PREC
/*************************************************************************
  NOME:        GET_DATI_OGPR_PREC
  DESCRIZIONE: Variazione
               Si ricercano i dati relativi all'ultima situazione
               dell'oggetto per il contribuente
  NOTE:
  Rev.    Date         Author      Note
  000     04/09/2018   VD          Prima emissione
**************************************************************************/
( p_oggetto                        in number
, p_tipo_tributo                   in varchar2
, p_anno                           in number
, p_cod_fiscale                    in varchar2
, p_flag_esclusione                in varchar2
, p_fonte_oggetto                  out number
, p_anno_oggetto                   out number
, p_perc_possesso_prec             out number
, p_tipo_oggetto_prec              out number
, p_categoria_prec                 out varchar2
, p_classe_prec                    out varchar2
, p_valore_prec                    out number
, p_titolo_prec                    out varchar2
, p_flag_esclusione_prec           out varchar2
, p_flag_ab_princ_prec             out varchar2
, p_cf_prec                        out varchar2
, p_ogpr_prec                      out number
, p_valore_prec_anno_dich          out number
, p_mesi_possesso_prec             out number
, p_mesi_possesso_1sem_prec        out number
, p_mesi_esclusione_prec           out number)
is
  w_anno      number;
  w_operatore varchar2(2) := '<=';
begin
  select nvl(ogpr.fonte,-1)
       , ogpr.anno
       , ogco.perc_possesso
       , ogpr.tipo_oggetto
       , ogpr.categoria_catasto
       , ogpr.classe_catasto
       , ogpr.valore
       , ogpr.titolo
       , ogco.flag_esclusione
       , ogco.flag_ab_principale
       , ogco.cod_fiscale
       , ogco.oggetto_pratica
       , f_valore(ogpr.valore,
                  ogpr.tipo_oggetto,
                  prtr.anno,
                  w_anno,
                  ogpr.categoria_catasto,
                  prtr.tipo_pratica,
                  ogpr.flag_valore_rivalutato)
       , ogco.mesi_possesso
       , ogco.mesi_possesso_1sem
       , ogco.mesi_esclusione
    into p_fonte_oggetto
       , p_anno_oggetto
       , p_perc_possesso_prec
       , p_tipo_oggetto_prec
       , p_categoria_prec
       , p_classe_prec
       , p_valore_prec
       , p_titolo_prec
       , p_flag_esclusione_prec
       , p_flag_ab_princ_prec
       , p_cf_prec
       , p_ogpr_prec
       , p_valore_prec_anno_dich
       , p_mesi_possesso_prec
       , p_mesi_possesso_1sem_prec
       , p_mesi_esclusione_prec
    from pratiche_tributo     prtr
       , oggetti_pratica      ogpr
       , oggetti_contribuente ogco
   where ogco.oggetto_pratica = ogpr.oggetto_pratica
     and ogpr.pratica = prtr.pratica
     and ogco.cod_fiscale = p_cod_fiscale
     and ogpr.oggetto = p_oggetto
     and ogco.flag_possesso = 'S'
     and nvl(ogco.flag_esclusione, 'N') =
         nvl(p_flag_esclusione,'N')
     and prtr.tipo_tributo || '' = p_tipo_tributo
     and (ogco.anno || ogco.tipo_rapporto || 'S' ||
         lpad(ogco.oggetto_pratica, 10, '0')) =
         (select max(ogco_sub.anno || ogco_sub.tipo_rapporto ||
                     ogco_sub.flag_possesso ||
                     lpad(ogco_sub.oggetto_pratica, 10, '0'))
            from pratiche_tributo     prtr_sub,
                 oggetti_pratica      ogpr_sub,
                 oggetti_contribuente ogco_sub
           where prtr_sub.tipo_tributo || '' = p_tipo_tributo
             and ((prtr_sub.tipo_pratica || '' = 'D' and
                 prtr_sub.data_notifica is null) or
                 (prtr_sub.tipo_pratica || '' = 'A' and
                 prtr_sub.data_notifica is not null and
                 nvl(prtr_sub.stato_accertamento, 'D') = 'D' and
                 nvl(prtr_sub.flag_denuncia, ' ') = 'S' and
                 ((w_operatore = '>=' and prtr_sub.anno >= w_anno) or
                 (w_operatore = '<=' and prtr_sub.anno <= w_anno) or
                 (w_operatore = '>' and prtr_sub.anno > w_anno) or
                 (w_operatore = '<' and prtr_sub.anno < w_anno) or
                 (w_operatore = '=' and prtr_sub.anno = w_anno))))
             and prtr_sub.pratica = ogpr_sub.pratica
             and ((w_operatore = '>=' and ogco_sub.anno >= w_anno) or
                 (w_operatore = '<=' and ogco_sub.anno <= w_anno) or
                 (w_operatore = '>' and ogco_sub.anno > w_anno) or
                 (w_operatore = '<' and ogco_sub.anno < w_anno) or
                 (w_operatore = '=' and ogco_sub.anno = w_anno))
             and ogco_sub.cod_fiscale = ogco.cod_fiscale
             and ogco_sub.oggetto_pratica = ogpr_sub.oggetto_pratica
             and ogpr_sub.oggetto = ogpr.oggetto
             and ogco_sub.tipo_rapporto in ('C', 'D', 'E')
             And nvl(ogco_sub.flag_esclusione, 'N') =
                 nvl(p_flag_esclusione,'N'));
exception
  when no_data_found then
    p_ogpr_prec             := null;
  when others then
    w_errore := 'Errore GET_DATI_OGPR_PREC ' || p_oggetto || ' ' || p_tipo_tributo || ' ' ||  p_anno ||' ' || p_cod_fiscale || ' ' || p_flag_esclusione ||
                        ' (' || substr(sqlerrm, 1, 100) || ')';
    raise errore;
end get_dati_ogpr_prec;
--------------------------------------------------------------------------------
procedure INS_ANOMALIE_CAR
/*************************************************************************
  NOME:        INS_ANOMALIE_CAR
  DESCRIZIONE: Inserimento riga in tabella ANOMALIE_CARICAMENTO
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_documento_id         number
, a_oggetto              number
, a_descrizione          varchar2
, a_dati_oggetto         varchar2
, a_cod_fiscale          varchar2
, a_cognome              varchar2
, a_note                 varchar2  default null
) is
  begin
    begin
      insert into anomalie_caricamento ( documento_id
                                       , oggetto
                                       , descrizione
                                       , dati_oggetto
                                       , cod_fiscale
                                       , cognome
                                       , note
                                       )
      values ( a_documento_id
             , a_oggetto
             , a_descrizione
             , a_dati_oggetto
             , a_cod_fiscale
             , a_cognome
             , a_note
             );
    exception
      when others then
        w_errore := 'Errore in inserimento anomalie_caricamento soggetto: '
                 || a_cod_fiscale
                 || ' ('
                 || sqlerrm
                 || ')';
        raise errore;
    end;
    w_conta_anomalie_car := w_conta_anomalie_car + 1;
  end;
--------------------------------------------------------------------------------
procedure INS_ANOMALIE_ICI
/*************************************************************************
  NOME:        INS_ANOMALIE_ICI
  DESCRIZIONE: Inserimento riga in tabella ANOMALIE_ICI
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_anno                           number
, a_cod_fiscale                    varchar2
, a_data_variazione                date
, a_flag_ok                        varchar2
, a_note                           varchar2
, a_oggetto                        number
, a_tipo_anomalia                  number
) is
  begin
    begin
      insert into anomalie_ici ( anno
                               , cod_fiscale
                               , data_variazione
                               , flag_ok
                               , note
                               , oggetto
                               , tipo_anomalia
                               )
      values ( a_anno
             , a_cod_fiscale
             , a_data_variazione
             , a_flag_ok
             , a_note
             , a_oggetto
             , a_tipo_anomalia
             );
    exception
      when others then
        w_errore := 'Errore in inserimento anomalie_ici soggetto: '
                 || a_cod_fiscale
                 || ' ('
                 || sqlerrm
                 || ')';
        raise errore;
    end;
    w_conta_anomalie_ici := w_conta_anomalie_ici + 1;
  end;
--------------------------------------------------------------------------------
procedure INS_DATI_PRATICA
/*************************************************************************
  NOME:        INS_DATI_PRATICA
  DESCRIZIONE: Inserimento dati della pratica:
               PRATICHE_TRIBUTO
               RAPPORTI_TRIBUTO
               DENUNCE_ICI/DENUNCE_TASI (a seconda del tipo tributo)
  NOTE:
  Rev.    Date         Author      Note
  002     07/11/2018   VD          Corretta gestione flag firma: mentre
                                   nel file il flag attivo significa che
                                   la dichiarazione e' stata firmata, in
                                   TR4 significa l'esatto contrario.
                                   Quindi se il flag sul file è = 1, NON
                                   si attiva il flag sulle tabelle
                                   DENUNCE_ICI/DENUNCE_TASI.
  001     08/10/2018   VD          Eliminata gestione tabelle aggiuntive
                                   (i dati vengono visualizzati direttamente
                                   dalle tabelle WRK)
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_documento_id                   wrk_enc_testata.documento_id%type
, a_progr_dichiarazione            wrk_enc_testata.progr_dichiarazione%type
, a_pratica                        pratiche_tributo.pratica%type
, a_cod_fiscale                    pratiche_tributo.cod_fiscale%type
, a_tipo_tributo                   pratiche_tributo.tipo_tributo%type
, a_anno                           pratiche_tributo.anno%type
, a_tipo_pratica                   pratiche_tributo.tipo_pratica%type
, a_tipo_evento                    pratiche_tributo.tipo_evento%type
, a_data                           pratiche_tributo.data%type
, a_utente                         pratiche_tributo.utente%type
, a_data_variazione                pratiche_tributo.data_variazione%type
, a_note                           pratiche_tributo.note%type
, a_firma_dichiarante              wrk_enc_testata.firma_dichiarazione%type
, a_fonte                          number
/*, a_imu_dovuto                     number
, a_eccedenza_imu_dic_prec         number
, a_eccedenza_imu_dic_prec_f24     number
, a_rate_imu_versate               number
, a_imu_debito                     number
, a_imu_credito                    number
, a_imu_credito_dic_presente       number
, a_credito_imu_rimborso           number
, a_credito_imu_compensazione      number
, a_tasi_dovuto                    number
, a_eccedenza_tasi_dic_prec        number
, a_eccedenza_tasi_dic_prec_f24    number
, a_rate_tasi_versate              number
, a_tasi_debito                    number
, a_tasi_credito                   number
, a_tasi_credito_dic_presente      number
, a_credito_tasi_rimborso          number
, a_credito_tasi_compensazione     number */
, a_codice_tracciato                 wrk_enc_testata.codice_tracciato%type
) is
begin
  begin
    insert into pratiche_tributo
              ( pratica,
                cod_fiscale,
                tipo_tributo,
                anno,
                tipo_pratica,
                tipo_evento,
                data,
                documento_id,
                utente,
                data_variazione,
                note
              )
    values ( a_pratica
           , a_cod_fiscale
           , a_tipo_tributo
           , a_anno
           , a_tipo_pratica
           , a_tipo_evento
           , a_data
           , a_documento_id
           , a_utente
           , a_data_variazione
           , nvl(a_note,'Caricamento dich. '||a_codice_tracciato)
           );
  exception
    when others then
      w_errore := 'Errore in inserimento nuova pratica ' ||
                  f_descrizione_titr(a_tipo_tributo,a_anno) ||
                  ' - C.f. '|| a_cod_fiscale ||
                  ' (' || sqlerrm || ')';
      raise errore;
  end;
  --
  -- Inserimento tabella RAPPORTI_TRIBUTO
  --
  begin
    insert into rapporti_tributo
              ( pratica
              , cod_fiscale
              , tipo_rapporto
              )
    values ( a_pratica
           , a_cod_fiscale
           , 'D'
           );
  exception
    when others then
      w_errore := 'Errore in inserimento rapporto tributo ' ||
                  f_descrizione_titr(a_tipo_tributo,
                                     a_anno) || ' (' ||
                  sqlerrm || ')';
      raise errore;
  end;
  --
  -- Inserimento DENUNCE_ICI/DENUNCE_TASI
  --
  -- (VD - 08/10/2018): eliminata gestione tabelle aggiuntive.
  --                    I dati presenti solo in denuncia
  --                    verranno visualizzati dalle tabelle WRK.
  if a_tipo_tributo = 'ICI' then
     begin
       insert into denunce_ici
                 ( pratica
                 , denuncia
                 , flag_firma
                 , fonte
                 , utente
                 , data_variazione
                 /*, imu_dovuta
                 , eccedenza_imu_dic_prec
                 , eccedenza_imu_dic_prec_f24
                 , rate_imu_versate
                 , imu_debito
                 , imu_credito
                 , imu_credito_dic_presente
                 , credito_imu_rimborso
                 , credito_imu_compensazione */
                 )
       values ( a_pratica
              , a_pratica
              -- (VD - 07/11/2018): corretto flag firma dichiarazione:
              --, decode(a_firma_dichiarante,1,'S',null)
              , decode(a_firma_dichiarante,1,null,'S')
              , a_fonte
              , a_utente
              , a_data_variazione
              /*, a_imu_dovuto
              , a_eccedenza_imu_dic_prec
              , a_eccedenza_imu_dic_prec_f24
              , a_rate_imu_versate
              , a_imu_debito
              , a_imu_credito
              , a_imu_credito_dic_presente
              , a_credito_imu_rimborso
              , a_credito_imu_compensazione */
              );
     exception
       when others then
         w_errore := 'Errore in inserimento denunce_ici ' || ' (' ||
                     sqlerrm || ')';
         raise errore;
     end;
  else
     begin
       insert into denunce_tasi
                   ( pratica
                   , denuncia
                   , flag_firma
                   , fonte
                   , utente
                   , data_variazione
                   /*, tasi_dovuta
                   , eccedenza_tasi_dic_prec
                   , eccedenza_tasi_dic_prec_f24
                   , rate_tasi_versate
                   , tasi_debito
                   , tasi_credito
                   , tasi_credito_dic_presente
                   , credito_tasi_rimborso
                   , credito_tasi_compensazione */
                   )
       values ( a_pratica
              , a_pratica
              -- (VD - 07/11/2018): corretto flag firma dichiarazione:
              --, decode(a_firma_dichiarante,1,'S',null)
              , decode(a_firma_dichiarante,1,null,'S')
              , a_fonte
              , a_utente
              , a_data_variazione
              /*, a_tasi_dovuto
              , a_eccedenza_tasi_dic_prec
              , a_eccedenza_tasi_dic_prec_f24
              , a_rate_tasi_versate
              , a_tasi_debito
              , a_tasi_credito
              , a_tasi_credito_dic_presente
              , a_credito_tasi_rimborso
              , a_credito_tasi_compensazione */
              );
     exception
       when others then
         w_errore := 'Errore in inserimento denunce_tasi ' || ' (' ||
                     sqlerrm || ')';
         raise errore;
     end;
  end if;
  --
  -- Si aggiorna il numero della pratica sulla testata della dichiazione
  --
  begin
    update wrk_enc_testata
       set tr4_pratica_ici  = decode(a_tipo_tributo,'ICI',a_pratica,tr4_pratica_ici)
         , tr4_pratica_tasi = decode(a_tipo_tributo,'TASI',a_pratica,tr4_pratica_tasi)
     where documento_id = a_documento_id
       and progr_dichiarazione = a_progr_dichiarazione;
  exception
    when others then
      w_errore := 'Errore in aggiornamento wrk_enc_testata - progr. ' ||
                   a_progr_dichiarazione || ' (' ||
                  sqlerrm || ')';
      raise errore;
  end;
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
--------------------------------------------------------------------------------
procedure INS_DATI_OGGETTO_CONTRIBUENTE
/*************************************************************************
  NOME:        INS_DATI_OGGETTO_CONTRIBUENTE
  DESCRIZIONE: Inserimento dati del contribuente:
               OGGETTI_CONTRIBUENTE
               RAPPORTI_TRIBUTO
  NOTE:
  Rev.    Date         Author      Note
  000     05/04/2023   VM          Prima emissione
**************************************************************************/
( a_cod_fiscale                    oggetti_contribuente.cod_fiscale%type
, a_oggetto_pratica                oggetti_pratica.oggetto_pratica%type
, a_anno                           oggetti_pratica.anno%type
, a_tipo_rapporto                  oggetti_contribuente.tipo_rapporto%type
, a_perc_possesso                  oggetti_contribuente.perc_possesso%type
, a_mesi_possesso                  oggetti_contribuente.mesi_possesso%type
, a_mesi_possesso_1sem             oggetti_contribuente.mesi_possesso_1sem%type
, a_da_mese_possesso               oggetti_contribuente.da_mese_possesso%type
, a_mesi_esclusione                oggetti_contribuente.mesi_esclusione%type
, a_flag_possesso                  oggetti_contribuente.flag_possesso%type
, a_flag_esclusione                oggetti_contribuente.flag_esclusione%type
, a_detrazione                     oggetti_contribuente.detrazione%type
, a_utente                         oggetti_pratica.utente%type
, a_data_variazione                oggetti_pratica.data_variazione%type
, a_tipo_tributo                   pratiche_tributo.tipo_tributo%type
, a_pratica                        pratiche_tributo.pratica%type
, a_data_evento                    oggetti_contribuente.data_evento%type
)
is
begin
  --
  -- Inserimento oggetti_contribuente
  --
  begin
    insert into oggetti_contribuente
              ( cod_fiscale
              , oggetto_pratica
              , anno
              , tipo_rapporto
              , perc_possesso
              , mesi_possesso
              , mesi_possesso_1sem
              , da_mese_possesso
              , mesi_esclusione
              , flag_possesso
              , flag_esclusione
              , detrazione
              , utente
              , data_variazione
              , data_evento
              )
    values ( a_cod_fiscale
           , a_oggetto_pratica
           , a_anno
           , a_tipo_rapporto
           , a_perc_possesso
           , a_mesi_possesso
           , a_mesi_possesso_1sem
           , a_da_mese_possesso
           , a_mesi_esclusione
           , a_flag_possesso
           , a_flag_esclusione
           , a_detrazione
           , a_utente
           , a_data_variazione
           , a_data_evento
           );
  exception
    when others then
      w_errore := 'Errore in inserim. oggetti_contribuente ' ||
                  f_descrizione_titr(a_tipo_tributo,a_anno) ||
                  a_cod_fiscale || ' (' || sqlerrm || ')';
      raise errore;
  end;
  --
  -- Inserimento tabella RAPPORTI_TRIBUTO
  --
  begin
      insert into rapporti_tributo
      ( pratica
      , cod_fiscale
      , tipo_rapporto
      )
      values ( a_pratica
             , a_cod_fiscale
             , a_tipo_rapporto
             );
  exception
      when dup_val_on_index then
          null; -- ignora se il rapporto tributo esiste già
      when others then
          w_errore := 'Errore in inserimento rapporto tributo '|| a_tipo_rapporto || ' ' ||
                      f_descrizione_titr(a_tipo_tributo,
                                         a_anno) || ' (' ||
                      sqlerrm || ')';
          raise errore;
  end;
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
--------------------------------------------------------------------------------
procedure INS_DATI_OGGETTO_PRATICA
/*************************************************************************
  NOME:        INS_DATI_OGGETTO_PRATICA
  DESCRIZIONE: Inserimento dati della pratica:
               PRATICHE_TRIBUTO
               RAPPORTI_TRIBUTO
               DENUNCE_ICI/DENUNCE_TASI (a seconda del tipo tributo)
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
  001     08/10/2018   VD          Eliminata gestione tabelle aggiuntive
                                   (i dati vengono visualizzati direttamente
                                   dalle tabelle WRK)
**************************************************************************/
( a_documento_id                   wrk_enc_immobili.documento_id%type
, a_progr_dichiarazione            wrk_enc_immobili.progr_dichiarazione%type
, a_tipo_immobile                  wrk_enc_immobili.tipo_immobile%type
, a_progr_immobile                 wrk_enc_immobili.progr_immobile%type
, a_num_ordine                     wrk_enc_immobili.num_ordine%type
, a_tipo_attivita                  wrk_enc_immobili.tipo_attivita%type
, a_detrazione                     wrk_enc_immobili.detrazione%type
, a_tipo_tributo                   pratiche_tributo.tipo_tributo%type
, a_cod_fiscale                    oggetti_contribuente.cod_fiscale%type
, a_oggetto_pratica                oggetti_pratica.oggetto_pratica%type
, a_oggetto                        oggetti_pratica.oggetto%type
, a_tipo_oggetto                   oggetti_pratica.tipo_oggetto%type
, a_pratica                        oggetti_pratica.pratica%type
, a_anno                           oggetti_pratica.anno%type
, a_categoria_catasto              oggetti_pratica.categoria_catasto%type
, a_classe_catasto                 oggetti_pratica.classe_catasto%type
, a_tipo_qualita                   oggetti_pratica.tipo_qualita%type
, a_valore                         oggetti_pratica.valore%type
, a_titolo                         oggetti_pratica.titolo%type
, a_estremi_titolo                 oggetti_pratica.estremi_titolo%type
, a_fonte                          oggetti_pratica.fonte%type
, a_tipo_rapporto                  oggetti_contribuente.tipo_rapporto%type
, a_perc_possesso                  oggetti_contribuente.perc_possesso%type
, a_mesi_possesso                  oggetti_contribuente.mesi_possesso%type
, a_mesi_possesso_1sem             oggetti_contribuente.mesi_possesso_1sem%type
, a_da_mese_possesso               oggetti_contribuente.da_mese_possesso%type
, a_mesi_esclusione                oggetti_contribuente.mesi_esclusione%type
, a_flag_possesso                  oggetti_contribuente.flag_possesso%type
, a_flag_esclusione                oggetti_contribuente.flag_esclusione%type
, a_utente                         oggetti_pratica.utente%type
, a_data_variazione                oggetti_pratica.data_variazione%type
, a_note                           oggetti_pratica.note%type
, d_corrispettivo_medio            number default null
, d_costo_medio                    number default null
, d_rapporto_superficie            number default null
, d_rapporto_sup_gg                number default null
, d_rapporto_soggetti              number default null
, d_rapporto_sogg_gg               number default null
, d_rapporto_giorni                number default null
, d_perc_imponibilita              number default null
, d_valore_ass_art_5               number default null
, d_valore_ass_art_4               number default null
, d_casella_rigo_g                 number default null
, d_casella_rigo_h                 number default null
, d_rapporto_cms_cm                number default null
, d_valore_ass_parziale            number default null
, d_valore_ass_compl               number default null
, a_corrispettivo_medio_perc       number default null
, a_corrispettivo_medio_prev       number default null
, a_rapporto_superficie            number default null
, a_rapporto_sup_gg                number default null
, a_rapporto_soggetti              number default null
, a_rapporto_sogg_gg               number default null
, a_rapporto_giorni                number default null
, a_perc_imponibilita              number default null
, a_valore_assoggettato            number default null
, a_codice_tracciato               wrk_enc_testata.codice_tracciato%type
, a_data_evento                    oggetti_contribuente.data_evento%type
)
is
begin
  begin
    insert into oggetti_pratica
                      ( oggetto_pratica
                      , oggetto
                      , tipo_oggetto
                      , pratica
                      , anno
                      , num_ordine
                      , categoria_catasto
                      , classe_catasto
                      , tipo_qualita
                      , valore
                      , titolo
                      , estremi_titolo
                      , fonte
                      , utente
                      , data_variazione
                      , note
                      )
    values ( a_oggetto_pratica
           , a_oggetto
           , a_tipo_oggetto
           , a_pratica
           , a_anno
           , a_num_ordine
           , a_categoria_catasto
           , a_classe_catasto
           , a_tipo_qualita
           , decode(a_tipo_immobile
                   ,'A',a_valore
                       ,decode(
                               decode(a_tipo_attivita,10,decode(nvl(d_valore_ass_parziale,0)
                                                               ,0,d_valore_ass_compl
                                                                 ,d_valore_ass_parziale
                                                               )
                                                        ,a_valore_assoggettato
                                     )
                              ,0,a_valore
                                ,decode(a_tipo_attivita,10,decode(nvl(d_valore_ass_parziale,0)
                                                                 ,0,d_valore_ass_compl
                                                                   ,d_valore_ass_parziale
                                                                 )
                                                          ,a_valore_assoggettato
                                       )
                              )
                   )
           , a_titolo
           , a_estremi_titolo
           , a_fonte
           , a_utente
           , a_data_variazione
           --, nvl(a_note,'Da caricamento dichiarazione ENC')
           , a_note||decode(a_note,'','',' - ')||'Da caricamento dichiarazione '|| a_codice_tracciato
           );
  exception
    when others then
      w_errore := 'Errore in inserimento oggetti_pratica doppio quadro ' ||
                  f_descrizione_titr(a_tipo_tributo,a_anno) || ' '||
                  a_cod_fiscale || ' Tipo_oggetto: '||
                  a_tipo_oggetto || ' (' || sqlerrm || ')';
      raise errore;
  end;
  --
  -- Inserimento proprietario
  --
  ins_dati_oggetto_contribuente( a_cod_fiscale
                               , a_oggetto_pratica
                               , a_anno
                               , a_tipo_rapporto
                               , a_perc_possesso
                               , a_mesi_possesso
                               , a_mesi_possesso_1sem
                               , a_da_mese_possesso
                               , a_mesi_esclusione
                               , a_flag_possesso
                               , a_flag_esclusione
                               , a_detrazione
                               , a_utente
                               , a_data_variazione
                               , a_tipo_tributo
                               , a_pratica
                               , a_data_evento
                               );
  --
  -- Inserimento tabella aggiuntiva oggetti pratica (OGGETTI_ICI_ENC/OGGETTI_TASI_ENC)
  -- (VD - 04/09/2018): si inseriscono i record solo se almeno uno dei dati da memorizzare
  --                    e' valorizzato
  -- (VD - 08/10/2018): eliminata gestione tabelle aggiuntive.
  --                    I dati della dichiarazione verranno visualizzati direttamente
  --                    dalle tabelle WRK
  --
  /*if d_corrispettivo_medio      is not null or
     d_costo_medio              is not null or
     d_rapporto_superficie      is not null or
     d_rapporto_sup_gg          is not null or
     d_rapporto_soggetti        is not null or
     d_rapporto_sogg_gg         is not null or
     d_rapporto_giorni          is not null or
     d_perc_imponibilita        is not null or
     d_valore_ass_art_5         is not null or
     d_valore_ass_art_4         is not null or
     d_casella_rigo_g           is not null or
     d_casella_rigo_h           is not null or
     d_rapporto_cms_cm          is not null or
     d_valore_ass_parziale      is not null or
     d_valore_ass_compl         is not null or
     a_corrispettivo_medio_perc is not null or
     a_corrispettivo_medio_prev is not null or
     a_rapporto_superficie      is not null or
     a_rapporto_sup_gg          is not null or
     a_rapporto_soggetti        is not null or
     a_rapporto_sogg_gg         is not null or
     a_rapporto_giorni          is not null or
     a_perc_imponibilita        is not null or
     a_valore_assoggettato      is not null then
     if a_tipo_tributo = 'ICI' then
        begin
          insert into oggetti_ici_enc
                    ( oggetto_pratica
                    , documento_id
                    , progr_dichiarazione
                    , tipo_attivita
                    , d_corrispettivo_medio
                    , d_costo_medio
                    , d_rapporto_superficie
                    , d_rapporto_sup_gg
                    , d_rapporto_soggetti
                    , d_rapporto_sogg_gg
                    , d_rapporto_giorni
                    , d_perc_imponibilita
                    , d_valore_ass_art_5
                    , d_valore_ass_art_4
                    , d_casella_rigo_g
                    , d_casella_rigo_h
                    , d_rapporto_cms_cm
                    , d_valore_ass_parziale
                    , d_valore_ass_compl
                    , a_corrispettivo_medio_perc
                    , a_corrispettivo_medio_prev
                    , a_rapporto_superficie
                    , a_rapporto_sup_gg
                    , a_rapporto_soggetti
                    , a_rapporto_sogg_gg
                    , a_rapporto_giorni
                    , a_perc_imponibilita
                    , a_valore_assoggettato
                    )
           values ( w_oggetto_pratica
                  , a_documento_id
                  , a_progr_dichiarazione
                  , a_tipo_attivita
                  , d_corrispettivo_medio
                  , d_costo_medio
                  , d_rapporto_superficie
                  , d_rapporto_sup_gg
                  , d_rapporto_soggetti
                  , d_rapporto_sogg_gg
                  , d_rapporto_giorni
                  , d_perc_imponibilita
                  , d_valore_ass_art_5
                  , d_valore_ass_art_4
                  , d_casella_rigo_g
                  , d_casella_rigo_h
                  , d_rapporto_cms_cm
                  , d_valore_ass_parziale
                  , d_valore_ass_compl
                  , a_corrispettivo_medio_perc
                  , a_corrispettivo_medio_prev
                  , a_rapporto_superficie
                  , a_rapporto_sup_gg
                  , a_rapporto_soggetti
                  , a_rapporto_sogg_gg
                  , a_rapporto_giorni
                  , a_perc_imponibilita
                  , a_valore_assoggettato
                  );
        exception
          when others then
            w_errore := 'Errore in inserim. OGGETTI_'||a_tipo_tributo||'_ENC ' ||
                        f_descrizione_titr(a_tipo_tributo,a_anno) || ' ' ||
                        a_cod_fiscale || ' (' || sqlerrm || ')';
            raise errore;
        end;
     else
        begin
          insert into oggetti_tasi_enc
                    ( oggetto_pratica
                    , documento_id
                    , progr_dichiarazione
                    , d_corrispettivo_medio
                    , d_costo_medio
                    , d_rapporto_superficie
                    , d_rapporto_sup_gg
                    , d_rapporto_soggetti
                    , d_rapporto_sogg_gg
                    , d_rapporto_giorni
                    , d_perc_imponibilita
                    , d_valore_ass_art_5
                    , d_valore_ass_art_4
                    , d_casella_rigo_g
                    , d_casella_rigo_h
                    , d_rapporto_cms_cm
                    , d_valore_ass_parziale
                    , d_valore_ass_compl
                    , a_corrispettivo_medio_perc
                    , a_corrispettivo_medio_prev
                    , a_rapporto_superficie
                    , a_rapporto_sup_gg
                    , a_rapporto_soggetti
                    , a_rapporto_sogg_gg
                    , a_rapporto_giorni
                    , a_perc_imponibilita
                    , a_valore_assoggettato
                    )
           values ( w_oggetto_pratica
                  , a_documento_id
                  , a_progr_dichiarazione
                  , d_corrispettivo_medio
                  , d_costo_medio
                  , d_rapporto_superficie
                  , d_rapporto_sup_gg
                  , d_rapporto_soggetti
                  , d_rapporto_sogg_gg
                  , d_rapporto_giorni
                  , d_perc_imponibilita
                  , d_valore_ass_art_5
                  , d_valore_ass_art_4
                  , d_casella_rigo_g
                  , d_casella_rigo_h
                  , d_rapporto_cms_cm
                  , d_valore_ass_parziale
                  , d_valore_ass_compl
                  , a_corrispettivo_medio_perc
                  , a_corrispettivo_medio_prev
                  , a_rapporto_superficie
                  , a_rapporto_sup_gg
                  , a_rapporto_soggetti
                  , a_rapporto_sogg_gg
                  , a_rapporto_giorni
                  , a_perc_imponibilita
                  , a_valore_assoggettato
                  );
        exception
          when others then
            w_errore := 'Errore in inserim. OGGETTI_'||a_tipo_tributo||'_ENC ' ||
                        f_descrizione_titr(a_tipo_tributo,a_anno) || ' ' ||
                        a_cod_fiscale || ' (' || sqlerrm || ')';
            raise errore;
        end;
     end if;
  end if; */
  --
  -- Si aggiorna l'oggetto_pratica sulla tabella wrk_enc_immobili
  --
  if a_documento_id is not null then
     begin
       update wrk_enc_immobili
          set tr4_oggetto_pratica_ici  = decode(a_tipo_tributo,'ICI',a_oggetto_pratica,tr4_oggetto_pratica_ici)
            , tr4_oggetto_pratica_tasi = decode(a_tipo_tributo,'ICI',tr4_oggetto_pratica_tasi,a_oggetto_pratica)
        where documento_id        = a_documento_id
          and progr_dichiarazione = a_progr_dichiarazione
          and tipo_immobile       = a_tipo_immobile
          and progr_immobile      = a_progr_immobile
          and num_ordine          = a_num_ordine;
     exception
       when others then
         w_errore := 'Errore in aggiornamento wrk_enc_immobili - progr. ' ||
                      a_progr_dichiarazione || '/' || a_tipo_immobile ||
                      '/' || a_progr_immobile ||
                      ' (' || sqlerrm || ')';
         raise errore;
     end;
  end if;
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
--------------------------------------------------------------------------------
procedure CARICA_DICHIARAZIONI
/*************************************************************************
  NOME:        CARICA_DICHIARAZIONI
  DESCRIZIONE: Carica i dati delle dichiarazioni IMU/TASI degli enti
               non commerciali nelle tabelle di appoggio
  NOTE:
  Rev.    Date         Author      Note
  007     02/08/2023   VM          #65574 - Aggiunte differenze tracciato ENC 2023 ver 1
  006     01/08/2023   VM          #65574 - Scelta versione tracciato ECPF in base alla data della dichiarazione
  005     01/08/2023   VM          #65574 - Scelta versione tracciato ENC in base alla data della dichiarazione
  004     21/07/2023   VM          #65574 - Fix su gestione delle diverse versioni flusso Enti Commerciali
  003     03/04/2023   VM          #54857 - Gestione nuovo flusso Enti Commerciali e delle Persone Fisiche
  002     19/05/2022   VD          Modificato test su stato di documenti_caricati.
                                   Per gestire l'avanzamento dell'elaborazione da
                                   Tributiweb ora bisogna trattare gli stati 1 e 15.
  001     20/12/2021   VD          Correzione tracciato record immobili
                                   per denunce fatte in anni > 2015:
                                   manca il campo "immobile inagibile/
                                   non abiltabile". Corretta seleziona dati
                                   in attesa di nuovo campo sulla tabella.
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
  ( a_documento_id            number
  , a_utente                  varchar2
  , a_messaggio        in out varchar2
  ) is
  w_commenti                  number := 1;
  w_comune_dage               varchar2(6);
  -- Variabili per gestione Blob/Clob
  w_documento_blob            blob;
  w_documento_clob            clob;
  dest_offset                 number := 1;
  src_offset                  number := 1;
  amount                      integer := DBMS_LOB.lobmaxsize;
  blob_csid                   number  := DBMS_LOB.default_csid;
  lang_ctx                    integer := DBMS_LOB.default_lang_ctx;
  warning                     integer;
  w_stato                     number;
  w_nome_documento            documenti_caricati.nome_documento%type;
  w_dimensione_file           number;
  w_posizione                 number;
  w_posizione_old             number;
  w_inizio                    number;
  w_progr_dichiarazione       number;
  w_anno_dich                 number;
  w_progr_imm_a               number;
  w_progr_imm_b               number;
  w_lunghezza_ele             number;
  w_posizione_tipo            number;
  w_cod_comune                varchar2(4);
  w_cf_dichiarante            varchar2(16);
  w_tipo_attivita             number;
  w_tipo_tracciato            varchar(4);       -- Tipo tracciato:
                                                --      ENC (Enti non Commerciali)
                                                --      ECPF (Enti Commerciali e delle Persone Fisiche)
  w_anno_imposta              number;
  w_denominazione             varchar(60);
  w_nome                      varchar(60);
  w_telefono                  varchar(12);
  w_email                     varchar(50);
  w_indirizzo                 varchar(35);
  w_num_civ                   varchar(5);
  w_scala                     varchar(5);
  w_piano                     varchar(5);
  w_interno                   varchar(5);
  w_cap                       varchar(5);
  w_comune                    varchar(100);
  w_provincia                 varchar(2);
  w_num_immobili_a            number;
  w_num_immobili_b            number;
  w_firma_dichiarante         varchar(1);
  w_progr_contitolare         number;
  w_progr_immobile            number;
  w_num_ordine                number;
  w_cf_contribuente           varchar2(16);
  w_testata_exists            number;
  w_caratteristica             varchar2(3);
  w_indirizzo_imm              varchar2(100);
  w_tipo                       varchar2(1);
  w_cod_catastale              varchar2(5);
  w_sezione                    varchar2(3);
  w_foglio                     varchar2(4);
  w_numero                     varchar2(10);
  w_subalterno                 varchar2(4);
  w_categoria_catasto          varchar2(25);
  w_classe_catasto             varchar2(10);
  w_protocollo_catasto         varchar2(20);
  w_anno_catasto               varchar2(4);
  w_immobile_storico           number;
  w_valore                     number;
  w_perc_possesso              number;
  w_data_var_imposta           varchar2(8);
  w_flag_acquisto              number;
  w_flag_cessione              number;
  w_agenzia_entrate            varchar2(24);
  w_estremi_titolo             varchar2(24);
  w_annotazioni                varchar2(500);
  w_data_variazione            date;
  w_progr_immobile_dich        number;
  w_ind_continuita             number;
  w_flag_altro                 number;
  w_descrizione_altro          varchar2(100);
  w_immobile_esente            number;
  w_d_corrispettivo_medio      number;
  w_d_costo_medio              number;
  w_d_rapporto_superficie      number;
  w_d_rapporto_sup_gg          number;
  w_d_rapporto_soggetti        number;
  w_d_rapporto_sogg_gg         number;
  w_d_rapporto_giorni          number;
  w_d_perc_imponibilita        number;
  w_d_valore_ass_art_5         number;
  w_d_valore_ass_art_4         number;
  w_d_casella_rigo_g           number;
  w_d_casella_rigo_h           number;
  w_d_rapporto_cms_cm          number;
  w_d_valore_ass_parziale      number;
  w_d_valore_ass_compl         number;
  w_a_corrispettivo_medio_perc number;
  w_a_corrispettivo_medio_prev number;
  w_a_rapporto_superficie      number;
  w_a_rapporto_sup_gg          number;
  w_a_rapporto_soggetti        number;
  w_a_rapporto_sogg_gg         number;
  w_a_rapporto_giorni          number;
  w_a_perc_imponibilita        number;
  w_a_valore_assoggettato      number;
  w_data_dichiarazione         date;
  /*
     TODO: per maggiore chiarezza si dovrebbe riportare in nota l'equivalende della versione
           del tracciato come fatto per la co_data_tracc_ecpf_v6
  */
  co_data_tracc_enc_2014_v1    constant date := to_date('04-08-2014','DD-MM-YYYY');
  co_data_tracc_enc_2014_v2    constant date := to_date('29-09-2014','DD-MM-YYYY');
  co_data_tracc_enc_2015_v1    constant date := to_date('03-06-2015','DD-MM-YYYY');
  co_data_tracc_enc_2018_v1    constant date := to_date('10-07-2018','DD-MM-YYYY');
  co_data_tracc_enc_2019_v1    constant date := to_date('15-07-2019','DD-MM-YYYY');
  co_data_tracc_enc_2023_v1    constant date := to_date('04-05-2023','DD-MM-YYYY');
  co_data_tracc_ecpf_v4        constant date := to_date('10-07-2018','DD-MM-YYYY');
  co_data_tracc_ecpf_v5        constant date := to_date('15-07-2019','DD-MM-YYYY');
  -- Versione 3.0.0
  -- https://telematici.agenziaentrate.gov.it/Main/Avviso?id=20220907115200
  co_data_tracc_ecpf_v6        constant date := to_date('07-09-2022','DD-MM-YYYY');
  w_detrazione                 number;
  w_imu_dovuta                  number;
  w_eccedenza_imu_dic_prec      number;
  w_eccedenza_imu_dic_prec_f24  number;
  w_rate_imu_versate            number;
  w_imu_debito                  number;
  w_imu_credito                 number;
  w_tasi_dovuta                 number;
  w_eccedenza_tasi_dic_prec     number;
  w_eccedenza_tasi_dic_prec_f24 number;
  w_tasi_rate_versate           number;
  w_tasi_debito                 number;
  w_tasi_credito                number;
  w_imu_credito_dic_presente    number;
  w_credito_imu_rimborso        number;
  w_credito_imu_compensazione   number;
  w_tasi_credito_dic_presente   number;
  w_credito_tasi_rimborso       number;
  w_credito_tasi_compensazione  number;

  w_step                        number;
begin
  if w_commenti > 0 then
     DBMS_OUTPUT.Put_Line('---- Inizio ----');
  end if;
  -- Estrazione comune dati generali
  begin
     select comu.sigla_cfis
       into w_comune_dage
       from dati_generali dage
          , ad4_comuni comu
      where dage.com_cliente = comu.comune
        and dage.pro_cliente = comu.provincia_stato
          ;
  exception
   when others then
      w_errore := 'Errore in recupero comune dati_generali '||
                  ' ('||sqlerrm||')';
      raise errore;
  end;
  -- Estrazione BLOB
  begin
    select contenuto
         , stato
         , nome_documento
      into w_documento_blob
         , w_stato
         , w_nome_documento
      from documenti_caricati doca
     where doca.documento_id  = a_documento_id
    ;
  end;
  -- (VD - 19/05/2022): modificato test su stato di documenti_caricati.
  --                    Per gestire l'avanzamento dell'elaborazione da
  --                    Tributiweb ora bisogna trattare gli stati 1 e 15.
  --if w_stato = 1 then
  w_step := 1;
  if w_stato in (1,15) then
     -- Verifica dimensione file caricato
     w_dimensione_file:= DBMS_LOB.GETLENGTH(w_documento_blob);
     if nvl(w_dimensione_file,0) = 0 then
        w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
        raise errore;
     end if;
     -- Trasformazione in CLOB
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
         w_errore :=
           'Errore in trasformazione Blob in Clob  (' || sqlerrm || ')';
         raise errore;
     end;
     --
     w_contarighe          := 0;
     w_posizione_old       := 1;
     w_posizione           := 1;
     w_progr_dichiarazione := 0;
     --
     w_step := 2;
     while w_posizione < w_dimensione_file
     loop
       w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
       w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
       w_posizione_old := w_posizione + 1;
       w_contarighe    := w_contarighe + 1;
       --
       -- (VM - 01/08/2023): Le righe di 40 caratteri indicano info di testata sulla signola dichiarazione
       --
       if length(w_riga) = 40 then
         w_step := 3;
         if substr(w_riga, 1, 4) <> w_comune_dage then
           w_errore := 'Il file caricato non si riferisce all''ente';
           raise errore;
         end if;
         begin
           w_data_dichiarazione := to_date(substr(w_riga,22,6), 'YYMMDD');
         exception
           when others then
             w_errore := 'Impossibile elaborare la data della dichiarazione ('|| sqlerrm || ')';
             raise errore;
         end;
       end if;
       --
       -- (VM - 01/08/2023): Le righe di 1900 caratteri indicano i record della singola dichiarazione
       --
       if length(w_riga) = 1900 then
          --
          -- (VD - 21/09/2018): Aggiunto test sul record di testa per verificare che non
          --                    si tratti di tracciati del 2018
          -- (VD - 26/05/2022): Modificato test perché in alcuni file c'è il tipo record "0" e
          --                    non "A"
          --
          -- (AB - 13/02/2023): Aggiunti i controlli relativi al valore che puo assumere nel campo 39
          w_step := 4;
          if substr(w_riga,1,1) in ('0','A') then

            if substr(w_riga,16,5) = 'TAS00' then
             w_tipo_tracciato := 'ENC';

             if w_data_dichiarazione >= co_data_tracc_enc_2018_v1 then
              if substr(w_riga,39,1) not in ('N', 'S', 'M') then
                w_errore := 'Il file caricato e'' in formato non previsto';
                raise errore;
              end if;
             end if;

            elsif substr(w_riga,16,5) = 'TAT00' then
             w_tipo_tracciato := 'ECPF';
             if w_data_dichiarazione >= co_data_tracc_ecpf_v4 then
              if substr(w_riga,39,1) not in ('N', 'S', 'M') then
                w_errore := 'Il file caricato e'' in formato non previsto';
                raise errore;
              end if;
             end if;

            else
             w_errore := 'Il codice fornitura non e'' valido';
             raise errore;
            end if;

          end if;
          --
          -- Trattamento tipo_record "B"
          --    ENC (Enti non Commerciali):
          --        Frontespizio - Dati dichiarante
          --    ECPF (Enti Commerciali e delle Persone Fisiche):
          --        Frontespizio - Dati dichiarante
          --
          if substr(w_riga,1,1) = 'B' then
             w_step := 5;
             w_progr_dichiarazione := w_progr_dichiarazione + 1;
             w_cf_dichiarante      := rtrim(substr(w_riga,2,16));
             w_cod_comune          := substr(w_riga,98,4);
             w_anno_dich           := substr(w_riga,90,4);
             w_anno_imposta        := to_number(substr(w_riga,94,4));
             w_progr_imm_a         := 0;
             w_progr_imm_b         := 0;
             w_progr_contitolare   := 0;
             w_progr_immobile      := 0;

             if w_tipo_tracciato = 'ENC' then

               w_denominazione := rtrim(substr(w_riga,152,60));
               w_telefono      := replace(substr(w_riga,228,12),' ','');
               w_email         := rtrim(substr(w_riga,240,50));
               w_indirizzo     := rtrim(substr(w_riga,290,35));
               w_num_civ       := rtrim(substr(w_riga,325,5));
               w_scala         := rtrim(substr(w_riga,330,5));
               w_piano         := rtrim(substr(w_riga,335,5));
               w_interno       := rtrim(substr(w_riga,340,5));
               w_cap           := rtrim(substr(w_riga,345,5));
               w_comune        := rtrim(substr(w_riga,350,100));
               w_provincia     := rtrim(substr(w_riga,450,2));
               w_cf_contribuente := rtrim(substr(w_riga,212,16));

               if w_data_dichiarazione >= co_data_tracc_enc_2023_v1 then
                 w_num_immobili_a    := to_number(rtrim(substr(w_riga,678,9)));
                 w_num_immobili_b    := to_number(rtrim(substr(w_riga,696,9)));
                 w_firma_dichiarante := to_number(substr(w_riga,707,1));
               elsif w_data_dichiarazione >= co_data_tracc_enc_2015_v1 then
                 w_num_immobili_a    := to_number(rtrim(substr(w_riga,699,9)));
                 w_num_immobili_b    := to_number(rtrim(substr(w_riga,717,9)));
                 w_firma_dichiarante := to_number(substr(w_riga,728,1));
               else
                 w_num_immobili_a    := to_number(rtrim(substr(w_riga,696,9)));
                 w_num_immobili_b    := to_number(rtrim(substr(w_riga,705,9)));
                 w_firma_dichiarante := to_number(substr(w_riga,716,1));
               end if;

             elsif w_tipo_tracciato = 'ECPF' then
               w_denominazione := rtrim(substr(w_riga,230,24));
               w_nome          := rtrim(substr(w_riga,254,20));
               w_telefono      := replace(substr(w_riga,168,12),' ','');
               w_email         := rtrim(substr(w_riga,180,50));
               w_indirizzo     := rtrim(substr(w_riga,328,35));
               w_num_civ       := rtrim(substr(w_riga,363,5));
               w_scala         := rtrim(substr(w_riga,368,5));
               w_piano         := rtrim(substr(w_riga,373,5));
               w_interno       := rtrim(substr(w_riga,378,5));
               w_cap           := rtrim(substr(w_riga,383,5));
               w_comune        := rtrim(substr(w_riga,388,100));
               w_provincia     := rtrim(substr(w_riga,488,2));
               w_cf_contribuente := rtrim(substr(w_riga,152,16));

             end if;

             if w_cod_comune <> w_comune_dage then
                w_errore := 'Il file caricato non si riferisce all''ente';
                raise errore;
             end if;

             if w_cf_dichiarante <> w_cf_contribuente then
--               w_errore := 'EPCF <> cf';
--               raise errore;
               ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record B'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , 'Il CF contribuente deve essere obbligatoriamente uguale al CF soggetto dichiarante.'|| chr(13)||chr(10) || w_riga
                                  );
                 begin
                   insert into WRK_ENC_TESTATA ( documento_id
                                               , progr_dichiarazione
                                               , anno_dichiarazione
                                               , anno_imposta
                                               , cod_comune
                                               , cod_fiscale
                                               , denominazione
                                               , telefono
                                               , email
                                               , indirizzo
                                               , num_civ
                                               , scala
                                               , piano
                                               , interno
                                               , cap
                                               , comune
                                               , provincia
                                               , num_immobili_a
                                               , num_immobili_b
                                               , firma_dichiarazione
                                               , data_variazione
                                               , utente
                                               , codice_tracciato
                                               , nome
                                               )
                   values ( a_documento_id
                          , w_progr_dichiarazione
                          , w_anno_dich                            -- anno dichiarazione
                          , w_anno_imposta                         -- anno imposta
                          , w_cod_comune
                          , w_cf_dichiarante
                          , w_denominazione
                          , w_telefono
                          , w_email
                          , w_indirizzo
                          , w_num_civ
                          , w_scala
                          , w_piano
                          , w_interno
                          , w_cap
                          , w_comune
                          , w_provincia
                          , w_num_immobili_a
                          , w_num_immobili_b
                          , w_firma_dichiarante
                          , trunc(sysdate)                         -- data_variazione
                          , a_utente                               -- utente
                          , w_tipo_tracciato
                          , w_nome
                          );
                 exception
                   when others then
                     ins_anomalie_car ( a_documento_id
                                      , to_number(null)
                                      , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record B'
                                      , null
                                      , w_cf_dichiarante
                                      , null
                                      , w_riga
                                      );
                 end;
--               continue;
               goto uscita_loop;
             end if;

             --
             -- Inserimento testata dichiarazione
             --
             --
             -- (VD - 01/08/2018): Gestione tracciati diversi a seconda dell'anno di dichiarazione
             -- (VD - 10/10/2018): Aggiunto campo flag firma dichiarazione
             --
             begin
               insert into WRK_ENC_TESTATA ( documento_id
                                           , progr_dichiarazione
                                           , anno_dichiarazione
                                           , anno_imposta
                                           , cod_comune
                                           , cod_fiscale
                                           , denominazione
                                           , telefono
                                           , email
                                           , indirizzo
                                           , num_civ
                                           , scala
                                           , piano
                                           , interno
                                           , cap
                                           , comune
                                           , provincia
                                           , num_immobili_a
                                           , num_immobili_b
                                           , firma_dichiarazione
                                           , data_variazione
                                           , utente
                                           , codice_tracciato
                                           , nome
                                           )
               values ( a_documento_id
                      , w_progr_dichiarazione
                      , w_anno_dich                            -- anno dichiarazione
                      , w_anno_imposta                         -- anno imposta
                      , w_cod_comune
                      , w_cf_dichiarante
                      , w_denominazione
                      , w_telefono
                      , w_email
                      , w_indirizzo
                      , w_num_civ
                      , w_scala
                      , w_piano
                      , w_interno
                      , w_cap
                      , w_comune
                      , w_provincia
                      , w_num_immobili_a
                      , w_num_immobili_b
                      , w_firma_dichiarante
                      , trunc(sysdate)                         -- data_variazione
                      , a_utente                               -- utente
                      , w_tipo_tracciato
                      , w_nome
                      );
             exception
               when others then
                 ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record B'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
             end;
          end if;
          --
          -- Trattamento tipo_record "C"
          --    ENC (Enti non Commerciali):
          --        Quadro A - Immobili imponibili
          --    ECPF (Enti Commerciali e delle Persone Fisiche):
          --        Frontespizio - Ulteriori informazioni contitolari dichiarazione
          --
          if substr(w_riga,1,1) = 'C' then
             w_step := 6;
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "C", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;

             w_testata_exists := 0;
             select count(*)
                  into w_testata_exists
             from wrk_enc_testata wete
                  where wete.documento_id = a_documento_id
                        and wete.progr_dichiarazione = w_progr_dichiarazione;
             if w_testata_exists = 0 then
               ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tipo record C ignorato a causa di anomalie su Tipo record B'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
--               continue;
               goto uscita_loop;
             end if;

             if w_tipo_tracciato = 'ENC' then

                if w_data_dichiarazione >= co_data_tracc_enc_2023_v1 then
                  w_lunghezza_ele := 378;
                  w_posizione_tipo := 110;
                elsif w_data_dichiarazione >= co_data_tracc_enc_2018_v1 then
                  w_lunghezza_ele := 379;
                  w_posizione_tipo := 112;
                elsif w_data_dichiarazione >= co_data_tracc_enc_2015_v1 then
                  w_lunghezza_ele := 378;
                  w_posizione_tipo := 112;
                else
                  w_lunghezza_ele := 270;
                  w_posizione_tipo := 107;
                end if;
               --
               for w_ind in 1..3
               loop
                 w_inizio := 90;
                 w_inizio := w_inizio + (w_lunghezza_ele * (w_ind - 1));
                 if afc.is_numeric(substr(w_riga,w_inizio,4)) = 1 and
                    substr(w_riga,w_inizio,4) <> '0000' and
                    substr(w_riga,w_inizio + w_posizione_tipo,1) in ('U','T') then
                    w_progr_imm_a := w_progr_imm_a + 1;
                    --
                    -- Inserimento immobile imponibile
                    --
                  begin

                    w_num_ordine      := to_number(substr(w_riga,w_inizio,4));
                    w_data_variazione := trunc(sysdate);
                    w_immobile_esente := 0;

                    if w_data_dichiarazione >= co_data_tracc_enc_2015_v1 then
                      w_progr_immobile_dich := to_number(substr(w_riga,w_inizio + 4,4));
                      w_ind_continuita      := to_number(substr(w_riga,w_inizio + 8,1));

                      if w_data_dichiarazione >= co_data_tracc_enc_2023_v1 then
                        w_caratteristica      := rtrim(substr(w_riga,w_inizio + 9,1));
                        w_indirizzo_imm       := rtrim(substr(w_riga,w_inizio + 10,100));
                        w_tipo                := substr(w_riga,w_inizio + 110,1);
                        w_cod_catastale       := rtrim(substr(w_riga,w_inizio + 111,5));
                        w_sezione             := rtrim(substr(w_riga,w_inizio + 116,3));
                        w_foglio              := rtrim(substr(w_riga,w_inizio + 119,4));
                        w_numero              := rtrim(substr(w_riga,w_inizio + 123,10));
                        w_subalterno          := rtrim(substr(w_riga,w_inizio + 133,4));
                        w_categoria_catasto   := ltrim(rtrim(substr(w_riga,w_inizio + 137,25)));
                        w_classe_catasto      := rtrim(substr(w_riga,w_inizio + 162,10));
                        w_protocollo_catasto  := rtrim(substr(w_riga,w_inizio + 172,20));
                        w_anno_catasto        := rtrim(substr(w_riga,w_inizio + 192,4));
                        -- Riduzioni: 1 - Per immobile storico o artistico
                        --            2 - Per immobile inagibile/inabitabile
                        --            3 - Altre riduzioni
                        w_immobile_storico    := case when (rtrim(substr(w_riga,w_inizio + 196,1)) = '1') then 1 else 0 end;
                        w_immobile_esente     := case when (rtrim(substr(w_riga,w_inizio + 217,1)) = '1' or rtrim(substr(w_riga,w_inizio + 329,1)) = '1') then 1 else 0 end;
                        w_valore              := to_number(rtrim(substr(w_riga,w_inizio + 197,15)));
                        w_perc_possesso       := to_number(rtrim(substr(w_riga,w_inizio + 212,5))) / 100;
                        w_data_var_imposta    := substr(w_riga,w_inizio + 218,8);
                        w_flag_acquisto       := to_number(rtrim(substr(w_riga,w_inizio + 226,1)));
                        w_flag_cessione       := to_number(rtrim(substr(w_riga,w_inizio + 227,1)));
                        w_flag_altro          := to_number(rtrim(substr(w_riga,w_inizio + 228,1)));
                        w_descrizione_altro   := rtrim(substr(w_riga,w_inizio + 229,100));
                        w_agenzia_entrate     := rtrim(substr(w_riga,w_inizio + 330,24));
                        w_estremi_titolo      := rtrim(substr(w_riga,w_inizio + 354,24));
                        w_annotazioni        := case when (w_ind=1) then rtrim(substr(w_riga,1224,500)) else '' end;
                      else
                        w_caratteristica      := rtrim(substr(w_riga,w_inizio + 9,3));
                        w_indirizzo_imm       := rtrim(substr(w_riga,w_inizio + 12,100));
                        w_tipo                := substr(w_riga,w_inizio + 112,1);
                        w_cod_catastale       := rtrim(substr(w_riga,w_inizio + 113,5));
                        w_sezione             := rtrim(substr(w_riga,w_inizio + 118,3));
                        w_foglio              := rtrim(substr(w_riga,w_inizio + 121,4));
                        w_numero              := rtrim(substr(w_riga,w_inizio + 125,10));
                        w_subalterno          := rtrim(substr(w_riga,w_inizio + 135,4));
                        w_categoria_catasto   := ltrim(rtrim(substr(w_riga,w_inizio + 139,25)));
                        w_classe_catasto      := rtrim(substr(w_riga,w_inizio + 164,10));
                        w_protocollo_catasto  := rtrim(substr(w_riga,w_inizio + 174,20));
                        w_anno_catasto        := rtrim(substr(w_riga,w_inizio + 194,4));
                        w_immobile_storico    := to_number(rtrim(substr(w_riga,w_inizio + 198,1)));

                        if w_data_dichiarazione >= co_data_tracc_enc_2018_v1 then
                          w_valore              := to_number(rtrim(substr(w_riga,w_inizio + 200,15)));
                          w_perc_possesso       := to_number(rtrim(substr(w_riga,w_inizio + 215,5))) / 100;
                          w_data_var_imposta    := substr(w_riga,w_inizio + 220,8);
                          w_flag_acquisto       := to_number(rtrim(substr(w_riga,w_inizio + 228,1)));
                          w_flag_cessione       := to_number(rtrim(substr(w_riga,w_inizio + 229,1)));
                          w_flag_altro          := to_number(rtrim(substr(w_riga,w_inizio + 230,1)));
                          w_descrizione_altro   := rtrim(substr(w_riga,w_inizio + 231,100));
                          w_agenzia_entrate     := rtrim(substr(w_riga,w_inizio + 331,24));
                          w_estremi_titolo      := rtrim(substr(w_riga,w_inizio + 355,24));
                          w_annotazioni        := case when (w_ind=1) then rtrim(substr(w_riga,1227,500)) else '' end;
                        else
                          w_valore              := to_number(rtrim(substr(w_riga,w_inizio + 199,15)));
                          w_perc_possesso       := to_number(rtrim(substr(w_riga,w_inizio + 214,5))) / 100;
                          w_data_var_imposta    := substr(w_riga,w_inizio + 219,8);
                          w_flag_acquisto       := to_number(rtrim(substr(w_riga,w_inizio + 227,1)));
                          w_flag_cessione       := to_number(rtrim(substr(w_riga,w_inizio + 228,1)));
                          w_flag_altro          := to_number(rtrim(substr(w_riga,w_inizio + 229,1)));
                          w_descrizione_altro   := rtrim(substr(w_riga,w_inizio + 230,100));
                          w_agenzia_entrate     := rtrim(substr(w_riga,w_inizio + 330,24));
                          w_estremi_titolo      := rtrim(substr(w_riga,w_inizio + 354,24));
                          w_annotazioni         := case when (w_ind=1) then rtrim(substr(w_riga,1224,500)) else '' end;
                        end if;
                      end if;
                    else
                      w_caratteristica     := ltrim(rtrim(substr(w_riga,w_inizio + 4,3)));
                      w_indirizzo_imm      := rtrim(substr(w_riga,w_inizio + 7,100));
                      w_tipo               := substr(w_riga,w_inizio + 107,1);
                      w_cod_catastale      := rtrim(substr(w_riga,w_inizio + 108,5));
                      w_sezione            := rtrim(substr(w_riga,w_inizio + 113,3));
                      w_foglio             := rtrim(substr(w_riga,w_inizio + 116,4));
                      w_numero             := rtrim(substr(w_riga,w_inizio + 120,10));
                      w_subalterno         := rtrim(substr(w_riga,w_inizio + 130,4));
                      w_categoria_catasto  := ltrim(rtrim(substr(w_riga,w_inizio + 134,25)));
                      w_classe_catasto     := rtrim(substr(w_riga,w_inizio + 159,10));
                      w_protocollo_catasto := rtrim(substr(w_riga,w_inizio + 169,20));
                      w_anno_catasto       := rtrim(substr(w_riga,w_inizio + 189,4));
                      w_immobile_storico   := to_number(rtrim(substr(w_riga,w_inizio + 193,1)));
                      w_valore             := to_number(rtrim(substr(w_riga,w_inizio + 194,15)));
                      w_perc_possesso      := to_number(rtrim(substr(w_riga,w_inizio + 209,3)));
                      w_data_var_imposta   := substr(w_riga,w_inizio + 212,8);
                      w_flag_acquisto      := to_number(rtrim(substr(w_riga,w_inizio + 220,1)));
                      w_flag_cessione      := to_number(rtrim(substr(w_riga,w_inizio + 221,1)));
                      w_agenzia_entrate    := rtrim(substr(w_riga,w_inizio + 222,24));
                      w_estremi_titolo     := rtrim(substr(w_riga,w_inizio + 246,24));
                      w_annotazioni        := case when (w_ind=1) then rtrim(substr(w_riga,900,500)) else '' end;
                    end if;

                    insert into WRK_ENC_IMMOBILI
                      (documento_id,
                       progr_dichiarazione,
                       tipo_immobile,
                       progr_immobile,
                       num_ordine,
                       progr_immobile_dich,
                       ind_continuita,
                       caratteristica,
                       indirizzo,
                       tipo,
                       cod_catastale,
                       sezione,
                       foglio,
                       numero,
                       subalterno,
                       categoria_catasto,
                       classe_catasto,
                       protocollo_catasto,
                       anno_catasto,
                       immobile_storico,
                       immobile_esente,
                       valore,
                       perc_possesso,
                       data_var_imposta,
                       flag_acquisto,
                       flag_cessione,
                       flag_altro,
                       descrizione_altro,
                       agenzia_entrate,
                       estremi_titolo,
                       annotazioni,
                       data_variazione,
                       utente)
                    values
                      (a_documento_id,
                       w_progr_dichiarazione,
                       'A',
                       w_progr_imm_a,
                       w_num_ordine,
                       w_progr_immobile_dich,
                       w_ind_continuita,
                       w_caratteristica,
                       w_indirizzo_imm,
                       w_tipo,
                       w_cod_catastale,
                       w_sezione,
                       w_foglio,
                       w_numero,
                       w_subalterno,
                       w_categoria_catasto,
                       w_classe_catasto,
                       w_protocollo_catasto,
                       w_anno_catasto,
                       w_immobile_storico,
                       w_immobile_esente,
                       w_valore,
                       w_perc_possesso,
                       w_data_var_imposta,
                       w_flag_acquisto,
                       w_flag_cessione,
                       w_flag_altro,
                       w_descrizione_altro,
                       w_agenzia_entrate,
                       w_estremi_titolo,
                       w_annotazioni,
                       w_data_variazione,
                       a_utente);
                  exception
                    when others then
                      ins_anomalie_car ( a_documento_id
                                       , to_number(null)
                                       , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record C'
                                       , 'Progr. modulo '||substr(w_riga,18,8)
                                       , w_cf_dichiarante
                                       , null
                                       , w_riga
                                       );
                  end;
  --dbms_output.put_line('Inserito quadro C: '||to_number(substr(w_riga,w_inizio,4)));
               elsif substr(w_riga,w_inizio,4) not in ('    ','0000') or
                     substr(w_riga,w_inizio + 107,1) not in (' ','U','T') then
                  ins_anomalie_car ( a_documento_id
                                   , to_number(null)
                                   , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record C'
                                   , 'Progr. modulo '||substr(w_riga,18,8)
                                   , w_cf_dichiarante
                                   , null
                                   , w_riga
                                   );
                 end if;
               end loop;

             elsif w_tipo_tracciato = 'ECPF' then
               w_lunghezza_ele := 304;
               --
               for w_ind in 1..4
               loop
                 w_inizio := 90;
                 w_inizio := w_inizio + (w_lunghezza_ele * (w_ind - 1));
                 if afc.is_numeric(substr(w_riga,w_inizio,4)) = 1 and substr(w_riga,w_inizio,4) <> '0000' then
                    w_progr_contitolare := w_progr_contitolare + 1;
                    w_num_ordine        := to_number(substr(w_riga,w_inizio,4));
                    w_progr_immobile    := w_num_ordine;
                    --
                    -- Inserimento contitolare
                    --
                    begin
                      insert into WRK_ENC_CONTITOLARI ( documento_id
                                                      , progr_dichiarazione
                                                      , progr_contitolare
                                                      , progr_immobile
                                                      , tipo_immobile
                                                      , num_ordine
                                                      , denominazione
                                                      , cod_fiscale
                                                      , indirizzo
                                                      , num_civ
                                                      , scala
                                                      , piano
                                                      , interno
                                                      , cap
                                                      , comune
                                                      , provincia
                                                      , perc_possesso
                                                      , detrazione
                                                      , firma_contitolare
                                                    )
                       values ( a_documento_id
                              , w_progr_dichiarazione
                              , w_progr_contitolare
                              , w_progr_immobile
                              , 'A'
                              , w_num_ordine
                              , rtrim(substr(w_riga,w_inizio + 4,50))                    -- denominazione
                              , substr(w_riga,w_inizio + 99,16)                          -- cod_fiscale
                              , rtrim(substr(w_riga,w_inizio + 124,35))                  -- indirizzo
                              , rtrim(substr(w_riga,w_inizio + 159,5))                   -- num_civ
                              , rtrim(substr(w_riga,w_inizio + 164,5))                   -- scala
                              , rtrim(substr(w_riga,w_inizio + 169,5))                   -- piano
                              , rtrim(substr(w_riga,w_inizio + 174,5))                   -- interno
                              , rtrim(substr(w_riga,w_inizio + 179,5))                   -- cap
                              , rtrim(substr(w_riga,w_inizio + 184,100))                 -- comune
                              , rtrim(substr(w_riga,w_inizio + 284,2))                   -- provincia
                              , to_number(rtrim(substr(w_riga,w_inizio + 289,5))) / 100  -- perc_possesso
                              , to_number(rtrim(substr(w_riga,w_inizio + 294,9))) / 100  -- detrazione
                              , to_number(substr(w_riga,w_inizio + 303,1))               -- firma_contitolare
                              );
                    exception
                    when others then
                      ins_anomalie_car ( a_documento_id
                                       , to_number(null)
                                       , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record C'
                                       , 'Progr. modulo '||substr(w_riga,18,8)
                                       , w_cf_dichiarante
                                       , null
                                       , w_riga
                                       );
                    end;
                 elsif substr(w_riga,w_inizio,4) not in ('    ','0000') then
                  ins_anomalie_car ( a_documento_id
                                   , to_number(null)
                                   , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record C'
                                   , 'Progr. modulo '||substr(w_riga,18,8)
                                   , w_cf_dichiarante
                                   , null
                                   , w_riga
                                   );
                 end if;
               end loop;
             end if;

          end if;
          --
          -- Trattamento tipo_record "D"
          --    ENC (Enti non Commerciali):
          --        Quadro B - Immobili parzialmente imponibili o totalmente esenti
          --    ECPF (Enti Commerciali e delle Persone Fisiche):
          --        Immobili
          --
          if substr(w_riga,1,1) = 'D' then
             w_step := 7;
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "D", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;

             w_testata_exists := 0;
             select count(*)
                  into w_testata_exists
             from wrk_enc_testata wete
                  where wete.documento_id = a_documento_id
                        and wete.progr_dichiarazione = w_progr_dichiarazione;
             if w_testata_exists = 0 then
               ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tipo record D ignorato a causa di anomalie su Tipo record B'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
--               continue;
               goto uscita_loop;
             end if;

             if w_tipo_tracciato = 'ENC' then
               if w_data_dichiarazione >= co_data_tracc_enc_2015_v1 then
                  w_posizione_tipo := 212;
               else
                  w_posizione_tipo := 207;
               end if;

               if afc.is_numeric(substr(w_riga,90,4)) = 1 and
                  substr(w_riga,90,4) <> '0000' and
                  substr(w_riga,w_posizione_tipo,1) in ('U','T') then
                  w_progr_imm_b := w_progr_imm_b + 1;
                  w_num_ordine := to_number(substr(w_riga,90,4));
                  w_data_variazione := trunc(sysdate);

                  if w_data_dichiarazione >= co_data_tracc_enc_2015_v1 then
                    if to_number(substr(w_riga,99,1)) = 1 then
                        w_tipo_attivita := 1;              -- Attivita' assistenziali
                     elsif
                        to_number(substr(w_riga,100,1)) = 1 then
                        w_tipo_attivita := 2;              -- Attivita' previdenziali
                     elsif
                        to_number(substr(w_riga,101,1)) = 1 then
                        w_tipo_attivita := 3;              -- Attivita' sanitarie
                     elsif
                        to_number(substr(w_riga,102,1)) = 1 then
                        w_tipo_attivita := 4;              -- Attivita' didattiche
                     elsif
                        to_number(substr(w_riga,103,1)) = 1 then
                        w_tipo_attivita := 5;              -- Attivita' ricettive
                     elsif
                        to_number(substr(w_riga,104,1)) = 1 then
                        w_tipo_attivita := 6;              -- Attivita' culturali
                     elsif
                        to_number(substr(w_riga,105,1)) = 1 then
                        w_tipo_attivita := 7;              -- Attivita' ricreative
                     elsif
                        to_number(substr(w_riga,106,1)) = 1 then
                        w_tipo_attivita := 8;              -- Attivita' sportive
                     elsif
                        to_number(substr(w_riga,107,1)) = 1 then
                        w_tipo_attivita := 9;              -- Attivita' religione e culto
                     elsif
                        to_number(substr(w_riga,108,1)) = 1 then
                        w_tipo_attivita := 10;             -- Attivita' ricerca scientifica
                     end if;

                     w_progr_immobile_dich := to_number(substr(w_riga,94,4));
                     w_ind_continuita := to_number(substr(w_riga,98,1));

                     if w_data_dichiarazione >= co_data_tracc_enc_2023_v1 then
                       w_caratteristica := rtrim(substr(w_riga,109,1));
                       w_indirizzo_imm := rtrim(substr(w_riga,110,100));
                       w_tipo := substr(w_riga,210,1);
                       w_cod_catastale := rtrim(substr(w_riga,211,5));
                       w_sezione := rtrim(substr(w_riga,216,3));
                       w_foglio := rtrim(substr(w_riga,219,4));
                       w_numero := rtrim(substr(w_riga,223,10));
                       w_subalterno := rtrim(substr(w_riga,233,4));
                       w_categoria_catasto := ltrim(rtrim(substr(w_riga,237,25)));
                       w_classe_catasto := rtrim(substr(w_riga,262,10));
                       w_protocollo_catasto := rtrim(substr(w_riga,272,20));
                       w_anno_catasto := rtrim(substr(w_riga,292,4));
                       -- Riduzioni: 1 - Per immobile storico o artistico
                       --            2 - Per immobile inagibile/inabitabile
                       --            3 - Altre riduzioni
                       w_immobile_storico := case when (rtrim(substr(w_riga,296,1)) = '1') then 1 else 0 end;
                       w_valore := to_number(rtrim(substr(w_riga,297,15)));
                       w_perc_possesso := to_number(rtrim(substr(w_riga,312,5))) / 100;
                       w_immobile_esente := case when (rtrim(substr(w_riga,317,1)) = '1' or rtrim(substr(w_riga,w_inizio + 429,1)) = '1') then 1 else 0 end;
                       w_data_var_imposta := substr(w_riga,318,8);
                       w_flag_acquisto := to_number(rtrim(substr(w_riga,326,1)));
                       w_flag_cessione := to_number(rtrim(substr(w_riga,327,1)));
                       w_flag_altro := to_number(rtrim(substr(w_riga,328,1)));
                       w_descrizione_altro := rtrim(substr(w_riga,329,100));
                       w_agenzia_entrate := rtrim(substr(w_riga,430,24));
                       w_estremi_titolo := rtrim(substr(w_riga,454,24));
                       w_d_corrispettivo_medio := to_number(rtrim(substr(w_riga,478,9))) / 100;
                       w_d_costo_medio := to_number(rtrim(substr(w_riga,487,9))) / 100;
                       w_d_rapporto_superficie := to_number(rtrim(substr(w_riga,496,5))) / 100;
                       w_d_rapporto_sup_gg := to_number(rtrim(substr(w_riga,501,5))) / 100;
                       w_d_rapporto_soggetti := to_number(rtrim(substr(w_riga,506,5))) / 100;
                       w_d_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,511,5))) / 100;
                       w_d_rapporto_giorni := to_number(rtrim(substr(w_riga,516,5))) / 100;
                       w_d_perc_imponibilita := to_number(rtrim(substr(w_riga,521,5))) / 100;
                       w_d_valore_ass_art_5 := to_number(rtrim(substr(w_riga,526,12))) / 100;
                       w_d_valore_ass_art_4 := to_number(rtrim(substr(w_riga,538,12))) / 100;
                       w_d_casella_rigo_g := to_number(rtrim(substr(w_riga,550,1)));
                       w_d_casella_rigo_h := to_number(rtrim(substr(w_riga,551,1)));
                       w_d_rapporto_cms_cm := to_number(rtrim(substr(w_riga,552,5))) / 100;
                       w_d_valore_ass_parziale := to_number(rtrim(substr(w_riga,557,12))) / 100;
                       w_d_valore_ass_compl := to_number(rtrim(substr(w_riga,569,12))) / 100;
                       w_a_corrispettivo_medio_perc := to_number(rtrim(substr(w_riga,581,9))) / 100;
                       w_a_corrispettivo_medio_prev := to_number(rtrim(substr(w_riga,590,9))) / 100;
                       w_a_rapporto_superficie := to_number(rtrim(substr(w_riga,599,5))) / 100;
                       w_a_rapporto_sup_gg := to_number(rtrim(substr(w_riga,604,5))) / 100;
                       w_a_rapporto_soggetti := to_number(rtrim(substr(w_riga,609,5))) / 100;
                       w_a_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,614,5))) / 100;
                       w_a_rapporto_giorni := to_number(rtrim(substr(w_riga,619,5))) / 100;
                       w_a_perc_imponibilita := to_number(rtrim(substr(w_riga,624,5))) / 100;
                       w_a_valore_assoggettato := to_number(rtrim(substr(w_riga,629,12))) / 100;
                     else
                       w_caratteristica := rtrim(substr(w_riga,109,3));
                       w_indirizzo_imm := rtrim(substr(w_riga,112,100));
                       w_tipo := substr(w_riga,212,1);
                       w_cod_catastale := rtrim(substr(w_riga,213,5));
                       w_sezione := rtrim(substr(w_riga,218,3));
                       w_foglio := rtrim(substr(w_riga,221,4));
                       w_numero := rtrim(substr(w_riga,225,10));
                       w_subalterno := rtrim(substr(w_riga,235,4));
                       w_categoria_catasto := ltrim(rtrim(substr(w_riga,239,25)));
                       w_classe_catasto := rtrim(substr(w_riga,264,10));
                       w_protocollo_catasto := rtrim(substr(w_riga,274,20));
                       w_anno_catasto := rtrim(substr(w_riga,294,4));
                       w_immobile_storico := to_number(rtrim(substr(w_riga,298,1)));

                       if w_data_dichiarazione >= co_data_tracc_enc_2018_v1 then
                         w_valore := to_number(rtrim(substr(w_riga,300,15)));
                         w_immobile_esente := to_number(rtrim(substr(w_riga,315,1)));
                         w_perc_possesso := to_number(rtrim(substr(w_riga,316,5))) / 100;
                         w_data_var_imposta := substr(w_riga,321,8);
                         w_flag_acquisto := to_number(rtrim(substr(w_riga,329,1)));
                         w_flag_cessione := to_number(rtrim(substr(w_riga,330,1)));
                         w_flag_altro := to_number(rtrim(substr(w_riga,331,1)));
                         w_descrizione_altro := rtrim(substr(w_riga,332,100));
                         w_agenzia_entrate := rtrim(substr(w_riga,432,24));
                         w_estremi_titolo := rtrim(substr(w_riga,456,24));
                         w_d_corrispettivo_medio := to_number(rtrim(substr(w_riga,480,9))) / 100;
                         w_d_costo_medio := to_number(rtrim(substr(w_riga,489,9))) / 100;
                         w_d_rapporto_superficie := to_number(rtrim(substr(w_riga,498,5))) / 100;
                         w_d_rapporto_sup_gg := to_number(rtrim(substr(w_riga,503,5))) / 100;
                         w_d_rapporto_soggetti := to_number(rtrim(substr(w_riga,508,5))) / 100;
                         w_d_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,513,5))) / 100;
                         w_d_rapporto_giorni := to_number(rtrim(substr(w_riga,518,5))) / 100;
                         w_d_perc_imponibilita := to_number(rtrim(substr(w_riga,523,5))) / 100;
                         w_d_valore_ass_art_5 := to_number(rtrim(substr(w_riga,528,12))) / 100;
                         w_d_valore_ass_art_4 := to_number(rtrim(substr(w_riga,540,12))) / 100;
                         w_d_casella_rigo_g := to_number(rtrim(substr(w_riga,552,1)));
                         w_d_casella_rigo_h := to_number(rtrim(substr(w_riga,553,1)));
                         w_d_rapporto_cms_cm := to_number(rtrim(substr(w_riga,554,5))) / 100;
                         w_d_valore_ass_parziale := to_number(rtrim(substr(w_riga,559,12))) / 100;
                         w_d_valore_ass_compl := to_number(rtrim(substr(w_riga,571,12))) / 100;
                         w_a_corrispettivo_medio_perc := to_number(rtrim(substr(w_riga,583,9))) / 100;
                         w_a_corrispettivo_medio_prev := to_number(rtrim(substr(w_riga,592,9))) / 100;
                         w_a_rapporto_superficie := to_number(rtrim(substr(w_riga,601,5))) / 100;
                         w_a_rapporto_sup_gg := to_number(rtrim(substr(w_riga,606,5))) / 100;
                         w_a_rapporto_soggetti := to_number(rtrim(substr(w_riga,611,5))) / 100;
                         w_a_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,616,5))) / 100;
                         w_a_rapporto_giorni := to_number(rtrim(substr(w_riga,621,5))) / 100;
                         w_a_perc_imponibilita := to_number(rtrim(substr(w_riga,626,5))) / 100;
                         w_a_valore_assoggettato := to_number(rtrim(substr(w_riga,631,12))) / 100;
                       else
                         w_valore := to_number(rtrim(substr(w_riga,299,15)));
                         w_immobile_esente := to_number(rtrim(substr(w_riga,314,1)));
                         w_perc_possesso := to_number(rtrim(substr(w_riga,315,5))) / 100;
                         w_data_var_imposta := substr(w_riga,320,8);
                         w_flag_acquisto := to_number(rtrim(substr(w_riga,328,1)));
                         w_flag_cessione := to_number(rtrim(substr(w_riga,329,1)));
                         w_flag_altro := to_number(rtrim(substr(w_riga,330,1)));
                         w_descrizione_altro := rtrim(substr(w_riga,331,100));
                         w_agenzia_entrate := rtrim(substr(w_riga,431,24));
                         w_estremi_titolo := rtrim(substr(w_riga,455,24));
                         w_d_corrispettivo_medio := to_number(rtrim(substr(w_riga,479,9))) / 100;
                         w_d_costo_medio := to_number(rtrim(substr(w_riga,488,9))) / 100;
                         w_d_rapporto_superficie := to_number(rtrim(substr(w_riga,497,5))) / 100;
                         w_d_rapporto_sup_gg := to_number(rtrim(substr(w_riga,502,5))) / 100;
                         w_d_rapporto_soggetti := to_number(rtrim(substr(w_riga,507,5))) / 100;
                         w_d_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,512,5))) / 100;
                         w_d_rapporto_giorni := to_number(rtrim(substr(w_riga,517,5))) / 100;
                         w_d_perc_imponibilita := to_number(rtrim(substr(w_riga,522,5))) / 100;
                         w_d_valore_ass_art_5 := to_number(rtrim(substr(w_riga,527,12))) / 100;
                         w_d_valore_ass_art_4 := to_number(rtrim(substr(w_riga,539,12))) / 100;
                         w_d_casella_rigo_g := to_number(rtrim(substr(w_riga,551,1)));
                         w_d_casella_rigo_h := to_number(rtrim(substr(w_riga,552,1)));
                         w_d_rapporto_cms_cm := to_number(rtrim(substr(w_riga,553,5))) / 100;
                         w_d_valore_ass_parziale := to_number(rtrim(substr(w_riga,558,12))) / 100;
                         w_d_valore_ass_compl := to_number(rtrim(substr(w_riga,570,12))) / 100;
                         w_a_corrispettivo_medio_perc := to_number(rtrim(substr(w_riga,582,9))) / 100;
                         w_a_corrispettivo_medio_prev := to_number(rtrim(substr(w_riga,591,9))) / 100;
                         w_a_rapporto_superficie := to_number(rtrim(substr(w_riga,600,5))) / 100;
                         w_a_rapporto_sup_gg := to_number(rtrim(substr(w_riga,605,5))) / 100;
                         w_a_rapporto_soggetti := to_number(rtrim(substr(w_riga,610,5))) / 100;
                         w_a_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,615,5))) / 100;
                         w_a_rapporto_giorni := to_number(rtrim(substr(w_riga,620,5))) / 100;
                         w_a_perc_imponibilita := to_number(rtrim(substr(w_riga,625,5))) / 100;
                         w_a_valore_assoggettato := to_number(rtrim(substr(w_riga,630,12))) / 100;
                       end if;
                     end if;
                  else
                     if to_number(substr(w_riga,94,1)) = 1 then
                        w_tipo_attivita := 1;              -- Attivita' assistenziali
                     elsif
                        to_number(substr(w_riga,95,1)) = 1 then
                        w_tipo_attivita := 2;              -- Attivita' previdenziali
                     elsif
                        to_number(substr(w_riga,96,1)) = 1 then
                        w_tipo_attivita := 3;              -- Attivita' sanitarie
                     elsif
                        to_number(substr(w_riga,97,1)) = 1 then
                        w_tipo_attivita := 4;              -- Attivita' didattiche
                     elsif
                        to_number(substr(w_riga,98,1)) = 1 then
                        w_tipo_attivita := 5;              -- Attivita' ricettive
                     elsif
                        to_number(substr(w_riga,99,1)) = 1 then
                        w_tipo_attivita := 6;              -- Attivita' culturali
                     elsif
                        to_number(substr(w_riga,100,1)) = 1 then
                        w_tipo_attivita := 7;              -- Attivita' ricreative
                     elsif
                        to_number(substr(w_riga,101,1)) = 1 then
                        w_tipo_attivita := 8;              -- Attivita' sportive
                     elsif
                        to_number(substr(w_riga,102,1)) = 1 then
                        w_tipo_attivita := 9;              -- Attivita' religione e culto
                     elsif
                        to_number(substr(w_riga,103,1)) = 1 then
                        w_tipo_attivita := 10;             -- Attivita' ricerca scientifica
                     end if;

                     w_caratteristica := rtrim(substr(w_riga,104,3));
                     w_indirizzo_imm := rtrim(substr(w_riga,107,100));
                     w_tipo := substr(w_riga,207,1);
                     w_cod_catastale := rtrim(substr(w_riga,208,5));
                     w_sezione := rtrim(substr(w_riga,213,3));
                     w_foglio := rtrim(substr(w_riga,216,4));
                     w_numero := rtrim(substr(w_riga,220,10));
                     w_subalterno := rtrim(substr(w_riga,230,4));
                     w_categoria_catasto := ltrim(rtrim(substr(w_riga,234,25)));
                     w_classe_catasto := rtrim(substr(w_riga,259,10));
                     w_protocollo_catasto := rtrim(substr(w_riga,269,20));
                     w_anno_catasto := rtrim(substr(w_riga,289,4));
                     w_immobile_storico := to_number(rtrim(substr(w_riga,293,1)));
                     w_valore := to_number(rtrim(substr(w_riga,294,15)));
                     w_immobile_esente := to_number(rtrim(substr(w_riga,309,1)));
                     w_perc_possesso := to_number(rtrim(substr(w_riga,310,3)));
                     w_data_var_imposta := substr(w_riga,313,8);
                     w_flag_acquisto := to_number(rtrim(substr(w_riga,321,1)));
                     w_flag_cessione := to_number(rtrim(substr(w_riga,322,1)));
                     w_agenzia_entrate := rtrim(substr(w_riga,323,24));
                     w_estremi_titolo := rtrim(substr(w_riga,347,24));
                     w_d_corrispettivo_medio := to_number(rtrim(substr(w_riga,371,9))) / 100;
                     w_d_costo_medio := to_number(rtrim(substr(w_riga,380,9))) / 100;
                     w_d_rapporto_superficie := to_number(rtrim(substr(w_riga,389,3)));
                     w_d_rapporto_sup_gg := to_number(rtrim(substr(w_riga,392,3)));
                     w_d_rapporto_soggetti := to_number(rtrim(substr(w_riga,395,3)));
                     w_d_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,398,3)));
                     w_d_rapporto_giorni := to_number(rtrim(substr(w_riga,401,3)));
                     w_d_perc_imponibilita := to_number(rtrim(substr(w_riga,404,3)));
                     w_d_valore_ass_art_5 := to_number(rtrim(substr(w_riga,407,12)));
                     w_d_valore_ass_art_4 := to_number(rtrim(substr(w_riga,419,12)));
                     w_d_casella_rigo_g := to_number(rtrim(substr(w_riga,431,1)));
                     w_d_casella_rigo_h := to_number(rtrim(substr(w_riga,432,1)));
                     w_d_rapporto_cms_cm := to_number(rtrim(substr(w_riga,433,3)));
                     w_d_valore_ass_parziale := to_number(rtrim(substr(w_riga,436,12)));
                     w_d_valore_ass_compl := to_number(rtrim(substr(w_riga,448,12)));
                     w_a_corrispettivo_medio_perc := to_number(rtrim(substr(w_riga,460,9))) / 100;
                     w_a_corrispettivo_medio_prev := to_number(rtrim(substr(w_riga,469,9))) / 100;
                     w_a_rapporto_superficie := to_number(rtrim(substr(w_riga,478,3)));
                     w_a_rapporto_sup_gg := to_number(rtrim(substr(w_riga,481,3)));
                     w_a_rapporto_soggetti := to_number(rtrim(substr(w_riga,484,3)));
                     w_a_rapporto_sogg_gg := to_number(rtrim(substr(w_riga,487,3)));
                     w_a_rapporto_giorni := to_number(rtrim(substr(w_riga,490,3)));
                     w_a_perc_imponibilita := to_number(rtrim(substr(w_riga,493,3)));
                     w_a_valore_assoggettato := to_number(rtrim(substr(w_riga,496,12)));
                  end if;

                  if w_tipo_attivita = 4 then
                      w_a_corrispettivo_medio_perc := to_number(null);
                      w_a_corrispettivo_medio_prev := to_number(null);
                      w_a_rapporto_superficie := to_number(null);
                      w_a_rapporto_sup_gg := to_number(null);
                      w_a_rapporto_soggetti := to_number(null);
                      w_a_rapporto_sogg_gg := to_number(null);
                      w_a_rapporto_giorni := to_number(null);
                      w_a_perc_imponibilita := to_number(null);
                      w_a_valore_assoggettato := to_number(null);
                  else
                      w_d_corrispettivo_medio := to_number(null);
                      w_d_costo_medio := to_number(null);
                      w_d_rapporto_superficie := to_number(null);
                      w_d_rapporto_sup_gg := to_number(null);
                      w_d_rapporto_soggetti := to_number(null);
                      w_d_rapporto_sogg_gg := to_number(null);
                      w_d_rapporto_giorni := to_number(null);
                      w_d_perc_imponibilita := to_number(null);
                      w_d_valore_ass_art_5 := to_number(null);
                      w_d_valore_ass_art_4 := to_number(null);
                      w_d_casella_rigo_g := to_number(null);
                      w_d_casella_rigo_h := to_number(null);
                      w_d_rapporto_cms_cm := to_number(null);
                      w_d_valore_ass_parziale := to_number(null);
                      w_d_valore_ass_compl := to_number(null);
                  end if;
                  --
                  -- Inserimento immobile parzialmente imponibile o esente
                  --
                  w_step := 8;
                  begin
                    insert into WRK_ENC_IMMOBILI
                      (documento_id,
                       progr_dichiarazione,
                       tipo_immobile,
                       progr_immobile,
                       num_ordine,
                       progr_immobile_dich,
                       ind_continuita,
                       tipo_attivita,
                       caratteristica,
                       indirizzo,
                       tipo,
                       cod_catastale,
                       sezione,
                       foglio,
                       numero,
                       subalterno,
                       categoria_catasto,
                       classe_catasto,
                       protocollo_catasto,
                       anno_catasto,
                       immobile_storico,
                       valore,
                       immobile_esente,
                       perc_possesso,
                       data_var_imposta,
                       flag_acquisto,
                       flag_cessione,
                       flag_altro,
                       descrizione_altro,
                       agenzia_entrate,
                       estremi_titolo,
                       d_corrispettivo_medio,
                       d_costo_medio,
                       d_rapporto_superficie,
                       d_rapporto_sup_gg,
                       d_rapporto_soggetti,
                       d_rapporto_sogg_gg,
                       d_rapporto_giorni,
                       d_perc_imponibilita,
                       d_valore_ass_art_5,
                       d_valore_ass_art_4,
                       d_casella_rigo_g,
                       d_casella_rigo_h,
                       d_rapporto_cms_cm,
                       d_valore_ass_parziale,
                       d_valore_ass_compl,
                       a_corrispettivo_medio_perc,
                       a_corrispettivo_medio_prev,
                       a_rapporto_superficie,
                       a_rapporto_sup_gg,
                       a_rapporto_soggetti,
                       a_rapporto_sogg_gg,
                       a_rapporto_giorni,
                       a_perc_imponibilita,
                       a_valore_assoggettato,
                       data_variazione,
                       utente)
                    values
                      (a_documento_id,
                       w_progr_dichiarazione,
                       'B',
                       w_progr_imm_b,
                       w_num_ordine,
                       w_progr_immobile_dich,
                       w_ind_continuita,
                       w_tipo_attivita,
                       w_caratteristica,
                       w_indirizzo,
                       w_tipo,
                       w_cod_catastale,
                       w_sezione,
                       w_foglio,
                       w_numero,
                       w_subalterno,
                       w_categoria_catasto,
                       w_classe_catasto,
                       w_protocollo_catasto,
                       w_anno_catasto,
                       w_immobile_storico,
                       w_valore,
                       w_immobile_esente,
                       w_perc_possesso,
                       w_data_var_imposta,
                       w_flag_acquisto,
                       w_flag_cessione,
                       w_flag_altro,
                       w_descrizione_altro,
                       w_agenzia_entrate,
                       w_estremi_titolo,
                       w_d_corrispettivo_medio,
                       w_d_costo_medio,
                       w_d_rapporto_superficie,
                       w_d_rapporto_sup_gg,
                       w_d_rapporto_soggetti,
                       w_d_rapporto_sogg_gg,
                       w_d_rapporto_giorni,
                       w_d_perc_imponibilita,
                       w_d_valore_ass_art_5,
                       w_d_valore_ass_art_4,
                       w_d_casella_rigo_g,
                       w_d_casella_rigo_h,
                       w_d_rapporto_cms_cm,
                       w_d_valore_ass_parziale,
                       w_d_valore_ass_compl,
                       w_a_corrispettivo_medio_perc,
                       w_a_corrispettivo_medio_prev,
                       w_a_rapporto_superficie,
                       w_a_rapporto_sup_gg,
                       w_a_rapporto_soggetti,
                       w_a_rapporto_sogg_gg,
                       w_a_rapporto_giorni,
                       w_a_perc_imponibilita,
                       w_a_valore_assoggettato,
                       w_data_variazione,
                       a_utente);
                  exception
                    when others then
                        ins_anomalie_car ( a_documento_id
                                         , to_number(null)
                                         , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record D'
                                         , 'Progr. modulo '||substr(w_riga,18,8)
                                         , w_cf_dichiarante
                                         , null
                                         , w_riga
                                         );
                  end;
               elsif substr(w_riga,90,4) not in ('    ','0000')  or
                  substr(w_riga,207,1) not in (' ','U','T') then
                  ins_anomalie_car ( a_documento_id
                                   , to_number(null)
                                   , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record D - step '||w_step
                                   , 'Progr. modulo '||substr(w_riga,18,8)
                                   , w_cf_dichiarante
                                   , null
                                   , w_riga
                                   );
               end if;
             elsif w_tipo_tracciato = 'ECPF' then
               w_step := 9;

               if w_data_dichiarazione >= co_data_tracc_ecpf_v6 then
                 w_lunghezza_ele := 389;
                 w_posizione_tipo := 112;
               elsif w_data_dichiarazione >= co_data_tracc_ecpf_v5 then
                 w_lunghezza_ele := 397;
                 w_posizione_tipo := 112;
               else
                 w_lunghezza_ele := 398;
                 w_posizione_tipo := 112;
               end if;
               --
               for w_ind in 1..3
               loop
                 w_inizio := 90;
                 w_inizio := w_inizio + (w_lunghezza_ele * (w_ind - 1));
                 if afc.is_numeric(substr(w_riga,w_inizio,4)) = 1 and
                    substr(w_riga,w_inizio,4) <> '0000' and
                    substr(w_riga,w_inizio + w_posizione_tipo,1) in ('U','T') then
                    w_step := 91;
                    w_progr_immobile := w_progr_immobile + 1;
                    w_num_ordine := to_number(substr(w_riga,w_inizio,4));
                    w_step := 911;
                    w_progr_immobile := to_number(substr(w_riga,w_inizio + 4,4));
                    w_ind_continuita := to_number(substr(w_riga,w_inizio + 8,1));
                    w_step := 912;
                    w_caratteristica := rtrim(substr(w_riga,w_inizio + 9,3));
                    w_indirizzo_imm := rtrim(substr(w_riga,w_inizio + 12,100));
                    w_step := 913;
                    w_tipo := substr(w_riga,w_inizio + 112,1);
                    w_cod_catastale := rtrim(substr(w_riga,w_inizio + 113,5));
                    w_step := 914;
                    w_sezione := rtrim(substr(w_riga,w_inizio + 118,3));
                    w_foglio := rtrim(substr(w_riga,w_inizio + 121,4));
                    w_numero := rtrim(substr(w_riga,w_inizio + 125,10));
                    w_subalterno := rtrim(substr(w_riga,w_inizio + 135,4));
                    w_categoria_catasto := ltrim(rtrim(substr(w_riga,w_inizio + 139,25)));
                    w_classe_catasto := rtrim(substr(w_riga,w_inizio + 164,10));
                    w_step := 915;
                    w_protocollo_catasto := rtrim(substr(w_riga,w_inizio + 174,20));
                    w_anno_catasto := rtrim(substr(w_riga,w_inizio + 194,4));
                    w_immobile_storico := case when (rtrim(substr(w_riga,w_inizio + 198,1)) = '1') then 1 else 0 end;
                    w_data_variazione := trunc(sysdate);

                    if w_data_dichiarazione >= co_data_tracc_ecpf_v6 then
                      w_step := 92;
                      w_inizio := w_inizio - 1;
                      w_valore := to_number(rtrim(substr(w_riga,w_inizio + 200,15)));
                      w_step := 921;
                      w_perc_possesso := to_number(rtrim(substr(w_riga,w_inizio + 215,5))) / 100;
                      w_step := 922;
                      w_data_var_imposta := substr(w_riga,w_inizio + 221,8);
                      w_step := 923;
                      w_detrazione := to_number(rtrim(substr(w_riga,w_inizio + 229,9))) / 100;
                      w_step := 924;
                      w_flag_acquisto := to_number(rtrim(substr(w_riga,w_inizio + 238,1)));
                      w_step := 925;
                      w_flag_cessione := to_number(trim(substr(w_riga,w_inizio + 239,1)));
                      w_step := 926;
                      w_flag_altro := to_number(rtrim(substr(w_riga,w_inizio + 240,1)));
                      w_descrizione_altro := rtrim(substr(w_riga,w_inizio + 241,100));
                      w_agenzia_entrate := rtrim(substr(w_riga,w_inizio + 341,24));
                      w_estremi_titolo := rtrim(substr(w_riga,w_inizio + 365,24));
                      w_annotazioni := case when (w_ind=1) then rtrim(substr(w_riga,1168,500)) else '' end;
                    elsif w_data_dichiarazione >= co_data_tracc_ecpf_v4 then
                      w_step := 93;
                      w_valore := to_number(rtrim(substr(w_riga,w_inizio + 200,15)));
                      w_perc_possesso := to_number(rtrim(substr(w_riga,w_inizio + 215,5))) / 100;
                      w_data_var_imposta := substr(w_riga,w_inizio + 222,8);
                      w_detrazione := to_number(rtrim(substr(w_riga,w_inizio + 230,9))) / 100;
                      w_flag_acquisto := to_number(rtrim(substr(w_riga,w_inizio + 247,1)));
                      w_flag_cessione := to_number(rtrim(substr(w_riga,w_inizio + 248,1)));
                      w_flag_altro := to_number(rtrim(substr(w_riga,w_inizio + 249,1)));
                      w_descrizione_altro := rtrim(substr(w_riga,w_inizio + 250,100));
                      w_agenzia_entrate := rtrim(substr(w_riga,w_inizio + 350,24));
                      w_estremi_titolo := rtrim(substr(w_riga,w_inizio + 374,24));
                      w_annotazioni := case when (w_ind=1) then rtrim(substr(w_riga,1284,500)) else '' end;
                    else
                      w_step := 94;
                      w_valore := to_number(rtrim(substr(w_riga,w_inizio + 199,15)));
                      w_perc_possesso := to_number(rtrim(substr(w_riga,w_inizio + 214,5))) / 100;
                      w_data_var_imposta := substr(w_riga,w_inizio + 221,8);
                      w_detrazione := to_number(rtrim(substr(w_riga,w_inizio + 229,9))) / 100;
                      w_flag_acquisto := to_number(rtrim(substr(w_riga,w_inizio + 246,1)));
                      w_flag_cessione := to_number(rtrim(substr(w_riga,w_inizio + 247,1)));
                      w_flag_altro := to_number(rtrim(substr(w_riga,w_inizio + 248,1)));
                      w_descrizione_altro := rtrim(substr(w_riga,w_inizio + 249,100));
                      w_agenzia_entrate := rtrim(substr(w_riga,w_inizio + 349,24));
                      w_estremi_titolo := rtrim(substr(w_riga,w_inizio + 373,24));
                      w_annotazioni := case when (w_ind=1) then rtrim(substr(w_riga,1281,500)) else '' end;
                    end if;
                    w_step := 95;

                    --
                    -- Inserimento immobile
                    --
                    begin
                       insert into WRK_ENC_IMMOBILI ( documento_id
                                                    , progr_dichiarazione
                                                    , tipo_immobile
                                                    , progr_immobile
                                                    , num_ordine
                                                    , progr_immobile_dich
                                                    , ind_continuita
                                                    , caratteristica
                                                    , indirizzo
                                                    , tipo
                                                    , cod_catastale
                                                    , sezione
                                                    , foglio
                                                    , numero
                                                    , subalterno
                                                    , categoria_catasto
                                                    , classe_catasto
                                                    , protocollo_catasto
                                                    , anno_catasto
                                                    , immobile_storico
                                                    , valore
                                                    , perc_possesso
                                                    , data_var_imposta
                                                    , detrazione
                                                    , flag_acquisto
                                                    , flag_cessione
                                                    , flag_altro
                                                    , descrizione_altro
                                                    , agenzia_entrate
                                                    , estremi_titolo
                                                    , annotazioni
                                                    , data_variazione
                                                    , utente
                                                    )
                       values ( a_documento_id
                              , w_progr_dichiarazione
                              , 'A'
                              , w_progr_immobile
                              , w_num_ordine
                              , w_progr_immobile
                              , w_ind_continuita
                              , w_caratteristica
                              , w_indirizzo
                              , w_tipo
                              , w_cod_catastale
                              , w_sezione
                              , w_foglio
                              , w_numero
                              , w_subalterno
                              , w_categoria_catasto
                              , w_classe_catasto
                              , w_protocollo_catasto
                              , w_anno_catasto
                              , w_immobile_storico
                              , w_valore
                              , w_perc_possesso
                              , w_data_var_imposta
                              , w_detrazione
                              , w_flag_acquisto
                              , w_flag_cessione
                              , w_flag_altro
                              , w_descrizione_altro
                              , w_agenzia_entrate
                              , w_estremi_titolo
                              , w_annotazioni
                              , w_data_variazione
                              , a_utente
                              );
                    exception
                      when others then
                        ins_anomalie_car ( a_documento_id
                                         , to_number(null)
                                         , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record D - step '||w_step||' w_inizio '||w_inizio
                                         , 'Progr. modulo '||substr(w_riga,18,8)
                                         , w_cf_dichiarante
                                         , null
                                         , substr(w_riga||' Errore: '||SQLERRM,1,2000)
                                         );
                    end;
                 elsif substr(w_riga,w_inizio,4) not in ('    ','0000') or
                     substr(w_riga,w_inizio + 107,1) not in (' ','U','T') then
                  w_step := 96;
                  ins_anomalie_car ( a_documento_id
                                   , to_number(null)
                                   , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record D - step '||w_step||' w_inizio '||w_inizio
                                   , 'Progr. modulo '||substr(w_riga,18,8)
                                   , w_cf_dichiarante
                                   , null
                                   , substr(w_riga||' Errore: '||SQLERRM,1,2000)
                                   );
                 end if;
               end loop;
             end if;
          end if;
          --
          -- Trattamento tipo_record "E": Quadro C - Determinazione dell'IMU e della TASI
          --                              Quadro D - Compensazioni e rimborsi
          --
          -- I record di tipo "E" non sono presenti nel tracciato ECPF
          --
          -- DM 20/05/2024 adeguamenti tracciato ECPF 2022, per il momento escludiamo i record E
          --               in attesa di modificare la banca dati con i nuovi campi per le piattaforme
          --               ed i rigassificatori.
          if substr(w_riga,1,1) = 'E' AND w_tipo_tracciato != 'ECPF' then
             w_step := 10;
--dbms_output.put_line('Tipo record E');
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "E", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;

             w_testata_exists := 0;
             select count(*)
                  into w_testata_exists
             from wrk_enc_testata wete
                  where wete.documento_id = a_documento_id
                        and wete.progr_dichiarazione = w_progr_dichiarazione;
             if w_testata_exists = 0 then
               ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tipo record E ignorato a causa di anomalie su Tipo record B'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
--               continue;
               goto uscita_loop;
             end if;
             --
             -- Si aggiornano i dati di riepilogo sulla riga di testata delle dichiarazione
             --
             w_imu_dovuta                  := to_number(substr(w_riga,90,12));
             w_eccedenza_imu_dic_prec      := to_number(substr(w_riga,102,12));
             w_eccedenza_imu_dic_prec_f24  := to_number(substr(w_riga,114,12));
             w_rate_imu_versate            := to_number(substr(w_riga,126,12));
             w_imu_debito                  := to_number(substr(w_riga,138,12));
             w_imu_credito                 := to_number(substr(w_riga,150,12));

             if w_data_dichiarazione >= co_data_tracc_enc_2023_v1 then
               w_step := 11;
               w_tasi_dovuta                 := null;
               w_eccedenza_tasi_dic_prec     := null;
               w_eccedenza_tasi_dic_prec_f24 := null;
               w_tasi_rate_versate           := null;
               w_tasi_debito                 := null;
               w_tasi_credito                := null;
               w_imu_credito_dic_presente    := to_number(substr(w_riga,162,12));
               w_credito_imu_rimborso        := to_number(substr(w_riga,174,12));
               w_credito_imu_compensazione   := to_number(substr(w_riga,186,12));
               w_tasi_credito_dic_presente   := null;
               w_credito_tasi_rimborso       := null;
               w_credito_tasi_compensazione  := null;
             else
               w_step := 12;
               w_tasi_dovuta                 := to_number(substr(w_riga,162,12));
               w_eccedenza_tasi_dic_prec     := to_number(substr(w_riga,174,12));
               w_eccedenza_tasi_dic_prec_f24 := to_number(substr(w_riga,186,12));
               w_tasi_rate_versate           := to_number(substr(w_riga,198,12));
               w_tasi_debito                 := to_number(substr(w_riga,210,12));
               w_tasi_credito                := to_number(substr(w_riga,222,12));
               w_imu_credito_dic_presente    := to_number(substr(w_riga,234,12));
               w_credito_imu_rimborso        := to_number(substr(w_riga,246,12));
               w_credito_imu_compensazione   := to_number(substr(w_riga,258,12));
               w_tasi_credito_dic_presente   := to_number(substr(w_riga,270,12));
               w_credito_tasi_rimborso       := to_number(substr(w_riga,282,12));
               w_credito_tasi_compensazione  := to_number(substr(w_riga,294,12));
             end if;
             begin
               update WRK_ENC_TESTATA
                  set imu_dovuta                  = w_imu_dovuta
                    , eccedenza_imu_dic_prec      = w_eccedenza_imu_dic_prec
                    , eccedenza_imu_dic_prec_f24  = w_eccedenza_imu_dic_prec_f24
                    , rate_imu_versate            = w_rate_imu_versate
                    , imu_debito                  = w_imu_debito
                    , imu_credito                 = w_imu_credito
                    , tasi_dovuta                 = w_tasi_dovuta
                    , eccedenza_tasi_dic_prec     = w_eccedenza_tasi_dic_prec
                    , eccedenza_tasi_dic_prec_f24 = w_eccedenza_tasi_dic_prec_f24
                    , tasi_rate_versate           = w_tasi_rate_versate
                    , tasi_debito                 = w_tasi_debito
                    , tasi_credito                = w_tasi_credito
                    , imu_credito_dic_presente    = w_imu_credito_dic_presente
                    , credito_imu_rimborso        = w_credito_imu_rimborso
                    , credito_imu_compensazione   = w_credito_imu_compensazione
                    , tasi_credito_dic_presente   = w_tasi_credito_dic_presente
                    , credito_tasi_rimborso       = w_credito_tasi_rimborso
                    , credito_tasi_compensazione  = w_credito_tasi_compensazione
                where documento_id = a_documento_id
                  and progr_dichiarazione = w_progr_dichiarazione;
             exception
               when others then
                 ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tracciato '||w_tipo_tracciato||' non conforme - Tipo record E'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
             end;
          end if;
       end if;
     << uscita_loop >>
     null;
     end loop;
  end if;
  --
  a_messaggio := 'Righe trattate: '||w_contarighe||';';
  --
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,w_cf_dichiarante||' w_step: '||w_step||' '||to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
----------------------------------------------------------------------------------
procedure TRATTA_SOGGETTI
/*************************************************************************
  NOME:        TRATTA_SOGGETTI
  DESCRIZIONE: Esamina i contribuenti presenti nel file e se non sono
               gia' presenti in anagrafe li inserisce
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
  001     03/04/2023   VM          #54857 - inserimento dei contribuenti presenti in wrk_enc_contitolari
**************************************************************************/
( a_documento_id                number
, a_utente                      varchar2
, a_messaggio            in out varchar2
) is
  w_cod_pro_dage                number;
  w_cod_com_dage                number;
  w_ins_cont                    varchar2(1);  -- flag per inserimento contribuenti
  w_ni                          soggetti.ni%type;
  w_cod_pro_res                 soggetti.cod_pro_res%type;
  w_cod_com_res                 soggetti.cod_com_res%type;
  w_tr4_cod_via                 soggetti.cod_via%type;
  w_num_civ                     soggetti.num_civ%type;
  w_suffisso                    soggetti.suffisso%type;
  w_interno                     soggetti.interno%type;
  w_cap                         soggetti.cap%type;
  w_cod_pro_nas                 soggetti.cod_pro_nas%type;
  w_cod_com_nas                 soggetti.cod_com_nas%type;
  w_cognome_nome                soggetti.cognome_nome%type;
  w_tipo                        soggetti.tipo%type;
begin
  -- Estrazione comune dati generali
  begin
     select comu.provincia_stato
          , comu.comune
       into w_cod_pro_dage
          , w_cod_com_dage
       from dati_generali dage
          , ad4_comuni comu
      where dage.com_cliente = comu.comune
        and dage.pro_cliente = comu.provincia_stato
          ;
  exception
   when others then
      w_errore := 'Errore in recupero comune dati_generali '||
                  ' ('||sqlerrm||')';
      raise errore;
  end;
  --
  -- Trattamento soggetti
  --
  w_conta_soggetti := 0;
  for sel_ana in (select progr_dichiarazione
                       , cod_fiscale
                       , denominazione
                       , telefono
                       , email
                       , indirizzo
                       , num_civ
                       , scala
                       , piano
                       , interno
                       , cap
                       , comune
                       , provincia
                       , sesso
                       , data_nascita
                       , comune_nascita
                       , provincia_nascita
                       , null as progr_contitolare
                       , 'wrk_enc_testata' as tabella
                       , codice_tracciato
                       , nome
                    from wrk_enc_testata
                   where documento_id = a_documento_id
                   union
                   select weco.progr_dichiarazione
                       , weco.cod_fiscale
                       , weco.denominazione
                       , ''
                       , ''
                       , weco.indirizzo
                       , weco.num_civ
                       , weco.scala
                       , weco.piano
                       , weco.interno
                       , weco.cap
                       , weco.comune
                       , weco.provincia
                       , weco.sesso
                       , weco.data_nascita
                       , weco.comune_nascita
                       , weco.provincia_nascita
                       , weco.progr_contitolare
                       , 'wrk_enc_contitolari' as tabella
                       , wete.codice_tracciato
                       , ''
                    from wrk_enc_contitolari weco
                        ,wrk_enc_testata wete
                   where wete.documento_id = weco.documento_id
                        and wete.progr_dichiarazione = weco.progr_dichiarazione
                        and wete.documento_id = a_documento_id)
  loop
    --
    -- Controllo esistenza contribuente
    --
    begin
      select ni
           , 'N'
        into w_ni
           , w_ins_cont
        from contribuenti
       where cod_fiscale = sel_ana.cod_fiscale;
    exception
      when no_data_found then
        w_ni := to_number(null);
        w_ins_cont := 'S';
      when too_many_rows then
        w_errore := 'Contribuente '||sel_ana.cod_fiscale||' presente piu'' volte';
        raise errore;
      when others then
        w_errore := 'Errore in ricerca contribuente '||sel_ana.cod_fiscale||
                    '('||sqlerrm||')';
        raise errore;
    end;
    --
    -- Se non esiste il contribuente si controlla se esiste il soggetto
    --
    if w_ni is null then
       begin
         select max(ni)
           into w_ni
           from soggetti
          where cod_fiscale = sel_ana.cod_fiscale
         having max(ni) is not null;
       exception
         when no_data_found then
           w_ni := to_number(null);
         when others then
           w_errore := 'Errore in ricerca contribuente '||sel_ana.cod_fiscale||
                       '('||sqlerrm||')';
           raise errore;
       end;
    end if;
    --
    -- Se non esiste il soggetto, si inserisce dopo aver controllato i dati
    -- che necessitano di decodifica oppure di controllo
    --
    if w_ni is null then
       --
       -- Controllo luogo nascita
       --
       w_contarighe := 0;
       w_cod_pro_nas := to_number(null);
       w_cod_com_nas := to_number(null);
       for sel_res in (select com.provincia_stato
                            , com.comune
                            , com.cap
                         from ad4_provincie pro
                            , ad4_comuni com
                        where pro.sigla         = nvl(sel_ana.provincia_nascita,pro.sigla)
                          and pro.provincia     = com.provincia_stato
                          and com.denominazione like sel_ana.comune_nascita||'%'
                          and com.data_soppressione is null)
       loop
         w_contarighe := w_contarighe + 1;
         if w_contarighe = 1 then
            w_cod_pro_nas := sel_res.provincia_stato;
            w_cod_com_nas := sel_res.comune;
         end if;
       end loop;
       --
       -- Controllo residenza
       --
       w_contarighe := 0;
       w_cod_pro_res := to_number(null);
       w_cod_com_res := to_number(null);
       for sel_res in (select com.provincia_stato
                            , com.comune
                            , com.cap
                         from ad4_provincie pro
                            , ad4_comuni com
                        where pro.sigla         = nvl(sel_ana.provincia,pro.sigla)
                          and pro.provincia     = com.provincia_stato
                          and com.denominazione like sel_ana.comune||'%'
                          and com.data_soppressione is null)
       loop
         w_contarighe := w_contarighe + 1;
         if w_contarighe = 1 then
            w_cod_pro_res := sel_res.provincia_stato;
            w_cod_com_res := sel_res.comune;
         end if;
       end loop;
       --
       -- Anomalia residenza non codificata
       --
       if w_cod_pro_res is null and
          w_cod_com_res is null then
          ins_anomalie_car ( a_documento_id
                           , to_number(null)
                           , 'Comune/Provincia residenza non codificati'
                           , sel_ana.comune||' '||sel_ana.provincia
                           , sel_ana.cod_fiscale
                           , substr(sel_ana.denominazione,1,60)
                           );
       end if;
       --
       -- Ricerca indirizzo in archivio vie
       --
       if w_cod_pro_res = w_cod_pro_dage and
          w_cod_com_res = w_cod_com_dage then
          begin
            select cod_via
              into w_tr4_cod_via
              from denominazioni_via
             where descrizione like
                   '%'
                   || sel_ana.indirizzo
                   || '%'
               and rownum = 1
            ;
          exception
            when others then
              w_tr4_cod_via := to_number(null);
          end;
       else
          w_tr4_cod_via := to_number(null);
       end if;
       --
       -- Controllo campo numero civico
       --
       begin
          if instr(sel_ana.num_civ,'/') = 0 then
             w_num_civ := to_number(sel_ana.num_civ);
             w_suffisso := to_char(null);
          else
             w_num_civ := to_number(substr(sel_ana.num_civ,1,instr(sel_ana.num_civ,'/') -1));
             w_suffisso := substr(sel_ana.num_civ,instr(sel_ana.num_civ,'/') + 1);
          end if;
       exception
         when others then
           w_num_civ := to_number(null);
           w_suffisso := to_char(null);
           ins_anomalie_car ( a_documento_id
                            , to_number(null)
                            , 'Dati indirizzo: numero civico non numerico o di formato non corretto'
                            , sel_ana.num_civ
                            , sel_ana.cod_fiscale
                            , substr(sel_ana.denominazione,1,60)
                            );
       end;
       --
       -- Controllo campo interno
       --
       begin
         w_interno := to_number(sel_ana.interno);
       exception
         when others then
           w_interno := to_number(null);
           ins_anomalie_car ( a_documento_id
                            , to_number(null)
                            , 'Dati indirizzo: interno non numerico'
                            , sel_ana.interno
                            , sel_ana.cod_fiscale
                            , substr(sel_ana.denominazione,1,60)
                            );
       end;
       --
       -- Controllo campo cap
       --
       begin
         w_cap := to_number(sel_ana.cap);
       exception
         when others then
           w_cap := to_number(null);
           ins_anomalie_car ( a_documento_id
                            , to_number(null)
                            , 'Dati indirizzo: CAP non numerico'
                            , sel_ana.cap
                            , sel_ana.cod_fiscale
                            , substr(sel_ana.denominazione,1,60)
                            );
       end;
       --
       -- Scelta tipo e cognome_nome
       --
       w_tipo         := 1;
       w_cognome_nome := sel_ana.denominazione;
       if sel_ana.codice_tracciato = 'ECPF'
          and sel_ana.tabella = 'wrk_enc_testata'
          and length(trim(nvl(sel_ana.nome, ''))) > 0 then
          w_tipo         := 0;
          w_cognome_nome := sel_ana.denominazione||'/'||sel_ana.nome;
       end if;
       --
       -- Inserimento soggetto
       --
       w_conta_soggetti := w_conta_soggetti + 1;
       soggetti_nr (w_ni);
       begin
         insert into soggetti ( ni
                              , tipo_residente
                              , cod_fiscale
                              , cognome_nome
                              , cod_via
                              , denominazione_via
                              , num_civ
                              , suffisso
                              , scala
                              , piano
                              , interno
                              , cod_pro_res
                              , cod_com_res
                              , cap
                              , tipo
                              , fonte
                              , utente
                              , data_variazione
                              , note
                              , sesso
                              , data_nas
                              , cod_com_nas
                              , cod_pro_nas
                              )
         values ( w_ni
                , 1
                , sel_ana.cod_fiscale
                , w_cognome_nome
                , w_tr4_cod_via
                , decode(w_tr4_cod_via,to_char(null),sel_ana.indirizzo
                                                    ,to_char(null))
                , w_num_civ
                , w_suffisso
                , sel_ana.scala
                , sel_ana.piano
                , w_interno
                , w_cod_pro_res
                , w_cod_com_res
                , w_cap
                , w_tipo
                , w_fonte
                , a_utente
                , trunc(sysdate)
                , 'DA CARICAMENTO DICHIARAZIONI '|| sel_ana.codice_tracciato
                , sel_ana.sesso
                , sel_ana.data_nascita
                , w_cod_com_nas
                , w_cod_pro_nas
                );
       exception
         when others then
           w_errore := 'Errore in inserimento soggetto: '
                    || sel_ana.cod_fiscale
                    || ' ('
                    || sqlerrm
                    || ')';
           raise errore;
       end;
    end if;
    --
    -- Se il contribuente non esiste oppure non esisteva neanche il
    -- soggetto, si inserisce il contribuente
    --
    if w_ins_cont = 'S' then
       begin
         insert into contribuenti ( cod_fiscale
                                  , ni
                                  )
         values ( sel_ana.cod_fiscale
                , w_ni
                );
       exception
         when others then
           w_errore := 'Errore in inserimento soggetto: '
                    || sel_ana.cod_fiscale
                    || ' ('
                    || sqlerrm
                    || ')';
           raise errore;
       end;
    end if;
    if sel_ana.tabella = 'wrk_enc_testata' then
      --
      -- Aggiornamento ni su tabella WRK_ENC_TESTATA
      --
      begin
        update wrk_enc_testata
           set tr4_ni = w_ni
         where documento_id = a_documento_id
           and progr_dichiarazione = sel_ana.progr_dichiarazione;
      exception
        when others then
          w_errore := 'Errore in aggiornamento soggetto su WRK_ENC_TESTATA: '
                   || sel_ana.progr_dichiarazione
                   || ' ('
                   || sqlerrm
                   || ')';
          raise errore;
      end;
    elsif sel_ana.tabella = 'wrk_enc_contitolari' then
      --
      -- Aggiornamento ni su tabella WRK_ENC_CONTITOLARI
      --
      begin
        update wrk_enc_contitolari
           set tr4_ni = w_ni
         where documento_id = a_documento_id
           and progr_dichiarazione = sel_ana.progr_dichiarazione
           and progr_contitolare   = sel_ana.progr_contitolare;
      exception
        when others then
          w_errore := 'Errore in aggiornamento soggetto su WRK_ENC_CONTITOLARI: '
                   || sel_ana.progr_dichiarazione
                   ||' progr_contitolare: '|| sel_ana.progr_contitolare
                   || ' ('
                   || sqlerrm
                   || ')';
          raise errore;

      end;
    end if;
  end loop;
--
  a_messaggio := a_messaggio||' Soggetti inseriti: '||w_conta_soggetti||';';
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
 end;
----------------------------------------------------------------------------------
procedure TRATTA_TIPI_QUALITA
/*************************************************************************
  NOME:        TRATTA_TIPI_QUALITA
  DESCRIZIONE: Esamina i tipi qualita dei terreni presenti nel file e
               e se non esistono li inserisce nell'apposita tabella
  NOTE:
  Rev.    Date         Author      Note
  001     20/12/2021   VD          Modificata gestione terreni: ora si testa
                                   il tipo e anche la caratteristica (1,2)
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_documento_id             number
) is
  w_tipo_qualita              oggetti.tipo_qualita%type;
  w_conta_tipi                number := 0;
begin
  --
  -- Controllo tipi qualita ed eventuale popolamento della relativa tabella TIPI_QUALITA
  --
  select nvl(max(tipo_qualita),0)
    into w_tipo_qualita
    from tipi_qualita;
  --
  for sel_qua in ( select distinct categoria_catasto
                     from wrk_enc_immobili w
                    where documento_id = a_documento_id
                      and (tipo = 'T' or caratteristica in ('1','2'))
                      and not exists (select 'x' from tipi_qualita x
                                       where x.descrizione = w.categoria_catasto)
                    order by 1)
  loop
    w_tipo_qualita := w_tipo_qualita + 1;
    w_conta_tipi := w_conta_tipi + 1;
    begin
      insert into tipi_qualita ( tipo_qualita
                               , descrizione
                               )
      values ( w_tipo_qualita
             , sel_qua.categoria_catasto
             );
    exception
      when others then
        w_errore := 'Errore in inserimento TIPI_QUALITA: '
                 || sel_qua.categoria_catasto
                 || ' ('
                 || sqlerrm
                 || ')';
        raise errore;
    end;
  end loop;
--
--  dbms_output.put_line(' Tipi qualita'' inseriti: '||w_conta_tipi||';');
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
----------------------------------------------------------------------------------
procedure TRATTA_CATEGORIE_CATASTO
/*************************************************************************
  NOME:         TRATTA_CATEGORIE
  DESCRIZIONE: Esamina le categoria catastali presenti nel file e
               se non esistono li inserisce nell'apposita tabella
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_documento_id             number
) is
begin
  for sel_cat in (select distinct decode(nvl(length(wenc.categoria_catasto),0)
                                        ,2,substr(wenc.categoria_catasto,1,1)||
                                           lpad(substr(wenc.categoria_catasto,2),2,'0')
                                        ,3,replace(wenc.categoria_catasto,'/','0')
                                          ,substr(replace(wenc.categoria_catasto,'/',''),1,3)) categoria_catasto
                                  , wete.codice_tracciato
                    from wrk_enc_immobili wenc
                        ,wrk_enc_testata wete
                   where wete.documento_id = wenc.documento_id
                        and wete.progr_dichiarazione = wenc.progr_dichiarazione
                        and wenc.documento_id = a_documento_id
                        and wenc.tipo = 'U'
                        and not exists (select 'x' from categorie_catasto caca
                                      where caca.categoria_catasto =
                                            decode(length(wenc.categoria_catasto)
                                                  ,2,substr(wenc.categoria_catasto,1,1)||
                                                     lpad(substr(wenc.categoria_catasto,2),2,'0')
                                                  ,3,replace(wenc.categoria_catasto,'/','0')
                                                    ,substr(replace(wenc.categoria_catasto,'/',''),1,3))))
  loop
    begin
      insert into categorie_catasto ( categoria_catasto
                                    , descrizione
                                    )
      values ( sel_cat.categoria_catasto
             , 'DA CARICAMENTO DICHIARAZIONI '|| sel_cat.codice_tracciato
             );
    exception
      when others then
        w_errore := 'Errore in inserimento CATEGORIE_CATASTO: '
                 || sel_cat.categoria_catasto
                 || ' ('
                 || sqlerrm
                 || ')';
        raise errore;
    end;
  end loop;
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
----------------------------------------------------------------------------------
 procedure TRATTA_OGGETTI
/*************************************************************************
  NOME:         TRATTA_OGGETTI
  DESCRIZIONE: Esamina gli immobili e i terreni presenti nel file e
               se non esistono li inserisce nell'apposita tabella
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
  001     21/09/2018   VD          Modificati criteri di ricerca oggetto
  002     18/10/2019   VD          Corretta composizione estremi catasto:
                                   sostituita RPAD con LPAD
**************************************************************************/
( a_documento_id              number
, a_utente                    varchar2
, a_messaggio          in out varchar2
) is
  w_oggetto                   oggetti.oggetto%type;
  w_indirizzo_localita        varchar2(100);
  w_indirizzo_localita_1      varchar2(100);
  w_denom_ric                 denominazioni_via.descrizione%type;
  w_cod_via                   number;
  w_num_civ                   number;
  w_suffisso                  varchar2(5);
  w_flag_ins_oggetto          number;
begin
  --
  -- Trattamento oggetti
  --
  w_conta_oggetti := 0;
  for sel_ogg in ( select progr_dichiarazione
                        , tipo_immobile
                        --, num_ordine
                        , progr_immobile
                        , sezione
                        , foglio
                        , decode(greatest(5,nvl(length(numero),0))
                                ,5,numero
                                  ,substr(numero,1,5))                               numero
                        , subalterno
                        , tipo
                        , anno_catasto
                        , decode(greatest(36,nvl(length(indirizzo),0))
                                ,36,indirizzo
                                   ,substr(indirizzo,1,36))                          indirizzo_localita
                        , decode(nvl(length(caratteristica),0)
                                ,3,3
                                  ,to_number(caratteristica))                        tipo_oggetto
                        , decode(greatest(6,nvl(length(protocollo_catasto),0))
                                ,6,protocollo_catasto
                                  ,substr(protocollo_catasto,1,6))                   protocollo_catasto
                        , case when caratteristica in ('1','2')
                               then null
                               else decode(nvl(length(categoria_catasto),0)
                                                ,2,substr(categoria_catasto,1,1)||
                                                   lpad(substr(categoria_catasto,2),2,'0')
                                                ,3,replace(categoria_catasto,'/','0')
                                                  ,substr(replace(categoria_catasto,'/',''),1,3))
                          end                                                        categoria_catasto
                        , case when caratteristica in ('1','2')
                               then f_get_tipo_qualita(categoria_catasto)
                               else to_number(null)
                          end                                                        tipo_qualita
                        , decode(greatest(2,nvl(length(classe_catasto),0))
                                ,2,classe_catasto
                                  ,substr(classe_catasto,1,2))                       classe_catasto
                        , lpad(ltrim(nvl(sezione, ' '),'0'),3,' ') ||
                          lpad(ltrim(nvl(foglio,' '),'0'),5,' ') ||
                          lpad(ltrim(nvl(numero,' '),'0'),5,' ') ||
                          lpad(ltrim(nvl(subalterno, ' '),'0'),4,' ') ||
                          lpad(' ', 3)                                               estremi_catasto
                        , ltrim(decode(greatest(36,nvl(length(indirizzo),0))
                                       ,36,''
                                          ,'Indirizzo completo: '||indirizzo||';')||
                                decode(greatest(6,nvl(length(protocollo_catasto),0))
                                      ,6,''
                                        ,' Protocollo catasto: '||protocollo_catasto||';')||
                                decode(greatest(2,nvl(length(classe_catasto),0))
                                      ,2,''
                                        ,' Classe catasto: '||classe_catasto||';')||
                                decode(greatest(5,nvl(length(numero),0))
                                      ,5,''
                                        ,' Estremi catasto - numero: '||numero||';')
                               )  note
                     from wrk_enc_immobili
                    where documento_id = a_documento_id
                    --order by progr_dichiarazione,num_ordine)
                    order by progr_dichiarazione,tipo_immobile,progr_immobile )
  loop
    --
    -- Sistemazione dati indirizzo
    --
    w_indirizzo_localita := sel_ogg.indirizzo_localita;
    w_num_civ  := to_number(null);
    w_suffisso := to_char(null);
    BEGIN
      select cod_via,descrizione,w_indirizzo_localita
        into w_cod_via,w_denom_ric,w_indirizzo_localita_1
        from denominazioni_via devi
       where w_indirizzo_localita like '%'||devi.descrizione||'%'
         and devi.descrizione is not null
         and not exists (select 'x'
                           from denominazioni_via devi1
                          where w_indirizzo_localita
                                  like '%'||devi1.descrizione||'%'
                            and devi1.descrizione is not null
                            and devi1.cod_via != devi.cod_via)
         and rownum = 1
     ;
    EXCEPTION
      WHEN no_data_found then
        w_cod_via := 0;
      WHEN others THEN
        w_errore := 'Errore in ricerca indirizzo fabbricato - '||
                    'indir: '||w_indirizzo_localita||
                    ' ('||sqlerrm||')';
        raise errore;
    END;
    IF w_cod_via != 0 THEN
       BEGIN
         select substr(w_indirizzo_localita_1,
                (instr(w_indirizzo_localita_1,w_denom_ric)
                 + length(w_denom_ric)))
           into w_indirizzo_localita_1
           from dual
         ;
       EXCEPTION
         WHEN no_data_found THEN
           null;
         WHEN others THEN
           w_errore := 'Errore in decodifica indirizzo (1) - '||
                       'indir: '||w_indirizzo_localita||
                       ' ('||sqlerrm||')';
       END;
       BEGIN
         select
          substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9'),
           decode(
           sign(4 - (
           length(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
           -
           nvl(
           length(
           ltrim(
           translate(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
           '1234567890','9999999999'),'9')),0))),-1,4,
           length(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
           -
           nvl(
           length(
           ltrim(
           translate(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
           '1234567890','9999999999'),'9')),0))
          ) num_civ,
          ltrim(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')
           +
           length(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
           -
           nvl(
           length(
           ltrim(
           translate(
           substr(w_indirizzo_localita_1,
           instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
           '1234567890','9999999999'),'9')),0),
           5),
           ' /'
          ) suffisso
       into w_num_civ,w_suffisso
       from dual
       ;
       EXCEPTION
         WHEN no_data_found THEN
           w_num_civ  := to_number(null);
           w_suffisso := to_char(null);
         WHEN others THEN
           w_errore := 'Errore in decodifica numero civico e suffisso - '||
                       'indir: '||w_indirizzo_localita||
                        ' ('||sqlerrm||')';
       END;
    END IF; -- fine controllo cod_via != 0
    --dbms_output.put_line('>>Num.ordine: '||sel_ogg.num_ordine);
    --dbms_output.put_line('>>Progr.immobile: '||sel_ogg.progr_immobile);
    --dbms_output.put_line('Estremi catasto: '||sel_ogg.estremi_catasto);
    --dbms_output.put_line('Categoria catasto: '||sel_ogg.categoria_catasto);
    --
    -- Si ricerca l'oggetto per estremi catastali e, se e' un immobile,
    -- per la prima lettera della categoria catastale
    -- (VD - 20/09/2018): modificata ricerca oggetto
    --
    w_flag_ins_oggetto := 0;
    w_oggetto          := to_number(null);
    --
    if sel_ogg.estremi_catasto is not null then
       if sel_ogg.tipo_oggetto in ('1','2') then
       -- Terreni: si ricerca l'oggetto per estremi catastali, tipo oggetto e tipo qualità
          select max(oggetto)
            into w_oggetto
            from oggetti ogge
           where ogge.estremi_catasto = sel_ogg.estremi_catasto
             and to_char(ogge.tipo_oggetto) = sel_ogg.tipo_oggetto
             and nvl(ogge.tipo_qualita,-1) = nvl(sel_ogg.tipo_qualita,-1);
       -- Terreni: se la ricerca fallisce, si ricerca l'oggetto per estremi catastali e tipo oggetto
          if w_oggetto is null then
             select max(oggetto)
               into w_oggetto
               from oggetti ogge
              where ogge.estremi_catasto = sel_ogg.estremi_catasto
                and to_char(ogge.tipo_oggetto) = sel_ogg.tipo_oggetto;
          end if;
       else
       -- Immobili: si ricerca l'oggetto per estremi catastali, tipo oggetto e categoria catasto
          select max(oggetto)
            into w_oggetto
            from oggetti ogge
           where ogge.estremi_catasto = sel_ogg.estremi_catasto
             and to_char(ogge.tipo_oggetto) = sel_ogg.tipo_oggetto
             and nvl(ogge.categoria_catasto,'   ') = nvl(sel_ogg.categoria_catasto,'   ');
--       and (sel_ogg.tipo = 'T' or
--           (sel_ogg.tipo = 'U' and
--            substr(sel_ogg.categoria_catasto,1,1) = substr(ogge.categoria_catasto,1,1)));
          if w_oggetto is null then
             -- Immobili: se la ricerca fallisce, si ricerca per estremi catastali, tipo oggetto
             -- e prima lettera della categoria catastale
             select max(oggetto)
               into w_oggetto
               from oggetti ogge
              where ogge.estremi_catasto = sel_ogg.estremi_catasto
                and to_char(ogge.tipo_oggetto) = sel_ogg.tipo_oggetto
                and substr(nvl(ogge.categoria_catasto,'   '),1,1) =
                    substr(nvl(sel_ogg.categoria_catasto,'   '),1,1);
          end if;
          --
          -- se il subalterno è nullo e non esiste un oggetto con la stessa categoria
          -- catastale, si interrompe la ricerca. Questo per evitare di abbinare
          -- immobili con stessi estremi catastali (subalterno escluso perché nullo)
          -- ad un unico oggetto anche se con categoria catastale diversa
          --
          if sel_ogg.subalterno is not null then
             if w_oggetto is null then
                -- se la ricerca precedente fallisce, si ricerca per estremi catastali
                -- e tipo oggetto
                select max(oggetto)
                  into w_oggetto
                  from oggetti ogge
                 where ogge.estremi_catasto = sel_ogg.estremi_catasto
                   and to_char(ogge.tipo_oggetto) = sel_ogg.tipo_oggetto;
             end if;
          end if;
       end if;
       -- Terreni/Immobili: se la ricerca precedente fallisce e i dati catastali sono completi,
       -- si ricerca solo per estremi catastali
       if sel_ogg.subalterno is not null then
          if w_oggetto is null then
             select max(oggetto)
               into w_oggetto
               from oggetti ogge
              where ogge.estremi_catasto = sel_ogg.estremi_catasto;
          end if;
       end if;
    end if;
    --
    -- Se tutte le ricerche falliscono, si inserisce un nuovo oggetto
    --
    if w_oggetto is null then
       w_flag_ins_oggetto := 1;
       w_conta_oggetti := w_conta_oggetti + 1;
       oggetti_nr(w_oggetto);
       begin
         insert into oggetti ( oggetto
                             , tipo_oggetto
                             , indirizzo_localita
                             , cod_via
                             , num_civ
                             , suffisso
                             , sezione
                             , foglio
                             , numero
                             , subalterno
                             , protocollo_catasto
                             , anno_catasto
                             , categoria_catasto
                             , classe_catasto
                             , tipo_qualita
                             , fonte
                             , utente
                             , data_variazione
                             , note
                             )
         values ( w_oggetto
                , sel_ogg.tipo_oggetto
                , substr(w_indirizzo_localita,1,36)
                , decode(w_cod_via,0,to_number(null),w_cod_via)
                , decode(w_num_civ,0,to_number(null),w_num_civ)
                , w_suffisso
                , sel_ogg.sezione
                , sel_ogg.foglio
                , sel_ogg.numero
                , sel_ogg.subalterno
                , sel_ogg.protocollo_catasto
                , sel_ogg.anno_catasto
                , sel_ogg.categoria_catasto
                , sel_ogg.classe_catasto
                , sel_ogg.tipo_qualita
                , w_fonte
                , a_utente
                , trunc(sysdate)
                , sel_ogg.note
                );
       exception
         when others then
           w_errore := 'Errore in inserimento OGGETTI: '
                    || sel_ogg.indirizzo_localita ||' - '
                    || sel_ogg.estremi_catasto
                    || ' ('
                    || sqlerrm
                    || ')';
           raise errore;
       end;
    end if;
    --
    -- Si aggiorna la tabella wrk_enc_immobili con l'oggetto di TR4
    --
    begin
      update wrk_enc_immobili
         set tr4_oggetto     = decode(w_flag_ins_oggetto,1,to_number(null),w_oggetto)
           , tr4_oggetto_new = decode(w_flag_ins_oggetto,1,w_oggetto,to_number(null))
       where documento_id = a_documento_id
         and progr_dichiarazione = sel_ogg.progr_dichiarazione
         and tipo_immobile = sel_ogg.tipo_immobile
--         and num_ordine = sel_ogg.num_ordine;
         and progr_immobile = sel_ogg.progr_immobile;
    exception
      when others then
        w_errore := 'Errore in aggiornamento oggetto su WRK_ENC_IMMOBILI: '
                 || sel_ogg.progr_dichiarazione
--                 || sel_ogg.num_ordine
                 || sel_ogg.progr_immobile
                 || ' ('
                 || sqlerrm
                 || ')';
        raise errore;
    end;
  end loop;
--
  a_messaggio := a_messaggio||' Oggetti inseriti: '||w_conta_oggetti||';';
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto')||' '||w_oggetto);
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100)||' '||w_oggetto);
end;
----------------------------------------------------------------------------------
procedure TRATTA_PRATICHE
/*************************************************************************
  NOME:         TRATTA_PRATICHE
  DESCRIZIONE: Esamina le dichiarazioni presenti nel file e le carica
               nelle apposite tabelle, per IMU e/o TASI a seconda del
               parametro presente in installazione_parametri.
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
  001     21/09/2018   VD          Aggiunta gestione variazioni in corso
                                   d'anno
  002     03/04/2023   VM          Gestione contitolari
**************************************************************************/
( a_documento_id              number
, a_utente                    varchar2
, a_messaggio          in out varchar2
) is
  w_parametro                 installazione_parametri.valore%type;
  w_tipo_tributo              varchar2(5);
  w_pos                       number;
  w_data_var                  date;
  w_perc_possesso             number;
  w_flag_possesso             varchar2(1);
  w_mesi_possesso             number;
  w_mesi_possesso_1s          number;
  w_da_mese_possesso          number;
  w_flag_esclusione           varchar2(1);
  w_mesi_esclusione           number;
  w_diff_mesi                 number;
  w_diff_mesi_1s              number;
  w_mesi_possesso_var         number;
  w_mesi_possesso_var_1s      number;
  w_flag_possesso_var         varchar2(1);
  w_mesi_esclusione_var       number;
  w_pratica                   number;
  w_oggetto_pratica           number;
  w_fonte_oggetto             number;
  w_anno_oggetto              number;
  w_perc_possesso_prec        number;
  w_tipo_oggetto_prec         number;
  w_categoria_prec            varchar2(3);
  w_classe_prec               varchar2(2);
  w_valore_prec               number;
  w_titolo_prec               varchar2(1);
  w_flag_esclusione_prec      varchar2(1);
  w_flag_ab_princ_prec        varchar2(1);
  w_cf_prec                   varchar2(16);
  w_ogpr_prec                 number;
  w_valore_prec_anno_dich     number;
  w_mesi_possesso_prec        number;
  w_mesi_possesso_1sem_prec   number;
  w_mesi_esclusione_prec      number;
  w_flag_denuncia             number;
  w_tipo_anomalia_var         number := 41; -- tipI anomalia per inserimento ANOMALIE_ICI
  w_tipo_anomalia_ins         number := 42;
  w_oggetto_prec              number;
  w_righe_oggetto             number;
begin
  --
  -- Selezione tipi tributo previsti per caricamento
  -- dichiarazione
  begin
    select nvl(trim (upper (valore)),'ICI')
      into w_parametro
      from installazione_parametri
     where parametro = 'TITR_DIENC';
  exception
    when no_data_found then
      w_parametro := 'ICI';
    when others then
      w_errore := 'Errore in selezione parametro TITR_DIENC'
                 || ' ('
                 || sqlerrm
                 || ')';
      raise errore;
  end;
  --
  -- Trattamento tipi tributo da parametri installazione
  --
  w_conta_pratiche_ici := 0;
  w_conta_pratiche_tasi := 0;
  while w_parametro is not null
  loop
    w_pos := nvl (instr (w_parametro, ' '), 0);
    if w_pos = 0 then
       w_tipo_tributo := w_parametro;
       w_parametro    := null;
    else
       w_tipo_tributo := substr (w_parametro, 1, w_pos - 1);
    end if;
    if w_pos < length (w_parametro) and w_pos > 0 then
       w_parametro := substr (w_parametro, w_pos + 1);
    else
       w_parametro := null;
    end if;
    --
    -- Trattamento denunce
    --
    for sel_dic in ( select *
                       from wrk_enc_testata wkte
                      where wkte.documento_id = a_documento_id
                        and exists (select 'x' from wrk_enc_immobili wkim
                                     where wkim.documento_id = wkte.documento_id
                                       and wkim.progr_dichiarazione = wkte.progr_dichiarazione)
                      order by progr_dichiarazione )
    loop
      --
      -- La testata della pratica viene inserita al momento dell'inserimento del primo dettaglio
      --
      w_pratica := to_number(null);
      w_flag_denuncia := 0;
      w_oggetto_prec  := 0;
      w_righe_oggetto := 0;
      for sel_imm in ( select nvl(tr4_oggetto,tr4_oggetto_new) tr4_oggetto
                            , progr_immobile
                            , tipo_attivita
                            , decode(nvl(data_var_imposta,'00000000')
                                    ,'00000000',to_date('0101'||sel_dic.anno_imposta,'ddmmyyyy')
                                    ,to_date(data_var_imposta,'ddmmyyyy')
                                    ) data_var_imposta
                            , perc_possesso
                            , flag_acquisto
                            , flag_cessione
                            , nvl(flag_altro,0) flag_altro
                            , descrizione_altro
                            , num_ordine
                            , tipo_immobile
                            , valore
                            , immobile_esente
                            , d_corrispettivo_medio
                            , d_costo_medio
                            , d_rapporto_superficie
                            , d_rapporto_sup_gg
                            , d_rapporto_soggetti
                            , d_rapporto_sogg_gg
                            , d_rapporto_giorni
                            , d_perc_imponibilita
                            , d_valore_ass_art_5
                            , d_valore_ass_art_4
                            , d_casella_rigo_g
                            , d_casella_rigo_h
                            , d_rapporto_cms_cm
                            , d_valore_ass_parziale
                            , d_valore_ass_compl
                            , a_corrispettivo_medio_perc
                            , a_corrispettivo_medio_prev
                            , a_rapporto_superficie
                            , a_rapporto_sup_gg
                            , a_rapporto_soggetti
                            , a_rapporto_sogg_gg
                            , a_rapporto_giorni
                            , a_perc_imponibilita
                            , a_valore_assoggettato
                            , nvl(agenzia_entrate,estremi_titolo) estremi_titolo
                            , case
                                 when decode(nvl(length(caratteristica),0)
                                             ,3,3
                                             ,to_number(caratteristica)) in (5,5.1,5.2,6,7,7.1,7.2,7.3,8)
                                      then 3
                                 else
                                      decode(nvl(length(caratteristica),0)
                                             ,3,3
                                             ,to_number(caratteristica))
                              end tipo_oggetto
                            , decode(greatest(6,nvl(length(protocollo_catasto),0))
                                    ,6,protocollo_catasto
                                      ,substr(protocollo_catasto,1,6))                   protocollo_catasto
                            , decode(tipo,'U',decode(nvl(length(categoria_catasto),0)
                                                    ,2,substr(categoria_catasto,1,1)||
                                                       lpad(substr(categoria_catasto,2),2,'0')
                                                    ,3,replace(categoria_catasto,'/','0')
                                                      ,substr(replace(categoria_catasto,'/',''),1,3))
                                         ,to_char(null))                                 categoria_catasto
                            , decode(greatest(2,nvl(length(classe_catasto),0))
                                    ,2,classe_catasto
                                      ,substr(classe_catasto,1,2))                       classe_catasto
                            , decode(tipo,'T',f_get_tipo_qualita(categoria_catasto)
                                              ,to_number(null))                          tipo_qualita
                            , decode(flag_acquisto,1,'A'
                                                    ,decode(flag_cessione,1,'C',null)
                                    )                                                    titolo
                            , ltrim(annotazioni||
                                    decode(tr4_oggetto,null,null
                                                      ,'Indirizzo orig.: '||indirizzo)||
                                    decode(greatest(6,nvl(length(protocollo_catasto),0))
                                          ,6,''
                                            ,' Protocollo catasto orig.: '||protocollo_catasto||';')||
                                    decode(greatest(2,nvl(length(classe_catasto),0))
                                          ,2,''
                                            ,' Classe catasto orig.: '||classe_catasto||';')||
                                    decode(length(trim(nvl(descrizione_altro, ''))),0,'',' Descrizione: '||descrizione_altro))  note
                            , decode(detrazione, 0, null, detrazione) detrazione
                            , case
                                 when substr(data_var_imposta,1,2) between 1 and 31 and
                                      substr(data_var_imposta,3,2) between 1 and 12 then
                                      to_date(data_var_imposta,'ddmmyyyy')
                                 else
                                      null
                              end data_evento
                         from wrk_enc_immobili
                        where documento_id = a_documento_id
                          and progr_dichiarazione = sel_dic.progr_dichiarazione
                        order by 1  --oggetto
                               , 4  -- data_var_imposta
                               , 10 --num_ordine
                     )
      loop
        if sel_imm.tr4_oggetto <> w_oggetto_prec then
           w_oggetto_prec  := sel_imm.tr4_oggetto;
           w_righe_oggetto := 0;
        end if;
        --
        -- Determinazione dati possesso
        --
        w_righe_oggetto := w_righe_oggetto + 1;
        w_oggetto_pratica := to_number(null);
        w_perc_possesso := sel_imm.perc_possesso;
        w_flag_possesso := 'S';
        w_data_var      := sel_imm.data_var_imposta;
        if w_data_var is null or
           (sel_imm.flag_acquisto = 0 and
            sel_imm.flag_altro = 0 and
            sel_imm.flag_cessione = 0) then
           w_mesi_possesso    := 12;
           w_mesi_possesso_1s := 6;
           w_da_mese_possesso := 1;
        else
           if sel_imm.flag_acquisto = 1 or
              (sel_imm.flag_altro = 1 and w_righe_oggetto > 1) then
              w_mesi_possesso := 13 - to_number(to_char(w_data_var,'mm'));
              w_da_mese_possesso := to_number(to_char(w_data_var,'mm'));
              if to_number(to_char(w_data_var,'dd')) > 15 then
                 w_mesi_possesso := w_mesi_possesso -1;
                 if w_da_mese_possesso < 12 then
                    w_da_mese_possesso := w_da_mese_possesso + 1;
                 end if;
              end if;
              if w_da_mese_possesso > 6 then
                 w_mesi_possesso_1s := 0;
              else
                 w_mesi_possesso_1s := 7 - w_da_mese_possesso;
              end if;
           end if;
           if sel_imm.flag_cessione = 1 or
              (sel_imm.flag_altro = 1 and w_righe_oggetto = 1) then
              w_flag_possesso := null;
              w_mesi_possesso := to_number(to_char(w_data_var,'mm'));
              w_da_mese_possesso := 1;
              if to_number(to_char(w_data_var,'dd')) <= 15 then
                 w_mesi_possesso := w_mesi_possesso -1;
              end if;
              if w_mesi_possesso > 6 then
                 --w_mesi_possesso_1s := w_mesi_possesso - 6;
                 w_mesi_possesso_1s := 6;
              else
                 w_mesi_possesso_1s := w_mesi_possesso;
              end if;
           end if;
        end if;
        --
        -- Determinazione dati esclusione
        --
        if sel_imm.immobile_esente = 1 then
           w_flag_esclusione := w_flag_possesso;
           w_mesi_esclusione := w_mesi_possesso;
        else
           w_flag_esclusione := null;
           w_mesi_esclusione := to_number(null);
        end if;
        --
        -- Se si tratta di acquisto, si verifica che non esista già una dichiarazione
        -- per lo stesso oggetto: se esiste già con dati diversi, si segnala in
        -- anomalie_ici ma si carica comunque; se esiste con gli stessi dati, si segnala
        -- in anomalie_caricamento e non si carica
        if sel_imm.flag_acquisto = 1 then
           w_flag_denuncia := f_esiste_pratica ( w_tipo_tributo
                                               , sel_dic.cod_fiscale
                                               , sel_dic.anno_imposta
                                               , sel_imm.tr4_oggetto
                                               , w_flag_possesso
                                               , w_mesi_possesso
                                               , w_mesi_possesso_1s
                                               , w_perc_possesso
                                               , w_flag_esclusione
                                               , w_mesi_esclusione
                                               );
           if w_flag_denuncia = 2 then
              -- si il flag_denuncia è 2 significa che la denuncia è già presente
              -- con dati diversi: si inserisce un'anomalia in anomalie_ici ma
              -- la denuncia viene comunque caricata
              ins_anomalie_ici ( sel_dic.anno_imposta
                               , sel_dic.cod_fiscale
                               , trunc(sysdate)
                               , null
                               , null
                               , sel_imm.tr4_oggetto
                               , w_tipo_anomalia_ins
                               );
           end if;
        end if;
        --
        -- Se si tratta di cessione, si verifica se lo stesso oggetto e' gia' presente
        -- nella stessa dichiarazione (immobile acquisito e ceduto nello stesso anno).
        -- Se si', si aggiornano i dati inseriti per l'acquisizione accorciando il
        -- periodo di possesso (e non si inserisce nessun dettaglio nella pratica)
        --
        if sel_imm.flag_cessione = 1 and
           w_pratica is not null then
           w_oggetto_pratica := f_get_oggetto_pratica (w_pratica, sel_imm.tr4_oggetto);
           if w_oggetto_pratica is not null then
              w_diff_mesi := 12 - w_mesi_possesso;
              w_diff_mesi_1s := 6 - w_mesi_possesso_1s;
              w_flag_possesso := null;
              begin
                update oggetti_contribuente
                   set mesi_possesso = mesi_possesso - w_diff_mesi
                     , mesi_possesso_1sem = mesi_possesso_1sem - w_diff_mesi_1s
                     , flag_possesso = w_flag_possesso
                 where cod_fiscale = sel_dic.cod_fiscale
                   and oggetto_pratica = w_oggetto_pratica;
              exception
                when others then
                  w_errore := 'Errore in aggiornamento oggetti_contribuente (Cessione) ' ||
                              f_descrizione_titr(w_tipo_tributo,sel_dic.anno_imposta) || ' '||
                              sel_dic.cod_fiscale || ' '||w_oggetto_pratica ||
                              ' (' || sqlerrm || ')';
                  raise errore;
              end;
           end if;
        end if;

        --
        -- Inserimento dettaglio pratica
        --
        if w_oggetto_pratica is null and
           w_flag_denuncia <> 1 then
           oggetti_pratica_nr(w_oggetto_pratica);
           if w_pratica is null then
              pratiche_tributo_nr(w_pratica);
              if w_tipo_tributo = 'ICI' then
                 w_conta_pratiche_ici := w_conta_pratiche_ici + 1;
              else
                 w_conta_pratiche_tasi := w_conta_pratiche_tasi + 1;
              end if;
              ins_dati_pratica ( a_documento_id
                               , sel_dic.progr_dichiarazione
                               , w_pratica
                               , sel_dic.cod_fiscale
                               , w_tipo_tributo
                               , sel_dic.anno_imposta
                               , w_tipo_pratica
                               , 'I'
                               , nvl(w_data_var,to_date(to_char('0101'||sel_dic.anno_imposta),'ddmmyyyy'))
                               , a_utente
                               , trunc(sysdate)
                               , ''
                               , sel_dic.firma_dichiarazione
                               , w_fonte
                               /*, sel_dic.imu_dovuta
                               , sel_dic.eccedenza_imu_dic_prec
                               , sel_dic.eccedenza_imu_dic_prec_f24
                               , sel_dic.rate_imu_versate
                               , sel_dic.imu_debito
                               , sel_dic.imu_credito
                               , sel_dic.imu_credito_dic_presente
                               , sel_dic.credito_imu_rimborso
                               , sel_dic.credito_imu_compensazione
                               , sel_dic.tasi_dovuta
                               , sel_dic.eccedenza_tasi_dic_prec
                               , sel_dic.eccedenza_tasi_dic_prec_f24
                               , sel_dic.tasi_rate_versate
                               , sel_dic.tasi_debito
                               , sel_dic.tasi_credito
                               , sel_dic.tasi_credito_dic_presente
                               , sel_dic.credito_tasi_rimborso
                               , sel_dic.credito_tasi_compensazione */
                               , sel_dic.codice_tracciato
                               );
           end if;
           ins_dati_oggetto_pratica ( a_documento_id
                                    , sel_dic.progr_dichiarazione
                                    , sel_imm.tipo_immobile
                                    , sel_imm.progr_immobile
                                    , sel_imm.num_ordine
                                    , sel_imm.tipo_attivita
                                    , sel_imm.detrazione
                                    , w_tipo_tributo
                                    , sel_dic.cod_fiscale
                                    , w_oggetto_pratica
                                    , sel_imm.tr4_oggetto
                                    , sel_imm.tipo_oggetto
                                    , w_pratica
                                    , sel_dic.anno_imposta
                                    , sel_imm.categoria_catasto
                                    , sel_imm.classe_catasto
                                    , sel_imm.tipo_qualita
                                    , sel_imm.valore
                                    , sel_imm.titolo
                                    , sel_imm.estremi_titolo
                                    , w_fonte
                                    , 'D'
                                    , w_perc_possesso
                                    , w_mesi_possesso
                                    , w_mesi_possesso_1s
                                    , w_da_mese_possesso
                                    , w_mesi_esclusione
                                    , w_flag_possesso
                                    , w_flag_esclusione
                                    , a_utente
                                    , trunc(sysdate)
                                    , sel_imm.note
                                    , sel_imm.d_corrispettivo_medio
                                    , sel_imm.d_costo_medio
                                    , sel_imm.d_rapporto_superficie
                                    , sel_imm.d_rapporto_sup_gg
                                    , sel_imm.d_rapporto_soggetti
                                    , sel_imm.d_rapporto_sogg_gg
                                    , sel_imm.d_rapporto_giorni
                                    , sel_imm.d_perc_imponibilita
                                    , sel_imm.d_valore_ass_art_5
                                    , sel_imm.d_valore_ass_art_4
                                    , sel_imm.d_casella_rigo_g
                                    , sel_imm.d_casella_rigo_h
                                    , sel_imm.d_rapporto_cms_cm
                                    , sel_imm.d_valore_ass_parziale
                                    , sel_imm.d_valore_ass_compl
                                    , sel_imm.a_corrispettivo_medio_perc
                                    , sel_imm.a_corrispettivo_medio_prev
                                    , sel_imm.a_rapporto_superficie
                                    , sel_imm.a_rapporto_sup_gg
                                    , sel_imm.a_rapporto_soggetti
                                    , sel_imm.a_rapporto_sogg_gg
                                    , sel_imm.a_rapporto_giorni
                                    , sel_imm.a_perc_imponibilita
                                    , sel_imm.a_valore_assoggettato
                                    , sel_dic.codice_tracciato
                                    , sel_imm.data_evento
                                    );
         end if;
         --
         -- (VM - 05/04/2023 - #54857): Gestione contitolari dell'immobile
         --
         for sel_contitolare in ( select progr_contitolare
                                        , denominazione
                                        , cod_fiscale
                                        , indirizzo
                                        , num_civ
                                        , scala
                                        , piano
                                        , interno
                                        , cap
                                        , comune
                                        , provincia
                                        , perc_possesso
                                        , detrazione
                                        , firma_contitolare
                                        , sesso
                                        , data_nascita
                                        , comune_nascita
                                        , provincia_nascita
                                   from wrk_enc_contitolari
                                   where documento_id = a_documento_id
                                         and progr_dichiarazione = sel_dic.progr_dichiarazione
                                         and num_ordine = sel_imm.num_ordine
                                   )
         loop
           --
           -- Inserimento contitolari
           --
           ins_dati_oggetto_contribuente(sel_contitolare.cod_fiscale
                                         , w_oggetto_pratica
                                         , sel_dic.anno_imposta
                                         , 'C'                            -- (C = contitolare)
                                         , sel_contitolare.perc_possesso
                                         , w_mesi_possesso
                                         , w_mesi_possesso_1s
                                         , w_da_mese_possesso
                                         , w_mesi_esclusione
                                         , w_flag_possesso
                                         , w_flag_esclusione
                                         , sel_contitolare.detrazione
                                         , a_utente
                                         , trunc(sysdate)
                                         , w_tipo_tributo
                                         , w_pratica
                                         , ''
                                         );
         end loop;
      end loop;
      --
      -- (VD - 09/01/2020): Archiviazione denuncia appena inserita
      --
      archivia_denunce('','',w_pratica);
    end loop;
  end loop;
--
  a_messaggio := a_messaggio||' Denunce IMU inserite: '||w_conta_pratiche_ici||';'
                            ||' Denunce TASI inserite: '||w_conta_pratiche_tasi||';';
--
exception
   when errore then
      rollback;
      raise_application_error(-20999,nvl(w_errore,'vuoto'));
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||SQLERRM);
end;
----------------------------------------------------------------------------------
procedure ESEGUI
/*************************************************************************
  NOME:         ESEGUI
  DESCRIZIONE: Esegue in sequenza le procedure per caricare i dati
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
**************************************************************************/
( a_documento_id                   number
, a_utente                         varchar2
, a_messaggio               in out varchar2
) is
begin
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
  w_messaggio := '';
  w_conta_anomalie_car := 0;
  w_conta_anomalie_ici := 0;
  --
  CARICA_DIC_ENC_ECPF.CARICA_DICHIARAZIONI (a_documento_id,a_utente,w_messaggio);
  w_fonte := f_get_fonte(a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_SOGGETTI (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC_ECPF.TRATTA_TIPI_QUALITA (a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_CATEGORIE_CATASTO (a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_OGGETTI (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC_ECPF.TRATTA_PRATICHE (a_documento_id,a_utente,w_messaggio);
  --
  if w_conta_anomalie_car > 0 then
     w_messaggio := w_messaggio || ' Anomalie caricamento inserite: '||w_conta_anomalie_car;
  end if;
  --
  if w_conta_anomalie_ici > 0 then
     w_messaggio := w_messaggio || ' Anomalie da verificare: '||w_conta_anomalie_ici;
  end if;
  --
  -- A fine elaborazione si aggiorna lo stato del documento trattato
  --
  begin
     update documenti_caricati
        set stato = 2
          , data_variazione = sysdate
          , utente = a_utente
          , note = substr(w_messaggio,1,2000)
      where documento_id = a_documento_id
          ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in Aggiornamento Stato del documento '||
                                   ' ('||sqlerrm||')';
  end;
  --
  a_messaggio := w_messaggio;
end;


procedure ESEGUI_WEB
/*************************************************************************
  NOME:         ESEGUI_WEB
  DESCRIZIONE: Esegue in sequenza le procedure per caricare i dati
  NOTE:
  Rev.    Date         Author      Note
  000     13/06/2025   DM          Prima emissione
**************************************************************************/
( a_documento_id                   number
, a_utente                         varchar2
, a_messaggio               in out varchar2
) is
begin
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
  w_messaggio := '';
  w_conta_anomalie_car := 0;
  w_conta_anomalie_ici := 0;
  --
  w_fonte := f_get_fonte(a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_SOGGETTI (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC_ECPF.TRATTA_TIPI_QUALITA (a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_CATEGORIE_CATASTO (a_documento_id);
  CARICA_DIC_ENC_ECPF.TRATTA_OGGETTI (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC_ECPF.TRATTA_PRATICHE (a_documento_id,a_utente,w_messaggio);
  --
  if w_conta_anomalie_car > 0 then
     w_messaggio := w_messaggio || ' Anomalie caricamento inserite: '||w_conta_anomalie_car;
  end if;
  --
  if w_conta_anomalie_ici > 0 then
     w_messaggio := w_messaggio || ' Anomalie da verificare: '||w_conta_anomalie_ici;
  end if;
  --
  -- A fine elaborazione si aggiorna lo stato del documento trattato
  --
  begin
     update documenti_caricati
        set stato = 2
          , data_variazione = sysdate
          , utente = a_utente
          , note = substr(w_messaggio,1,2000)
      where documento_id = a_documento_id
          ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in Aggiornamento Stato del documento '||
                                   ' ('||sqlerrm||')';
  end;
  --
  a_messaggio := w_messaggio;
end;
----------------------------------------------------------------------------------
end CARICA_DIC_ENC_ECPF;
/
