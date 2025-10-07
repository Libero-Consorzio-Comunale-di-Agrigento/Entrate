--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_common stripComments:false runOnChange:true 
 
create or replace package stampa_common is
/******************************************************************************
 NOME:        STAMPA_COMMON
 DESCRIZIONE: Funzioni per stampa comune a vari modelli
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   13/02/2025  DM      #78549
                           Corretto raggruppamento interessi
 001   16/09/2024  RV      #55525
                           Aggiunto INTERESSI
 000   xx/xx/xxxx  xx      Prima emissione
******************************************************************************/

  TYPE record_pratica IS RECORD(
    COMUNE_ENTE           VARCHAR2(40),
    SIGLA_ENTE            VARCHAR2(5),
    PROVINCIA_ENTE        VARCHAR2(40),
    COGNOME_NOME          VARCHAR2(100),
    NI                    NUMBER(10),
    COD_SESSO             VARCHAR2(1),
    SESSO                 VARCHAR2(7),
    COD_CONTRIBUENTE      NUMBER,
    COD_CONTROLLO         NUMBER,
    COD_FISCALE           VARCHAR2(16),
    INDIRIZZO             VARCHAR2(4000),
    PRATICA               NUMBER(10),
    TIPO_TRIBUTO          VARCHAR2(5),
    DESCR_TITR            VARCHAR2(4000),
    TIPO_PRATICA          VARCHAR2(1),
    TIPO_EVENTO           VARCHAR2(1),
    ANNO                  NUMBER(4),
    NUMERO                VARCHAR2(15),
    TIPO_RAPPORTO         VARCHAR2(1),
    DATA_PRATICA          VARCHAR2(10),
    DATA_NOTIFICA         VARCHAR2(10),
    DATA_ODIERNA          VARCHAR2(10),
    DATI_DB1              CHAR,
    DATI_DB2              CHAR,
    LABEL_RAP             VARCHAR2(15),
    RAPPRESENTANTE        VARCHAR2(40),
    COD_FISCALE_RAP       VARCHAR2(16),
    INDIRIZZO_RAP         VARCHAR2(50),
    COMUNE_RAP            VARCHAR2(51),
    CARICA_RAP            VARCHAR2(4000),
    COMUNE                VARCHAR2(4000),
    TELEFONO              VARCHAR2(47),
    DATA_NASCITA          VARCHAR2(10),
    COMUNE_NASCITA        VARCHAR2(45),
    PRESSO                VARCHAR2(4000),
    EREDE_DI              VARCHAR2(9),
    COGNOME_NOME_EREDE    VARCHAR2(100),
    COD_FISCALE_EREDE     VARCHAR2(16),
    INDIRIZZO_EREDE       VARCHAR2(4000),
    COMUNE_EREDE          VARCHAR2(4000),
    NOTE_PRATICA          VARCHAR2(2000),
    MOTIVO_PRATICA        VARCHAR2(2000),
    UTENTE_PRATICA        VARCHAR2(8),
    DES_UTENTE_PRATICA    VARCHAR2(40),
    LABEL_INDIRIZZO_PEC   VARCHAR2(4000),
    INDIRIZZO_PEC         VARCHAR2(4000),
    LABEL_INDIRIZZO_EMAIL VARCHAR2(4000),
    INDIRIZZO_EMAIL       VARCHAR2(4000),
    LABEL_TELEFONO_FISSO  VARCHAR2(4000),
    TELEFONO_FISSO        VARCHAR2(4000),
    LABEL_CELL_PERSONALE  VARCHAR2(4000),
    CELL_PERSONALE        VARCHAR2(4000),
    LABEL_CELL_LAVORO     VARCHAR2(4000),
    CELL_LAVORO           VARCHAR2(4000),
    RIGA_DESTINATARIO_1   VARCHAR2(4000),
    RIGA_DESTINATARIO_2   VARCHAR2(4000),
    RIGA_DESTINATARIO_3   VARCHAR2(4000),
    RIGA_DESTINATARIO_4   VARCHAR2(4000),
    RIGA_DESTINATARIO_5   VARCHAR2(4000));

  type record_pratica_table is table of record_pratica;
  p_tab_eredi            record_pratica_table := record_pratica_table();
  p_tab_soggetto_pratica record_pratica_table := record_pratica_table();

  function f_get_collection_eredi return record_pratica_table
    pipelined;

  function f_get_collection_principale return record_pratica_table
    pipelined;

  function f_get_tipo_tributo(a_pratica number) return varchar2;
  function f_formatta_numero(a_numero    number,
                             a_formato   varchar2,
                             a_null_zero varchar2 default null)
    return varchar2;
  function f_get_stringa_versamenti(a_tipo_tributo   varchar2,
                                    a_cod_fiscale    varchar2,
                                    a_ruolo          number,
                                    a_anno_ruolo     number,
                                    a_tipo_ruolo     number,
                                    a_tipo_emissione varchar2,
                                    a_modello        number) return varchar2;
  function contribuente(a_pratica  number default -1,
                        a_ni_erede number default -1) return sys_refcursor;
  function contribuenti_ente(a_ni           number default -1,
                             a_tipo_tributo varchar2 default '',
                             a_cod_fiscale  varchar2 default '',
                             a_ruolo        number default -1,
                             a_modello      number default -1,
                             a_anno         number default -1,
                             a_pratica_base number default -1)
    return sys_refcursor;

  function interessi(a_pratica         number default -1,
                     a_tipo_interessi  varchar2 default null)
    return sys_refcursor;

  FUNCTION eredi(a_pratica             NUMBER default -1,
                 a_ni_erede_principale number default -1)
    return sys_refcursor;

  FUNCTION get_ni_erede_principale RETURN NUMBER;
  FUNCTION set_ni_erede_principale(p_ni_erede NUMBER) RETURN NUMBER;
  PROCEDURE delete_ni_erede_principale;
