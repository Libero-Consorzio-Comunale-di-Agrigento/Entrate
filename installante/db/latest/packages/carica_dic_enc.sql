--liquibase formatted sql 
--changeset abrandolini:20250326_152429_carica_dic_enc stripComments:false runOnChange:true 
 
create or replace package CARICA_DIC_ENC is
/******************************************************************************
 NOME:        CARICA_DIC_ENC
 DESCRIZIONE: Procedure e Funzioni per caricamento dichiarazioni ENC.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
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
  procedure CARICA_DICHIARAZIONI_ENC
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure TRATTA_SOGGETTI_ENC
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
  procedure TRATTA_OGGETTI_ENC
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure TRATTA_PRATICHE_ENC
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
  procedure ESEGUI
  ( a_documento_id           number
  , a_utente                 varchar2
  , a_messaggio       in out varchar2
  );
end CARICA_DIC_ENC;
/
create or replace package body CARICA_DIC_ENC is
/******************************************************************************
  NOME:        CARICA_DIC_ENC.
  DESCRIZIONE: Procedure e Funzioni per caricamento dichiarazioni ENC.
  ANNOTAZIONI: .
  REVISIONI: .
  Rev.  Data        Autore  Descrizione.
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
           , nvl(a_note,'Caricamento dich. ENC')
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
, a_tipo_tributo                   pratiche_tributo.tipo_tributo%type
, a_cod_fiscale                    oggetti_contribuente.cod_fiscale%type
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
)
is
  w_oggetto_pratica                oggetti_pratica.oggetto_pratica%type;
begin
  w_oggetto_pratica := null;
  oggetti_pratica_nr(w_oggetto_pratica);
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
    values ( w_oggetto_pratica
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
           , a_note||decode(a_note,'','',' - ')||'Da caricamento dichiarazione ENC'
           );
  exception
    when others then
      w_errore := 'Errore in inserimento oggetti_pratica doppio quadro ' ||
                  f_descrizione_titr(a_tipo_tributo,a_anno) || ' '||
                  a_cod_fiscale || ' (' || sqlerrm || ')';
      raise errore;
  end;
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
              , utente
              , data_variazione
              )
    values ( a_cod_fiscale
           , w_oggetto_pratica
           , a_anno
           , a_tipo_rapporto
           , a_perc_possesso
           , a_mesi_possesso
           , a_mesi_possesso_1sem
           , a_da_mese_possesso
           , a_mesi_esclusione
           , a_flag_possesso
           , a_flag_esclusione
           , a_utente
           , a_data_variazione
           );
  exception
    when others then
      w_errore := 'Errore in inserim. oggetti_contribuente ' ||
                  f_descrizione_titr(a_tipo_tributo,a_anno) ||
                  a_cod_fiscale || ' (' || sqlerrm || ')';
      raise errore;
  end;
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
          set tr4_oggetto_pratica_ici  = decode(a_tipo_tributo,'ICI',w_oggetto_pratica,tr4_oggetto_pratica_ici)
            , tr4_oggetto_pratica_tasi = decode(a_tipo_tributo,'ICI',tr4_oggetto_pratica_tasi,w_oggetto_pratica)
        where documento_id        = a_documento_id
          and progr_dichiarazione = a_progr_dichiarazione
          and tipo_immobile       = a_tipo_immobile
          and progr_immobile      = a_progr_immobile;
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
procedure CARICA_DICHIARAZIONI_ENC
/*************************************************************************
  NOME:        CARICA_DICHIARAZIONI_ENC
  DESCRIZIONE: Carica i dati delle dichiarazioni IMU/TASI degli enti
               non commerciali nelle tabelle di appoggio
  NOTE:
  Rev.    Date         Author      Note
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
  w_commenti                  number := 0;
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
     while w_posizione < w_dimensione_file
     loop
       w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
       w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
       w_posizione_old := w_posizione + 1;
       w_contarighe    := w_contarighe + 1;
       --
       -- Si trattano solo le righe di 1898 crt
       --
       if length(w_riga) = 1900 then
          --
          -- (VD - 21/09/2018): Aggiunto test sul record di testa per verificare che non
          --                    si tratti di tracciati del 2018
          -- (VD - 26/05/2022): Modificato test perchè in alcuni file c'è il tipo record "0" e
          --                    non "A"
          --
          -- (AB - 13/02/2023): Aggiunti i controlli relativi al valore che puo assumere nel campo 39
          --if substr(w_riga,1,1) = 'A' then
          if substr(w_riga,1,1) in ('0','A') then
             if substr(w_riga,39,1) not in (' ', 'N', 'S', 'M') then
                w_errore := 'Il file caricato e'' in formato non previsto';
                raise errore;
             end if;
          end if;
          --
          -- Trattamento tipo_record "B": Frontespizio - Dati dichiarante
          --
          if substr(w_riga,1,1) = 'B' then
             w_progr_dichiarazione := w_progr_dichiarazione + 1;
             w_cf_dichiarante      := rtrim(substr(w_riga,2,16));
             w_cod_comune          := substr(w_riga,98,4);
             w_anno_dich           := substr(w_riga,90,4);
             w_progr_imm_a         := 0;
             w_progr_imm_b         := 0;
             if w_cod_comune <> w_comune_dage then
                w_errore := 'Il file caricato non si riferisce all''ente';
                raise errore;
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
                                           )
               values ( a_documento_id
                      , w_progr_dichiarazione
                      , to_number(substr(w_riga,90,4))         -- anno dichiarazione
                      , to_number(substr(w_riga,94,4))         -- anno imposta
                      , w_cod_comune
                      , w_cf_dichiarante
                      , rtrim(substr(w_riga,152,60))           -- denominazione
                      , replace(substr(w_riga,228,12),' ','')  -- telefono
                      , rtrim(substr(w_riga,240,50))           -- indirizzo email
                      , rtrim(substr(w_riga,290,35))           -- indirizzo
                      , rtrim(substr(w_riga,325,5))            -- num.civ.
                      , rtrim(substr(w_riga,330,5))            -- scala
                      , rtrim(substr(w_riga,335,5))            -- piano
                      , rtrim(substr(w_riga,340,5))            -- interno
                      , rtrim(substr(w_riga,345,5))            -- cap
                      , rtrim(substr(w_riga,350,100))          -- comune
                      , rtrim(substr(w_riga,450,2))            -- provincia
                      --
                      -- (VD - 01/08/2018): gestione differenze tracciati per anno dichiarazione
                      --
                      , case when w_anno_dich < 2015
                          then to_number(rtrim(substr(w_riga,696,9)))
                          else to_number(rtrim(substr(w_riga,699,9)))
                        end                                    -- num_immobili_a
                      , case when w_anno_dich < 2015
                          then to_number(rtrim(substr(w_riga,705,9)))
                          else to_number(rtrim(substr(w_riga,717,9)))
                        end                                    -- num_immobili_b
                      , case when w_anno_dich < 2015
                          then to_number(substr(w_riga,716,1))
                          else to_number(substr(w_riga,728,1))
                        end                                    -- firma_dichiarante
                      , trunc(sysdate)                         -- data_variazione
                      , a_utente                               -- utente
                      );
             exception
               when others then
                 ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tracciato non conforme - Frontespizio'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
             end;
          end if;
          --
          -- Trattamento tipo_record "C": Quadro A - Immobili imponibili
          --
          if substr(w_riga,1,1) = 'C' then
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "C", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;
             if w_anno_dich < 2015 then
                w_lunghezza_ele := 270;
                w_posizione_tipo := 107;
             else
                -- (VD - 20/12/2021): aggiunto 1 carattere all'elemento dati immobile
                -- (VD - 26/05/2022): ripristinato tracciato precedente
                w_lunghezza_ele := 378;
                --w_lunghezza_ele := 379;
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
                  w_progr_imm_a := w_progr_imm_a + 1;
                  --
                  -- Inserimento immobile imponibile
                  --
                  begin
                    --
                    -- (VD - 01/08/2018): Gestione differenze tracciati per anno dichiarazione
                    --
                    if w_anno_dich < 2015 then
                       insert into WRK_ENC_IMMOBILI ( documento_id
                                                    , progr_dichiarazione
                                                    , tipo_immobile
                                                    , progr_immobile
                                                    , num_ordine
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
                                                    , flag_acquisto
                                                    , flag_cessione
                                                    , agenzia_entrate
                                                    , estremi_titolo
                                                    , annotazioni
                                                    , data_variazione
                                                    , utente
                                                    )
                       values ( a_documento_id
                              , w_progr_dichiarazione
                              , 'A'
                              , w_progr_imm_a
                              , to_number(substr(w_riga,w_inizio,4))                -- num_ordine
                              , ltrim(rtrim(substr(w_riga,w_inizio + 4,3)))         -- caratteristica
                              , rtrim(substr(w_riga,w_inizio + 7,100))              -- indirizzo
                              , substr(w_riga,w_inizio + 107,1)                     -- tipo
                              , rtrim(substr(w_riga,w_inizio + 108,5))              -- cod_catastale
                              , rtrim(substr(w_riga,w_inizio + 113,3))              -- sezione
                              , rtrim(substr(w_riga,w_inizio + 116,4))              -- foglio
                              , rtrim(substr(w_riga,w_inizio + 120,10))             -- numero
                              , rtrim(substr(w_riga,w_inizio + 130,4))              -- subalterno
                              , ltrim(rtrim(substr(w_riga,w_inizio + 134,25)))      -- categoria_catasto
                              , rtrim(substr(w_riga,w_inizio + 159,10))             -- classe_catasto
                              , rtrim(substr(w_riga,w_inizio + 169,20))             -- protocollo_catasto
                              , rtrim(substr(w_riga,w_inizio + 189,4))              -- anno_catasto
                              , to_number(rtrim(substr(w_riga,w_inizio + 193,1)))   -- immobile_storico
                              , to_number(rtrim(substr(w_riga,w_inizio + 194,15)))  -- valore
                              , to_number(rtrim(substr(w_riga,w_inizio + 209,3)))   -- perc_possesso
                              , substr(w_riga,w_inizio + 212,8)                     -- data_var_imposta
                              , to_number(rtrim(substr(w_riga,w_inizio + 220,1)))   -- flag_acquisto
                              , to_number(rtrim(substr(w_riga,w_inizio + 221,1)))   -- flag_cessione
                              , rtrim(substr(w_riga,w_inizio + 222,24))             -- agenzia_entrate
                              , rtrim(substr(w_riga,w_inizio + 246,24))             -- estremi_titolo
                              , decode(w_ind,1,rtrim(substr(w_riga,900,500)),'')    -- annotazioni
                              , trunc(sysdate)                                      -- data_variazione
                              , a_utente
                              );
                    else
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
                                                    --, immobile_inagibile
                                                    , valore
                                                    , perc_possesso
                                                    , data_var_imposta
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
                              , w_progr_imm_a
                              , to_number(substr(w_riga,w_inizio,4))                -- num_ordine
                              , to_number(substr(w_riga,w_inizio + 4,4))            ---- progr_immobile_dich
                              , to_number(substr(w_riga,w_inizio + 8,1))            ---- ind_continuita
                              , rtrim(substr(w_riga,w_inizio + 9,3))                -- caratteristica
                              , rtrim(substr(w_riga,w_inizio + 12,100))             -- indirizzo
                              , substr(w_riga,w_inizio + 112,1)                     -- tipo
                              , rtrim(substr(w_riga,w_inizio + 113,5))              -- cod_catastale
                              , rtrim(substr(w_riga,w_inizio + 118,3))              -- sezione
                              , rtrim(substr(w_riga,w_inizio + 121,4))              -- foglio
                              , rtrim(substr(w_riga,w_inizio + 125,10))             -- numero
                              , rtrim(substr(w_riga,w_inizio + 135,4))              -- subalterno
                              , ltrim(rtrim(substr(w_riga,w_inizio + 139,25)))      -- categoria_catasto
                              , rtrim(substr(w_riga,w_inizio + 164,10))             -- classe_catasto
                              , rtrim(substr(w_riga,w_inizio + 174,20))             -- protocollo_catasto
                              , rtrim(substr(w_riga,w_inizio + 194,4))              -- anno_catasto
                              , to_number(rtrim(substr(w_riga,w_inizio + 198,1)))   -- immobile_storico
                              -- (VD - 20/12/2021): inserimento campo "Immobile inagibile" dimenticato
                              --                    nella versione precedente. Per ora si correggono
                              --                    solo le substr dei campi successivi, in attesa del
                              --                    nuovo campo sulla tabella
                              -- (VD - 26/05/2022): ripristinata situazione precedente. Il nuovo campo
                              --                    esiste solo nel tracciato valido dal 2018 che ancora
                              --                    non viene gestito.
                              --, to_number(rtrim(substr(w_riga,w_inizio + 199,1)))   -- immobile_inagibile
                              , to_number(rtrim(substr(w_riga,w_inizio + 199,15)))  -- valore
                              --, to_number(rtrim(substr(w_riga,w_inizio + 200,15)))  -- valore
                              , to_number(rtrim(substr(w_riga,w_inizio + 214,5))) / 100   ---- perc_possesso
                              --, to_number(rtrim(substr(w_riga,w_inizio + 215,5))) / 100   ---- perc_possesso
                              , substr(w_riga,w_inizio + 219,8)                     -- data_var_imposta
                              --, substr(w_riga,w_inizio + 220,8)                     -- data_var_imposta
                              , to_number(rtrim(substr(w_riga,w_inizio + 227,1)))   -- flag_acquisto
                              --, to_number(rtrim(substr(w_riga,w_inizio + 228,1)))   -- flag_acquisto
                              , to_number(rtrim(substr(w_riga,w_inizio + 228,1)))   -- flag_cessione
                              --, to_number(rtrim(substr(w_riga,w_inizio + 229,1)))   -- flag_cessione
                              , to_number(rtrim(substr(w_riga,w_inizio + 229,1)))   ---- flag_altro
                              --, to_number(rtrim(substr(w_riga,w_inizio + 230,1)))   ---- flag_altro
                              , rtrim(substr(w_riga,w_inizio + 230,100))            ---- descrizione_altro
                              --, rtrim(substr(w_riga,w_inizio + 231,100))            ---- descrizione_altro
                              , rtrim(substr(w_riga,w_inizio + 330,24))             -- agenzia_entrate
                              --, rtrim(substr(w_riga,w_inizio + 331,24))             -- agenzia_entrate
                              , rtrim(substr(w_riga,w_inizio + 354,24))             -- estremi_titolo
                              --, rtrim(substr(w_riga,w_inizio + 355,24))             -- estremi_titolo
                              , decode(w_ind,1,rtrim(substr(w_riga,1227,500)),'')   -- annotazioni
                              , trunc(sysdate)                                      -- data_variazione
                              , a_utente
                              );
                  end if;
                exception
                  when others then
                    ins_anomalie_car ( a_documento_id
                                     , to_number(null)
                                     , 'Tracciato non conforme - Tipo record C'
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
                                 , 'Tracciato non conforme - Tipo record C'
                                 , 'Progr. modulo '||substr(w_riga,18,8)
                                 , w_cf_dichiarante
                                 , null
                                 , w_riga
                                 );
               end if;
             end loop;
          end if;
          --
          -- Trattamento tipo_record "D": Quadro B - Immobili parzialmente imponibili
          --                              o totalmente esenti
          --
          if substr(w_riga,1,1) = 'D' then
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "D", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;
             --
             -- (VD - 01/08/2018): Gestione differenze tracciati per anno dichiarazione
             --
             if w_anno_dich < 2015 then
                w_inizio := 207;
             else
                w_inizio := 212;
             end if;
             if afc.is_numeric(substr(w_riga,90,4)) = 1 and
                substr(w_riga,90,4) <> '0000' and
                substr(w_riga,w_inizio,1) in ('U','T') then
                w_progr_imm_b := w_progr_imm_b + 1;
                --
                -- Definizione tipo attivita'
                -- (VD - 01/08/2018): Gestione differenze tracciati per anno dichiarazione
                --
                if w_anno_dich < 2015 then
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
                else
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
                end if;
                --
                -- Inserimento immobile parzialmente imponibile o esente
                --
                begin
                  if w_anno_dich < 2015 then
                     insert into WRK_ENC_IMMOBILI ( documento_id
                                                  , progr_dichiarazione
                                                  , tipo_immobile
                                                  , progr_immobile
                                                  , num_ordine
                                                  , tipo_attivita
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
                                                  , immobile_esente
                                                  , perc_possesso
                                                  , data_var_imposta
                                                  , flag_acquisto
                                                  , flag_cessione
                                                  , agenzia_entrate
                                                  , estremi_titolo
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
                                                  , data_variazione
                                                  , utente
                                                  )
                     values ( a_documento_id
                            , w_progr_dichiarazione
                            , 'B'
                            , w_progr_imm_b
                            , to_number(substr(w_riga,90,4))               -- num_ordine
                            , w_tipo_attivita
                            , rtrim(substr(w_riga,104,3))                  -- caratteristica
                            , rtrim(substr(w_riga,107,100))                -- indirizzo
                            , substr(w_riga,207,1)                         -- tipo
                            , rtrim(substr(w_riga,208,5))                  -- cod_catastale
                            , rtrim(substr(w_riga,213,3))                  -- sezione
                            , rtrim(substr(w_riga,216,4))                  -- foglio
                            , rtrim(substr(w_riga,220,10))                 -- numero
                            , rtrim(substr(w_riga,230,4))                  -- subalterno
                            , ltrim(rtrim(substr(w_riga,234,25)))          -- categoria_catasto
                            , rtrim(substr(w_riga,259,10))                 -- classe_catasto
                            , rtrim(substr(w_riga,269,20))                 -- protocollo_catasto
                            , rtrim(substr(w_riga,289,4))                  -- anno_catasto
                            , to_number(rtrim(substr(w_riga,293,1)))       -- immobile_storico
                            , to_number(rtrim(substr(w_riga,294,15)))      -- valore
                            , to_number(rtrim(substr(w_riga,309,1)))       -- immobile_esente
                            , to_number(rtrim(substr(w_riga,310,3)))       -- perc_possesso
                            , substr(w_riga,313,8)                         -- data_var_imposta
                            , to_number(rtrim(substr(w_riga,321,1)))       -- flag_acquisto
                            , to_number(rtrim(substr(w_riga,322,1)))       -- flag_cessione
                            , rtrim(substr(w_riga,323,24))                 -- agenzia_entrate
                            , rtrim(substr(w_riga,347,24))                 -- estremi_titolo
                            --
                            -- Dati relativi a immobili adibiti ad attività didattica
                            --
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,371,9))) / 100
                                      ,to_number(null))                   -- d_corrispettivo_medio
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,380,9))) / 100
                                      ,to_number(null))                   -- d_costo_medio
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,389,3)))
                                      ,to_number(null))                   -- d_rapporto_superficie
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,392,3)))
                                      ,to_number(null))                   -- d_rapporto_sup_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,395,3)))
                                      ,to_number(null))                   -- d_rapporto_soggetti
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,398,3)))
                                      ,to_number(null))                   -- d_rapporto_sogg_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,401,3)))
                                      ,to_number(null))                   -- d_rapporto_giorni
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,404,3)))
                                      ,to_number(null))                   -- d_perc_imponibilita
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,407,12)))
                                      ,to_number(null))                   -- d_valore_ass_art_5
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,419,12)))
                                      ,to_number(null))                   -- d_valore_ass_art_4
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,431,1)))
                                      ,to_number(null))                   -- d_casella_rigo_g
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,432,1)))
                                      ,to_number(null))                   -- d_casella_rigo_h
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,433,3)))
                                      ,to_number(null))                   -- d_rapporto_cms_cm
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,436,12)))
                                      ,to_number(null))                   -- d_valore_ass_parziale
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,448,12)))
                                      ,to_number(null))                   -- d_valore_ass_compl
                            --
                            -- Dati relativi ad immobili adibiti ad altre attività
                            --
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,460,9))) / 100)   -- a_corrispettivo_medio_perc
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,469,9))) / 100)   -- a_corrispettivo_medio_prev
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,478,3))))   -- a_rapporto_superficie
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,481,3))))   -- a_rapporto_sup_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,484,3))))   -- a_rapporto_soggetti
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,487,3))))   -- a_rapporto_sogg_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,490,3))))   -- a_rapporto_giorni
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,493,3))))   -- a_perc_imponibilita
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,496,12))))  -- a_valore_assoggettato
                            , trunc(sysdate)                               -- data_variazione
                            , a_utente
                            );
                  else
                     insert into WRK_ENC_IMMOBILI ( documento_id
                                                  , progr_dichiarazione
                                                  , tipo_immobile
                                                  , progr_immobile
                                                  , num_ordine
                                                  , progr_immobile_dich
                                                  , ind_continuita
                                                  , tipo_attivita
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
                                                  --, immobile_inagibile
                                                  , valore
                                                  , immobile_esente
                                                  , perc_possesso
                                                  , data_var_imposta
                                                  , flag_acquisto
                                                  , flag_cessione
                                                  , flag_altro
                                                  , descrizione_altro
                                                  , agenzia_entrate
                                                  , estremi_titolo
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
                                                  , data_variazione
                                                  , utente
                                                  )
                     values ( a_documento_id
                            , w_progr_dichiarazione
                            , 'B'
                            , w_progr_imm_b
                            , to_number(substr(w_riga,90,4))               -- num_ordine
                            , to_number(substr(w_riga,94,4))               ---- progr_immobile_dich
                            , to_number(substr(w_riga,98,1))               ---- ind_continuita
                            , w_tipo_attivita
                            , rtrim(substr(w_riga,109,3))                  -- caratteristica
                            , rtrim(substr(w_riga,112,100))                -- indirizzo
                            , substr(w_riga,212,1)                         -- tipo
                            , rtrim(substr(w_riga,213,5))                  -- cod_catastale
                            , rtrim(substr(w_riga,218,3))                  -- sezione
                            , rtrim(substr(w_riga,221,4))                  -- foglio
                            , rtrim(substr(w_riga,225,10))                 -- numero
                            , rtrim(substr(w_riga,235,4))                  -- subalterno
                            , ltrim(rtrim(substr(w_riga,239,25)))          -- categoria_catasto
                            , rtrim(substr(w_riga,264,10))                 -- classe_catasto
                            , rtrim(substr(w_riga,274,20))                 -- protocollo_catasto
                            , rtrim(substr(w_riga,294,4))                  -- anno_catasto
                            , to_number(rtrim(substr(w_riga,298,1)))       -- immobile_storico
                            -- (VD - 20/12/2021): inserimento campo "Immobile inagibile" dimenticato
                            --                    nella versione precedente. Per ora si correggono
                            --                    solo le substr dei campi successivi, in attesa del
                            --                    nuovo campo sulla tabella
                            -- (VD - 26/05/2022): ripristinata situazione precedente. Il nuovo campo
                            --                    esiste solo nel tracciato valido dal 2018 che ancora
                            --                    non viene gestito.
                            --, to_number(rtrim(substr(w_riga,299,1)))       -- immobile_inagibile
                            , to_number(rtrim(substr(w_riga,299,15)))      -- valore
                            --, to_number(rtrim(substr(w_riga,300,15)))      -- valore
                            , to_number(rtrim(substr(w_riga,314,1)))       -- immobile_esente
                            --, to_number(rtrim(substr(w_riga,315,1)))       -- immobile_esente
                            , to_number(rtrim(substr(w_riga,315,5))) / 100 ---- perc_possesso
                            --, to_number(rtrim(substr(w_riga,316,5))) / 100 ---- perc_possesso
                            , substr(w_riga,320,8)                         -- data_var_imposta
                            --, substr(w_riga,321,8)                         -- data_var_imposta
                            , to_number(rtrim(substr(w_riga,328,1)))       -- flag_acquisto
                            --, to_number(rtrim(substr(w_riga,329,1)))       -- flag_acquisto
                            , to_number(rtrim(substr(w_riga,329,1)))       -- flag_cessione
                            --, to_number(rtrim(substr(w_riga,330,1)))       -- flag_cessione
                            , to_number(rtrim(substr(w_riga,330,1)))       ---- flag_altro
                            --, to_number(rtrim(substr(w_riga,331,1)))       ---- flag_altro
                            , rtrim(substr(w_riga,331,100))                ---- descrizione_altro
                            --, rtrim(substr(w_riga,332,100))                ---- descrizione_altro
                            , rtrim(substr(w_riga,431,24))                 -- agenzia_entrate
                            --, rtrim(substr(w_riga,432,24))                 -- agenzia_entrate
                            , rtrim(substr(w_riga,455,24))                 -- estremi_titolo
                            --, rtrim(substr(w_riga,456,24))                 -- estremi_titolo
                            --
                            -- Dati relativi a immobili adibiti ad attività didattica
                            --
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,479,9))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,480,9))) / 100
                                      ,to_number(null))                   ---- d_corrispettivo_medio
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,488,9))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,489,9))) / 100
                                      ,to_number(null))                   ---- d_costo_medio
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,497,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,498,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_superficie
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,502,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,503,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_sup_gg
                            , decode(w_tipo_attivita
                                    --,4,to_number(rtrim(substr(w_riga,507,5))) / 100
                                    ,4,to_number(rtrim(substr(w_riga,508,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_soggetti
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,512,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,513,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_sogg_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,517,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,518,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_giorni
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,522,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,523,5))) / 100
                                      ,to_number(null))                   ---- d_perc_imponibilita
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,527,12))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,528,12))) / 100
                                      ,to_number(null))                   ---- d_valore_ass_art_5
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,539,12))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,540,12))) / 100
                                      ,to_number(null))                   ---- d_valore_ass_art_4
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,551,1)))
                                    --,4,to_number(rtrim(substr(w_riga,552,1)))
                                      ,to_number(null))                   -- d_casella_rigo_g
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,552,1)))
                                    --,4,to_number(rtrim(substr(w_riga,553,1)))
                                      ,to_number(null))                   -- d_casella_rigo_h
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,553,5))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,554,5))) / 100
                                      ,to_number(null))                   ---- d_rapporto_cms_cm
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,558,12))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,559,12))) / 100
                                      ,to_number(null))                   ---- d_valore_ass_parziale
                            , decode(w_tipo_attivita
                                    ,4,to_number(rtrim(substr(w_riga,570,12))) / 100
                                    --,4,to_number(rtrim(substr(w_riga,571,12))) / 100
                                      ,to_number(null))                   ---- d_valore_ass_compl
                            --
                            -- Dati relativi ad immobili adibiti ad altre attività
                            --
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,582,9))) / 100)   ---- a_corrispettivo_medio_perc
                                      --,to_number(rtrim(substr(w_riga,583,9))) / 100)   ---- a_corrispettivo_medio_perc
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,591,9))) / 100)   ---- a_corrispettivo_medio_prev
                                      --,to_number(rtrim(substr(w_riga,592,9))) / 100)   ---- a_corrispettivo_medio_prev
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,600,5))) / 100)   ---- a_rapporto_superficie
                                      --,to_number(rtrim(substr(w_riga,601,5))) / 100)   ---- a_rapporto_superficie
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,605,5))) / 100)   ---- a_rapporto_sup_gg
                                      --,to_number(rtrim(substr(w_riga,606,5))) / 100)   ---- a_rapporto_sup_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,610,5))) / 100)   ---- a_rapporto_soggetti
                                      --,to_number(rtrim(substr(w_riga,611,5))) / 100)   ---- a_rapporto_soggetti
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,615,5))) / 100)   ---- a_rapporto_sogg_gg
                                      --,to_number(rtrim(substr(w_riga,616,5))) / 100)   ---- a_rapporto_sogg_gg
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,620,5))) / 100)   ---- a_rapporto_giorni
                                      --,to_number(rtrim(substr(w_riga,621,5))) / 100)   ---- a_rapporto_giorni
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,625,5))) / 100)   ---- a_perc_imponibilita
                                      --,to_number(rtrim(substr(w_riga,626,5))) / 100)   ---- a_perc_imponibilita
                            , decode(w_tipo_attivita
                                    ,4,to_number(null)
                                      ,to_number(rtrim(substr(w_riga,630,12))) / 100)  ---- a_valore_assoggettato
                                      --,to_number(rtrim(substr(w_riga,631,12))) / 100)  ---- a_valore_assoggettato
                            , trunc(sysdate)                               -- data_variazione
                            , a_utente
                            );
                  end if;
                exception
                  when others then
                      ins_anomalie_car ( a_documento_id
                                       , to_number(null)
                                       , 'Tracciato non conforme - Tipo record D'
                                       , 'Progr. modulo '||substr(w_riga,18,8)
                                       , w_cf_dichiarante
                                       , null
                                       , w_riga
                                       );
                end;
--dbms_output.put_line('Inserito quadro D: '||to_number(substr(w_riga,90,4)));
             elsif substr(w_riga,90,4) not in ('    ','0000')  or
                substr(w_riga,207,1) not in (' ','U','T') then
                ins_anomalie_car ( a_documento_id
                                 , to_number(null)
                                 , 'Tracciato non conforme - Tipo record D'
                                 , 'Progr. modulo '||substr(w_riga,18,8)
                                 , w_cf_dichiarante
                                 , null
                                 , w_riga
                                 );
             end if;
          end if;
          --
          -- Trattamento tipo_record "E": Quadro C - Determinazione dell'IMU e della TASI
          --                              Quadro D - Compensazioni e rimborsi
          --
          if substr(w_riga,1,1) = 'E' then
--dbms_output.put_line('Tipo record E');
             if rtrim(substr(w_riga,2,16)) <> w_cf_dichiarante then
                w_errore := 'Attenzione! Tipo record "E", sequenza righe errata: Dati non relativi al dichiarante indicato nel frontespizio';
                raise errore;
             end if;
             --
             -- Si aggiornano i dati di riepilogo sulla riga di testata delle dichiarazione
             --
             begin
               update WRK_ENC_TESTATA
                  set imu_dovuta                  = to_number(substr(w_riga,90,12))
                    , eccedenza_imu_dic_prec      = to_number(substr(w_riga,102,12))
                    , eccedenza_imu_dic_prec_f24  = to_number(substr(w_riga,114,12))
                    , rate_imu_versate            = to_number(substr(w_riga,126,12))
                    , imu_debito                  = to_number(substr(w_riga,138,12))
                    , imu_credito                 = to_number(substr(w_riga,150,12))
                    , tasi_dovuta                 = to_number(substr(w_riga,162,12))
                    , eccedenza_tasi_dic_prec     = to_number(substr(w_riga,174,12))
                    , eccedenza_tasi_dic_prec_f24 = to_number(substr(w_riga,186,12))
                    , tasi_rate_versate           = to_number(substr(w_riga,198,12))
                    , tasi_debito                 = to_number(substr(w_riga,210,12))
                    , tasi_credito                = to_number(substr(w_riga,222,12))
                    , imu_credito_dic_presente    = to_number(substr(w_riga,234,12))
                    , credito_imu_rimborso        = to_number(substr(w_riga,246,12))
                    , credito_imu_compensazione   = to_number(substr(w_riga,258,12))
                    , tasi_credito_dic_presente   = to_number(substr(w_riga,270,12))
                    , credito_tasi_rimborso       = to_number(substr(w_riga,282,12))
                    , credito_tasi_compensazione  = to_number(substr(w_riga,294,12))
                where documento_id = a_documento_id
                  and progr_dichiarazione = w_progr_dichiarazione;
             exception
               when others then
                 ins_anomalie_car ( a_documento_id
                                  , to_number(null)
                                  , 'Tracciato non conforme - Tipo record E'
                                  , null
                                  , w_cf_dichiarante
                                  , null
                                  , w_riga
                                  );
             end;
          end if;
       end if;
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
      raise_application_error(-20999,w_cf_dichiarante||' '||to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
----------------------------------------------------------------------------------
procedure TRATTA_SOGGETTI_ENC
/*************************************************************************
  NOME:        TRATTA_SOGGETTI_ENC
  DESCRIZIONE: Esamina i contribuenti presenti nel file e se non sono
               gia' presenti in anagrafe li inserisce
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
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
                    from wrk_enc_testata
                   where documento_id = a_documento_id)
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
                              )
         values ( w_ni
                , 1
                , sel_ana.cod_fiscale
                , sel_ana.denominazione
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
                , 1
                , w_fonte
                , a_utente
                , trunc(sysdate)
                , 'DA CARICAMENTO DICHIARAZIONI ENC'
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
                    from wrk_enc_immobili wenc
                   where wenc.documento_id = a_documento_id
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
             , 'DA CARICAMENTO DICHIARAZIONI ENC'
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
 procedure TRATTA_OGGETTI_ENC
/*************************************************************************
  NOME:         TRATTA_OGGETTI_ENC
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
          -- immobili con stessi estremi catastali (subalterno escluso perchè nullo)
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
procedure TRATTA_PRATICHE_ENC
/*************************************************************************
  NOME:         TRATTA_PRATICHE_ENC
  DESCRIZIONE: Esamina le dichiarazioni presenti nel file e le carica
               nelle apposite tabelle, per IMU e/o TASI a seconda del
               parametro presente in installazione_parametri.
  NOTE:
  Rev.    Date         Author      Note
  000     20/04/2018   VD          Prima emissione
  001     21/09/2018   VD          Aggiunta gestione variazioni in corso
                                   d'anno
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
  -- dichiarazione ENC
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
                            , decode(nvl(length(caratteristica),0)
                                    ,3,3
                                      ,to_number(caratteristica)) tipo_oggetto
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
                                            ,' Classe catasto orig.: '||classe_catasto||';'))  note
                         from wrk_enc_immobili
                        where documento_id = a_documento_id
                          and progr_dichiarazione = sel_dic.progr_dichiarazione
                        order by 1  --oggetto
                               , 4  -- data_var_imposta
                               , 10 --num_ordine
                     )
      loop
        --
        -- Controllo data variazione imposta
        --
        /*begin
          if nvl(sel_imm.data_var_imposta,' ') = ' ' or
             sel_imm.data_var_imposta = lpad('0',8,'0') then
             w_data_var := to_date(null);
          else
             w_data_var := to_date(sel_imm.data_var_imposta,'ddmmyyyy');
          end if;
        exception
          when others then
            w_data_var := to_date(null);
            ins_anomalie_car ( a_documento_id
                             , to_number(null)
                             , 'Data variazione imposta: formato non corretto'
                             , sel_imm.data_var_imposta
                             , sel_dic.cod_fiscale
                             , substr(sel_dic.denominazione,1,60)
                             );
        end;*/
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
              /*if w_mesi_possesso > 6 then
                 w_mesi_possesso_1s := w_mesi_possesso - 6;
              else
                 w_mesi_possesso_1s := 0;
              end if;*/
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
        -- Se si tratta di variazione, si verifica se lo stesso oggetto e' gia' presente
        -- nella stessa dichiarazione.
        -- Se si', si aggiornano i dati inseriti per il primo periodo accorciando il
        -- periodo di possesso e si inserisce un nuovo dettaglio nella pratica
        -- relativo alla variazione.
        -- (VD - 22/10/2021): si considera che le variazioni vengano inserite sempre con
        --                    2 righe: la prima che identifica il periodo in cui l'oggetto
        --                    non era variato, la secondo con l'indicazione della data di
        --                    inizio della variazione.
        --                    Quindi il seguente trattamento viene commentato (in attesa di
        --                    eventuali altre informazioni).
        --
        /*if sel_imm.flag_altro = 1 then
           w_oggetto_pratica := f_get_oggetto_pratica (w_pratica, sel_imm.tr4_oggetto);
           if w_oggetto_pratica is not null then
              w_diff_mesi := w_mesi_possesso;
              w_diff_mesi_1s := w_mesi_possesso_1s;
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
                  w_errore := 'Errore in aggiornamento oggetti_contribuente (Variazione)' ||
                              f_descrizione_titr(w_tipo_tributo,sel_dic.anno_imposta) || ' '||
                              sel_dic.cod_fiscale || ' '||w_oggetto_pratica ||
                              ' (' || sqlerrm || ')';
                  raise errore;
              end;
              w_oggetto_pratica := to_number(null);
           else
              if w_data_var > to_date('0101'||sel_dic.anno_imposta,'ddmmyyyy') then
                 -- Se l'oggetto variato non esiste nella pratica e la variazione
                 -- è stata effettuata successivamente al 01/01, si ricercano gli
                 -- ultimi dati validi e si inserisce un dettaglio nella pratica
                 -- contenente le informazioni del periodo precedente alla variazione
                 --
                 w_flag_possesso_var := null;
                 w_mesi_possesso_var := to_number(to_char(w_data_var,'mm'));
                 if to_number(to_char(w_data_var,'dd')) <= 15 then
                    w_mesi_possesso_var := w_mesi_possesso_var -1;
                 end if;
                 if w_mesi_possesso_var > 6 then
                    w_mesi_possesso_var_1s := w_mesi_possesso_var - 6;
                 else
                    w_mesi_possesso_var_1s := w_mesi_possesso_var;
                 end if;
                 GET_DATI_OGPR_PREC ( sel_imm.tr4_oggetto
                                    , w_tipo_tributo
                                    , sel_dic.anno_imposta
                                    , sel_dic.cod_fiscale
                                    , w_flag_esclusione
                                    , w_fonte_oggetto
                                    , w_anno_oggetto
                                    , w_perc_possesso_prec
                                    , w_tipo_oggetto_prec
                                    , w_categoria_prec
                                    , w_classe_prec
                                    , w_valore_prec
                                    , w_titolo_prec
                                    , w_flag_esclusione_prec
                                    , w_flag_ab_princ_prec
                                    , w_cf_prec
                                    , w_ogpr_prec
                                    , w_valore_prec_anno_dich
                                    , w_mesi_possesso_prec
                                    , w_mesi_possesso_1sem_prec
                                    , w_mesi_esclusione_prec);
                 if w_ogpr_prec is not null then
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
                                        , 'D'
                                        , 'I'
                                        , nvl(w_data_var,to_date(to_char('0101'||sel_dic.anno_imposta),'ddmmyyyy'))
                                        , a_utente
                                        , trunc(sysdate)
                                        , ''
                                        , sel_dic.firma_dichiarazione
                                        , w_fonte
                                        --, sel_dic.imu_dovuta
                                        --, sel_dic.eccedenza_imu_dic_prec
                                        --, sel_dic.eccedenza_imu_dic_prec_f24
                                        --, sel_dic.rate_imu_versate
                                        --, sel_dic.imu_debito
                                        --, sel_dic.imu_credito
                                        --, sel_dic.imu_credito_dic_presente
                                        --, sel_dic.credito_imu_rimborso
                                        --, sel_dic.credito_imu_compensazione
                                        --, sel_dic.tasi_dovuta
                                        --, sel_dic.eccedenza_tasi_dic_prec
                                        --, sel_dic.eccedenza_tasi_dic_prec_f24
                                        --, sel_dic.tasi_rate_versate
                                        --, sel_dic.tasi_debito
                                        --, sel_dic.tasi_credito
                                        --, sel_dic.tasi_credito_dic_presente
                                        --, sel_dic.credito_tasi_rimborso
                                        --, sel_dic.credito_tasi_compensazione 
                                        );
                    end if;
                    ins_dati_oggetto_pratica ( to_number(null)    --a_documento_id
                                             , sel_dic.progr_dichiarazione
                                             , 'A'                --sel_imm.tipo_immobile
                                             , to_number(null)    --sel_imm.progr_immobile
                                             , to_number(null)    --sel_imm.num_ordine
                                             , sel_imm.tipo_attivita
                                             , w_tipo_tributo
                                             , sel_dic.cod_fiscale
                                             , sel_imm.tr4_oggetto
                                             , w_tipo_oggetto_prec
                                             , w_pratica
                                             , sel_dic.anno_imposta
                                             , w_categoria_prec
                                             , w_classe_prec
                                             , sel_imm.tipo_qualita
                                             , w_valore_prec
                                             , w_titolo_prec
                                             , '' --sel_imm.estremi_titolo
                                             , w_fonte
                                             , 'D'
                                             , w_perc_possesso_prec
                                             , w_mesi_possesso_var
                                             , w_mesi_possesso_var_1s
                                             , 1  -- da_mese_possesso
                                             , w_mesi_esclusione_var
                                             , w_flag_possesso_var
                                             , w_flag_esclusione_prec
                                             , a_utente
                                             , trunc(sysdate)
                                             , 'Ins. periodo ante variazione');
                 else
                    -- se l'oggetto pratica precedente è nullo, si tratta di variazione priva di
                    -- denuncia precedente: si inserisce in anomalie_ici
                    ins_anomalie_ici ( sel_dic.anno_imposta
                                     , sel_dic.cod_fiscale
                                     , trunc(sysdate)
                                     , null
                                     , null
                                     , sel_imm.tr4_oggetto
                                     , w_tipo_anomalia_var
                                     );
                 end if;
                 w_oggetto_pratica := to_number(null);
              end if;
           end if;
        end if;*/
        --
        -- Inserimento dettaglio pratica
        --
        if w_oggetto_pratica is null and
           w_flag_denuncia <> 1 then
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
                               , 'D'
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
                               );
           end if;
           ins_dati_oggetto_pratica ( a_documento_id
                                    , sel_dic.progr_dichiarazione
                                    , sel_imm.tipo_immobile
                                    , sel_imm.progr_immobile
                                    , sel_imm.num_ordine
                                    , sel_imm.tipo_attivita
                                    , w_tipo_tributo
                                    , sel_dic.cod_fiscale
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
                                    );
         end if;
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
  w_fonte := F_INPA_VALORE('FONT_DIENC');
  --
  CARICA_DIC_ENC.CARICA_DICHIARAZIONI_ENC (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC.TRATTA_SOGGETTI_ENC (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC.TRATTA_TIPI_QUALITA (a_documento_id);
  CARICA_DIC_ENC.TRATTA_CATEGORIE_CATASTO (a_documento_id);
  CARICA_DIC_ENC.TRATTA_OGGETTI_ENC (a_documento_id,a_utente,w_messaggio);
  CARICA_DIC_ENC.TRATTA_PRATICHE_ENC (a_documento_id,a_utente,w_messaggio);
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
end CARICA_DIC_ENC;
/