end stampa_common;
/
create or replace package body stampa_common is
/******************************************************************************
 NOME:        STAMPA_COMMON
 DESCRIZIONE: Funzioni per stampa comune a vari modelli
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   13/02/2025  DM      #78549
                           Corretto raggruppamento interessi
 001   16/09/2024  RV      #55525
                           Aggiunto INTERESSI
 000   xx/xx/xxxx  xx      Prima emissione
******************************************************************************/

  FUNCTION get_session_id return NUMBER IS
    w_session_id          NUMBER;
  BEGIN
    select sys_context('userenv','sessionid') into w_session_id from dual;

    return w_session_id;
  END;

  FUNCTION get_valore_parametro(p_parametro VARCHAR2, p_progressivo NUMBER DEFAULT 1)
    return VARCHAR2 IS

    w_valore        VARCHAR2(2000);
    w_session_id    NUMBER;
  BEGIN

    w_session_id := get_session_id();

    BEGIN
      select param.valore
        into w_valore
        from parametri param
       where param.sessione = w_session_id
         and param.nome_parametro = p_parametro
         and param.progressivo = p_progressivo;
    EXCEPTION
      when others then
        return null;
    END;

    return w_valore;

  END;

  FUNCTION set_valore_parametro(p_parametro VARCHAR,
    p_valore VARCHAR2,
    p_progressivo NUMBER DEFAULT NULL)
    return NUMBER IS

    w_session_id  NUMBER;
    w_progressivo NUMBER;

  BEGIN

    w_session_id := get_session_id();

    if (p_progressivo is NULL) THEN
      parametri_nr(a_sessione       => w_session_id,
                   a_nome_parametro => p_parametro,
                   a_progressivo    => w_progressivo);
    END IF;

    BEGIN
      insert into parametri
        (sessione, nome_parametro, progressivo, valore, data)
      values
        (w_session_id, p_parametro, w_progressivo, p_valore, sysdate);
    EXCEPTION
      when others then
        return null;
    END;

    return w_progressivo;

  END;

  PROCEDURE delete_parametro(p_parametro VARCHAR2, p_progressivo NUMBER) IS
    w_session_id NUMBER;
  BEGIN

    w_session_id := get_session_id();

    delete from parametri param
     where param.sessione = w_session_id
       and param.progressivo = p_progressivo
       and param.nome_parametro = p_parametro;
  END;

  PROCEDURE delete_ni_erede_principale IS

    w_parametro CONSTANT VARCHAR2(30) := 'NI_EREDE_PRINCIPALE';

  BEGIN
    delete_parametro(w_parametro, 1);
  END;

  function f_get_collection_eredi return record_pratica_table
    pipelined is
  begin
    for i in 1 .. p_tab_eredi.count loop
      pipe row(p_tab_eredi(i));
    end loop;
    return;
  end;

  FUNCTION set_ni_erede_principale(p_ni_erede NUMBER) RETURN NUMBER IS

    w_parametro CONSTANT VARCHAR2(30) := 'NI_EREDE_PRINCIPALE';

  BEGIN
    delete_ni_erede_principale;

    return set_valore_parametro(w_parametro, to_char(p_ni_erede), 1);
  END;

  FUNCTION get_ni_erede_principale RETURN NUMBER IS

    w_parametro CONSTANT VARCHAR2(30) := 'NI_EREDE_PRINCIPALE';

  BEGIN

    return get_valore_parametro(w_parametro, 1);
  END;

  function f_get_collection_principale return record_pratica_table
    pipelined is
  begin
    for i in 1 .. p_tab_soggetto_pratica.count loop
      pipe row(p_tab_soggetto_pratica(i));
    end loop;
    return;
  end;
  -- (VD - 13/02/2020): aggiunta selezione tipo_tributo da pratiche_tributo per utilizzare
  --                    il package anche per la TASI
  function f_get_tipo_tributo(a_pratica number) return varchar2 is
    p_tipo_tributo varchar2(5);
  begin
    begin
      select tipo_tributo
        into p_tipo_tributo
        from pratiche_tributo
       where pratica = a_pratica;
    exception
      when others then
        p_tipo_tributo := 'ICI';
    end;
    --
    return p_tipo_tributo;
  end;
  -- (VD - 26/02/2020): nuova funzione di formattazione campi numerici
  function f_formatta_numero(a_numero    number,
                             a_formato   varchar2,
                             a_null_zero varchar2 default null)
    return varchar2 is
    w_numero_formattato varchar2(20);
    c_formato_importo   varchar2(20) := '99G999G999G990D00';
    c_formato_perc      varchar2(20) := '990D00';
    c_formato_coeff     varchar2(20) := '90D0000';
    c_formato_tariffa   varchar2(20) := '999G990D00000';
  begin
    if nvl(a_null_zero, 'N') = 'N' and nvl(a_numero, 0) = 0 then
      w_numero_formattato := '';
    else
      select trim(to_char(nvl(a_numero, 0),
                          decode(a_formato,
                                 'I',c_formato_importo,
                                 'P',c_formato_perc,
                                 'C',c_formato_coeff,
                                 'T',c_formato_tariffa,
                                 ''),
                          'NLS_NUMERIC_CHARACTERS = '',.'''))
        into w_numero_formattato
        from dual;
    end if;
    --
    return w_numero_formattato;
    --
  end f_formatta_numero;
  function f_get_stringa_versamenti
  ( a_tipo_tributo              varchar2
  , a_cod_fiscale               varchar2
  , a_ruolo                     number
  , a_anno_ruolo                number
  , a_tipo_ruolo                number
  , a_tipo_emissione            varchar2
  , a_modello                   number
  ) return varchar2 is
    w_note_utenza               varchar2(4000);
    w_insolvenza_min            number;
    w_numero_anni               number;
    w_stringa_vers_reg          varchar2(4000);
    w_stringa_vers_irr          varchar2(4000);
    w_stringa_anni              varchar2(100);
    w_ruolo_acconto             number;
    w_ultimo_ruolo              number;
    w_anno_rif                  number;
    w_importo_anno              number;
    w_imp_dovuto                number;
    w_imp_versato               number;
    w_imp_sgravi                number;
    w_ind                       number;
    type t_importo_anno_t       is table of number index by binary_integer;
    t_importo_anno              t_importo_anno_t;
  begin
    -- Si selezionano i parametri necessari del modello
    w_note_utenza      := null;
    w_numero_anni      := nvl(to_number(f_descrizione_timp (a_modello,'ANNI_CHECK_VERS')),0);
    -- Se il numero di anni per cui controllare i versamenti è 0, la funzione
    -- restituisce una stringa nulla
    if w_numero_anni = 0 then
       return w_note_utenza;
    end if;
    --
    w_insolvenza_min   := nvl(to_number(f_descrizione_timp (a_modello,'INSOLVENZA_MIN')),0);
    w_stringa_vers_reg := f_descrizione_timp (a_modello,'VERS_CORRETTI');
    w_stringa_vers_irr := f_descrizione_timp (a_modello,'VERS_MANCANTI');
    -- Se il ruolo che si sta trattando è a saldo, si verificano anche i
    -- versamenti relativi al ruolo in acconto. Se il ruolo è in acconto o
    -- totale, si verificano solo i versamenti per gli anni precedenti
    w_importo_anno := to_number(null);
    if a_tipo_emissione = 'S' then
       begin
         select ruolo
           into w_ruolo_acconto
           from ruoli
          where anno_ruolo = a_anno_ruolo
            --and progr_emissione = 1
            and tipo_emissione = 'A'
            and invio_consorzio is not null;
       exception
         when others then
           w_ruolo_acconto := to_number(null);
       end;
       if w_ruolo_acconto is not null then
          w_importo_anno := nvl(f_importi_ruoli_tarsu(a_cod_fiscale,a_anno_ruolo,w_ruolo_acconto,to_number(null),'IMPOSTA'),0) -
                            nvl(f_importo_vers(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_importo_vers_ravv(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_dovuto(0,a_anno_ruolo,'TARSU',0,-1,'S',null,a_cod_fiscale),0);
          if w_importo_anno <= w_insolvenza_min then
             w_importo_anno := to_number(null);
          end if;
       end if;
    end if;
    -- Si esegue un loop sui 5 anni precedenti per determinare
    -- l'eventuale dovuto residuo
    t_importo_anno.delete;
    w_ind := 0;
    for w_ind in 1 .. w_numero_anni
    loop
      -- Si determina l'anno di riferimento e l'ultimo ruolo totale emesso per quell'anno
      w_anno_rif := a_anno_ruolo - w_ind;
      begin
        w_ultimo_ruolo := f_ruolo_totale(a_cod_fiscale
                                        ,w_anno_rif
                                        ,a_tipo_tributo
                                        ,-1
                                        );
      exception
        when others then
          w_ultimo_ruolo := to_number(null);
      end;
      begin
        select nvl(sum(nvl(ogim.imposta,0) + nvl(ogim.maggiorazione_eca,0) +
               nvl(ogim.addizionale_eca,0) + nvl(ogim.addizionale_pro,0) +
               nvl(ogim.iva,0) + nvl(ogim.maggiorazione_tares,0)),0) imp_dovuto
          into w_imp_dovuto
          from oggetti_imposta ogim
              ,oggetti_pratica ogpr
              ,pratiche_tributo prtr
              ,ruoli ruol
         where ogim.cod_fiscale = a_cod_fiscale
           and ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = prtr.pratica
           and (prtr.tipo_pratica = 'D'
             or (prtr.tipo_pratica = 'A'
             and ogim.anno > prtr.anno))
           and prtr.tipo_tributo||'' = 'TARSU'
           and nvl (ogim.ruolo, -1) =
                 nvl (nvl (w_ultimo_ruolo
                          ,ogim.ruolo
                          )
                     ,-1
                     )
            and ruol.ruolo = ogim.ruolo
            and ruol.invio_consorzio is not null
            and ogim.anno = w_anno_rif
          group by ogim.anno
                 , prtr.tipo_tributo
                 ;
      exception
        when others then
          w_imp_dovuto := 0;
      end;
      begin
        select f_importo_vers (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, null)
             + f_importo_vers_ravv (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, 'U') imp_versato
             , nvl(f_dovuto(0,a_anno_ruolo - w_ind,a_tipo_tributo,0,-1,'S',null,a_cod_fiscale),0) imp_sgravi
          into w_imp_versato
             , w_imp_sgravi
          from dual;
      exception
        when others then
          w_imp_versato := 0;
          w_imp_sgravi := 0;
      end;
      t_importo_anno(w_ind) := w_imp_dovuto - w_imp_versato - w_imp_sgravi;
      if t_importo_anno(w_ind) <= w_insolvenza_min then
         t_importo_anno(w_ind) := to_number(null);
      end if;
    end loop;
    -- Alla fine del trattamento si verifica se occorre compilare anche la
    -- nota utenza
    w_stringa_anni := '';
    if w_importo_anno is not null then
       w_stringa_anni := 'l''anno '||a_anno_ruolo;
    end if;
    for w_ind in reverse 1 .. w_numero_anni
    loop
       if t_importo_anno (w_ind) is not null then
          if w_stringa_anni is null then
             w_stringa_anni := 'l''anno '||to_char(a_anno_ruolo - w_ind);
          else
             w_stringa_anni := replace(w_stringa_anni,'l''anno','gli anni');
             w_stringa_anni := w_stringa_anni||', '||to_char(a_anno_ruolo - w_ind);
          end if;
       end if;
     end loop;
     if w_stringa_anni is not null then
        w_note_utenza := replace(w_stringa_vers_irr,'XXXX',w_stringa_anni);
     else
        w_note_utenza := w_stringa_vers_reg;
     end if;
    return w_note_utenza;
  end f_get_stringa_versamenti;

  function contribuente(a_pratica number
                       ,a_ni_erede number default -1) return sys_refcursor is
    rc sys_refcursor;
    w_index                        number;
    w_deceduto                     record_pratica;
    w_progressivo_erede            number;
  begin

    p_tab_soggetto_pratica.delete;
    w_index := 0;

    delete_ni_erede_principale;
    if (a_ni_erede != -1) then
       w_progressivo_erede := set_ni_erede_principale(a_ni_erede);
    end if;

    open rc for
      select comune_ente,
             sigla_ente,
             provincia_ente,
             cognome_nome,
             ni,
             cod_sesso,
             sesso,
             cod_contribuente,
             cod_controllo,
             cod_fiscale,
             indirizzo,
             pratica,
             tipo_tributo,
             f_descrizione_titr(tipo_tributo, anno) as descr_titr,
             tipo_pratica,
             tipo_evento,
             anno,
             numero,
             tipo_rapporto,
             data_pratica,
             data_notifica,
             data_odierna,
             dati_db1,
             dati_db2,
             label_rap,
             rappresentante,
             cod_fiscale_rap,
             indirizzo_rap,
             comune_rap,
             descr_carica carica_rap,
             comune,
             telefono,
             data_nascita,
             comune_nascita,
             presso,
             erede_di,
             cognome_nome_erede,
             cod_fiscale_erede,
             indirizzo_erede,
             comune_erede,
             note_pratica,
             motivo_pratica,
             utente_pratica,
             des_utente_pratica,
             decode(f_recapito(ni,
                               tipo_tributo,
                               3,
                               trunc(sysdate)
                               ),
                    null,null,'PEC ') label_indirizzo_pec,
             f_recapito(ni,
                        tipo_tributo,
                        3,
                        trunc(sysdate)
                       ) indirizzo_pec,
             decode(f_recapito(ni,
                               tipo_tributo,
                               2,
                               trunc(sysdate)
                               ),
                    null,null,'E-mail ') label_indirizzo_email,
             f_recapito(ni,
                        tipo_tributo,
                        2,
                        trunc(sysdate)
                       ) indirizzo_email,
             decode(f_recapito(ni,
                               tipo_tributo,
                               4,
                               trunc(sysdate)
                               ),
                    null,null,'Nr. Tel. ') label_telefono_fisso,
             f_recapito(ni,
                        tipo_tributo,
                        4,
                        trunc(sysdate)
                       ) telefono_fisso,
             decode(f_recapito(ni,
                               tipo_tributo,
                               6,
                               trunc(sysdate)
                               ),
                    null,null,'Cell. ') label_cell_personale,
             f_recapito(ni,
                        tipo_tributo,
                        6,
                        trunc(sysdate)
                       ) cell_personale,
             decode(f_recapito(ni,
                               tipo_tributo,
                               7,
                               trunc(sysdate)
                               ),
                    null,null,'Cell. Ufficio ') label_cell_lavoro,
             f_recapito(ni,
                        tipo_tributo,
                        7,
                        trunc(sysdate)
                       ) cell_lavoro,
             decode(sopr.tipo_residente||sopr.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                    11,sopr.cognome_nome, --decode(sopr.label_rap,'',sopr.cognome_nome,sopr.rappresentante),
                       decode(sopr.erede_di,
                             '',decode(sopr.stato,50,'Eredi di ','')||sopr.cognome_nome,
                             sopr.cognome_nome_erede)
                   ) riga_destinatario_1,
             decode(sopr.tipo_residente||sopr.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                    11,sopr.presso, --decode(sopr.label_rap,'',sopr.presso,sopr.descr_carica||' '||sopr.cognome_nome),
                       decode(sopr.erede_di,
                              '',sopr.presso,
                                 sopr.erede_di||' '||sopr.cognome_nome||
                                 decode(sopr.presso_erede,'','',' '||sopr.presso_erede)
                             )
                   ) riga_destinatario_2,
             ltrim(decode(sopr.scala_dest,'','','Scala '||sopr.scala_dest)||
                   decode(sopr.piano_dest,'','',' Piano '||sopr.piano_dest)||
                   decode(sopr.interno_dest,'','',' Int. '||sopr.interno_dest)) riga_destinatario_3,
             sopr.via_dest||' '||sopr.num_civ_dest||
             decode(sopr.suffisso_dest,'','','/'||sopr.suffisso_dest) riga_destinatario_4,
             sopr.cap_dest||' '||sopr.comune_dest||' '||sopr.provincia_dest riga_destinatario_5
        from soggetti_pratica sopr
       where (sopr.pratica = a_pratica)
         and (nvl(tipo_rapporto, 'D') in ('D', 'E'));

       loop fetch rc into w_deceduto;
          exit when rc%NOTFOUND;

          p_tab_soggetto_pratica.extend;
          w_index := w_index + 1;
          p_tab_soggetto_pratica(w_index) := w_deceduto;

          end loop;
      close rc;


       if (a_ni_erede != -1) then
          delete_ni_erede_principale;
       end if;

    open rc for
      select * from table(f_get_collection_principale);

    return rc;
  end;

  function contribuenti_ente(a_ni           number default -1,
                             a_tipo_tributo varchar2 default '',
                             a_cod_fiscale  varchar2 default '',
                             a_ruolo        number default -1,
                             a_modello      number default -1,
                             a_anno         number default -1,
                             a_pratica_base number default -1)
    return sys_refcursor is
    w_ni                     number;
    rc                       sys_refcursor;
    w_descr_ord              modelli.descrizione_ord%TYPE;
  begin
    -- se si passa come parametro il codice fiscale invece dell'ni
    -- si determina l'ni dalla tabella contribuenti
    if nvl(a_ni,-1) = -1 and a_cod_fiscale is not null then
       begin
         select ni
           into w_ni
           from contribuenti
          where cod_fiscale = a_cod_fiscale;
       exception
         when others then
           w_ni := -1;
       end;
    else
       w_ni := a_ni;
    end if;
    begin
      select modelli.descrizione_ord
        into w_descr_ord
        from modelli
       where modello = a_modello;
    exception
      when NO_DATA_FOUND then
        w_descr_ord := '';
    end;
    if a_ruolo = -1 then -- Utilizzato per lettera generica
       open rc for
         select coen.comune_ente,
                coen.sigla_ente,
                coen.provincia_ente,
                coen.cognome_nome,
                coen.ni,
                coen.cod_sesso,
                coen.sesso,
                coen.cod_contribuente,
                coen.cod_controllo,
                coen.cod_fiscale,
                coen.presso,
                upper(coen.indirizzo) indirizzo,
                coen.comune,
                coen.comune_provincia,
                coen.cap,
                coen.telefono,
                to_char(coen.data_nascita, 'DD/MM/YYYY') data_nascita,
                coen.comune_nascita,
                coen.label_rap,
                coen.rappresentante,
                coen.cod_fiscale_rap,
                coen.indirizzo_rap,
                coen.comune_rap,
                coen.data_odierna,
                coen.tipo_tributo,
                coen.erede_di,
                coen.cognome_nome_erede,
                coen.cod_fiscale_erede,
                coen.indirizzo_erede,
                coen.comune_erede,
                coen.partita_iva,
                upper(coen.via_dest) via_dest,
                coen.num_civ_dest,
                decode(coen.suffisso_dest,'','','/'||suffisso_dest) suffisso_dest,
                coen.scala_dest,
                coen.piano_dest,
                coen.interno_dest,
                coen.cap_dest,
                upper(coen.comune_dest) comune_dest,
                coen.provincia_dest,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  3,
                                  trunc(sysdate)
                                  ),
                       null,null,'PEC ') label_indirizzo_pec,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           3,
                           trunc(sysdate)
                          ) indirizzo_pec,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                 2,
                                 trunc(sysdate)
                                 ),
                      null,null,'E-mail ') label_indirizzo_email,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           2,
                           trunc(sysdate)
                          ) indirizzo_email,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  4,
                                  trunc(sysdate)
                                  ),
                       null,null,'Nr. Tel. ') label_telefono_fisso,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           4,
                           trunc(sysdate)
                          ) telefono,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  6,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. ') label_cell_personale,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           6,
                           trunc(sysdate)
                          ) cell_personale,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  7,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. Ufficio ') label_cell_lavoro,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           7,
                           trunc(sysdate)
                          ) cell_lavoro,
                decode(coen.tipo_residente||coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.cognome_nome, --decode(coen.label_rap,'',coen.cognome_nome,coen.rappresentante),
                          decode(coen.erede_di,
                                '',decode(coen.stato,50,'Eredi di ','')||coen.cognome_nome,
                                coen.cognome_nome_erede)
                      ) riga_destinatario_1,
                decode(coen.tipo_residente||coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.presso, --decode(coen.label_rap,'',coen.presso,coen.descr_carica||' '||coen.cognome_nome),
                          decode(coen.erede_di,
                                 '',coen.presso,
                                    coen.erede_di||' '||coen.cognome_nome||
                                    decode(coen.presso_erede,'','',' '||coen.presso_erede)
                                )
                      ) riga_destinatario_2,
                ltrim(decode(coen.scala_dest,'','','Scala '||coen.scala_dest)||
                      decode(coen.piano_dest,'','',' Piano '||coen.piano_dest)||
                      decode(coen.interno_dest,'','',' Int. '||coen.interno_dest)
                     ) riga_destinatario_3,
                coen.via_dest||' '||coen.num_civ_dest||
                decode(coen.suffisso_dest,'','','/'||coen.suffisso_dest) riga_destinatario_4,
                coen.cap_dest||' '||coen.comune_dest||' '||coen.provincia_dest riga_destinatario_5,
                f_descrizione_titr(coen.tipo_tributo,to_number(to_char(sysdate,'yyyy'))) descr_titr,
                a_ruolo ruolo,
                a_modello modello,
                a_anno anno_imposta,
               a_pratica_base pratica_base,
               to_char(CURRENT_DATE, 'dd/mm/yyyy') data_odierna,
               to_char(scad.r0, 'dd/mm/yyyy') scadenza_rata_unica,
               to_char(scad.r1, 'dd/mm/yyyy') scadenza_prima_rata,
               to_char(scad.r2, 'dd/mm/yyyy') scadenza_rata_2,
               to_char(scad.r3, 'dd/mm/yyyy') scadenza_rata_3,
               to_char(scad.r4, 'dd/mm/yyyy') scadenza_rata_4,
               to_char(scad.r5, 'dd/mm/yyyy') scadenza_rata_5
          from contribuenti_ente coen,
                (select
                  w_ni as ni,
                  max((case when rata = 0 then data_scadenza else null end)) as R0,
                  max((case when rata = 1 then data_scadenza else null end)) as R1,
                  max((case when rata = 2 then data_scadenza else null end)) as R2,
                  max((case when rata = 3 then data_scadenza else null end)) as R3,
                  max((case when rata = 4 then data_scadenza else null end)) as R4,
                  max((case when rata = 5 then data_scadenza else null end)) as R5
                from
                  scadenze
                where
                  tipo_scadenza = 'V' and
                  tipo_tributo = a_tipo_tributo and
                  anno = a_anno
                group by
                  tipo_scadenza, tipo_tributo, anno
                ) scad
         where coen.ni = w_ni
           and coen.tipo_tributo = a_tipo_tributo
           and coen.ni = scad.ni (+);
    else
       open rc for
         select coen.comune_ente,
                coen.sigla_ente,
                coen.provincia_ente,
                coen.cognome_nome,
                coen.ni,
                coen.cod_sesso,
                coen.sesso,
                coen.cod_contribuente,
                coen.cod_controllo,
                coen.cod_fiscale,
                coen.presso,
                upper(coen.indirizzo),
                coen.comune,
                coen.comune_provincia,
                coen.cap,
                coen.telefono,
                to_char(coen.data_nascita, 'DD/MM/YYYY') data_nascita,
                coen.comune_nascita,
                coen.label_rap,
                coen.rappresentante,
                coen.cod_fiscale_rap,
                coen.indirizzo_rap,
                coen.comune_rap,
                coen.descr_carica carica_rap,
                coen.data_odierna,
                coen.tipo_tributo,
                coen.erede_di,
                coen.cognome_nome_erede,
                coen.cod_fiscale_erede,
                coen.indirizzo_erede,
                coen.comune_erede,
                coen.partita_iva,
                upper(coen.via_dest) via_dest,
                coen.num_civ_dest,
                decode(coen.suffisso_dest,'','','/'||suffisso_dest) suffisso_dest,
                coen.scala_dest,
                coen.piano_dest,
                coen.interno_dest,
                coen.cap_dest,
                upper(coen.comune_dest) comune_dest,
                coen.provincia_dest,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  3,
                                  trunc(sysdate)
                                  ),
                       null,null,'PEC ') label_indirizzo_pec,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           3,
                           trunc(sysdate)
                          ) indirizzo_pec,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  2,
                                  trunc(sysdate)
                                  ),
                       null,null,'E-mail ') label_indirizzo_email,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           2,
                           trunc(sysdate)
                          ) indirizzo_email,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  4,
                                  trunc(sysdate)
                                  ),
                       null,null,'Nr. Tel. ') label_telefono_fisso,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           4,
                           trunc(sysdate)
                          ) telefono,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  6,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. ') label_cell_personale,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           6,
                           trunc(sysdate)
                          ) cell_personale,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  7,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. Ufficio ') label_cell_lavoro,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           7,
                           trunc(sysdate)
                          ) cell_lavoro,
                decode(coen.tipo_residente||coen.tipo,
                    -- (VM - 28/08/2023): #65940 - Aggiunta la rimozione del rappresentante legale
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.cognome_nome, --decode(coen.label_rap,'',coen.cognome_nome,coen.rappresentante),
                          decode(coen.erede_di,
                                '',decode(coen.stato,50,'Eredi di ','')||coen.cognome_nome,
                                coen.cognome_nome_erede)
                      ) riga_destinatario_1,
                decode(coen.tipo_residente||coen.tipo,
                    -- Aggiunto il 30/01/2023 AB qui era scappato
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.presso, --decode(coen.label_rap,'',coen.presso,coen.descr_carica||' '||coen.cognome_nome),
                          decode(coen.erede_di,
                                 '',coen.presso,
                                    coen.erede_di||' '||coen.cognome_nome||
                                    decode(coen.presso_erede,'','',' '||coen.presso_erede)
                                )
                      ) riga_destinatario_2,
                ltrim(decode(coen.scala_dest,'','','Scala '||coen.scala_dest)||
                      decode(coen.piano_dest,'','',' Piano '||coen.piano_dest)||
                      decode(coen.interno_dest,'','',' Int. '||coen.interno_dest)
                     ) riga_destinatario_3,
                coen.via_dest||' '||coen.num_civ_dest||
                decode(coen.suffisso_dest,'','','/'||coen.suffisso_dest) riga_destinatario_4,
                coen.cap_dest||' '||coen.comune_dest||' '||coen.provincia_dest riga_destinatario_5,
                f_descrizione_titr(coen.tipo_tributo,anno_ruolo) descr_titr,
                a_ruolo ruolo,
                a_modello modello,
               a_anno anno_imposta,
                a_pratica_base pratica_base,
             -- Ruolo
                ruoli.tipo_ruolo,
                ruoli.anno_ruolo,
                ruoli.anno_emissione,
                ruoli.progr_emissione,
                to_char(ruoli.data_emissione, 'dd/mm/yyyy') data_emissione,
                ruoli.descrizione,
                ruoli.rate,
                ruoli.specie_ruolo,
                ruoli.cod_sede,
                ruoli.data_denuncia,
                to_char(ruoli.scadenza_prima_rata, 'dd/mm/yyyy') scadenza_prima_rata,
                to_char(ruoli.scadenza_rata_2, 'dd/mm/yyyy') scadenza_rata_2,
                to_char(ruoli.scadenza_rata_3, 'dd/mm/yyyy') scadenza_rata_3,
                to_char(ruoli.scadenza_rata_4, 'dd/mm/yyyy') scadenza_rata_4,
               to_char(ruoli.scadenza_rata_unica, 'dd/mm/yyyy') scadenza_rata_unica,
                to_char(ruoli.invio_consorzio, 'dd/mm/yyyy') invio_consorzio,
                ruoli.ruolo_rif,
                ruoli.importo_lordo,
                ruoli.a_anno_ruolo,
                ruoli.cognome_resp,
                ruoli.nome_resp,
                to_char(ruoli.data_fine_interessi, 'dd/mm/yyyy') data_fine_interessi,
                ruoli.stato_ruolo,
                ruoli.ruolo_master,
                ruoli.tipo_calcolo,
                ruoli.tipo_emissione,
                ruoli.perc_acconto,
                ruoli.ente,
                ruoli.flag_calcolo_tariffa_base,
                ruoli.flag_tariffe_ruolo,
                ruoli.note,
                ruoli.utente,
                to_char(ruoli.data_variazione, 'dd/mm/yyyy') data_variazione,
                decode(w_descr_ord, 'SGR%', '',
                   f_get_stringa_versamenti( ruoli.tipo_tributo
                                           , a_cod_fiscale
                                           , a_ruolo
                                           , ruoli.anno_ruolo
                                           , ruoli.tipo_ruolo
                                           , ruoli.tipo_emissione
                                           , a_modello)) stringa_versamenti
           from contribuenti_ente coen,
                ruoli
          where coen.ni = w_ni
            and ruoli.ruolo = a_ruolo
            and coen.tipo_tributo = a_tipo_tributo;
    end if;
    return rc;
  end;
-----------------------------------------------------------------
function interessi(
   a_pratica          number    default -1
 , a_tipo_interessi   varchar2  default null
)
return sys_refcursor is
  /******************************************************************************
    NOME:        INTERESSI
    DESCRIZIONE: Restituisce un ref_cursor contenente il dettaglio degli interessi
    RITORNA:     ref_cursor.
    PARAMETRI :  a_pratica           Numero della pratica
                 a_tipo_interessi    Tipo di interessi da uutilizzare
                                     null : Tipo predefinito per tipo_pratica
                                     'G' : Giornaliero
                                     'L' : Legale

    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    000   16/09/2024  RV      #55525
                              Versione iniziale
  ******************************************************************************/
    rc sys_refcursor;
  begin
    open rc for
      select TIPO_VERSAMENTO
       , RATA
       , stampa_common.f_formatta_numero(SUM(base),'I','N') as base
       , ALIQUOTA
       , DAL
       , AL
       , GG
       , decode(sum(interessi),null,'',
                       trim(to_char(sum(interessi),'99G999G999G990D0000','NLS_NUMERIC_CHARACTERS = '',.'''))
                ) as interessi
       , INTERESSI_RICALC_TOT
       , INTERESSI_RICALC_ROUND
        from (
          select 
                  -- Finale : Formattazione valori
                    decode(intr.tipo_versamento,'U','Unico','A','Acconto','S','Saldo','') as tipo_versamento
                  , decode(intr.rata,null,'',0,'Unica',to_char(intr.rata)) as rata
                  , intr.base
                  , decode(intr.interessi,null,'',
                           trim(to_char(intr.aliquota,'99G999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.'''))
                    ) as aliquota
                  , to_char(intr.dal,'DD/mm/YYYY') as dal
                  , to_char(intr.al,'DD/mm/YYYY') as al
                  , to_char(intr.gg) as gg
                  , intr.interessi
                  , decode(intr.interessi,null,'',
                           trim(to_char(intr.interessi_ricalc_tot,'99G999G999G990D0000','NLS_NUMERIC_CHARACTERS = '',.'''))
                    ) as interessi_ricalc_tot
                  , stampa_common.f_formatta_numero(round(sum(intr.inter_bysanz_tot / intr.inter_bysanz_cnt) over(),2),'I','S') as interessi_ricalc_round
                from
                  (select
                      -- INTR : Arrotondamenti e totali
                      intt.cod_sanzione,
                      intt.ordine,
                      intt.tipo_versamento,
                      intt.rata,
                      intt.base,
                      intt.aliquota,
                      intt.dal,
                      intt.al,
                      intt.gg,
                      intt.interessi,
                      decode(intt.interessi,null,null,round(intt.interessi,2)) as interessi_round,
                      round(intt.int_rif,2) as interessi_rif,
                      round(intt.int_tot_rif,2) as interessi_tot,
                      sum(round(nvl(intt.interessi,0),4)) over () as interessi_ricalc_tot,
                      round(sum(intt.interessi) over (PARTITION BY intt.cod_sanzione),2) as inter_bysanz_tot,
                      count(*) over (PARTITION BY intt.cod_sanzione) as inter_bysanz_cnt
                  from
                    (select
                      -- INTT : Calcolo gg ed interessi parziali per singola aliquota
                      intc.cod_sanzione,
                      intc.tipo_versamento,
                      intc.rata,
                      intc.int_rif,
                      intc.int_tot_rif,
                      intc.ordine,
                      intc.base,
                      intc.aliquota,
                      intc.dal,
                      intc.al,
                      (intc.al - intc.dal + 1) as gg,
                      decode(intc.base,null,null,
                             intc.base * intc.aliquota * 0.01 * (intc.al - intc.dal + 1) / 365
                      ) as interessi
                    from
                      (select
                        -- INTC : Scomposizione ed estrazione aliquote per data dal / al
                        intv.cod_sanzione,
                        intv.tipo_versamento,
                        intv.rata,
                        intv.int_rif,
                        intv.int_tot_rif,
                        intv.ordine,
                        intv.base,
                        inte.aliquota,
                        greatest(inte.data_inizio,intv.dal) dal,
                        least(inte.data_fine,intv.al) al
                      from
                        pratiche_tributo prtr,
                        interessi inte,
                        (select
                            -- INTV : Elaborazione ed estrazione date dal/al ed importo base
                            ints.pratica,
                            ints.cod_sanzione,
                            ints.tipo_versamento,
                            ints.rata,
                            ints.int_rif,
                            ints.int_tot_rif,
                            ints.ordine,
                            decode(ints.str_dal,null,
                                    case when ints.data_rif is not null and ints.gg_rif is not null then
                                      ints.data_rif - ints.gg_rif + 1
                                    else
                                      TO_DATE('31/12/9999','dd/mm/YYYY')
                                    end,
                                    TO_DATE(ints.str_dal,'dd/mm/YYYY')
                                    ) as dal,
                            decode(ints.str_al,null,
                                    case when ints.data_rif is not null and ints.gg_rif is not null then
                                      ints.data_rif
                                    else
                                      TO_DATE('31/12/9999','dd/mm/YYYY')
                                    end,
                                    TO_DATE(ints.str_al,'dd/mm/YYYY')
                                    ) as al,
                            decode(ints.str_base,null,null,TO_NUMBER(ints.str_base,'99999D99','NLS_NUMERIC_CHARACTERS='',.''')) as base
                        from
                          (select
                              -- INTS : Estrazione di gg_rif, stringhe di date dal/al ed importo base
                              intd.pratica,
                              intd.cod_sanzione,
                              intd.tipo_versamento,
                              intd.rata,
                              intd.int_rif,
                              intd.int_tot_rif,
                              intd.data_rif,
                              intd.ordine,
                              case when (intd.idx_dal - intd.idx_gg) > 6 then  -- ' gg: xxxxx' 6-10 chars
                                TO_NUMBER(substr(intd.note,intd.idx_gg + 5,intd.idx_dal - intd.idx_gg - 5))
                              else
                                case when (intd.idx_int_1 - intd.idx_gg_1) > 6 then  -- ' GG xxxxx' 5-9 chars
                                  TO_NUMBER(substr(intd.note,intd.idx_gg_1 + 4,intd.idx_int_1 - intd.idx_gg_1 - 4))
                                else
                                  null
                                end
                              end gg_rif,
                              case when (intd.idx_al - intd.idx_dal) = 16 then  -- ' dal: dd/mm/yyyy' 16 chars
                                substr(intd.note,intd.idx_dal + 6,10)
                              else
                                null
                              end str_dal,
                              case when (intd.idx_base - intd.idx_al) = 15 then  -- ' al: dd/mm/yyyy' 15 chars
                                substr(intd.note,intd.idx_al + 5,10)
                              else
                                null
                              end str_al,
                              case when (intd.idx_base > intd.idx_al ) and (intd.idx_end - intd.idx_base) > 0 then
                                substr(intd.note,intd.idx_base + 7,intd.idx_end - intd.idx_base - 5)
                              else
                                case when (intd.idx_base_1 > 0) and (intd.idx_gg_1 - intd.idx_base_1) > 6 then
                                  substr(intd.note, intd.idx_base_1 + 6,intd.idx_gg_1 - intd.idx_base_1 - 6)
                                else
                                  null
                                end
                              end str_base
                          from
                            (select
                              -- INTD : Determina posizione valori di interesse
                              intp.pratica,
                              intp.cod_sanzione,
                              intp.tipo_versamento,
                              intp.rata,
                              intp.ordine,
                              intp.note,
                              intp.int_rif,
                              intp.int_tot_rif,
                              intp.data_rif,
                              instr(intp.note,' gg: ') as idx_gg,
                              instr(intp.note,' dal: ') as idx_dal,
                              instr(intp.note,' al: ') as idx_al,
                              instr(intp.note,' base: ') as idx_base,
                              instr(intp.note,'Base: ') as idx_base_1,
                              instr(intp.note,' GG ') as idx_gg_1,
                              instr(intp.note,' interessi ') as idx_int_1,
                              length(intp.note) as idx_end
                            from
                            (select intx.*, ROWNUM as ordine from 
                                (select distinct
                                  -- INTP : Scompone le note per singolo dettaglio calcolo
                                  intr.pratica,
                                  intr.cod_sanzione,
                                  intr.tipo_versamento,
                                  intr.rata,
                                  intr.int_rif,
                                  intr.int_tot_rif,
                                  intr.data_rif,
                                  trim(REGEXP_SUBSTR(intr.note,'[^#]+', 1, level)) AS note
                                from
                                  (select
                                    -- INTR : Estrazione sanzioni di interessi, data riferimento interessi e predisposizione campo note
                                    sapr.pratica,
                                    sapr.cod_sanzione,
                                    replace(sapr.note||' ',' - ','#') as note,
                                    sanz.tipo_versamento,
                                    sanz.rata,
                                    sapr.importo as int_rif,
                                    sum(sapr.importo) over() as int_tot_rif,
                                    decode(prtr.tipo_pratica,
                                           'V',nvl(prtr.data_rif_ravvedimento,prtr.data),
                                           prtr.data
                                           ) as data_rif
                                  from
                                    sanzioni_pratica sapr,
                                    sanzioni sanz,
                                    pratiche_tributo prtr
                                  where prtr.pratica = a_pratica
                                    and sapr.pratica = prtr.pratica
                                    and sapr.cod_sanzione = sanz.cod_sanzione
                                    and sapr.sequenza_sanz = sanz.sequenza
                                    and sapr.tipo_tributo = sanz.tipo_tributo
                                    and sanz.tipo_causale = 'I'
                                   ) intr
                                CONNECT BY trim(REGEXP_SUBSTR(intr.note,'[^#]+', 1, level)) IS NOT NULL
                                ) intx 
                              ) intp
                            ) intd
                          ) ints
                        ) intv
                       where prtr.pratica = intv.pratica
                         and inte.tipo_tributo||''  = prtr.tipo_tributo||''
                         and inte.data_inizio      <= intv.al
                         and inte.data_fine        >= intv.dal
                         and inte.tipo_interesse    = decode(a_tipo_interessi,
                                                             null,decode(prtr.tipo_pratica,
                                                                         'V','L',
                                                                         'G'
                                                             ),
                                                             a_tipo_interessi
                                                      )
                      ) intc
                   ) intt
                 ) intr
               )
               GROUP BY
                 TIPO_VERSAMENTO,
                 RATA,
                 ALIQUOTA,
                 DAL,
                 AL,
                 GG,
                 INTERESSI_RICALC_TOT,
                 INTERESSI_RICALC_ROUND
              order by rata, to_date(dal, 'DD/MM/YYYY'), to_date(al, 'DD/MM/YYYY');

    return rc;
  end interessi;
------------------------------------------------------------------

  FUNCTION eredi(a_pratica             NUMBER default -1,
                 a_ni_erede_principale number default -1)
    RETURN sys_refcursor IS
    w_index     number;
    w_erede     record_pratica;
    w_eredi_cur sys_refcursor;
    rc          sys_refcursor;
  BEGIN

    p_tab_eredi.delete;
    w_index := 0;

    for sel_eredi in (select prtr.pratica, erso.ni_erede
                        from contribuenti     conx,
                             pratiche_tributo prtr,
                             eredi_soggetto   erso
                       where conx.cod_fiscale = prtr.cod_fiscale
                         and erso.ni = conx.ni
                         and prtr.pratica = a_pratica
                         and erso.ni_erede != decode(a_ni_erede_principale,
                                                     -1, f_primo_erede_ni(conx.ni),
                                                     a_ni_erede_principale)
                       order by erso.numero_ordine) loop

      w_eredi_cur := contribuente(sel_eredi.pratica, sel_eredi.ni_erede);

      loop

        fetch w_eredi_cur
          into w_erede;
        exit when w_eredi_cur%NOTFOUND;

        p_tab_eredi.extend;
        w_index := w_index + 1;
        p_tab_eredi(w_index) := w_erede;

      end loop;
      close w_eredi_cur;

    end loop;

    open rc for
      select * from table(f_get_collection_eredi);

    return rc;
  END eredi;
end stampa_common;
/
