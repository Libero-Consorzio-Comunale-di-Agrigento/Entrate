--liquibase formatted sql 
--changeset abrandolini:20250326_152423_replica_accertamento stripComments:false runOnChange:true 
 
create or replace procedure REPLICA_ACCERTAMENTO
/***************************************************************************
  NOME:        REPLICA_ACCERTAMENTO
  DESCRIZIONE: Replica l'accertamento per gli anni successivi
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  000   15/10/2024  RV      Prima emissione

  Dubbi                     Note
  ------------------------  ----------------------------------------------------
  p_dws.data_object         Quali servono ?
***************************************************************************/
( p_prat               IN  NUMBER
, p_anno_da            IN  NUMBER
, p_anno_a             IN  NUMBER
, p_data_emis          IN  DATE
, p_data_inizio        IN  VARCHAR2     --  YYYYMMDD per ogni annualita' : quindi (8 * ((p_anno_a - p_anno_da) + 1) caratteri
, p_data_fine          IN  VARCHAR2     --  Stesso formato di p_data_inizio
, p_flag_rivalutato    IN  VARCHAR2
, p_utente             IN  VARCHAR2
, p_pratiche_generate  OUT VARCHAR2
) IS
-------------------------------------------------
-- Definizioni - Costanti
------------------------------------------------
  NUOVO               constant number := 0;
  NUOVO_NO_ACC        constant number := 1;
  AGGIORNA            constant number := 2;
  ELIMINA             constant number := 3;
--
  NUOVO_SANZ          constant number := 100;
  VECCHIO_SANZ        constant number := 0;
  TUTTE               constant number := -1;
-------------------------------------------------
-- Definizioni - Tipi
------------------------------------------------
  type t_oggetto_acc is record
  ( oggetto_imposta         number,
    oggetto_pratica         number,
    cod_fiscale             varchar(16),
    anno                    number,
    imposta                 number,
    imposta_acconto         number,
    imposta_dovuta          number,
    imposta_dovuta_acconto  number,
    addizionale_eca         number,
    maggiorazione_eca       number,
    addizionale_pro         number,
    iva                     number,
    importo_versato         number,
    tipo_aliquota           number,
    aliquota                number,
    prtr_data               date,
    prtr_anno               number,
    prtr_data_notifica      date,
    prtr_numero             varchar(15),
    prtr_stato_accertamento varchar(2),
    prtr_tipo_tributo       varchar(5),
    oggetto                 number,
    ogpr_dic                number,
    ogpr_dic_v              number,
    perc_possesso           number,
    flag_ab_principale      varchar(1),
    imm_storico             varchar(1),
    mesi_possesso           number,
    mesi_possesso_1sem      number,
    da_mese_possesso        number,
    mesi_esclusione         number,
    mesi_riduzione          number,
    mesi_aliquota_ridot     number,
    detrazione              number,
    flag_possesso           varchar(1),
    flag_esclusione         varchar(1),
    flag_riduzione          varchar(1),
    flag_al_ridotta         varchar(1),
    flag_provvisorio        varchar(1),
    flag_valore_rivalutato  varchar(1),
    valore                  number,
    ruolo                   number,
    inizio_occupazione      date,
    fine_occupazione        date,
    data_decorrenza         date,
    data_cessazione         date,
    consistenza             number,
    tributo                 number,
    categoria               number,
    tipo_tariffa            number,
    tipo_occupazione        varchar(1),
    numero_familiari        number,
    categoria_catasto       varchar(3),
    classe_catasto          varchar(5),
    tipo_oggetto            number,
    oggetto_pratica_rif_ap  number,
    oggetto_ap              number,
    importo_pf              number,
    importo_pv              number,
    maggiorazione_tares     number,
    tipo_tariffa_base       number,
    imposta_base            number,
    addizionale_eca_base    number,
    maggiorazione_eca_base  number,
    addizionale_pro_base    number,
    iva_base                number,
    importo_pf_base         number,
    importo_pv_base         number,
    perc_riduzione_pf       number,
    perc_riduzione_pv       number,
    importo_riduzione_pf    number,
    importo_riduzione_pv    number,
    dettaglio_ogim          varchar(4000),
    dettaglio_ogim_base     varchar(4000),
    num_ordine              varchar(5),
    tipo_aliquota_prec      number,
    aliquota_prec           number,
    detrazione_prec_ogpr    number,
    imposta_lorda           number,
    flag_lordo              varchar(1),
    flag_ruolo              varchar(1),
    num_pertinenze          number,
    importo_lordo           number,
    --
    app_stringa_familiari   varchar(2000),
    app_dettaglio_ogim      varchar(4000),
    app_dettaglio_ogim_base varchar(4000),
    --
    quantita                number,
    superficie              number,
    larghezza               number,
    profondita              number,
    --
    settore                 number,
    reddito                 number,
    --
    detrazione_acconto      number,
    versato                 number,
    --
    prtr_dic_data           date,
    anno_rif                number,
    --
      perc_detrazione         number      -- TASI
    , mesi_occupato           number      -- TASI
    , mesi_occupato_1sem      number      -- TASI
    , aliquota_erar_prec      number      -- TASI
    , tipo_rapporto           varchar(1)  -- TASI
    , ogco_tipo_rapporto_k    varchar(1)  -- TASI
    --
    , flag_domicilio_fiscale   varchar(1) -- ICIAP
    --
    , data_concessione         date       -- ICP e TOSAP
  );
  --
  type t_oggetto_dic is record
  ( oggetto_imposta         number,
    oggetto_pratica         number,
    tipo_oggetto            number
  );
  --
  type t_dws is record
  ( ogg                     t_oggetto_acc,
    dic                     t_oggetto_dic,
    --
    data_object             varchar(40),
    replica                 boolean,
    --
    adesione                varchar(1)
  );
  --
  type t_ogg_riog is record
  ( data_inizio             date,
    data_fine               date,
    --
    categoria_catasto       varchar(3),
    classe_catasto          varchar(5),
    --
    rendita                 number,
    valore                  number,
    --
    mesi_possesso           number,
    mesi_possesso_1sem      number,
    da_mese_possesso        number,
    --
    mesi_esclusione         number,
    mesi_riduzione          number,
    mesi_aliquota_ridot     number,
    --
    num_ordine              varchar(5)
  );
  --
-------------------------------------------------
-- Definizioni - Variabili di lavoro
------------------------------------------------
  w_anno_acc              number;         -- era p_anno_acc
  w_titr                  varchar2(5);    -- era p_titr
  w_cf                    varchar2(16);   -- era p_cf
  w_stato_acc             varchar2(2);    -- era p_stato_acc
  w_flag_denuncia         varchar2(1);    -- era p_flag_denuncia
  w_flag_normalizzato     varchar2(1);    -- era p_flag_normalizzato
  w_motivo                varchar2(2000); -- era p_motivo
  --
  w_flag_adesione         varchar2(1);
  --
  w_rivalutato            boolean;        -- era p_rivalutato
  --
  v_dw_acc                t_dws;
  w_ogg_riog              t_ogg_riog;
  --
  v_rc                    sys_refcursor;
  v_rc_riog               sys_refcursor;
  --
  w_len                   number;
  w_ptr                   number;
  w_data_int              varchar(8);
  --
  w_data_replicabile      date;
  --
-------------------------------------------------
-- Definizioni - Da verificare - Generali di PB
------------------------------------------------
--
-- Da verificare - Legate alla pratica
  p_pratiche_acc          varchar(1000);
  p_tardiva_denuncia      varchar2(1);
  p_sanz                  number;
--
-- Da verificare - Legate al singolo oggetto
  p_esiste_dic            boolean;          -- era p_dic
  p_anno_dic              number;
  p_flag_poss_dic         varchar2(1);     -- era p_flag
  p_mesi_dic              number;          -- era p_mesi
--
-- Gestione oggetti multipli
  w_oggetto               number;          -- era p_oggetto
  w_oggetto_pratica_acc   number;          -- era p_oggetto_pratica_acc
  w_tipo_ogge             number;          -- era p_tipo_ogge
  w_flag_possesso_acc     varchar(1);      -- era p_flag_possesso_acc
  w_mesi_possesso_acc     number;          -- era p_mesi_possesso_acc
  w_da_mese_poss_acc      number;
  w_data_decorrenza_acc   date;            -- era p_data_decorrenza_acc
  w_data_cessazione_acc   date;            -- era p_data_cessazione_acc
  w_ogpr_dic_v            number;          -- era p_ogpr_dic_v
  --
-------------------------------------------------
-- Definizioni - Ereditate dal codice PB
------------------------------------------------
-- Variabili Generali per inserimento record di accertamento
  ianno                   number;
  w_check                 number;    -- check non si puo' usare !
  sanz                    number;
  w_check_acc             number;
  iAnno_Acc_Repl          number;
  iConta_Pratiche         number;
  iConta_Anno             number;
  iRet                    number;
  --
--num_ogge                number;
  num_prtr                number;
  num_ogpr                number;
  num_ogim                number;
  num_OgPrDic             number;
  num_Ogpr_Repl           number;
  nPratica                number;
  num_ordine              number;
  --
  data_not                date;
  dScad_vers              date;
  sNote                   varchar2(2000);
--sAppoggio               varchar2(100);
--sTitr                   varchar2(100);
  sPratiche_Acc           varchar2(1000);
  --
-- Variabili per l 'ICI
  dTipoOgge               number;
  dValore                 number;
  dTipo_Ali               number;
  dPercPoss               number;
  dMP                     number;
  dMP1S                   number;
  dME                     number;
  dMR                     number;
  dMP_Repl                number;
  dMP1S_Repl              number;
  detr                    number;
  dImposta                number;
  dImpostaDen             number;
  dImpo_dov               number;
  dImpo_ver               number;
  dImpo_dov_Repl          number;
  dImpo_ver_Repl          number;
  dImposta_Repl           number;
--dOgpr                   number;
  dAnno_dic               number;
--dMP_dic                 number;
--dOgge                   number;
  dOgim_vec               number;
  dAliq_Acc               number;
  dAliq                   number;
  detr_prec               number;
  dImposta_Prec           number;
  dtipo_ali_prec          number;
  dAliquota_prec          number;
  dImposta_acconto_Repl   number;
  dImpo_Dov_acconto_Repl  number;
  sf_ValRiv               varchar2(1);
  sf_ValRivPerCalc        varchar2(1);
  sCatCat                 varchar2(3);
  sCodFis                 varchar2(16);
  data_acc                date;
  data_acc_Repl           date;
  dAliquota               number;
  dAliquota_precedente    number;
--ret                     number;
  --
-- Variabili per ICP, TOSAP, TARSU
  data_dic                date;
  data_inizio             date;
  data_fine               date;
  data_decorr             date;
  data_cessaz             date;
  data_conc               date;
  inte_dal                date;
  inte_al                 date;
  dConsistenza            number;
  dQuantita               number;
  dTipo_Tari              number;
  dCate                   number;
  dTrib                   number;
  dImposta_Lorda          number;
  dMaggiorazioneTares     number;
  dMaggiorazioneTaresDen  number;
  dAddEcaDen              number;
  dMaggEcaDen             number;
  dAddProvDen             number;
  dIvaDen                 number;
  sTipoPubbl              varchar(1);
  sOccupazione            varchar(1);
  sFlag_Lordo             varchar(1);
  sFlag_ab_principale     varchar(1);
  sDettaglioOgim          varchar(4000);
  sDettaglioOgimDen       varchar(4000);
  sStringaFamiliari       varchar(2000);
  sTipoCalcolo            varchar(1);
  dMaggTares_repl         number;
  dMaggTares_dov_repl     number;
  dAddEca                 number;
  dMaggEca                number;
  dAddProv                number;
  dIva                    number;
--anno_dic                number;
  lnumero_familiari       number;
  --
-- (VD - 17/04/2019): variabili per nuovi parametri CALCOLO_ACCERTAMENTO_TARSU
  dImportoPf              number;
  dImportoPv              number;
  dTipoTariffaBase        number;
  dImportoBase            number;
  dAddEcaBase             number;
  dMaggEcaBase            number;
  dAddProvBase            number;
  dIvaBase                number;
  dImportoPfBase          number;
  dImportoPvBase          number;
  dPercRidPf              number;
  dPercRidPv              number;
  dImportoPfRid           number;
  dImportoPvRid           number;
  sDettaglioOgimBase      varchar(4000);
  --
-- (VD - 04/07/2022): variabile per nuovo parametro CALCOLO_ACCERTAMENTO_TARSU,
-- versione per TributiWeb (accertamenti con più oggetti)
  dImpostaPeriodo         number;
  --
-- Variabili per ICIAP
  dSettore                number;
  dClasse                 number;
  dReddito                number;
  --
-------------------------------------------------
-- Funzioni
------------------------------------------------
FUNCTION UF_CHECK_ACC
( p_tipo_tributo            IN     varchar2
, p_anno                    IN     number
, p_cod_fiscale             IN     varchar2
, p_oggetto                 IN     number
, p_pratica                 IN     number
, p_stato_accertamento      IN     varchar2
, p_flag_denuncia           IN     varchar2
, p_flag_possesso           IN     varchar2
, p_mesi_possesso           IN     number
, p_oggetto_pratica         IN     number
, p_dal                     IN     date
, p_al                      IN     date
) return number
/**
  Effettua controlli sugli accertamenti :
  Nel caso del tipo tributo IMU o TASI, a parità di Contribuente, Oggetto, Anno e Tipo Tributo,
  controlla che non esistano più accertamenti con stato nullo/D e flag denuncia = S.
  Inoltre gli eventuali accertamenti annullati non vengono considerati.
  Nel caso di TARI, a parità di Oggetto Pratica di Riferimento, Contribuente, Anno e Tipo Tributo
  controlla che non esistano accertamenti con stato nullo/D e flag denuncia = S.
  Inoltre questi non si devono intersecare con il periodo di validità dell'accertamento preso in esame.
  Nel caso di ICP/TOSAP, a parità di Oggetto Pratica di Riferimento, Contribuente, Anno e Tipo Tributo,
  controlla che non esistano altri accertamenti con stato nullo/D
  ----
  Attualmente la funzione è attiva soltanto per ICI e TARSU
  e per gli accertamenti con stato nullo o D -> Definitivo.
  Per ICI non sono significativi Dal e AL.
  Per TARSU non sono significativi Flag Possesso e Mesi Possesso.
**/
IS
  --
  w_result         number;
  --
  sErr             varchar2(2000);
  --
  nFlag_Denuncia   number;
  nFlag_Possesso   number;
  nMesi_Possesso   number;
  nOgpr_Rif        number;
  nIntersecanti    number;
--nTipo_Aliquota   number;
--nEsiste          number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    IF nvl(p_stato_accertamento, 'D' ) <> 'D' THEN
      w_result := 0;
    ELSE
      IF p_tipo_tributo IN ('ICI', 'TASI') then
        -- A parità di Contribuente, Oggetto, Anno, Tipo Tributo (ICI)
        -- non deve verificarsi:
        -- 1 - che esistano più accertamenti con stato nullo o D con flag denuncia = S
        -- 2 - che esistano più accertamenti con stato nullo o D con flag possesso = S
        -- 3 - che la somma dei mesi di possesso superi 12
        -- (VD - 23/08/2019): si esegue lo stesso controllo anche per la TASI (da verificare se va bene)
        -- (VD - 27/11/2019): aggiunto controllo su flag_annullamento: gli eventuali accertamenti annullati
        -- non vanno considerati
        BEGIN
          SELECT nvl(sum(decode(nvl(prtr.flag_denuncia, 'N' )||
                 nvl(p_flag_denuncia, 'N' ), 'SS' ,1,0)),0)
               , nvl(sum(decode(nvl(ogco.flag_possesso, 'N' )||
                 nvl(p_flag_possesso, 'N' ), 'SS' ,1,0)),0)
               , nvl(sum(nvl(ogco.mesi_possesso,12)),0) + nvl(p_mesi_possesso,12)
            INTO nFlag_Denuncia
               , nFlag_Possesso
               , nMesi_Possesso
            FROM oggetti_contribuente ogco
               , oggetti_pratica ogpr
               , pratiche_tributo prtr
           where prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND ogco.cod_fiscale = p_cod_fiscale
             AND ogco.anno = p_anno
             AND prtr.anno = p_anno
             AND prtr.tipo_pratica = 'A'
             AND nvl(prtr.stato_accertamento, 'D' ) = 'D'
             AND prtr.tipo_tributo|| '' = p_tipo_tributo
             AND ogpr.oggetto = p_oggetto
             AND prtr.pratica <> p_pratica
             AND nvl(prtr.flag_annullamento, 'N' ) <> 'S'
            ;
        EXCEPTION
          when NO_DATA_FOUND then
            nFlag_Possesso := 0;
            nFlag_Denuncia := 0;
            nMesi_Possesso := 0;
          WHEN others THEN
            raise_application_error(SQLCODE,SQLERRM);
        END;

        sErr := null;

        IF nFlag_Possesso > 0 THEN
          sErr := nvl(sErr,'') || '\nEsiste altro Accertamento con Possesso';
        END IF;
        IF nFlag_Denuncia > 0 THEN
          sErr := nvl(sErr,'') || '\nEsiste altro Accertamento per Omessa';
        END IF;
        IF nMesi_Possesso > 12 THEN
          sErr := nvl(sErr,'') || '\nI Mesi di Possesso dei vari Accertamenti superano i 12';
        END IF;

        if sErr is not null then
          raise_application_error(-20999,sErr);
          w_result := -2;
        end if;

        -- select ogpr.oggetto_pratica_rif
        --  into nOgpr_Rif
        --  from oggetti_pratica ogpr
        -- where ogpr.oggetto_pratica    = p_oggetto_pratica
        -- ;
        --
        -- select to_number(substr(max(lpad(to_char(ogim.anno),4,'0')||to_char(ogim.tipo_aliquota)),5))
        --   into nTipo_Aliquota
        --   from oggetti_imposta ogim
        --      , oggetti_pratica ogpr
        --  where ogim.oggetto_pratica = ogpr.oggetto_pratica
        --    and ogpr.oggetto_pratica = nOgpr_Rif
        --    and ogim.cod_fiscale     = p_cod_fiscale
        --    and ogim.anno           <= p_anno
        -- ;
        -- if NO_DATA then
        --    nTipo_Aliquota := null;
        -- end if;
        --
        -- if nTipo_Aliquota is null then
        --   raise_application_error(-20999,'Non è possibile Replicare l'Accertamento in Assenza di Imposte '||
        --                                  'di Denuncia o con Denuncia con Aliquote Multiple');
        --   w_result := -1;
        -- end if
        --
        w_result := 0;

      ELSIF p_tipo_tributo = 'TARSU' then
        -- A parità di Oggetto Pratica di Riferimento, Contribuente, Anno, Tipo Tributo (TARSU)
        -- non deve verificarsi:
        -- 1 - che esistano più accertamenti con stato nullo o D con flag denuncia = S
        -- 2 - che esistano accertamenti con stato nullo o D che si intersecano col periodo di
        --     validità dell' accertamento in esame
        BEGIN
          SELECT nvl(oggetto_pratica_rif, oggetto_pratica)
            INTO nOgpr_Rif
            FROM oggetti_pratica
           where oggetto_pratica = p_oggetto_pratica
          ;
        EXCEPTION
          WHEN others THEN
            raise_application_error(-20999,'Errore in Ricerca dell''oggetto pratica '||p_oggetto_Pratica);
        END;

        BEGIN
          SELECT nvl(sum(decode(nvl(prtr.flag_denuncia, 'N' )||
                 nvl(p_flag_denuncia, 'N' ), 'SS' ,1,0)),0)
            INTO nFlag_Denuncia
            FROM oggetti_contribuente ogco
               , oggetti_pratica ogpr
               , pratiche_tributo prtr
           where prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND ogco.cod_fiscale = p_cod_fiscale
             AND ogco.anno = p_anno
             AND prtr.anno = p_anno
             AND prtr.tipo_pratica = 'A'
             AND nvl(prtr.stato_accertamento, 'D' ) = 'D'
             AND prtr.tipo_tributo|| '' = 'TARSU'
             AND ogpr.oggetto = p_oggetto
             AND prtr.pratica <> p_pratica
          ;
        EXCEPTION
          when NO_DATA_FOUND then
            nFlag_Denuncia := 0;
          WHEN others THEN
            raise_application_error(SQLCODE,SQLERRM);
        END;

        SELECT count(*)
          INTO nIntersecanti
          FROM oggetti_contribuente ogco
             , oggetti_pratica ogpr
             , pratiche_tributo prtr
         where nvl(ogco.data_decorrenza,to_date( '01011900' , 'ddmmyyyy' ))
                  <= nvl(p_al ,to_date( '31122999' , 'ddmmyyyy' ))
            AND nvl(ogco.data_cessazione ,to_date( '31122999' , 'ddmmyyyy' ))
                  >= nvl(p_dal,to_date( '01011900' , 'ddmmyyyy' ))
            AND ogco.cod_fiscale = p_cod_fiscale
            AND ogco.anno = p_anno
            AND ogpr.oggetto_pratica = ogco.oggetto_pratica
            AND ogpr.oggetto_pratica <> p_oggetto_pratica
            AND ogpr.oggetto = p_oggetto
        --  and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica) = nOgpr_Rif
            AND prtr.pratica = ogpr.pratica
            AND prtr.tipo_tributo|| '' = 'TARSU'
            AND prtr.tipo_pratica = 'A'
            AND nvl(prtr.stato_accertamento, 'D' ) = 'D'
            AND prtr.tipo_evento =
                (select tipo_evento
                   FROM pratiche_tributo
                  where pratica = p_pratica)
        ;

        sErr := null;

        IF nFlag_Denuncia > 0 THEN
          sErr := nvl(sErr,'') || '\nEsiste altro Accertamento per Omessa';
        END IF;

        IF nIntersecanti > 0 THEN
          sErr := nvl(sErr,'') || '\nEsistono altri Accertamenti nello stesso Periodo';
        END IF;

        if sErr is not null then
          raise_application_error(-20999,sErr);
          w_result := -2;
        end if;

        w_result := 0;

      ELSIF p_tipo_tributo IN('ICP' ,'TOSAP') then
        -- A parità di Oggetto Pratica di Riferimento, Contribuente, Anno, Tipo Tributo
        -- non deve verificarsi:
        -- 1 - che esistano altri accertamenti con stato nullo o D
        BEGIN
          SELECT 1
            INTO nFlag_Denuncia
            FROM oggetti_contribuente ogco
               , oggetti_pratica ogpr
               , pratiche_tributo prtr
           where prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND ogco.cod_fiscale = p_cod_fiscale
             AND ogco.anno = p_anno
             AND prtr.anno = p_anno
             AND prtr.tipo_pratica = 'A'
             AND nvl(prtr.stato_accertamento, 'D' ) = 'D'
             AND prtr.tipo_tributo|| '' = p_tipo_tributo
             AND ogpr.oggetto = p_oggetto
             AND prtr.pratica <> p_pratica
            ;
        EXCEPTION
          when NO_DATA_FOUND then
            nFlag_Denuncia := 0;
          WHEN others THEN
             raise_application_error(SQLCODE,SQLERRM);
        END;

        sErr := null;

        IF nFlag_Denuncia > 0 THEN
            sErr := nvl(sErr,'') || 'Esiste altro Accertamento per Anno ' || p_anno;
        END IF;

        if sErr is not null then
          raise_application_error(-20999,sErr);
          w_result := -2;
        end if;

        w_result := 0;

      ELSE
        w_result := 0;
      END IF;
    END IF;

  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_CHECK_ACC;
------------------------------------------------
FUNCTION UF_UPDATE_PRTR
( p_dws             IN     t_dws
, p_pratica         IN     number
, p_cod_fiscale     IN     varchar2
, p_anno            IN     number
, p_data_not        IN     date
, p_motivo          IN     varchar2
, p_flag_denuncia   IN     varchar2
, p_note            IN     varchar2
, p_utente          IN     varchar2
, p_flag_update     IN     number
, p_tipo_tributo    IN     varchar2
, p_tipo_pratica    IN     varchar2             -- 'A'    ?????????????
, p_tipo_evento     IN     varchar2             -- 'U'    ?????????????
, p_data_dic        IN     date
, p_numero          IN     varchar2
, p_stato           IN     varchar2
, p_pratica_rif     IN     number
, p_tipo_calcolo    IN     varchar2
) return number
/**
  Se la pratica è nulla e flag_update = ELIMINA allora viene eliminata la pratica tributo legata al codice fiscale,
                                                anno e tipo_pratica (valore contenuto nel parametro p_tipo_trib).
  Se flag_update = NUOVO viene aggiunta la pratiche nelle pratiche_tributo.
  Se flag_update = AGGIORNA:

  Se p_dws.data_object = 'd_agg_noti_vers_multi' allora viene aggiornata solo la data notifica della pratica
  Altrimenti vengono aggiornati vari campi della pratica tra cui la data, il numero, lo stato_accertamento,
  il motivo, flag_denuncia, note, data_notifica, flag_adesione, utente, tipo_calcolo.
  Se la pratica esiste e flag_update = ELIMINA, la pratica viene eliminata.
  In caso di successo ritorna 0, altrimenti -1.
**/
IS
  --
  w_result         number;
  --
--nValore          number;
  stato_ades       varchar(2);
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    --
    stato_ades := null;
    --
    IF p_pratica is null AND p_flag_update = ELIMINA THEN
      -- In questo caso il parametro p_tipo_trib contiene il tipo pratica
      DELETE PRATICHE_TRIBUTO
       where COD_FISCALE = p_cod_fiscale
         AND ANNO = p_anno
         AND TIPO_PRATICA = p_tipo_tributo
      ;
      w_result := 0;

    ELSE
      IF p_flag_update <> ELIMINA THEN
        -- Tutto questo lo deve fare sempre tranne nel caso di replica
        IF p_tipo_tributo = 'TARSU' THEN
           stato_ades := p_dws.adesione;
        END IF;
      END IF;
      --
      CASE p_flag_update
        WHEN NUOVO then
--        p_dws.AcceptText()
          INSERT
            INTO PRATICHE_TRIBUTO
                 (PRATICA, COD_FISCALE, TIPO_TRIBUTO, ANNO, TIPO_PRATICA, TIPO_EVENTO,
                  DATA, NUMERO, STATO_ACCERTAMENTO, MOTIVO, FLAG_DENUNCIA, NOTE,
                  DATA_NOTIFICA, PRATICA_RIF, FLAG_ADESIONE, UTENTE, TIPO_CALCOLO )
          values (p_pratica, p_cod_fiscale, p_tipo_tributo, p_anno, p_tipo_pratica, p_tipo_evento,
                  p_data_dic, p_numero, p_stato, p_motivo, p_flag_denuncia, p_note,
                  p_data_not, p_pratica_rif, stato_ades, p_utente, p_tipo_calcolo)
          ;
          w_result := 0;

        WHEN AGGIORNA then
          IF p_dws.data_object = 'd_agg_noti_vers_multi' THEN
            UPDATE PRATICHE_TRIBUTO
               set DATA_NOTIFICA = p_data_not
             where PRATICA = p_pratica
            ;
          ELSE
            UPDATE PRATICHE_TRIBUTO
               set DATA = p_data_dic,
                   NUMERO = p_numero,
                   STATO_ACCERTAMENTO = p_stato,
                   MOTIVO = p_Motivo,
                   FLAG_DENUNCIA = p_flag_denuncia,
                   NOTE = p_note,
                   DATA_NOTIFICA = p_data_not,
                   FLAG_ADESIONE = stato_ades,
                   UTENTE = p_utente,
                   TIPO_CALCOLO = nvl(p_tipo_calcolo,tipo_calcolo)
             where PRATICA = p_pratica
            ;
          END IF;
          w_result := 0;

        WHEN ELIMINA then
          DELETE PRATICHE_TRIBUTO
           where PRATICA = p_pratica
          ;
          w_result := 0;

      END CASE;
    END IF;

  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_UPDATE_PRTR;
------------------------------------------------
FUNCTION UF_INSERT_RATR
( p_cod_fiscale      IN     varchar2
, p_pratica          IN     number
, p_tipo_rapp        IN     varchar2
) return number
/**
  Se è già presente un rapporto tributo per la pratica in questione non si fa niente.
  Altrimenti viene inserito il record in rapporti_tributo.
**/
IS
  --
  w_result         number;
  --
  w_ratr          number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    SELECT max(1)
      INTO w_ratr
      FROM rapporti_tributo ratr
     where ratr.pratica = p_pratica
       AND ratr.cod_fiscale = p_cod_fiscale
       AND ratr.tipo_rapporto = p_tipo_rapp
    ;
    if w_ratr is null then
      INSERT
        INTO RAPPORTI_TRIBUTO
             (PRATICA, COD_FISCALE, TIPO_RAPPORTO)
      VALUES (p_pratica, p_cod_fiscale, p_tipo_rapp)
      ;
      w_result := 0;
    else
      w_result := 0;
    end if;

  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_INSERT_RATR;
------------------------------------------------
FUNCTION UF_UPDATE_OGPR_ACC_ICI
( p_oggetto_pratica  IN     number
, p_tipo_al          IN     number
, p_al               IN     number
, p_detr             IN     number
) return number
/**
  Aggiorna OGGETTI_PRATICA.INDIRIZZO_OCC.
  In caso di successo restituisce 0, altrimenti -1.
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    UPDATE oggetti_pratica
       set indirizzo_occ = lpad(to_char(nvl(p_tipo_al,0)),2, '0' )||
           lpad(to_char(nvl(p_al,0) * 100),6, '0' )||
           lpad(to_char(nvl(p_detr,0) * 100),15, '0' )
     where oggetto_pratica = p_oggetto_pratica
    ;
    w_result := 0;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_UPDATE_OGPR_ACC_ICI;
------------------------------------------------
FUNCTION UF_UPDATE_OGPR
( p_dws             IN     t_dws
, p_num_ogpr        IN     number
, p_oggetto         IN     number
, p_pratica         IN     number
, p_utente          IN     varchar2
, p_flag_update     IN     number
, p_tipo_tributo    IN     varchar2
, p_anno            IN     number
, p_num_ogpr_dic    IN     number
) return number
/**
  Se flag_update != EMILINA vengono inizializzati i dati a seconda del tipo tributo.
  Poi in base al valore di flag update vengono eseguite diverse operazioni.
  Se flag_update = NUOVO viene ricercato l'oggetto pratica di origine. Poi sia per il valore NUOVO
                   che NUOVO_NO_ACC, a seconda del tipo tributo, viene aggiunto l'oggetto pratica.
  Se flag_update = AGGIORNA, a seconda del tipo tributo, viene aggiornato l'oggetto pratica.
  Se flag_update = ELIMINA l'oggetto pratica viene eliminato.
  Se flag_update contiene un valore diverso da quelli sopra viene segnalato un errore.
**/
IS
  --
  w_result              number;
  --
  nSettore              number;
  nNumeroFamiliari      number;
  --
  nValore               number;
  nReddito              number;
  nImpDov               number;
  nImpBas               number;
  nCons                 number;
  nAliq_Prec            number;
  nDetrazione_Prec      number;
  --
  nOgPrDic              number;
  nTributo              number;
  nCat                  number;
  nTari                 number;
  nTipo_Al_Prec         number;
  nAnno                 number;
  nOgprRif              number;
  nTipoOggetto          number;
  nQuantita             number;
  nOggettoPraticaRifAp  number;
  --
  numOrdine             varchar(5);
  --
  sCat                  varchar2(3);
  sClasse               varchar2(2);
  fprovv                varchar2(1);
  fRivVal               varchar2(1);
  sDomFisc              varchar2(1);
  sOccup                varchar2(1);
  sInd_Occ              varchar2(2000);
  sImmStorico           varchar2(1);
  --
  dConcess              date;
  --
--iQuantita             number;
  nSuperficie           number;
  nLarghezza            number;
  nProfondita           number;
  nOgpr_rif_ap          number;
  nAliq_Erar_Prec       number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    --
-- Indirizzo Occ è un campo di oggetti_pratica che è stato utilizzato per le pratiche K
-- ICI per contenere stringati tipo aliquota (2 chr), aliquota (6 chr di cui 2 dec) e
-- detrazione (15 chr di cui 2 dec) a lunghezza fissa con zeri a sinistra che sono
-- relativi all 'anno precedente e vengono utilizzati per il calcolo dell' acconto ICI
-- secondo le nuove disposizioni in vigore dall 'anno 2001.

    IF p_flag_update <> ELIMINA then

      numOrdine := p_dws.ogg.num_ordine;

      IF p_tipo_tributo = 'ICI' then

        nValore := p_dws.ogg.valore;
        sCat := p_dws.ogg.categoria_catasto;
        sClasse := p_dws.ogg.classe_catasto;
        fprovv := p_dws.ogg.flag_provvisorio;
        fRivVal := p_dws.ogg.flag_valore_rivalutato;
        nTipoOggetto := p_dws.ogg.tipo_oggetto;

        if p_dws.data_object = 'd_ogpr_prtr_k_cont_multiagg'  then
            nTipo_Al_Prec := p_dws.ogg.tipo_aliquota_prec;
            nAliq_Prec := p_dws.ogg.aliquota_prec;
            nDetrazione_Prec := p_dws.ogg.detrazione_acconto;
            nAnno := p_dws.ogg.anno_rif;
            sImmStorico := p_dws.ogg.imm_storico;
            nOgpr_rif_ap := p_dws.ogg.oggetto_pratica_rif_ap;
            nAliq_Erar_Prec := p_dws.ogg.aliquota_erar_prec;
            if nAnno > 2000 then
                select lpad(to_char(nvl(nTipo_Al_Prec,0)),2,' 0 ')||
                       lpad(to_char(nAliq_Prec * 100),6,' 0 ')||
                       lpad(to_char(nDetrazione_Prec * 100),15,' 0 ')||
                       lpad(to_char(nAliq_Erar_Prec * 100),6,' 0 ')
                  into sInd_Occ
                  from dual
                ;
--          else

            end if;
        end if;

      ELSIF p_tipo_tributo = 'ICIAP' then

        nReddito := p_dws.ogg.reddito;
        nCons := p_dws.ogg.consistenza;
        nSettore := p_dws.ogg.settore;

      ELSIF p_tipo_tributo in ('ICP', 'TARSU', 'TOSAP') then

        nValore := p_dws.ogg.consistenza;
        nTributo := p_dws.ogg.tributo;
        nCat := p_dws.ogg.categoria;
        nTari := p_dws.ogg.tipo_tariffa;
        sOccup := p_dws.ogg.tipo_occupazione;

        if p_tipo_tributo = 'TOSAP' then
          dConcess := p_dws.ogg.data_concessione;
        else
          dConcess := null;
        end if;

        if p_tipo_tributo in ('ICP', 'TOSAP') then
        --  iQuantita := p_dws.ogg.quantita;
            nQuantita := p_dws.ogg.quantita;
            nSuperficie := p_dws.ogg.superficie;
            nLarghezza := p_dws.ogg.larghezza;
            nProfondita := p_dws.ogg.profondita;
        end if;
        --
        if p_tipo_tributo = 'TARSU' then
            nNumeroFamiliari := p_dws.ogg.numero_familiari;
            nOggettoPraticaRifAp := p_dws.ogg.oggetto_pratica_rif_ap;
        else
            nNumeroFamiliari := null;
        end if;

      ELSIF p_tipo_tributo = 'TASI' then

        nValore := p_dws.ogg.valore;
        sCat := p_dws.ogg.categoria_catasto;
        sClasse := p_dws.ogg.classe_catasto;
        fprovv := p_dws.ogg.flag_provvisorio;
        fRivVal := p_dws.ogg.flag_valore_rivalutato;
        nTipoOggetto := p_dws.ogg.tipo_oggetto;

        if p_dws.data_object = 'd_ogpr_prtr_k_cont_multiagg'  then
          nTipo_Al_Prec := p_dws.ogg.tipo_aliquota_prec;
          nAliq_Prec := p_dws.ogg.aliquota_prec;
          nDetrazione_Prec := nvl(p_dws.ogg.detrazione_acconto,0);
          nAnno  := p_dws.ogg.anno_rif;
          sImmStorico := p_dws.ogg.imm_storico;
          nOgpr_rif_ap := p_dws.ogg.oggetto_pratica_rif_ap;
          nAliq_Erar_Prec := p_dws.ogg.aliquota_erar_prec;
          if nAnno > 2000 then
              select lpad(to_char(nvl(nTipo_Al_Prec,0)),2,' 0 ')||
                     lpad(to_char(nAliq_Prec * 100),6,' 0 ')||
                     lpad(to_char(nDetrazione_Prec * 100),15,' 0 ')||
                     lpad(to_char(nAliq_Erar_Prec * 100),6,' 0 ')
                into sInd_Occ
                from dual
              ;
          else
              sInd_Occ := null;
            end if;
        end if;

      ELSE
        raise_application_error(-20999,'Tipo Tributo non previsto : UF_UPDATE_OGPR');
      END IF;
    END IF;
    --
    IF p_flag_update in (NUOVO, NUOVO_NO_ACC) then
      if p_flag_update = NUOVO then
         nOgPrDic := p_dws.ogg.ogpr_dic;

        -- Loop per ricercare l' oggetto pratica di origine (Normalmente Iscrizione);
        -- l 'oggetto Pratica interessato è quello senza oggetto pratica di riferimento.
        -- Qualora si verificasse il caso in cui non esista più l' oggetto partica indicato
        -- come riferimento, l 'oggetto pratica di riferimento non viene assegnato.
        LOOP
          BEGIN
            select oggetto_pratica_rif
              into nOgprRif
             from oggetti_pratica
            where oggetto_pratica = nOgprDic
            ;
          EXCEPTION
            when NO_DATA_FOUND then
              nOgprDic := null;
            WHEN others THEN
              raise_application_error(SQLCODE,SQLERRM);
          END;
          --
          if nvl(nOgprRif,0) = 0 then
              EXIT;
          end if;
          --
          nOgprDic := nOgprRif;
        END LOOP;
      else
        nOgPrDic := null;
      end if;
      --
      IF p_tipo_tributo in ('ICI', 'TASI') then
         if p_dws.data_object = 'd_ogpr_prtr_k_cont_multiagg'  then
            insert
              into OGGETTI_PRATICA
                   (OGGETTO_PRATICA, OGGETTO, PRATICA, ANNO, VALORE, CATEGORIA_CATASTO, CLASSE_CATASTO,
                   OGGETTO_PRATICA_RIF, FLAG_PROVVISORIO, FLAG_VALORE_RIVALUTATO, UTENTE, INDIRIZZO_OCC,
                   TIPO_OGGETTO, IMM_STORICO, OGGETTO_PRATICA_RIF_AP, NUM_ORDINE )
            values (p_num_ogpr, p_oggetto, p_pratica, p_anno, nValore, sCat, sClasse,
                    nOgPrDic, fProvv, fRivVal, p_utente, sInd_occ,
                    nTipoOggetto, sImmStorico, nOgpr_rif_ap, numOrdine)
            ;
        else
            insert
              into OGGETTI_PRATICA
                   (OGGETTO_PRATICA, OGGETTO, PRATICA, ANNO, VALORE, CATEGORIA_CATASTO, CLASSE_CATASTO,
                    OGGETTO_PRATICA_RIF, FLAG_PROVVISORIO, FLAG_VALORE_RIVALUTATO, UTENTE, TIPO_OGGETTO, NUM_ORDINE)
            values (p_num_ogpr, p_oggetto, p_pratica, p_anno, nValore, sCat, sClasse,
                    nOgPrDic, fProvv, fRivVal, p_utente, nTipoOggetto, numOrdine)
            ;
        end if;

      ELSIF p_tipo_tributo = 'ICIAP' then
        if nOgPrDic is null Then
            insert
              into OGGETTI_PRATICA
                   (OGGETTO_PRATICA, OGGETTO, PRATICA, ANNO, SETTORE, CONSISTENZA, FLAG_UIP_PRINCIPALE,
                    REDDITO, OGGETTO_PRATICA_RIF, FLAG_PROVVISORIO, UTENTE )
            values (p_num_ogpr, p_oggetto, p_pratica, p_anno, nSettore, nCons, 'S',
                    nReddito, nOgPrDic, fProvv, p_utente)
            ;
        else
            insert
              into OGGETTI_PRATICA
                   (OGGETTO_PRATICA, OGGETTO, PRATICA, ANNO, SETTORE, CONSISTENZA, FLAG_UIP_PRINCIPALE,
                    REDDITO, FLAG_DOMICILIO_FISCALE, OGGETTO_PRATICA_RIF, FLAG_PROVVISORIO, UTENTE )
             select p_num_ogpr, oggetto, p_pratica, p_anno, nSettore, nCons, flag_uip_principale,
                    nReddito, flag_domicilio_fiscale, nOgPrDic, fProvv, p_utente
               from OGGETTI_PRATICA
              where oggetto_pratica = nOgPrDic
            ;
        end if;

      ELSIF p_tipo_tributo = 'ICP' then
     -- if iQuantita = 0 Then
          insert
            into OGGETTI_PRATICA
                 (OGGETTO_PRATICA, OGGETTO, PRATICA, CONSISTENZA, TRIBUTO, CATEGORIA, ANNO,
                  TIPO_TARIFFA, TIPO_OCCUPAZIONE, DATA_CONCESSIONE, OGGETTO_PRATICA_RIF,
                  LARGHEZZA, PROFONDITA, CONSISTENZA_REALE, QUANTITA, OGGETTO_PRATICA_RIF_V, UTENTE)
          values (p_num_ogpr, p_oggetto, p_pratica, nValore, ntributo, nCat, p_anno,
                  nTari, sOccup, dConcess, nOgPrDic,
                  nLarghezza, nprofondita, nSuperficie, nQuantita, p_num_ogpr_dic, p_utente)
          ;
     -- else
        -- insert
        --   into OGGETTI_PRATICA
        --        (OGGETTO_PRATICA, OGGETTO, PRATICA, CONSISTENZA, TRIBUTO, CATEGORIA, ANNO,
        --         TIPO_TARIFFA, TIPO_OCCUPAZIONE, DATA_CONCESSIONE, OGGETTO_PRATICA_RIF,
        --         OGGETTO_PRATICA_RIF_V, UTENTE )
        -- values (p_num_ogpr, p_oggetto, p_pratica, nValore, ntributo, nCat, p_anno,
        --         nTari, sOccup, dConcess, nOgPrDic, p_num_ogpr_dic, p_utente)
        -- ;
     -- end if;

      ELSIF p_tipo_tributo = 'TOSAP' then
        insert
          into OGGETTI_PRATICA
               (OGGETTO_PRATICA, OGGETTO, PRATICA, CONSISTENZA, TRIBUTO, CATEGORIA, ANNO,
                TIPO_TARIFFA, TIPO_OCCUPAZIONE, DATA_CONCESSIONE, OGGETTO_PRATICA_RIF,
                LARGHEZZA, PROFONDITA, CONSISTENZA_REALE, QUANTITA, OGGETTO_PRATICA_RIF_V, UTENTE)
        values (p_num_ogpr, p_oggetto, p_pratica, nValore, ntributo, nCat, p_anno,
                nTari, sOccup, dConcess, nOgPrDic,
                nLarghezza, nProfondita, nSuperficie, nQuantita, p_num_ogpr_dic, p_utente)
        ;

      ELSIF p_tipo_tributo = 'TARSU' then
        insert
          into OGGETTI_PRATICA
               (OGGETTO_PRATICA, OGGETTO, PRATICA, CONSISTENZA, TRIBUTO, CATEGORIA, ANNO,
                TIPO_TARIFFA, TIPO_OCCUPAZIONE, DATA_CONCESSIONE, OGGETTO_PRATICA_RIF,
                NUMERO_FAMILIARI, OGGETTO_PRATICA_RIF_V, OGGETTO_PRATICA_RIF_AP, UTENTE, NUM_ORDINE)
        values (p_num_ogpr, p_oggetto, p_pratica, nValore, ntributo, nCat, p_anno,
                nTari, sOccup, dConcess, nOgPrDic,
                nNumeroFamiliari, p_num_ogpr_dic, nOggettoPraticaRifAp, p_utente, numOrdine)
        ;
      END IF;
      --
      w_result := 0;

    ELSIF p_flag_update = AGGIORNA then
      IF p_tipo_tributo in ('ICI', 'TASI') then

        if p_dws.data_object = 'd_ogpr_prtr_k_cont_multiagg'  then
          update OGGETTI_PRATICA
             set VALORE = nValore,
                 CATEGORIA_CATASTO = sCat,
                 CLASSE_CATASTO = sClasse,
                 FLAG_PROVVISORIO = fprovv,
                 FLAG_VALORE_RIVALUTATO = fRivVal,
                 UTENTE = p_utente,
                 TIPO_OGGETTO = nTipoOggetto,
                 IMM_STORICO = sImmStorico,
                 OGGETTO_PRATICA_RIF_AP = nOgpr_rif_ap,
                 INDIRIZZO_OCC = sInd_Occ
           where OGGETTO_PRATICA = p_num_ogpr
          ;
        else
          update OGGETTI_PRATICA
             set VALORE = nValore,
                 CATEGORIA_CATASTO = sCat,
                 CLASSE_CATASTO = sClasse,
                 FLAG_PROVVISORIO = fprovv,
                 FLAG_VALORE_RIVALUTATO = fRivVal,
                 UTENTE = p_utente,
                 TIPO_OGGETTO = nTipoOggetto
           where OGGETTO_PRATICA = p_num_ogpr
           ;
        end if;

      ELSIF p_tipo_tributo = 'ICIAP' then
        nImpBas := p_dws.ogg.imposta_base;
        nImpDov := p_dws.ogg.imposta_dovuta;
        sDomFisc := p_dws.ogg.flag_domicilio_fiscale;

        update OGGETTI_PRATICA
           set REDDITO = nReddito,
               CONSISTENZA = nCons,
               SETTORE = nSettore,
               IMPOSTA_BASE = nImpBas,
               IMPOSTA_DOVUTA = nImpDov,
               FLAG_DOMICILIO_FISCALE = sDomFisc,
               UTENTE = p_utente
         where OGGETTO_PRATICA = p_num_ogpr
        ;

      ELSIF p_tipo_tributo = 'ICP' then
        update OGGETTI_PRATICA
           set CONSISTENZA = nValore,
               CONSISTENZA_REALE = nSuperficie,
               QUANTITA = nQuantita,
               LARGHEZZA = nLarghezza,
               PROFONDITA = nProfondita,
               TRIBUTO = ntributo,
               CATEGORIA = nCat,
               TIPO_TARIFFA = nTari,
               TIPO_OCCUPAZIONE = sOccup,
               DATA_CONCESSIONE = dConcess,
               UTENTE = p_utente
         where OGGETTO_PRATICA = p_num_ogpr
        ;

      ELSIF p_tipo_tributo = 'TOSAP' then
        update OGGETTI_PRATICA
           set CONSISTENZA = nValore,
               CONSISTENZA_REALE = nSuperficie,
               QUANTITA = nQuantita,
               LARGHEZZA = nLarghezza,
               PROFONDITA = nProfondita,
               TRIBUTO = ntributo,
               CATEGORIA = nCat,
               TIPO_TARIFFA = nTari,
               TIPO_OCCUPAZIONE = sOccup,
               DATA_CONCESSIONE = dConcess,
               UTENTE = p_utente
         where OGGETTO_PRATICA = p_num_ogpr
        ;

      ELSIF p_tipo_tributo = 'TARSU' then
        update OGGETTI_PRATICA
           set CONSISTENZA = nValore,
               TRIBUTO = ntributo,
               CATEGORIA = nCat,
               TIPO_TARIFFA = nTari,
               TIPO_OCCUPAZIONE = sOccup,
               DATA_CONCESSIONE = dConcess,
               NUMERO_FAMILIARI = nNumeroFamiliari,
               OGGETTO_PRATICA_RIF_AP = nOggettoPraticaRifAp,
               UTENTE = p_utente
         where OGGETTO_PRATICA = p_num_ogpr
        ;
      END IF;
      --
      w_result := 0;

    ELSIF p_flag_update = ELIMINA then
      delete OGGETTI_PRATICA
       where OGGETTO_PRATICA = p_num_ogpr
      ;
      w_result := 0;

    ELSE
      raise_application_error(-20999,'Tipo di aggiornamento non previsto : UF_UPDATE_OGPR');
    END IF;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_UPDATE_OGPR;
------------------------------------------------
FUNCTION UF_UPDATE_OGCO
( p_dws             IN     t_dws
, p_num_ogpr        IN     number
, p_cod_fiscale     IN     varchar2
, p_anno            IN     number
, p_tipo_rapp       IN     varchar2
, p_utente          IN     varchar2
, p_flag_update     IN     number
, p_tipo_tributo    IN     varchar2
) return number
/**
  Init dati:
    Se il tipo tributo è ICI vengono ottenuti dei dati, altri vengono anullati e viene gestito il campo da_mese_possesso
    Se il tipo tributo è ICIAP viene settato tutto a null
    Se il tipo tributo è ICP o TARI vengono ottenuti dei dati, altri vengono anullati
    Se il tipo tributo è TASI vengono ottenuti dei dati e sono gestiti da_mese_possesso, ogco_tipo_rapporto_k,
                              tipo_rapporto, mesi_occupato e mesi_occupato_1sem.
  Azioni:
    Se flag_update = NUOVO, NUOVO_NO_ACC viene creato l'oggetto contribuente
    Se flag_update = AGGIORNA viene aggiornato
    In caso di successo restituisce 0 altrimenti -1
    Altrimenti restituisce un errore
**/
IS
  --
  w_result         number;
  --
  mp               number;
  mp1s             number;
  damp             number;
  me               number;
  mr               number;
  ma               number;
  mesi_occ         number;
  mesi_occ_1s      number;
  --
  fp               varchar2(1);
  fe               varchar2(1);
  fr               varchar2(1);
  f_ap             varchar2(1);
  f_ar             varchar2(1);
  sTipoRapportoK   varchar2(1);
  seAgg_pers_detr  varchar2(1);
  --
  dInizio          date;
  dFine            date;
  dDecorrenza      date;
  dCessazione      date;
  --
  perc_poss        number;
  perc_detrazione  number;
  detr             number;
  --
  snomedw          varchar(40);
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    --
    seAgg_pers_detr := 'N';
    --
    IF p_tipo_tributo = 'ICI' then
        perc_poss := p_dws.ogg.perc_possesso;
        mp := p_dws.ogg.mesi_possesso;
        mp1S := p_dws.ogg.mesi_possesso_1sem;
        me := p_dws.ogg.mesi_esclusione;
        mr := p_dws.ogg.mesi_riduzione;
        ma := p_dws.ogg.mesi_aliquota_ridot;
        detr := p_dws.ogg.detrazione;
        perc_detrazione := null;
        mesi_occ := null;
        mesi_occ_1S := null;
        fp := p_dws.ogg.flag_possesso;
        fe := p_dws.ogg.flag_esclusione;
        fr := p_dws.ogg.flag_riduzione;
        f_ap := p_dws.ogg.flag_ab_principale;
        f_ar := p_dws.ogg.flag_al_ridotta;
        dInizio := null;
        dFine := null;
        dDecorrenza := null;
        dCessazione := null;
        -- (VD - 07/06/2019): il campo da_mese_possesso è significativo solo nelle denunce
        -- (VD - 01/09/2021): aggiunta gestione campo da_mese_possesso per i ravvedimenti
        -- (RV - 29/08/2024): aggiunto gestione campo da_mese_possesso per gli accertamenti
        IF p_dws.data_object = 'd_ogim_acc' or
            p_dws.data_object = 'd_ogco_deic_dic_monoagg' OR
            p_dws.data_object = 'd_ogpr_prtr_cont_multiagg' THEN
            damp := p_dws.ogg.da_mese_possesso;
        ELSE
            damp := null;
        END IF;

    ELSIF p_tipo_tributo = 'ICIAP' then
        dInizio := null;
        dFine := null;
        perc_poss := null;
        mp := null;
        mp1S := null;
        damp := null;
        me := null;
        mr := null;
        ma := null;
        detr := null;
        perc_detrazione := null;
        mesi_occ := null;
        mesi_occ_1S := null;
        fp := null;
        fe := null;
        fr := null;
        f_ap := null;
        f_ar := null;

    ELSIF p_tipo_tributo = 'ICP' then
        dInizio := p_dws.ogg.inizio_occupazione;
        dFine := p_dws.ogg.fine_occupazione;
        dDecorrenza := dInizio;
        dCessazione := dFine;
        perc_poss := null;
        mp := null;
        mp1S := null;
        damp := null;
        me := null;
        mr := null;
        ma := null;
        detr := null;
        perc_detrazione := null;
        mesi_occ := null;
        mesi_occ_1S := null;
        fp := null;
        fe := null;
        fr := null;
        f_ap := null;
        f_ar := null;

    ELSIF p_tipo_tributo = 'TARSU' then
        dInizio := p_dws.ogg.inizio_occupazione;
        dFine := p_dws.ogg.fine_occupazione;
        dDecorrenza := p_dws.ogg.data_decorrenza;
        dCessazione := p_dws.ogg.data_cessazione;
        perc_poss := p_dws.ogg.perc_possesso;
        mp := null;
        mp1S := null;
        damp := null;
        me := null;
        mr := null;
        ma := null;
        detr := null;
        perc_detrazione := null;
        mesi_occ := null;
        mesi_occ_1S := null;
        fp := null;
        fe := null;
        fr := null;
        f_ap := p_dws.ogg.flag_ab_principale;
        f_ar := null;

    ELSIF p_tipo_tributo = 'TASI' then
        perc_poss := p_dws.ogg.perc_possesso;
        mp := p_dws.ogg.mesi_possesso;
        mp1S := p_dws.ogg.mesi_possesso_1sem;
        me := p_dws.ogg.mesi_esclusione;
        mr := p_dws.ogg.mesi_riduzione;
        ma := p_dws.ogg.mesi_aliquota_ridot;
        detr := p_dws.ogg.detrazione;
        IF p_dws.data_object = 'd_ogco_desi_dic_monoagg' THEN
          -- (VD - 07/06/2019): il campo da_mese_possesso è significativo solo nelle denunce
          perc_detrazione := p_dws.ogg.perc_detrazione;
          damp := p_dws.ogg.da_mese_possesso;
        ELSE
          perc_detrazione := null;
          damp := null;
        END IF;
        --
        IF p_dws.data_object = 'd_ogco_desi_dic_monoagg' or
            p_dws.data_object = 'd_ogim_acc_tasi_cont_monoagg' or
            p_dws.data_object = 'd_ogpr_prtr_cont_tasi_multiagg' THEN
          -- (VD - 22/08/2019) Questi campi per ora sono gestiti solo dalla denuncia tasi e dall'accertamento tasi
          -- (VD - 26/03/2020) ora anche dal ravvedimento operoso tasi
          mesi_occ := p_dws.ogg.mesi_occupato;
          mesi_occ_1S := p_dws.ogg.mesi_occupato_1sem;
          seAgg_pers_detr := 'S';
        ELSE
          mesi_occ := null;
          mesi_occ_1S := null;
        END IF;
        --
        fp := p_dws.ogg.flag_possesso;
        fe := p_dws.ogg.flag_esclusione;
        fr := p_dws.ogg.flag_riduzione;
        f_ap := p_dws.ogg.flag_ab_principale;
        f_ar := p_dws.ogg.flag_al_ridotta;
        --
        IF p_dws.data_object = 'd_ogpr_prtr_k_cont_multiagg' THEN
          sTipoRapportoK := p_dws.ogg.ogco_tipo_rapporto_k;
        END IF;
        IF p_dws.data_object = 'd_ogpr_prtr_cont_tasi_multiagg' THEN
          sTipoRapportoK := p_dws.ogg.tipo_rapporto;
        END IF;
        --
        dInizio := null;
        dFine := null;
        dDecorrenza := null;
        dCessazione := null;

    ELSIF p_tipo_tributo = 'TOSAP' then
        dInizio := p_dws.ogg.inizio_occupazione;
        dFine := p_dws.ogg.fine_occupazione;
        perc_poss := p_dws.ogg.perc_possesso;
        dDecorrenza := dInizio;
        dCessazione := dFine;
        mp := null;
        mp1S := null;
        damp := null;
        me := null;
        mr := null;
        ma := null;
        detr := null;
        perc_detrazione := null;
        mesi_occ := null;
        mesi_occ_1S := null;
        fp := null;
        fe := null;
        fr := null;
        f_ap := null;
        f_ar := null;

    ELSE
        raise_application_error(-20999,'Tipo Tributo non previsto : UF_UPDATE_OGCO');
    END IF;
    --
    IF p_tipo_tributo in ('ICP', 'TARSU', 'TOSAP', 'ICIAP') then
        snomedw := p_dws.data_object;
        snomedw := lower(substr(snomedw,1,10));

        IF snomedw = 'd_ogim_acc' THEN
            IF p_dws.replica = TRUE THEN
                dDecorrenza := TO_DATE('01/01/'||p_anno,'dd/mm/YYYY');
                dCessazione := null;
                --
                IF dFine is not null THEN
                    IF EXTRACT(YEAR FROM dFine) < p_anno THEN
                        dFine := null;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
    --
    IF p_flag_update in (NUOVO, NUOVO_NO_ACC) then
      INSERT
        INTO OGGETTI_CONTRIBUENTE
              (COD_FISCALE, OGGETTO_PRATICA, ANNO, TIPO_RAPPORTO,
              INIZIO_OCCUPAZIONE, FINE_OCCUPAZIONE, DATA_DECORRENZA, DATA_CESSAZIONE,
              PERC_POSSESSO, MESI_POSSESSO, MESI_POSSESSO_1SEM, MESI_ESCLUSIONE,
              MESI_RIDUZIONE, MESI_ALIQUOTA_RIDOTTA, DETRAZIONE, PERC_DETRAZIONE,
              FLAG_POSSESSO, FLAG_ESCLUSIONE, FLAG_RIDUZIONE, FLAG_AB_PRINCIPALE,
              FLAG_AL_RIDOTTA, UTENTE, TIPO_RAPPORTO_K, MESI_OCCUPATO, MESI_OCCUPATO_1SEM,
              DA_MESE_POSSESSO)
       VALUES (p_cod_fiscale, p_num_ogpr, p_anno, p_tipo_rapp, dInizio, dFine, dDecorrenza,
              dCessazione, perc_poss, mp, mp1s, me, mr, ma, detr, perc_detrazione,
              fp, fe, fr, f_ap, f_ar, p_utente, sTipoRapportoK, mesi_occ, mesi_occ_1s,
              damp)
       ;
    ELSIF p_flag_update = AGGIORNA then
      UPDATE OGGETTI_CONTRIBUENTE
         SET INIZIO_OCCUPAZIONE = dInizio,
             FINE_OCCUPAZIONE = dFine,
             DATA_DECORRENZA = dDecorrenza,
             DATA_CESSAZIONE = dCessazione,
             PERC_POSSESSO = perc_poss,
             MESI_POSSESSO = mp,
             MESI_POSSESSO_1SEM = mp1s,
             MESI_ESCLUSIONE = me,
             MESI_RIDUZIONE = mr,
             MESI_ALIQUOTA_RIDOTTA = ma,
             DETRAZIONE = detr,
             PERC_DETRAZIONE = decode(seAgg_pers_detr, 'S', perc_detrazione, perc_detrazione),
             FLAG_POSSESSO = fp,
             FLAG_ESCLUSIONE = fe,
             FLAG_RIDUZIONE = fr,
             FLAG_AB_PRINCIPALE = f_ap,
             FLAG_AL_RIDOTTA = f_ar,
             UTENTE = p_utente,
             TIPO_RAPPORTO_K = sTipoRapportoK,
             MESI_OCCUPATO = decode(seAgg_pers_detr, 'S', mesi_occ, mesi_occupato),
             MESI_OCCUPATO_1SEM = decode(seAgg_pers_detr, 'S', mesi_occ_1s, mesi_occupato_1sem),
             DA_MESE_POSSESSO = damp
       where COD_FISCALE = p_cod_fiscale
         AND OGGETTO_PRATICA = p_num_ogpr
      ;
    ELSE
      raise_application_error(-20999,'Tipo di aggiornamento non previsto : UF_UPDATE_OGCO');
    END IF;
    --
    w_result := 0;
    --
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_UPDATE_OGCO;
------------------------------------------------
FUNCTION UF_RIV_RENDITA
( p_anno          IN     number
, p_tipo_oggetto  IN     number
) return number
/**
  Ritorna l'aliquota da rivalutazioni_vendita a seconda dell'anno e del tipo oggetto.
  Altrimenti in caso di problemi restituisce direttamente l'errore
**/
IS
  --
  w_naliq         number;
  --
BEGIN
  --
  w_naliq := null;
  --
  BEGIN
    SELECT aliquota
      INTO w_naliq
      FROM rivalutazioni_rendita
     where anno = p_anno
       AND tipo_oggetto = p_tipo_oggetto
    ;
  EXCEPTION
    WHEN others THEN
       raise_application_error(-20999,'Rivalutazione Aliquota non trovata per Anno '||p_anno||
                                                              ', Tipo Oggetto '||p_tipo_oggetto);
  END;
  --
  return w_naliq;
  --
END UF_RIV_RENDITA;
------------------------------------------------
FUNCTION UF_SE_ACCERTAMENTI_A_RUOLO
( p_cod_fiscale   IN     varchar2
, p_num_ogpr      IN     number
, p_anno          IN     number
) return varchar2
/**
  Conta quanti oggetti imposta ci sono relativi al ruolo dell'oggetto, al codice fiscale,
  all'oggetto pratica e all'invio consorzio che deve non essere nullo.
  Se il numero è > 0 oppure l'oggetto pratica è nullo restituisce 'SI', altrimenti 'NO'
**/
IS
  --
  w_result         varchar2(2);
  --
  w_count          number;
  --
BEGIN
  --
  IF p_num_ogpr is null THEN
     w_result := 'SI';
  ELSE
      SELECT count(*)
        INTO w_count
        FROM ruoli ruol,
             oggetti_imposta ogim
       where ruol.ruolo = ogim.ruolo
         AND ruol.anno_ruolo = p_anno
         AND ruol.invio_consorzio IS NOT null
         AND ogim.cod_fiscale = p_cod_fiscale
         AND ogim.oggetto_pratica = p_num_ogpr
      ;
      --
      IF w_count > 0 THEN
        w_result := 'SI';
      ELSE
         w_result := 'NO';
      END IF;
  END IF;
  --
  return w_result;
  --
END UF_SE_ACCERTAMENTI_A_RUOLO;
------------------------------------------------
FUNCTION UF_EXISTS_CLASU
( p_anno          IN     number
, p_settore       IN     number
) return number
/**
  Controlla se esistono classi_superficie per un certo anno e settore.
  In caso di errori restituisce -1.
  Se non sono stati trovati restituisce 0, altrimenti 1.
**/
IS
  --
  w_result         number;
  --
  w_clsu           number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    SELECT max(1)
      INTO w_clsu
      FROM classi_superficie
     where anno = p_anno
       AND settore = p_settore
    ;
    w_result := 1;
  EXCEPTION
    when NO_DATA_FOUND then
      w_result := 0;
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_EXISTS_CLASU;
------------------------------------------------
FUNCTION UF_EXISTS_SCARE
( p_anno          IN     number
) return number
/**
  Manca codice PowerBuilder ?????????????????????
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN

  w_result := -3;
--    w_result := 1;
  EXCEPTION
    when NO_DATA_FOUND then
      w_result := 0;
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_EXISTS_SCARE;
------------------------------------------------
FUNCTION UF_PRENDI_IMPOSTA_DENUNCIA
( p_cod_fiscale   IN    varchar2
, p_anno          IN    number
, p_num_ogpr      IN    number
) return number
/**
  Restituisce l'imposta di un oggetto imposta in base al codice fiscale, all'anno e all'oggetto pratica.
  In caso di errore restituisce null, altrimenti l'imposta.
**/
IS
  --
  w_imposta         number;
  --
BEGIN
  --
  w_imposta := null;
  --
  BEGIN
    SELECT max(imposta)
      INTO w_imposta
      FROM oggetti_imposta
     where cod_fiscale = p_cod_fiscale
      AND anno = p_anno
      AND oggetto_pratica = p_num_ogpr
      ;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_imposta;
  --
END UF_PRENDI_IMPOSTA_DENUNCIA;
------------------------------------------------
FUNCTION UF_EXISTS_OGIM
( p_cod_fiscale    IN     varchar2
, p_anno           IN     number
, p_num_ogpr       IN     number
) return number
/**
  Verifica esistenza OGIM
**/
IS
  --
  w_result         number;
  --
  lConta           number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    select count(*)
      into lConta
      from oggetti_imposta
     where cod_fiscale       = p_cod_fiscale
       and anno              = p_anno
        and oggetto_pratica  = p_num_ogpr
    ;
    w_result := lConta;

  EXCEPTION
    WHEN others THEN
     raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_EXISTS_OGIM;
------------------------------------------------
FUNCTION UF_INSERT_OGIM
( p_num_ogpr        IN     number
, p_cod_fiscale     IN     varchar2
, p_anno            IN     number
, p_imposta         IN     number
, p_imposta_acc     IN     number
, p_imposta_dovuta  IN     number
, p_imposta_dovuta_acc  IN number
, p_detrazione      IN     number
, p_detrazione_acc  IN     number
, p_utente          IN     varchar2
, p_flag_calcolo    IN     varchar2
, p_note            IN     varchar2
, p_tipo_tributo    IN     varchar2
, p_magg_tares      IN     number
, p_dettaglio_ogim  IN     number
, p_add_eca         IN     number
, p_magg_eca        IN     number
, p_add_prov        IN     number
, p_iva             IN     number
) return number
/**
  Inserisce OGIM
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    insert
      into OGGETTI_IMPOSTA
           (COD_FISCALE, OGGETTO_PRATICA, ANNO, IMPOSTA, IMPOSTA_ACCONTO,
            IMPOSTA_DOVUTA, IMPOSTA_DOVUTA_ACCONTO, DETRAZIONE, DETRAZIONE_ACCONTO,
            FLAG_CALCOLO, UTENTE, NOTE, tipo_tributo, MAGGIORAZIONE_TARES, DETTAGLIO_OGIM,
            ADDIZIONALE_ECA, MAGGIORAZIONE_ECA, ADDIZIONALE_PRO, IVA)
    values (p_cod_fiscale, p_num_ogpr, p_anno, p_imposta, p_imposta_acc,
            p_imposta_dovuta, p_imposta_dovuta_acc,
            p_detrazione, p_detrazione_acc, p_flag_calcolo, p_utente, p_note, p_tipo_tributo,
            p_magg_tares, p_dettaglio_ogim, p_add_eca, p_magg_eca, p_add_prov, p_iva)
    ;
    w_result := 0;

  EXCEPTION
    WHEN others THEN
     raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_INSERT_OGIM;
------------------------------------------------
FUNCTION UF_UPDATE_OGIM
( p_tipo_tributo          IN  varchar2
, p_ogim_new              IN  number
, p_ogim_old              IN  number
, p_num_ogpr              IN  number
, p_anno                  IN  number
, p_imposta               IN  number
, p_imp_dov               IN  number
, p_imp_acc               IN  number
, p_utente                IN  varchar2
, p_magg_tares            IN  number
, p_dettaglio_ogim        IN  varchar2
, p_add_eca               IN  number
, p_magg_eca              IN  number
, p_add_prov              IN  number
, p_iva                   IN  number
) return number
/**
  In base al tipo tributo che sia ICI oppure no, aggiorna un oggetto imposta.
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    IF p_tipo_tributo = 'ICI' THEN
        INSERT INTO OGGETTI_IMPOSTA
              (OGGETTO_IMPOSTA, COD_FISCALE,ANNO, OGGETTO_PRATICA,IMPOSTA, IMPOSTA_ACCONTO,
              IMPOSTA_DOVUTA, IMPOSTA_DOVUTA_ACCONTO, IMPORTO_VERSATO, TIPO_ALIQUOTA,
              ALIQUOTA, RUOLO,IMPORTO_RUOLO, FLAG_CALCOLO, UTENTE, NOTE )
              SELECT p_ogim_new, ogim.COD_FISCALE, p_anno, p_num_ogpr, p_imposta, ogim.IMPOSTA_ACCONTO,
                     p_imp_dov, p_imp_acc, ogim.IMPORTO_VERSATO, ogim.TIPO_ALIQUOTA,
                     aliq.ALIQUOTA, ogim.RUOLO,ogim.IMPORTO_RUOLO, ogim.FLAG_CALCOLO, p_utente,
                     ogim.NOTE
                FROM ALIQUOTE ALIQ,OGGETTI_IMPOSTA OGIM
               where ogim.oggetto_imposta = p_ogim_old
                 AND aliq.TIPO_ALIQUOTA (+) = ogim.TIPO_ALIQUOTA
                 AND aliq.ANNO (+) = p_anno
                 AND aliq.tipo_tributo (+) = p_tipo_tributo;
    ELSE
        INSERT INTO OGGETTI_IMPOSTA
              (OGGETTO_IMPOSTA, COD_FISCALE,ANNO, OGGETTO_PRATICA,IMPOSTA, IMPOSTA_ACCONTO,
              IMPOSTA_DOVUTA, IMPOSTA_DOVUTA_ACCONTO, IMPORTO_VERSATO, TIPO_ALIQUOTA,
              ALIQUOTA, RUOLO,IMPORTO_RUOLO, FLAG_CALCOLO, UTENTE, NOTE, MAGGIORAZIONE_TARES, DETTAGLIO_OGIM,
              ADDIZIONALE_ECA, MAGGIORAZIONE_ECA, ADDIZIONALE_PRO, IVA)
              SELECT p_ogim_new, COD_FISCALE, p_anno, p_num_ogpr, p_imposta, IMPOSTA_ACCONTO,
                     p_imp_dov, p_imp_acc, IMPORTO_VERSATO, TIPO_ALIQUOTA,
                     ALIQUOTA, RUOLO,IMPORTO_RUOLO, FLAG_CALCOLO, p_utente, NOTE,
                     p_magg_tares, p_dettaglio_ogim,
                     p_add_eca, p_magg_eca, p_add_prov, p_iva
               FROM OGGETTI_IMPOSTA
              where oggetto_imposta = p_ogim_old;
    END IF;
    w_result := 0;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_UPDATE_OGIM;
------------------------------------------------
FUNCTION UF_INSERT_FAOG_FROM_STRING
( p_num_ogim             IN     number
, p_stringa_familiari    IN OUT varchar2
, p_dettaglio_ogim       IN OUT varchar2
, p_dettaglio_ogim_base  IN OUT varchar2
) return number
/**
  Descrizione dal codice :
    Si inseriscono le righe in familiari_ogim per oggetto_imposta = p_ogim.
      p_stringa è fatta di blocchi da 20 caratteri:
        4 caratteri per il numero di familiari
        8 caratteri per la data decorrenza
        8 caratteri per la data cessazione.
  Ogni 20 caratteri si inserisce una riga in familiari_ogim, se il numero di familiari è lo stesso della
  riga precedente e i periodi sono consecutivi si puo' inserire una riga sola con le date opportune.
**/
IS
  --
  w_result              number;
  --
  sDal                  varchar2(8);
  sAl                   varchar2(8);
--sDalold               varchar2(8);
  --
  sBlocco               varchar2(20);
  sDettaglio_faog       varchar2(150);
  sDettaglio_faog_base  varchar2(170);
  --
  i                     number;
  nBlocchi              number;
  nBlocchiOgim          number;
  nResto                number;
  --
  nFamiliari            number;
--nFamiliariOld         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    --
    IF length(p_stringa_familiari) < 20 THEN
        w_result := 0;
        return w_result;
    END IF;
    --
    nResto := mod(length(p_stringa_familiari), 20);
    --
    IF nResto = 0 THEN
        nBlocchi := length(p_stringa_familiari) / 20;
    ELSE
        w_result := 0;
        return w_result;
    END IF;
    --
    -- Controllo che stringa e dettaglio ogim prevedano lo stesso numero di blocchi
    --
    nBlocchiOgim := length(p_dettaglio_ogim) / 150;
    --
    IF nBlocchi <> nBlocchiOgim THEN
        w_result := 0;
        return w_result;
    END IF;
    --
    DELETE familiari_ogim
     where oggetto_imposta = p_num_ogim
    ;
    --
  --nFamiliariOld := 0;
  --sDalOld := '01011900';
    --
    FOR i IN 1..nBlocchi
    LOOP
        sBlocco := substr(p_stringa_familiari, 1 + ((i - 1)*20), 20 * i);
        nFamiliari := to_number(substr(sBlocco,1,4));
        sDal := substr(sBlocco,5,8);
        sAl := substr(sBlocco,13,8);
        --
        sDettaglio_faog := substr(p_dettaglio_ogim, 1+((i - 1)*150), 150*i);
        sDettaglio_faog := '*' || substr(sDettaglio_faog,2,149);
        sDettaglio_faog_base := substr(p_dettaglio_ogim_base, 1+((i - 1)*170), 170*i);
        sDettaglio_faog_base := '*' || substr(sDettaglio_faog_base,2,169);
        --
        -- Tolto test: bisognerebbe controllare anche altri dati (che sono sul dettaglio faog)
        --             per attaccare insieme i familiari
        --
    --  if nFamiliariOld = nFamiliari then
    --    update familiari_ogim
    --       set al = to_date(sAl, 'ddmmyyyy' )
    --    where oggetto_imposta = p_ogim
    --    ;
    --  else
          INSERT INTO familiari_ogim
                 (oggetto_imposta, numero_familiari, dal, al, data_variazione, dettaglio_faog, dettaglio_faog_base)
          VALUES (p_num_ogim, nFamiliari, to_date(sDal,'ddmmyyyy'), to_date(sAl,'ddmmyyyy'),
                  trunc(sysdate), sDettaglio_faog, sDettaglio_faog_base)
          ;
          --
    --    nFamiliariOld := nFamiliari;
    --    sDalOld := sDal;
    --  end if;
    END LOOP;
    --
    p_dettaglio_ogim := '';
    p_dettaglio_ogim_base := '';
    --
    w_result := 1;
--  EXCEPTION
--    WHEN others THEN
--       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_INSERT_FAOG_FROM_STRING;
------------------------------------------------
FUNCTION UF_MAX_SCAD_TITR_ANNO
( p_tipo_tributo   IN     varchar2
, p_data           IN     date
, p_conc           IN     varchar2
) return date
/**
  Se il parametro p_conc = 'N' seleziona la data di scadenza dalle scadenze per un certo tipo tributo e data.
  Altrimenti aggiunge 1 mese al parametro data in ingresso.
  Se non ci sono stati problemi restituisce la data, altrimenti null.
**/
IS
  --
  w_data_scad      date;
  --
BEGIN
  --
  w_data_scad := null;
  --
  BEGIN
    IF p_conc = 'N' THEN
      SELECT distinct scad.data_scadenza
        INTO w_data_scad
        FROM scadenze scad
       where scad.tipo_tributo = p_tipo_tributo
         AND scad.tipo_scadenza = 'V'
         AND scad.rata IS NOT null
         AND scad.data_scadenza =
              (select min(sca2.data_scadenza)
                FROM scadenze sca2
                where sca2.tipo_tributo = p_tipo_tributo
                AND sca2.tipo_scadenza = 'V'
                AND sca2.rata IS NOT null
                AND sca2.data_scadenza >= p_data)
      ;
    ELSE
      SELECT add_months(p_data,1)
        INTO w_data_scad
      FROM dual
      ;
    END IF;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_data_scad;
  --
END UF_MAX_SCAD_TITR_ANNO;
------------------------------------------------
FUNCTION UF_DELETE_SAPR
( p_pratica        IN     number
, p_tipo_sanz      IN     number
) return number
/**
  In base al tipo_operazione cancella le sanzioni_pratica in base alla pratica e al cod_sanzione < 100 (NUOVO_SANZ),
  cancella le sanzioni_pratica in base alla pratica e al cod_sanzione > 100 (VECCHIO_SANZ)
  oppure cancella le sanzioni_pratica legate alla pratica.
  In caso di errore restituisce -1 altrimenti 0.
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := -1;
  --
  BEGIN
    CASE p_tipo_sanz
      WHEN NUOVO_SANZ then
        DELETE FROM sanzioni_pratica
         where pratica = p_pratica
        AND cod_sanzione < 100
        ;
      WHEN VECCHIO_SANZ then
        DELETE FROM sanzioni_pratica
         where pratica = p_pratica
           AND cod_sanzione > 100
        ;
      WHEN TUTTE then
        DELETE FROM sanzioni_pratica
         where pratica = p_pratica
        ;
    ELSE
      raise_application_error(-20999,'Tipo Operazione non riconosciuto : UF_DELETE_SAPR');
    END CASE;
    w_result := 0;
  EXCEPTION
    WHEN others THEN
       raise_application_error(SQLCODE,SQLERRM);
  END;
  --
  return w_result;
  --
END UF_DELETE_SAPR;
------------------------------------------------
FUNCTION WF_IMPDEN_ANNO
( p_tipo_tributo   IN     varchar2
, p_anno           IN     number
) return number
/**
  Manca codice PowerBuilder ?????????????????????
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := 0;
  --

  --
  return w_result;
  --
END WF_IMPDEN_ANNO;
------------------------------------------------
FUNCTION WF_IMPDEN_ANNO_TARSU
( p_anno            IN     number
, p_dMaggTares      OUT    number
, p_sDettaglioOgim  OUT    varchar2
, p_dAddEca         OUT    number
, p_dMaggEca        OUT    number
, p_dAddProv        OUT    number
, p_dIva            OUT    number
) return number
/**
  Manca codice PowerBuilder ?????????????????????
**/
IS
  --
  w_result         number;
  --
BEGIN
  --
  w_result := 0;
  --
  p_dMaggTares := null;
  p_sDettaglioOgim := null;
  p_dAddEca := null;
  p_dMaggEca := null;
  p_dAddProv := null;
  p_dIva := null;
  --
  return w_result;
  --
END WF_IMPDEN_ANNO_TARSU;
------------------------------------------------
-- Prepara cursor per dati accertati ICI/IMU
------------------------------------------------
function dati_oggetti_ici
( a_pratica        number
, a_anno          number
, a_cod_fiscale   varchar
)
return sys_refcursor is
  --
  rc                          sys_refcursor;
  --
begin
  open rc for
      SELECT
        OGIM_ACC.OGGETTO_IMPOSTA,
        OGIM_ACC.OGGETTO_PRATICA,
        OGIM_ACC.COD_FISCALE,
        OGIM_ACC.ANNO,
        OGIM_ACC.IMPOSTA,
        OGIM_ACC.IMPOSTA_ACCONTO,
        OGIM_ACC.IMPOSTA_DOVUTA,
        OGIM_ACC.IMPOSTA_DOVUTA_ACCONTO,
        OGIM_ACC.ADDIZIONALE_ECA,
        OGIM_ACC.MAGGIORAZIONE_ECA,
        OGIM_ACC.ADDIZIONALE_PRO,
        OGIM_ACC.IVA,
        OGIM_ACC.IMPORTO_VERSATO,
        OGIM_ACC.TIPO_ALIQUOTA,
        OGIM_ACC.ALIQUOTA,
        PRTR_ACC.DATA,
        PRTR_ACC.ANNO AS PRTR_ANNO,
        PRTR_ACC.DATA_NOTIFICA,
        PRTR_ACC.NUMERO,
        PRTR_ACC.STATO_ACCERTAMENTO,
        PRTR_ACC.TIPO_TRIBUTO,
        OGPR_ACC.OGGETTO,
        OGPR_ACC.OGGETTO_PRATICA_RIF OGPR_DIC,
        OGPR_ACC.OGGETTO_PRATICA_RIF_V OGPR_DIC_V,
        OGCO_ACC.PERC_POSSESSO,
        OGCO_ACC.FLAG_AB_PRINCIPALE,
        OGPR_ACC.IMM_STORICO,
        OGCO_ACC.MESI_POSSESSO,
        OGCO_ACC.MESI_POSSESSO_1SEM,
        OGCO_ACC.DA_MESE_POSSESSO,
        OGCO_ACC.MESI_ESCLUSIONE,
        OGCO_ACC.MESI_RIDUZIONE,
        OGCO_ACC.MESI_ALIQUOTA_RIDOTTA,
        OGCO_ACC.DETRAZIONE,
        OGCO_ACC.FLAG_POSSESSO,
        OGCO_ACC.FLAG_ESCLUSIONE,
        OGCO_ACC.FLAG_RIDUZIONE,
        OGCO_ACC.FLAG_AL_RIDOTTA,
        OGPR_ACC.FLAG_PROVVISORIO,
        OGPR_ACC.FLAG_VALORE_RIVALUTATO,
        OGPR_ACC.VALORE,
        OGIM_ACC.RUOLO,
        OGCO_ACC.INIZIO_OCCUPAZIONE,
        OGCO_ACC.FINE_OCCUPAZIONE,
        OGCO_ACC.DATA_DECORRENZA,
        OGCO_ACC.DATA_CESSAZIONE,
        OGPR_ACC.CONSISTENZA,
        OGPR_ACC.TRIBUTO,
        OGPR_ACC.CATEGORIA,
        OGPR_ACC.TIPO_TARIFFA,
        OGPR_ACC.TIPO_OCCUPAZIONE,
        OGPR_ACC.NUMERO_FAMILIARI,
        OGPR_ACC.CATEGORIA_CATASTO,
        OGPR_ACC.CLASSE_CATASTO,
        OGPR_ACC.TIPO_OGGETTO,
        OGPR_ACC.OGGETTO_PRATICA_RIF_AP,
        OGPR_RIF_AP.OGGETTO OGGETTO_AP,
        OGIM_ACC.IMPORTO_PF,
        OGIM_ACC.IMPORTO_PV,
        OGIM_ACC.MAGGIORAZIONE_TARES,
        OGIM_ACC.TIPO_TARIFFA_BASE,
        OGIM_ACC.IMPOSTA_BASE,
        OGIM_ACC.ADDIZIONALE_ECA_BASE,
        OGIM_ACC.MAGGIORAZIONE_ECA_BASE,
        OGIM_ACC.ADDIZIONALE_PRO_BASE,
        OGIM_ACC.IVA_BASE,
        OGIM_ACC.IMPORTO_PF_BASE,
        OGIM_ACC.IMPORTO_PV_BASE,
        OGIM_ACC.PERC_RIDUZIONE_PF,
        OGIM_ACC.PERC_RIDUZIONE_PV,
        OGIM_ACC.IMPORTO_RIDUZIONE_PF,
        OGIM_ACC.IMPORTO_RIDUZIONE_PV,
        OGIM_ACC.DETTAGLIO_OGIM,
        OGIM_ACC.DETTAGLIO_OGIM_BASE,
        NVL(OGPR_ACC.NUM_ORDINE,TO_CHAR(ROWNUM)) as NUM_ORDINE,

        to_number(substr(OGPR_ACC.indirizzo_occ,1,2)) TIPO_ALIQUOTA_PREC,
        to_number(substr(OGPR_ACC.indirizzo_occ,3,6)) / 100 ALIQUOTA_PREC,
        to_number(substr(OGPR_ACC.indirizzo_occ,9,15)) / 100 DETRAZIONE_PREC_OGPR,

        NULL AS IMPOSTA_LORDA,
        NULL AS FLAG_LORDO,
        NULL AS FLAG_RUOLO,
        NULL AS NUM_PERTINENZE,
        NULL AS IMPORTO_LORDO,

        'stringa vuota' STRINGA_FAMILIARI,
        lpad(' ',4000,' ') APPOGGIO_DETTAGLIO_OGIM,
        lpad(' ',4000,' ') APPOGGIO_DETTAGLIO_OGIM_BASE

      , null as quantita
      , null as superficie
      , null as larghezza
      , null as profondita

      , null as settore
      , null as reddito

      , null as detrazione_acconto
      , null as versato

      , null as prtr_dic_data

      , a_anno as anno_rif

      , null as perc_detrazione
      , null as mesi_occupato
      , null as mesi_occupato_1sem
      , null as aliquota_erar_prec

      , null as tipo_rapporto
      , null as ogco_tipo_rapporto_k

      , OGPR_ACC.flag_domicilio_fiscale

      , OGPR_ACC.data_concessione
      FROM
        OGGETTI_CONTRIBUENTE OGCO_ACC,
        OGGETTI_PRATICA      OGPR_ACC,
        OGGETTI_IMPOSTA      OGIM_ACC,
        PRATICHE_TRIBUTO     PRTR_ACC,
        OGGETTI_PRATICA       OGPR_RIF_AP
      WHERE
        ( OGIM_ACC.ANNO(+) = a_anno ) and
        ( OGIM_ACC.COD_FISCALE(+) = OGCO_ACC.COD_FISCALE) and
        ( OGIM_ACC.OGGETTO_PRATICA(+) = OGCO_ACC.OGGETTO_PRATICA) and
        ( OGCO_ACC.COD_FISCALE(+) = a_cod_fiscale ) and
        ( OGCO_ACC.OGGETTO_PRATICA(+)  = OGPR_ACC.OGGETTO_PRATICA ) and
        ( OGPR_ACC.PRATICA(+) = PRTR_ACC.PRATICA ) and
        ( PRTR_ACC.PRATICA = a_pratica ) and
        ( PRTR_ACC.ANNO  = a_anno ) and
        ( ogpr_rif_ap.oggetto_pratica (+) = OGPR_ACC.oggetto_pratica_rif_ap)
  ;

  return rc;
end dati_oggetti_ici;
------------------------------------------------
-- Prepara cursor per dati accertati TARSU
------------------------------------------------
function dati_oggetti_tarsu
( a_pratica        number
, a_anno          number
, a_cod_fiscale   varchar
)
return sys_refcursor is
  --
  rc                          sys_refcursor;
  --
begin
  open rc for
    SELECT
      OGIM_ACC.OGGETTO_IMPOSTA,
      OGIM_ACC.OGGETTO_PRATICA,
      OGIM_ACC.COD_FISCALE,
      OGIM_ACC.ANNO,
      OGIM_ACC.IMPOSTA,
      OGIM_ACC.IMPOSTA_ACCONTO,
      OGIM_ACC.IMPOSTA_DOVUTA,
      OGIM_ACC.IMPOSTA_DOVUTA_ACCONTO,
      OGIM_ACC.ADDIZIONALE_ECA,
      OGIM_ACC.MAGGIORAZIONE_ECA,
      OGIM_ACC.ADDIZIONALE_PRO,
      OGIM_ACC.IVA,
      OGIM_ACC.IMPORTO_VERSATO,
      OGIM_ACC.TIPO_ALIQUOTA,
      OGIM_ACC.ALIQUOTA,
      PRTR_ACC.DATA,
      PRTR_ACC.ANNO AS PRTR_ANNO,
      PRTR_ACC.DATA_NOTIFICA,
      PRTR_ACC.NUMERO,
      PRTR_ACC.STATO_ACCERTAMENTO,
      PRTR_ACC.TIPO_TRIBUTO,
      OGPR_ACC.OGGETTO,
      OGPR_ACC.OGGETTO_PRATICA_RIF OGPR_DIC,
      OGPR_ACC.OGGETTO_PRATICA_RIF_V OGPR_DIC_V,
      OGCO_ACC.PERC_POSSESSO,
      OGCO_ACC.FLAG_AB_PRINCIPALE,
      OGPR_ACC.IMM_STORICO,
      OGCO_ACC.MESI_POSSESSO,
      OGCO_ACC.MESI_POSSESSO_1SEM,
      OGCO_ACC.DA_MESE_POSSESSO,
      OGCO_ACC.MESI_ESCLUSIONE,
      OGCO_ACC.MESI_RIDUZIONE,
      OGCO_ACC.MESI_ALIQUOTA_RIDOTTA,
      OGCO_ACC.DETRAZIONE,
      OGCO_ACC.FLAG_POSSESSO,
      OGCO_ACC.FLAG_ESCLUSIONE,
      OGCO_ACC.FLAG_RIDUZIONE,
      OGCO_ACC.FLAG_AL_RIDOTTA,
      OGPR_ACC.FLAG_PROVVISORIO,
      OGPR_ACC.FLAG_VALORE_RIVALUTATO,
      OGPR_ACC.VALORE VALORE,
      OGIM_ACC.RUOLO,
      OGCO_ACC.INIZIO_OCCUPAZIONE,
      OGCO_ACC.FINE_OCCUPAZIONE,
      OGCO_ACC.DATA_DECORRENZA,
      OGCO_ACC.DATA_CESSAZIONE,
      OGPR_ACC.CONSISTENZA,
      OGPR_ACC.TRIBUTO,
      OGPR_ACC.CATEGORIA,
      OGPR_ACC.TIPO_TARIFFA,
      OGPR_ACC.TIPO_OCCUPAZIONE,
      OGPR_ACC.NUMERO_FAMILIARI,
      OGPR_ACC.CATEGORIA_CATASTO,
      OGPR_ACC.CLASSE_CATASTO,
      OGPR_ACC.TIPO_OGGETTO,
      OGPR_ACC.OGGETTO_PRATICA_RIF_AP,
      OGPR_RIF_AP.OGGETTO OGGETTO_AP,
      OGIM_ACC.IMPORTO_PF,
      OGIM_ACC.IMPORTO_PV,
      OGIM_ACC.MAGGIORAZIONE_TARES,
      OGIM_ACC.TIPO_TARIFFA_BASE,
      OGIM_ACC.IMPOSTA_BASE,
      OGIM_ACC.ADDIZIONALE_ECA_BASE,
      OGIM_ACC.MAGGIORAZIONE_ECA_BASE,
      OGIM_ACC.ADDIZIONALE_PRO_BASE,
      OGIM_ACC.IVA_BASE,
      OGIM_ACC.IMPORTO_PF_BASE,
      OGIM_ACC.IMPORTO_PV_BASE,
      OGIM_ACC.PERC_RIDUZIONE_PF,
      OGIM_ACC.PERC_RIDUZIONE_PV,
      OGIM_ACC.IMPORTO_RIDUZIONE_PF,
      OGIM_ACC.IMPORTO_RIDUZIONE_PV,
      OGIM_ACC.DETTAGLIO_OGIM,
      OGIM_ACC.DETTAGLIO_OGIM_BASE,
      NVL(OGPR_ACC.NUM_ORDINE,TO_CHAR(ROWNUM)) as NUM_ORDINE,

      NULL AS TIPO_ALIQUOTA_PREC,
      NULL AS ALIQUOTA_PREC,
      NULL AS DETRAZIONE_PREC_OGPR,
      decode(decode(RUOL.RUOLO,null,nvl(CATA.FLAG_LORDO,'N'),nvl(RUOL.IMPORTO_LORDO,'N'))
           ,'S',decode(COTR.FLAG_RUOLO
                      ,'S',round(OGIM_ACC.IMPOSTA * nvl(CATA.ADDIZIONALE_ECA,0) / 100,2)    +
                           round(OGIM_ACC.IMPOSTA * nvl(CATA.MAGGIORAZIONE_ECA,0) / 100,2)  +
                           round(OGIM_ACC.IMPOSTA * nvl(CATA.ADDIZIONALE_PRO,0) / 100,2)    +
                           round(OGIM_ACC.IMPOSTA * nvl(CATA.ALIQUOTA,0) / 100,2)
                          ,0
                      )
               ,0
           ) + OGIM_ACC.IMPOSTA IMPOSTA_LORDA,
      nvl(CATA.FLAG_LORDO,'N') FLAG_LORDO,
      nvl(COTR.FLAG_RUOLO,'N') FLAG_RUOLO,
      F_CONTA_PERTINENZE(OGPR_ACC.OGGETTO_PRATICA) NUM_PERTINENZE,
      RUOL.IMPORTO_LORDO,

      'stringa vuota' STRINGA_FAMILIARI,
      lpad(' ',4000,' ') APPOGGIO_DETTAGLIO_OGIM,
      lpad(' ',4000,' ') APPOGGIO_DETTAGLIO_OGIM_BASE

      , null as quantita
      , null as superficie
      , null as larghezza
      , null as profondita

      , null as settore
      , null as reddito

      , null as detrazione_acconto
      , null as versato

      , null as prtr_dic_data

      , a_anno as anno_rif

      , null as perc_detrazione
      , null as mesi_occupato
      , null as mesi_occupato_1sem
      , null as aliquota_erar_prec

      , null as tipo_rapporto
      , null as ogco_tipo_rapporto_k

      , OGPR_ACC.flag_domicilio_fiscale

      , OGPR_ACC.data_concessione
    FROM
      CARICHI_TARSU        CATA,
      CODICI_TRIBUTO       COTR,
      RUOLI                RUOL,
      OGGETTI_IMPOSTA      OGIM_DIC,
      OGGETTI_IMPOSTA      OGIM_ACC,
      OGGETTI_CONTRIBUENTE OGCO_ACC,
      OGGETTI_PRATICA      OGPR_ACC,
      PRATICHE_TRIBUTO     PRTR_ACC,
      OGGETTI_PRATICA    OGPR_RIF_AP
    WHERE
          CATA.ANNO                    = a_anno
      and COTR.TRIBUTO                 = OGPR_ACC.TRIBUTO
      and RUOL.RUOLO               (+) = OGIM_DIC.RUOLO
      and OGIM_ACC.ANNO            (+) = a_anno
      and OGIM_ACC.COD_FISCALE     (+) = OGCO_ACC.COD_FISCALE
      and OGIM_ACC.OGGETTO_PRATICA (+) = OGCO_ACC.OGGETTO_PRATICA
      and OGIM_DIC.OGGETTO_PRATICA (+) = nvl(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
      and OGIM_DIC.ANNO            (+) = a_anno
      and OGCO_ACC.COD_FISCALE     (+) = a_cod_fiscale
      and OGCO_ACC.OGGETTO_PRATICA (+) = OGPR_ACC.OGGETTO_PRATICA
      and OGPR_ACC.PRATICA         (+) = PRTR_ACC.PRATICA
      and PRTR_ACC.PRATICA             = a_pratica
      and ogpr_rif_ap.oggetto_pratica (+) = OGPR_ACC.oggetto_pratica_rif_ap
      and (OGIM_DIC.RUOLO               is null
           or  OGIM_DIC.RUOLO           is not null
              and to_char(RUOL.DATA_EMISSIONE,'YYYYMMDD')||lpad(to_char(RUOL.RUOLO),10,'0') =
                 (select max(to_char(RUOL_SUB.DATA_EMISSIONE,'YYYYMMDD')||lpad(to_char(RUOL_SUB.RUOLO),10,'0'))
                    from OGGETTI_IMPOSTA  OGIM_SUB,
                         RUOLI            RUOL_SUB
                   where OGIM_SUB.OGGETTO_PRATICA = OGIM_DIC.OGGETTO_PRATICA
                     and OGIM_SUB.ANNO            = OGIM_DIC.ANNO
                     and RUOL_SUB.RUOLO           = OGIM_SUB.RUOLO
                     and RUOL_SUB.INVIO_CONSORZIO is not null
                 )
             )
  ;

  return rc;

end dati_oggetti_tarsu;
------------------------------------------------
-- Prepara cursor per dati riog oggetti
------------------------------------------------
function riog_oggetto
( p_dws             IN     t_dws
, p_tipo_tributo    IN     varchar
, p_cod_fiscale     IN     varchar
, p_oggetto         IN     number
, p_anno            IN     number
)
return sys_refcursor is
  --
  rc                          sys_refcursor;
  --
begin
  --
  open rc for
    SELECT
      ROFF.INIZIO_VALIDITA,
      ROFF.FINE_VALIDITA,
      --
      ROFF.categoria_catasto,
      ROFF.classe_catasto,
      --
      ROFF.rendita,
      ROFF.valore,
      --
      ROFF.mesi_possesso,
      ROFF.mesi_possesso_1sem,
      ROFF.da_mese_possesso,
      --
      case WHEN ROFF.mesi_esclusione IS NOT NULL THEN
        case WHEN ROFF.mesi_esclusione >= ROFF.da_mese_possesso THEN
          ROFF.mesi_esclusione - ROFF.da_mese_possesso + 1
        ELSE
          null
        END
      ELSE
        null
      END mesi_esclusione,
      case WHEN ROFF.mesi_riduzione IS NOT NULL THEN
        case WHEN ROFF.mesi_riduzione >= ROFF.da_mese_possesso THEN
          ROFF.mesi_riduzione - ROFF.da_mese_possesso + 1
        ELSE
          null
        END
      ELSE
        null
      END mesi_riduzione,
      case WHEN ROFF.mesi_aliquota_ridot IS NOT NULL THEN
        case WHEN ROFF.mesi_aliquota_ridot >= ROFF.da_mese_possesso THEN
          ROFF.mesi_aliquota_ridot - ROFF.da_mese_possesso + 1
        ELSE
          null
        END
      ELSE
        null
      END mesi_aliquota_ridot,
      --
      num_ordine
    from (
      SELECT
        ROOG.INIZIO_VALIDITA,
        ROOG.FINE_VALIDITA,
        --
        ROOG.categoria_catasto,
        ROOG.classe_catasto,
        --
        ROOG.rendita,
        nvl(f_valore_da_rendita(ROOG.rendita,ROOG.tipo_oggetto,p_anno,ROOG.categoria_catasto,ROOG.imm_storico)
            , ROOG.valore) as valore,
        --
        f_get_mesi_possesso(p_tipo_tributo,p_cod_fiscale,p_anno,ROOG.oggetto,
                                    ROOG.INIZIO_VALIDITA,ROOG.FINE_VALIDITA) mesi_possesso,
        f_get_mesi_possesso_1sem(ROOG.INIZIO_VALIDITA,ROOG.FINE_VALIDITA) mesi_possesso_1sem,
        f_titolo_da_mese_possesso('A',ROOG.INIZIO_VALIDITA) da_mese_possesso,
        --
        p_dws.ogg.mesi_esclusione as mesi_esclusione,
        p_dws.ogg.mesi_riduzione as mesi_riduzione,
        p_dws.ogg.mesi_aliquota_ridot as mesi_aliquota_ridot,
        --
        p_dws.ogg.num_ordine || TO_CHAR(ROWNUM) as num_ordine
      from (
        SELECT
          greatest(PEOG.INIZIO_VALIDITA,f_get_data_inizio_da_mese(p_anno,null)) as INIZIO_VALIDITA,
          least(PEOG.FINE_VALIDITA,f_get_data_fine_da_mese(p_anno,12,1)) as FINE_VALIDITA,
          --
          nvl(F_GET_RIOG_DATA(PEOG.oggetto,PEOG.inizio_validita,'CA',null),p_dws.ogg.categoria_catasto) as categoria_catasto,
          nvl(F_GET_RIOG_DATA(PEOG.oggetto,PEOG.inizio_validita,'CL',null),p_dws.ogg.classe_catasto) as classe_catasto,
          nvl(p_dws.ogg.tipo_oggetto,ogge.tipo_oggetto) as tipo_oggetto,
          p_dws.ogg.imm_storico as imm_storico,
          PEOG.OGGETTO,
          --
          RIOG.rendita,
          p_dws.ogg.valore valore
        from
          OGGETTI OGGE,
          RIFERIMENTI_OGGETTO RIOG,
          (select OGGETTO, INIZIO_VALIDITA, FINE_VALIDITA, INIZIO_VALIDITA_EFF
           from PERIODI_RIOG
           where oggetto = p_oggetto
             and p_tipo_tributo in ('ICI','TASI')
          union
           select p_oggetto as OGGETTO,
                  TO_DATE('18000101','YYYYMMdd') as INIZIO_VALIDITA,
                  TO_DATE('99991231','YYYYMMdd') as FINE_VALIDITA,
                  TO_DATE('18000101','YYYYMMdd') as INIZIO_VALIDITA_EFF
             from dual
            where (p_tipo_tributo not in ('ICI','TASI')) or
                   (not exists
                        (select 1 from PERIODI_RIOG riog where oggetto = p_oggetto)
                   )
          ) PEOG
        WHERE PEOG.OGGETTO = RIOG.OGGETTO (+)
          AND PEOG.INIZIO_VALIDITA_EFF = RIOG.INIZIO_VALIDITA (+)
          AND PEOG.OGGETTO = OGGE.OGGETTO
          AND PEOG.INIZIO_VALIDITA <= TO_DATE(p_anno||'1231','YYYYMMdd')
          AND PEOG.FINE_VALIDITA >= TO_DATE(p_anno||'0101','YYYYMMdd')
        ) ROOG
    ) ROFF
  ;

  return rc;

end riog_oggetto;
------------------------------------------------
-- REPLICA_ACCERTAMENTO
------------------------------------------------
BEGIN
  --
  w_titr := null;
  w_anno_acc := 0;
  w_cf := null;
  w_stato_acc := null;
  w_flag_denuncia := null;
  w_motivo := null;
  --
  BEGIN
    select
      prtr.tipo_tributo,
      prtr.anno,
      prtr.cod_fiscale,
      prtr.stato_accertamento,
      prtr.flag_denuncia,
      decode(prtr.tipo_calcolo,'N','S',null) as flag_normalizzato,
      prtr.flag_adesione,
      prtr.motivo
     into
      w_titr, w_anno_acc, w_cf, w_stato_acc, w_flag_denuncia, w_flag_normalizzato, w_flag_adesione, w_motivo
     from
      pratiche_tributo prtr
    where
      prtr.pratica = p_prat
  ;
  EXCEPTION
    WHEN others THEN
      raise_application_error(-20999,'Errore ricavando dati Accertamento '|| p_prat);
  END;
  --
  w_rivalutato := nvl(p_flag_rivalutato,'N') = 'S';
  --
--dbms_output.put_line('Pratica: '||p_prat||', tributo: '||w_titr||', anno: '||w_anno_acc||', CF: '||w_cf);
  --
  p_pratiche_acc := null;        -- Elenco delle pratiche generate (per riutilizzo pratiche esistenti)
  --
  -- Parametri ricalcolo sanzioni, codice NON verificato.
  --   Quindi al momento il calcolo va fatto all'esterno di questa procedure
  p_sanz := 0;       -- 1;       -- Al momento non calcoliamo le sanzioni, poi si vedrà
  --
  p_tardiva_denuncia := null;    -- Calcolo Sanzioni, non usato
  --
  p_esiste_dic := false;         -- Calcolo sanzioni, esiste dichiarato
  p_anno_dic := null;            -- Calcolo sanzioni, anno dichiarazione
  p_mesi_dic := 12;              -- Calcolo sanzioni, mesi dichiarati
  p_flag_poss_dic := null;       -- Calcolo sanzioni, flag possesso dichiarato
  --
  -- Nome maschera data source orginale e flag replica
  --   Da verificare, preimpostiamo a valori neutri
  v_dw_acc.data_object := 'd_ogim_acc';
  v_dw_acc.replica := false;
  --
  -- Veniva letto dalla mschera, per ora ricicliamo quello dell'accertmaneto di origine
  --   Pseudo-Codice PB : f_existsSheet('w_acc_tarsu_apri' / 'w_acc_auto_tarsu_apri') . wf_get('adesione')
  v_dw_acc.adesione := w_flag_adesione;
  --
  w_check := 0;
  sPratiche_Acc := p_pratiche_acc;
  iConta_Pratiche := -1;
  iConta_Anno := -1;
  --
  /**
  *** Blocco di codice di debug
  *** Serve per capire cosa carica e cosa replica
  ***
    case w_titr
      WHEN 'ICI' THEN
          v_rc := dati_oggetti_ici(p_prat, w_anno_acc, w_cf);
      WHEN 'TARSU' THEN
          v_rc := dati_oggetti_ici(p_prat, w_anno_acc, w_cf);
      ELSE
          raise_application_error(-20999,'Tipo tributo non supportato '||w_titr);
    END CASE;
    --
    loop
      fetch v_rc
        into v_dw_acc.ogg;
      exit when v_rc%notfound;
      --
      dbms_output.put_line('OGPR : '||v_dw_acc.ogg.oggetto_pratica||', OGIM: '||v_dw_acc.ogg.oggetto_imposta);
      --
      w_oggetto := v_dw_acc.ogg.oggetto;
      --
      ianno := 2023;
      --
      v_rc_riog := riog_oggetto(v_dw_acc, w_titr, w_cf, w_oggetto, ianno);
      LOOP
        FETCH v_rc_riog
          INTO w_ogg_riog;
        EXIT WHEN v_rc_riog%notfound;
        --
        dbms_output.put_line('Ogg: '||w_oggetto||', Dal: '||w_ogg_riog.data_inizio||', Al: '||w_ogg_riog.data_fine);
        dbms_output.put_line('Cat: '||w_ogg_riog.categoria_catasto||', CL: '||w_ogg_riog.classe_catasto);
        dbms_output.put_line('Rend: '||w_ogg_riog.rendita||', Val: '||w_ogg_riog.valore);
        dbms_output.put_line('MP: '||w_ogg_riog.mesi_possesso||', MP1S: '||w_ogg_riog.mesi_possesso_1sem||', DMP: '||w_ogg_riog.da_mese_possesso);
        dbms_output.put_line('ME: '||w_ogg_riog.mesi_esclusione||', MR: '||w_ogg_riog.mesi_riduzione||', MAR: '||w_ogg_riog.mesi_aliquota_ridot);
        --
      END LOOP;
    end loop;
    --
  return;

  **
  **/

  --
--sDettaglioOgim := rpad('1',4000,'1');
--sStringaFamiliari := rpad('1',2000,'1');
  --
  FOR ianno in p_anno_da..p_anno_a
  LOOP
    sDettaglioOgim := rpad('1',4000,'1');
    sStringaFamiliari := rpad('1',2000,'1');
    sDettaglioOgimBase := rpad('1',4000,'1');
    --
    iConta_Anno := iConta_Anno + 1;
    iConta_Pratiche := iConta_Pratiche + 1;
    --
    IF ianno <> w_anno_acc THEN
      num_prtr := 0;
      --
      SELECT to_number(substr(sPratiche_Acc, iConta_Pratiche * 10 + 1,10))
        INTO nPratica
        FROM dual;
      --
      case w_titr
        WHEN 'ICI' THEN
            v_rc := dati_oggetti_ici(p_prat, w_anno_acc, w_cf);
        WHEN 'TARSU' THEN
            v_rc := dati_oggetti_ici(p_prat, w_anno_acc, w_cf);
        ELSE
            raise_application_error(-20999,'Tipo tributo non supportato '||w_titr);
      END CASE;
      -- Loop Oggetti Multipli : INIZIO
      num_ordine := 0;
      --
      LOOP
        FETCH v_rc
          INTO v_dw_acc.ogg;
        EXIT WHEN v_rc%notfound;
        --
        w_oggetto := v_dw_acc.ogg.oggetto;
        w_tipo_ogge := v_dw_acc.ogg.tipo_oggetto;
        w_oggetto_pratica_acc := v_dw_acc.ogg.oggetto_pratica;
        w_flag_possesso_acc := v_dw_acc.ogg.flag_possesso;
        w_mesi_possesso_acc := v_dw_acc.ogg.mesi_possesso;
        w_da_mese_poss_acc := v_dw_acc.ogg.da_mese_possesso;
        w_data_decorrenza_acc := v_dw_acc.ogg.data_decorrenza;
        w_data_cessazione_acc := v_dw_acc.ogg.data_cessazione;
        --
        w_ogpr_dic_v := v_dw_acc.ogg.ogpr_dic_v;
        --
      --dbms_output.put_line('Anno: '||ianno||', OGPR: '||w_oggetto_pratica_acc||', OGIM: '||v_dw_acc.ogg.oggetto_imposta);
        --
        -- Filtra gli oggetti ed applica dati di cessazione annualizzati
        --
        w_data_replicabile := to_date(w_anno_acc||'1231','YYYYMMdd');
        --
        if w_check = -9999 then
           iRet := -9999;   -- Inutile elaborare gli oggetti causa errore procedurale, vedi sotto
        else
          case w_titr
            WHEN 'ICI' THEN
              -- Prende tutto tranne :
              -- 1 : (nvl(MP,12) + nvl(DMP,12)) < 13
            --dbms_output.put_line('MP: '||w_mesi_possesso_acc||', DMP: '||w_da_mese_poss_acc);
              if (nvl(w_mesi_possesso_acc,12) + nvl(w_da_mese_poss_acc,12)) < 13 then
              --dbms_output.put_line('(MP + DMP < 13) -> SALTATO');
                iRet := 1;
              else
                iRet := 0;
              end if;
            WHEN 'TARSU' THEN
              -- Prende solo gli oggetti con Cessazione nulla o >= al 31/12/anno_acc
              if w_data_cessazione_acc is not null and
                 w_data_cessazione_acc < w_data_replicabile then
              --dbms_output.put_line('Cessazione: '||w_data_cessazione_acc||' -> SALTATO');
                iRet := 1;
              else
                -- Ricalcola data cessazione come fine anno nuovo accertamento
                -- Ci serve per il calcolo
                w_data_cessazione_acc := to_date(ianno||'1231','YYYYMMdd');
                v_dw_acc.ogg.data_cessazione := w_data_cessazione_acc;
                iRet := 0;
              end if;
            ELSE
              iRet := 0;
          END CASE;
        end if;
        --

      --
      if iRet = 0 then
        iRet := uf_check_acc(w_titr, ianno, w_cf, w_oggetto, p_prat, w_stato_acc, w_flag_denuncia,
                                        w_flag_possesso_acc, w_mesi_possesso_acc, w_oggetto_pratica_acc,
                                                             w_data_decorrenza_acc, w_data_cessazione_acc);
      end if;
      --
      IF iRet <> 0 THEN
        IF iRet = -2 THEN
          raise_application_error(-20999,'Esiste già un accertamento per l''oggetto '||w_oggetto||' per l''anno ' ||ianno);
        END IF;
      ELSE  -- Non esistenza di altro accertamento per l'anno in trattamento : INIZIO
        --
        -- Loop su evenuali RIOG oggetto per anno
        --
        v_rc_riog := riog_oggetto(v_dw_acc, w_titr, w_cf, w_oggetto, ianno);
        LOOP      -- Loop RIOG oggetto per anno : INIZIO
          FETCH v_rc_riog
            INTO w_ogg_riog;
          EXIT WHEN v_rc_riog%notfound;
          --
        --dbms_output.put_line('Ogg: '||w_oggetto||', Dal: '||w_ogg_riog.data_inizio||', Al: '||w_ogg_riog.data_fine);
        --dbms_output.put_line('Cat: '||w_ogg_riog.categoria_catasto||', CL: '||w_ogg_riog.classe_catasto);
        --dbms_output.put_line('Rend: '||w_ogg_riog.rendita||', Val: '||w_ogg_riog.valore);
        --dbms_output.put_line('MP: '||w_ogg_riog.mesi_possesso||', MP1S: '||w_ogg_riog.mesi_possesso_1sem||', DMP: '||w_ogg_riog.da_mese_possesso);
        --dbms_output.put_line('ME: '||w_ogg_riog.mesi_esclusione||', MR: '||w_ogg_riog.mesi_riduzione||', MAR: '||w_ogg_riog.mesi_aliquota_ridot);
          --
          -- Applica i dati derivati dal RIOG per la porzione di anno di pertinenza
          --
          v_dw_acc.ogg.mesi_possesso := w_ogg_riog.mesi_possesso;
          v_dw_acc.ogg.mesi_possesso_1sem := w_ogg_riog.mesi_possesso_1sem;
          v_dw_acc.ogg.da_mese_possesso := w_ogg_riog.da_mese_possesso;
          --
          v_dw_acc.ogg.mesi_esclusione := w_ogg_riog.mesi_esclusione;
          v_dw_acc.ogg.mesi_riduzione := w_ogg_riog.mesi_riduzione;
          v_dw_acc.ogg.mesi_aliquota_ridot := w_ogg_riog.mesi_aliquota_ridot;
          --
          v_dw_acc.ogg.classe_catasto := w_ogg_riog.classe_catasto;
          v_dw_acc.ogg.categoria_catasto := w_ogg_riog.categoria_catasto;
          v_dw_acc.ogg.valore := w_ogg_riog.valore;
          --
          num_ordine := num_ordine + 1;
          v_dw_acc.ogg.num_ordine := to_char(num_ordine);    -- w_ogg_riog.num_ordine;
          --

        IF nvl(nPratica,0) = 0 THEN
          -- Inserisci record
          num_prtr := null;
          data_not := null;
          sNote := null;

          IF w_flag_normalizzato = 'S' THEN
              sTipoCalcolo := 'N';
          ELSE
              sTipoCalcolo := 'T';
          END IF;

          pratiche_tributo_nr(num_prtr);
          w_check := uf_update_prtr(v_dw_acc, num_prtr, w_cf, ianno, data_not, w_motivo,
                                    w_flag_denuncia, sNote, p_utente, NUOVO, w_titr, 'A', 'U',
                                    p_data_emis, null, w_stato_acc, null, sTipoCalcolo);

          -- Si inserisce il contribuente nella tabella rapporti_tributo
          IF w_check = 0 THEN
              w_check := uf_insert_ratr(w_cf, num_prtr, 'E');
          END IF;
          --
          nPratica := num_prtr;
        ELSE
          num_prtr := nPratica;
          w_check := 0;
        END IF;
        --
      --dbms_output.put_line('Anno: '||ianno||', Pratica: '||num_prtr);
        --
        -- Si inserisce l 'oggetto_pratica
        --
        if w_check = 0 Then
          num_ogpr := null;
          oggetti_pratica_nr(num_ogpr);
          w_check := uf_update_ogpr(v_dw_acc, num_ogpr, w_oggetto, num_prtr, p_utente, NUOVO, w_titr, ianno, w_ogpr_dic_v);
        end if;
        --
      --dbms_output.put_line('Anno: '||ianno||', Oggetto_Pratica: '||num_ogpr);
        --
        if w_check = 0 then
          -- Si esegue un' ulteriore update per non cambiare i parametri della funzione
          -- di aggiornamento degli oggetti pratica, perché richiamata da n oggetti e
          -- perché la variazione dello stato di rivalutazione si verifica solo in questo caso.
          BEGIN
            IF w_rivalutato != false THEN
              UPDATE oggetti_pratica
                 set flag_valore_rivalutato = 'S'
               where oggetto_pratica = num_ogpr
              ;
            ELSE
              UPDATE oggetti_pratica
                  set flag_valore_rivalutato = null
                  where oggetto_pratica = num_ogpr
              ;
            END IF;
          EXCEPTION
            WHEN others THEN
              raise_application_error(-20999,'Errore in aggiornamento Indicatore di Rivalutazione di Accertamento');
          END;
        END IF;
        --
        -- Per ICI inserisco i dati dell'anno precedente
        --
        if w_check = 0 and w_titr = 'ICI' Then
          dTipo_Ali_prec := v_dw_acc.ogg.tipo_aliquota_prec;
          detr_prec := v_dw_acc.ogg.detrazione_prec_ogpr;
          -- Modifica del 29/06/2016: se l' anno è < 2012, si utilizza l 'aliquota dell' anno precedente
          -- altrimenti l 'aliquota base dello stesso anno
          if ianno < 2012 then
            BEGIN
              select aliquota
                into dAliquota_prec
                from aliquote
               where tipo_aliquota = dTipo_Ali_prec
                 and anno          = iAnno - 1
                 and tipo_tributo  = w_titr
              ;
            EXCEPTION
              when NO_DATA_FOUND then
                dTipo_Ali_prec := 1;
                BEGIN
                  select aliquota
                    into dAliquota_prec
                    from aliquote
                   where tipo_aliquota = dTipo_Ali_prec
                     and anno          = iAnno - 1
                     and tipo_tributo  = w_titr
                  ;
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Ricerca Aliquota Base Anno '||iAnno - 1);
                END;
              WHEN others THEN
                raise_application_error(SQLCODE,SQLERRM);
            END;
          else
            BEGIN
              select nvl(aliquota_base,aliquota)
                 into dAliquota_prec
                  from aliquote
                 where tipo_aliquota = dTipo_Ali_prec
                   and anno          = iAnno
                   and tipo_tributo  = w_titr
              ;
            EXCEPTION
              when NO_DATA_FOUND then
                dTipo_Ali_prec := 1;
                BEGIN
                  select nvl(aliquota_base,aliquota)
                       into dAliquota_prec
                     from aliquote
                      where tipo_aliquota = dTipo_Ali_prec
                        and anno          = iAnno
                        and tipo_tributo  = w_titr
                  ;
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Ricerca Aliquota Base Anno "||iAnno');
                END;
              WHEN others THEN
                raise_application_error(SQLCODE,SQLERRM);
            END;
          end if;
          if w_check = 0 then
             w_check := uf_update_ogpr_acc_ici(num_ogpr, dTipo_Ali_prec, daliquota_prec, detr_prec);
          end if;
        end if;
        --
        -- Per ICI si inseriscono eventuali costi Storici aventi anno < dell' anno
        -- della Pratica Replicata
        --
        IF w_check = 0 AND w_titr = 'ICI' THEN
          BEGIN
            INSERT
              INTO costi_storici
                   (oggetto_pratica, anno, costo, utente, data_variazione)
             SELECT num_ogpr, anno, costo, p_utente, trunc(sysdate)
               FROM costi_storici
              where oggetto_pratica = w_oggetto_pratica_acc
                AND anno < iAnno
             ;
          EXCEPTION
            WHEN others THEN
              raise_application_error(-20999,'"Errore in Inserimento Valori Contabili.');
          END;
        END IF;
        --
        -- Si inserisce l 'oggetto_contribuente
        --
        if w_check = 0 Then
          v_dw_acc.replica := TRUE;
          w_check := uf_update_ogco(v_dw_acc, num_ogpr, w_cf, ianno, 'E', p_utente, NUOVO, w_titr);
          v_dw_acc.replica := FALSE;
        end if;
        --
      --dbms_output.put_line('Anno: '||ianno||', Oggetto_Contribuente: '||num_ogpr);
        --
        -- Si calcola l' imposta dell 'accertamento
        --
        if w_check = 0 Then
          w_check_acc := 0;
          num_OgprDic := w_ogpr_dic_v;
          --
          if nvl(num_OgprDic,0) = 0 then
            num_OgPrDic := v_dw_acc.ogg.ogpr_dic;
          end if;
          --
          CASE w_titr
            WHEN 'ICI' then
              dTipoOgge := w_tipo_ogge;
              dValore := v_dw_acc.ogg.valore;
              sf_ValRiv := v_dw_acc.ogg.flag_valore_rivalutato;
              dTipo_Ali := v_dw_acc.ogg.tipo_aliquota;
              dPercPoss := v_dw_acc.ogg.perc_possesso;
              dMP := nvl(v_dw_acc.ogg.mesi_possesso,12);
              dMP1S := nvl(v_dw_acc.ogg.mesi_possesso_1sem,6);
              dME := v_dw_acc.ogg.mesi_esclusione;
              dMR := v_dw_acc.ogg.mesi_riduzione;
              detr := v_dw_acc.ogg.detrazione;
              sCatCat := v_dw_acc.ogg.categoria_catasto;
              sCodFis := v_dw_acc.ogg.cod_fiscale;
              dAnno_dic := null;
              --
              -- dAliq_Acc contiene l' Aliquota relativa ad un eventuale rivalutazione dell 'Accertamento
              -- da replicare; tale aliquota serve per svalutare l' eventuale valore rivalutato.
              --
              dAliq_Acc := uf_riv_rendita(w_anno_acc, dTipoOgge);
              --
              -- dAliq contiene l 'Aliquota relativa ad un eventuale rivalutazione da applicare
              -- all' Accertamento replicato se è previsto di rivalutarli.
              --
              dAliq := uf_riv_rendita(iAnno, dTipoOgge);
              --
              -- CASO 1 - Valore non rivalutato e non è richiesta la rivalutazione
              -- CASO 2 - Valore non rivalutato e è richiesta la rivalutazione
              -- CASO 3 - Valore rivalutato e non è richiesta la rivalutazione
              -- CASO 4 - Valore rivalutato ed è richiesta la rivalutazione
              --
              -- Il caso si complica leggermente con la gestione della rivalutazione degli
              -- oggetti di categoria catasto 'B' valida a partire dal 2007
              --
              if sf_ValRiv is null then
                if w_rivalutato = false then
                   -- Caso 1 : il Valore è già corretto
                   dValore := dValore;
                else
                   -- Caso 2 : rivaluta valore
                  dValore := dValore * (100 + dAliq) / 100;
                  --
                  if substr(sCatCat,1,1) = 'B' and w_anno_acc < 2007 and ianno > 2006 then
                     -- lo rivaluto del 40%
                     dValore := dValore * (100 + 40) / 100;
                  end if;
                end if;
              else
                if w_rivalutato = false then
                  -- Caso 3
                  dValore := dValore * 100 / (100 + dAliq_Acc);
                  if substr(sCatCat,1,1) = 'B' and w_anno_acc > 2006 then
                    -- lo svaluto del 40%
                    dValore := dValore * 100 / (100 + 40);
                  end if;
                else
                  -- Caso 4
                  dValore := dValore * 100 / (100 + dAliq_Acc) * (100 + dAliq) / 100;
                  if substr(sCatCat,1,1) = 'B' and w_anno_acc < 2007 and ianno > 2006 then
                    -- lo rivaluto del 40%
                    dValore := dValore * (100 + 40) / 100;
                  end if;
                end if;
              end if;
              --
              update oggetti_pratica
                 set valore = dValore
               where oggetto_pratica = num_ogpr
              ;
              --
              -- Se replico devo passare alla procedura per il calcolo come flag rivalutato,
              -- 'S' se lo cecco sulla replica, null se non lo cecco sulla maschera della replica
              --
              if w_rivalutato != false Then
                sf_ValRivPerCalc := 'S';
              else
                sf_ValRivPerCalc := null;
              end if;
              --
              BEGIN
                --
                -- Recupero dell' aliquota
                --
                SELECT aliquota
                  INTO dAliquota
                  FROM aliquote
                 where tipo_aliquota = dTipo_Ali
                   AND anno = ianno
                   AND tipo_tributo = w_titr
                ;
                --
                -- Recupero dell 'eventuale aliquota per categoria
                --
                select F_ALIQUOTA_ALCA(ianno, dTipo_Ali, sCatCat, dAliquota, 0, sCodFis, w_titr)
                  into dAliquota
                  from dual
                ;
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Recupero Aliquota');
              END;
              --
              BEGIN
                calcolo_accertamento_ici(ianno, dtipoogge, dvalore, sf_ValRivPerCalc, dTipo_Ali, dAliquota,
                                         dPercPoss, dMP, dME, dMR, null, detr, dAnno_dic, sCatCat, dImposta);
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Calcolo Accertamento ICI');
              END;
              --
              -- Recupero dell' aliquota anno precedente
              --
              -- select aliquota
              --   into dAliquota_prec
              --   from aliquote
              --  where tipo_aliquota = dTipo_Ali_prec
              --    and anno = (ianno -1)
              --    and tipo_tributo = w_titr
              -- ;
              --
              -- Modifica del 29/06/2016: se l 'anno è < 2012, si utilizza l' aliquota dell 'anno precedente
              -- altrimenti l' aliquota base dello stesso anno
              --
              IF ianno < 2012 THEN
                BEGIN
                  SELECT aliquota
                    INTO dAliquota_prec
                    FROM aliquote
                   where tipo_aliquota = dTipo_Ali_prec
                     AND anno = iAnno - 1
                     AND tipo_tributo = w_titr
                  ;
                EXCEPTION
                  when NO_DATA_FOUND then
                    dTipo_Ali_prec := 1;
                    BEGIN
                      SELECT aliquota
                        INTO dAliquota_prec
                        FROM aliquote
                       where tipo_aliquota = dTipo_Ali_prec
                         AND anno = iAnno - 1
                         AND tipo_tributo = w_titr
                      ;
                    EXCEPTION
                      WHEN others THEN
                        raise_application_error(-20999,'Errore in Ricerca Aliquota Base Anno '||(iAnno - 1));
                    END;
                  WHEN others THEN
                    raise_application_error(SQLCODE,SQLERRM);
                END;
                --
                -- Recupero dell 'eventuale aliquota per categoria anno precedente
                --
                BEGIN
                  select F_ALIQUOTA_ALCA((ianno -1), dTipo_Ali_prec, sCatCat, dAliquota_prec, 0, sCodFis, w_titr)
                   into dAliquota_precedente
                   from dual
                  ;
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Recupero Aliquota Anno Prec '||(iAnno - 1));
                END;
            else
              BEGIN
                select nvl(aliquota_base,aliquota)
                  into dAliquota_prec
                  from aliquote
                 where tipo_aliquota = dTipo_Ali_prec
                   and anno          = iAnno
                   and tipo_tributo  = w_titr
                ;
              EXCEPTION
                when NO_DATA_FOUND then
                  dTipo_Ali_prec := 1;
                  BEGIN
                    select nvl(aliquota_base,aliquota)
                      into dAliquota_prec
                      from aliquote
                     where tipo_aliquota = dTipo_Ali_prec
                       and anno          = iAnno
                       and tipo_tributo  = w_titr
                    ;
                  EXCEPTION
                    WHEN others THEN
                      raise_application_error(-20999,'Errore in Ricerca Aliquota Base Anno '||iAnno);
                  END;
                WHEN others THEN
                  raise_application_error(SQLCODE,SQLERRM);
                END;
                --
                BEGIN
                  -- Recupero dell' eventuale aliquota per categoria anno in corso (perchè >=2012)
                  SELECT F_ALIQUOTA_ALCA((ianno), dTipo_Ali_prec, sCatCat, dAliquota_prec, 0, sCodFis, w_titr)
                    INTO dAliquota_precedente
                    FROM dual
                  ;
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Recupero Aliquota Acconto '||iAnno);
                END;
              END IF;
              --
              -- Recupero dell 'eventuale aliquota per categoria anno precedente
              --
              -- select F_ALIQUOTA_ALCA((ianno -1), dTipo_Ali_prec, sCatCat, dAliquota_prec, 0, sCodFis, w_titr);
              --   into dAliquota_precedente
              --   from dual
              -- ;
              -- if SQLCA.SQLCODE <> 0 then
              --   f_mbx_error("E"    ,"Errore in Recupero Aliquota Anno Prec",SQLCA.SQLERRTEXT)
              -- end if
              --
              -- Aggiornamento dell' aliquota anno precedente su OGPR.indirizzo_occ
              --
              w_check := uf_update_ogpr_acc_ici(num_ogpr,dTipo_Ali_prec,dAliquota_precedente,detr_prec);
              --
              -- Calcolo Imposta Acconto
              -- Modifica del 30/06/2016: se l 'anno è < 2012 si passa l' anno precedente come parametro,
              -- altrimeni si passa l 'anno da trattare
              --
              BEGIN
                if ianno < 2012 then
                  CALCOLO_ACCERTAMENTO_ICI(ianno - 1, dTipoOgge, dvalore, sf_ValRivPerCalc, dTipo_Ali_prec,
                                           dAliquota_precedente, dPercPoss, dMP, dME, dMR, null, detr_prec,
                                                                            dAnno_dic, sCatCat, dImposta_prec);
                else
                  CALCOLO_ACCERTAMENTO_ICI(ianno, dTipoOgge, dvalore, sf_ValRivPerCalc, dTipo_Ali_prec,
                                           dAliquota_precedente, dPercPoss, dMP, dME, dMR, null, detr_prec,
                                                                            dAnno_dic, sCatCat, dImposta_prec);
                end if;
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Calcolo Accertamento ICI - Acconto"');
              END;
              dImposta_prec := Round(dImposta_prec / dMP * dMP1S, 2);

              if dImposta_prec > dImposta then
                dImposta_prec := dImposta;
              end if;

            WHEN 'ICIAP' then
              dSettore := v_dw_acc.ogg.settore;
              dClasse := v_dw_acc.ogg.consistenza;
              dReddito := v_dw_acc.ogg.reddito;
              BEGIN
                CALCOLO_ACCERTAMENTO_ICIAP(ianno, dClasse, dSettore, dReddito, dImposta);
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Calcolo Accertamento ICIAP');
              END;

            WHEN 'ICP' then
              sTipoPubbl := v_dw_acc.ogg.tipo_occupazione;
              data_dic := v_dw_acc.ogg.prtr_dic_data;
              data_inizio := v_dw_acc.ogg.inizio_occupazione;
              data_fine := v_dw_acc.ogg.fine_occupazione;
              dConsistenza := v_dw_acc.ogg.consistenza;
              dTrib := v_dw_acc.ogg.tributo;
              dCate := v_dw_acc.ogg.categoria;
              dTipo_Tari := v_dw_acc.ogg.tipo_tariffa;
              dQuantita := v_dw_acc.ogg.quantita;
              data_conc := null;
              BEGIN
                CALCOLO_ACCERTAMENTO_ICP(sTipoPubbl, ianno, dTrib, dCate, dTipo_Tari,
                                                    dConsistenza, dQuantita, data_inizio, data_fine, dImposta);
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Calcolo Accertamento ICP');
              END;

            WHEN 'TARSU' then
              dConsistenza := v_dw_acc.ogg.consistenza;
              data_decorr := v_dw_acc.ogg.data_decorrenza;
              data_cessaz := v_dw_acc.ogg.data_cessazione;
              dTrib := v_dw_acc.ogg.tributo;
              dCate := v_dw_acc.ogg.categoria;
              dTipo_Tari := v_dw_acc.ogg.tipo_tariffa;
              dPercPoss := v_dw_acc.ogg.perc_possesso;
              iAnno_Acc_Repl := v_dw_acc.ogg.anno;
              sFlag_ab_principale := v_dw_acc.ogg.flag_ab_principale;
              sOccupazione := v_dw_acc.ogg.tipo_occupazione;
              lnumero_familiari := v_dw_acc.ogg.numero_familiari;
              -- MESSAGEBOX("CALCOLO ACC TARSU DA PRAT TRIB"," w_cf " + w_cf+" num_ogprdic " +
              -- to_char(num_ogprdic)+" iAnno " +to_char(iAnno) )
              --
              if uf_se_accertamenti_a_ruolo(w_cf, num_ogprdic, iAnno) = 'SI'  then
                -- MESSAGEBOX("CALCOLO ACC TARSU DA PRAT TRIB" ,"Anno " +nvl(to_char(ianno),"null")+" Cons " +nvl(to_char(dConsistenza),"null" )+
                -- " Dec "  + nvl(to_char(date(data_decorr),"dd/mm/yyyy" ),"null" )+
                -- " Cess "  + nvl(to_char(date(data_cessaz),"dd/mm/yyyy" ),"null" )+
                -- " Perc "  + nvl(to_char(dPercPoss),"null"    )+" Trib " + nvl(to_char(dTrib),"null"    )+" Cat " +
                -- nvl(to_char(dCate),"null"    )+" Tar "+ nvl(to_char(dTipo_Tari),"null"    )+" Ogpr Dich " +
                -- nvl(to_char(num_ogprdic),"null"    )+" Cf "+ nvl(w_cf,"null"    )+" Norm " + nvl(p_flag_normalizzato,"null"))
                sFlag_Lordo := ' ';
                BEGIN
                  CALCOLO_ACCERTAMENTO_TARSU(ianno, dConsistenza,
                                              data_decorr, data_cessaz, dPercPoss, dTrib, dCate, dTipo_Tari,
                                              0, num_ogprdic, w_cf, null, w_flag_normalizzato, sFlag_ab_principale,
                                              sOccupazione, lnumero_familiari,
                                              dImposta, dImposta_Lorda, sFlag_Lordo, dMaggiorazioneTares, sDettaglioOgim,
                                              dAddEca, dMaggEca, dAddProv, dIva, sStringaFamiliari,
                                              dImportoPf, dImportoPv, dTipoTariffaBase, dImportoBase,
                                              dAddEcaBase, dMaggEcaBase, dAddProvBase, dIvaBase,
                                              dImportoPfBase, dImportoPvBase, dPercRidPf, dPercRidPv,
                                              dImportoPfRid, dImportoPvRid, sDettaglioOgimBase, dImpostaPeriodo);
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Calcolo Accertamento TARSU');
                END;
              else
                w_check_acc := 1;
                -- Si eliminano tutti gli inserimenti operati in precedenza, perché questo caso
                -- non consente di inserire oggetti imposta e quindi la situazione deve essere
                -- riportata al caso iniziale.
                BEGIN
                  delete from pratiche_tributo
                   where pratica = num_prtr
                  ;
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Cancellazione Pratiche TARSU');
                END;

--              f_mbx_error("A","Non è possibile accertare per l'anno " || iAnno +
--              "~nperché l'oggetto della pratica non è iscritto a Ruolo","")
                -- SC 28/11/2014 cancello la pratica e dico al chiamante che è inutile continuare con altri oggetti pratica
                COMMIT;
                nPratica := 0;
                num_prtr := 0;   -- Riporta zero per notifica all'applicazione
                w_check := -9999;
              end if;

            WHEN 'TOSAP' then
              SOccupazione := v_dw_acc.ogg.tipo_occupazione;
              data_dic := v_dw_acc.ogg.prtr_dic_data;
              data_inizio := v_dw_acc.ogg.inizio_occupazione;
              data_fine := v_dw_acc.ogg.fine_occupazione;
              data_conc := v_dw_acc.ogg.data_concessione;
              dConsistenza := v_dw_acc.ogg.consistenza;
              dQuantita := v_dw_acc.ogg.quantita;
              dTrib := v_dw_acc.ogg.tributo;
              dCate := v_dw_acc.ogg.categoria;
              dTipo_Tari := v_dw_acc.ogg.tipo_tariffa;
              dPercPoss := v_dw_acc.ogg.perc_possesso;
              BEGIN
                CALCOLO_ACCERTAMENTO_TOSAP(sOccupazione, ianno, dTrib,
                                           dCate, dTipo_Tari,dConsistenza, dQuantita,
                                           data_inizio, data_fine, dPercPoss, dImposta);
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Calcolo Accertamento TOSAP');
              END;

          END CASE;
        end if; -- ins/upd Oggetti Contribuente
        --
        if p_esiste_dic and w_check_acc = 0 Then
          --
          -- Se esiste il dichiarato si inserisce l'oggetto_imposta della dichiarazione
          --
          dImpostaDen := 0;
          --
          CASE w_titr
            WHEN 'ICI' THEN
              dImpostaDen := nvl(wf_impden_anno(w_titr, ianno),0);
              -- Per ottenere un 'imposta corretta, viene rieseguito il Calcolo del Dichiarato
              -- con la Routine standard che tratta tutte le pratiche del contribuente.
              BEGIN
                CALCOLO_IMPOSTA_ICI(ianno, w_cf, p_utente,'N');
              EXCEPTION
                WHEN others THEN
                  raise_application_error(-20999,'Errore in Ricalcolo Imposta ICI');
              END;

            WHEN 'TARSU' THEN
              dImpostaDen := nvl(wf_impden_anno_tarsu(ianno, dMaggiorazioneTaresDen,
                                  sDettaglioOgimDen, dAddEcaDen, dMaggEcaDen, dAddProvDen, dIvaDen),0);

            WHEN 'ICIAP' THEN
              w_check := uf_exists_scare(ianno);
              if w_check <= 0  then
                  raise_application_error(-20999,'Mancano i Redditi di Riferimento per l''anno'||ianno);
                w_check := -1;
              else
                w_check := uf_exists_clasu(ianno, dSettore);
                if w_check <= 0  then
                  raise_application_error(-20999,'Mancano le Classi di Superficie per l''anno '||ianno);
                  w_check := -1;
                else
                  dImpostaDen := nvl(wf_impden_anno(w_titr, ianno),0);
                end if;
              end if;

            WHEN 'ICP' THEN
              dImpostaDen := nvl(wf_impden_anno(w_titr, ianno),0);

            WHEN 'TOSAP' THEN
              dImpostaDen := nvl(wf_impden_anno(w_titr, ianno),0);

          END CASE;
          --
          -- Siccome per l' ICI viene rieseguito il Calcolo Imposta dul Dichiarato
          -- per l 'anno in esame, le seguenti istruzioni sarebbero superflue
          --
          if w_titr <> ' ICI ' then
            w_check := 0;
          else
            if uf_exists_ogim(w_cf, iAnno, num_OgPrDic) = 0 then
              w_check := uf_insert_ogim(num_OgPrDic, w_cf, ianno,
                                        dImpostaDen, null, null, null, null, null, p_utente, 'S', null, w_titr,
                                        dMaggiorazioneTaresDen, sDettaglioOgimDen, dAddEcaDen,
                                        dMaggEcaDen, dAddProvDen, dIvaDen);
            else
              dImpostaDen := uf_prendi_imposta_denuncia(w_cf, iAnno, num_OgPrDic);
              w_check := 0;
            end if;
          end if;
        else -- Non esiste il dichiarato
          dImpostaDen := null;
        end if;
        --
        if w_check = 0 and w_check_acc = 0 Then
          -- Si inserisce l' oggetto_imposta dell 'accertamento
          dOgim_vec := v_dw_acc.ogg.oggetto_imposta;
          --
          num_ogim := null;
          oggetti_imposta_nr(num_ogim);
          --
          -- S.Fazio 10/05/2001 Per risolvere il problema BO1309 si è inserita la riga seguente
          --
          if dImpostaDen = 0 and w_titr <> 'ICI' Then
            dImpostaDen := null;
          end if;
          --
          if w_titr = 'ICI' then
            if dTipo_Ali is null then
              dAliq_Acc := null;
        --  else
          --  select aliq.aliquota
          --    into dAliq_Acc
          --    from aliquote aliq
          --   where aliq.tipo_aliquota = dtipo_ali
          --     and aliq.anno          = iAnno
          --  ;
          --  if SQLCA.SQLCODE <> 0 then
          --    --Si riprova con l' aliquota base
          --    dTipo_ali := 1;
          --    select aliq.aliquota
          --      into dAliq_Acc
          --      from aliquote aliq
          --     where aliq.tipo_aliquota = dtipo_ali
          --       and aliq.anno = iAnno
          --    ;
          --    if SQLCA.SQLCODE <> 0 then
          --      f_mbx_error( "E" , "Errore in Recupero Aliquota Base ICI per anno " +to_char(iAnno),SQLCA.SQLERRTEXT)
          --      Return SQLCA.SQLCODE
          --    end if;
          --  end if;
            end if;
            --
            BEGIN
              INSERT
                INTO OGGETTI_IMPOSTA
                     (OGGETTO_IMPOSTA, COD_FISCALE,ANNO, OGGETTO_PRATICA,IMPOSTA, IMPOSTA_ACCONTO,
                     IMPOSTA_DOVUTA, IMPOSTA_DOVUTA_ACCONTO, IMPORTO_VERSATO, TIPO_ALIQUOTA,
                     ALIQUOTA, RUOLO,IMPORTO_RUOLO, FLAG_CALCOLO, UTENTE, NOTE )
              SELECT num_ogim, ogim.COD_FISCALE, ianno, num_ogpr, dImposta, dImposta_prec,
                     dImpostaDen, null, ogim.IMPORTO_VERSATO, dtipo_ali, dAliquota,
                     ogim.RUOLO, ogim.IMPORTO_RUOLO, ogim.FLAG_CALCOLO, p_utente, ogim.NOTE
                FROM OGGETTI_IMPOSTA OGIM
               where ogim.oggetto_imposta = dOgim_vec
              ;
            EXCEPTION
              WHEN others THEN
                raise_application_error(-20999,'Errore in Inserimento Oggetto Imposta ICI');
            END;
          ELSE  -- tipo tributo <> ICI
            w_check := uf_update_ogim(w_titr, num_ogim, dOgim_vec,
                                    num_ogpr, ianno, dImposta, dImpostaDen, null ,p_utente, dMaggiorazioneTares,
                                    sDettaglioOgim, dAddEca, dMaggEca, dAddProv, dIva);
            --
            IF w_titr = 'TARSU' THEN
              IF uf_insert_faog_from_string(num_ogim, sStringaFamiliari,sDettaglioOgim,sDettaglioOgimBase) < 0 THEN
                  w_check := -1;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        -- Si calcolano le Sanzioni dell 'accertamento
        --
        if p_sanz > 0 Then
          --
          -- Sono state calcolate le sanzioni nell' accertamento iniziale
          --
          inte_dal := null;
          inte_al := null;
          --
          if p_data_inizio is not null then
            w_len := length(p_data_inizio);
            w_ptr := iConta_Anno * 8;
            if w_len > w_ptr then
              w_data_int := substr(p_data_inizio, w_ptr + 1, 8);
              inte_dal := to_date(w_data_int,'YYYYMMdd');
            end if;
          end if;
          --
          if p_data_fine is not null then
            w_len := length(p_data_fine);
            w_ptr := iConta_Anno * 8;
            if w_len > w_ptr then
              w_data_int := substr(p_data_fine, w_ptr + 1, 8);
              inte_al := to_date(w_data_int,'YYYYMMdd');
            end if;
          end if;
          --
        --dbms_output.put_line('Int. Dal: '||inte_dal||', Al: '||inte_al);
          --
          IF w_check = 0 AND w_check_acc = 0 THEN
            BEGIN
              SELECT OGIM_ACC.IMPOSTA,
                     OGIM_ACC.IMPOSTA_ACCONTO,
                     OGIM_ACC.OGGETTO_PRATICA,
                     decode(prtr_acc.tipo_tributo,
                            'TARSU',
                            nvl(f_round(f_imposta_cont_anno_titr(OGIM_ACC.cod_fiscale,iAnno,'TARSU',
                                            nvl(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_DIC.OGGETTO_PRATICA)
                                            ,nvl(COTR_DIC.conto_corrente,nvl(TITR.CONTO_CORRENTE,0))),1),0)
                            -
                            nvl(f_round(f_sgravio_ogge_cont_anno(OGIM_ACC.cod_fiscale,iAnno,'TARSU',
                                                                             OGPR_DIC.OGGETTO_PRATICA),1),0)
                            ,OGIM_ACC.IMPOSTA_DOVUTA),
                     OGIM_ACC.IMPOSTA_DOVUTA_ACCONTO,
                     OGIM_ACC.IMPORTO_VERSATO,
                     OGCO_ACC.MESI_POSSESSO,
                     OGCO_ACC.MESI_POSSESSO_1SEM,
                     PRTR_ACC.DATA,
                     OGIM_ACC.MAGGIORAZIONE_TARES
                INTO dImposta_Repl,
                     dImposta_acconto_Repl,
                     num_Ogpr_Repl,
                     dImpo_Dov_Repl,
                     dImpo_Dov_acconto_Repl,
                     dImpo_Ver_Repl,
                     dMP_Repl,
                     dMP1S_Repl,
                     Data_Acc_Repl,
                     dMaggTares_Repl
                FROM OGGETTI_CONTRIBUENTE OGCO_ACC,
                     OGGETTI_PRATICA OGPR_ACC,
                     OGGETTI_IMPOSTA OGIM_ACC,
                     PRATICHE_TRIBUTO PRTR_ACC,
                     OGGETTI_PRATICA OGPR_DIC,
                     CODICI_TRIBUTO COTR_DIC,
                     TIPI_TRIBUTO TITR
               WHERE OGIM_ACC.ANNO(+) = iAnno
                 AND OGIM_ACC.COD_FISCALE (+) = OGCO_ACC.COD_FISCALE
                 AND OGIM_ACC.OGGETTO_PRATICA (+) = OGCO_ACC.OGGETTO_PRATICA
                 AND OGCO_ACC.COD_FISCALE = w_cf
                 AND OGCO_ACC.OGGETTO_PRATICA = OGPR_ACC.OGGETTO_PRATICA
                 AND OGPR_ACC.PRATICA = PRTR_ACC.PRATICA
                 AND PRTR_ACC.PRATICA = num_prtr
                 AND PRTR_ACC.ANNO = iAnno
                 AND OGPR_DIC.OGGETTO_PRATICA (+) = OGPR_ACC.OGGETTO_PRATICA_RIF
                 AND COTR_DIC.TRIBUTO (+) = OGPR_DIC.TRIBUTO
                 AND TITR.TIPO_TRIBUTO = PRTR_ACC.TIPO_TRIBUTO
                 AND OGPR_ACC.OGGETTO_PRATICA = num_ogpr
              ;
            EXCEPTION
              WHEN others THEN
                raise_application_error(-20999,'Errore in Ricerca Dati per Sanzioni');
            END;
            --
            BEGIN
              SELECT SUM(NVL(f_round(f_magg_tares_cont_anno_titr(w_cf,iAnno,'TARSU',
                                     nvl(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_DIC.OGGETTO_PRATICA)
                      ,nvl(COTR_DIC.conto_corrente,nvl(TITR.CONTO_CORRENTE,0))),1), 0)
                      - NVL(ROUND(F_SGRAVIO_OGIM(w_cf,iAnno,PRTR_ACC.TIPO_TRIBUTO,OGPR_DIC.oggetto_pratica,
                                                OGIM_DIC.oggetto_imposta,'S' ,'maggiorazione_tares' ),2),0))
                INTO dMaggTares_Dov_Repl
                FROM OGGETTI_CONTRIBUENTE OGCO_ACC,
                     OGGETTI_PRATICA OGPR_ACC,
                     OGGETTI_IMPOSTA OGIM_DIC,
                     PRATICHE_TRIBUTO PRTR_ACC,
                     OGGETTI_PRATICA OGPR_DIC,
                     CODICI_TRIBUTO COTR_DIC,
                     TIPI_TRIBUTO TITR
               WHERE OGIM_DIC.ANNO(+) = iAnno
                 AND OGIM_DIC.COD_FISCALE (+) = OGCO_ACC.COD_FISCALE
                 AND OGIM_DIC.OGGETTO_PRATICA (+) = OGCO_ACC.OGGETTO_PRATICA
                 AND OGCO_ACC.COD_FISCALE = w_cf
                 AND OGCO_ACC.OGGETTO_PRATICA = OGPR_ACC.OGGETTO_PRATICA
                 AND OGPR_ACC.PRATICA = PRTR_ACC.PRATICA
                 AND PRTR_ACC.PRATICA = num_prtr
                 AND PRTR_ACC.ANNO = iAnno
                 AND OGPR_DIC.OGGETTO_PRATICA (+) = OGPR_ACC.OGGETTO_PRATICA_RIF
                 AND COTR_DIC.TRIBUTO (+) = OGPR_DIC.TRIBUTO
                 AND TITR.TIPO_TRIBUTO = PRTR_ACC.TIPO_TRIBUTO
                 AND OGPR_ACC.OGGETTO_PRATICA = num_ogpr
              ;
            EXCEPTION
              WHEN others THEN
                raise_application_error(-20999,'Errore in Ricerca Magg. TARES dovuta per Sanzioni');
            END;
            --
            CASE w_titr
              WHEN 'ICI' THEN
                data_acc := nvl(v_dw_acc.ogg.prtr_dic_data,sysdate());
                dImpo_dov := v_dw_acc.ogg.imposta_dovuta;
                dImpo_ver := v_dw_acc.ogg.versato;
                dMP1S := v_dw_acc.ogg.mesi_possesso_1sem;
                BEGIN
                  CALCOLO_SANZIONI_ICI(ianno, data_acc_Repl, dImpo_dov_Repl,dImpo_dov_acconto_Repl,
                                       p_mesi_dic, p_flag_poss_dic, dImpo_ver_Repl, dImposta_Repl,
                                       dImposta_acconto_Repl, dMP_Repl, dMP1S_Repl, num_prtr,
                                       num_ogpr_Repl, 'S', p_utente);
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Calcolo Sanzioni ICI');
                END;

              WHEN 'ICIAP' THEN
                data_acc := nvl(v_dw_acc.ogg.prtr_dic_data,sysdate());
                dImpo_dov := v_dw_acc.ogg.imposta_dovuta;
                dImpo_ver := v_dw_acc.ogg.versato;
                BEGIN
                  CALCOLO_SANZIONI_ICIAP(ianno, data_acc_repl, num_prtr, num_ogpr_repl,
                                         dImposta_Repl , dImpo_dov_repl, dImpo_ver_repl, 'S', p_utente);
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Calcolo Sanzioni ICIAP');
                END;

              WHEN 'ICP' THEN
                dScad_vers := uf_max_scad_titr_anno('ICP',data_inizio, 'N');
                IF dScad_vers is null THEN
                    w_check := 0;
                ELSE
                  -- MESSAGEBOX( "CALCOLO SANZIONI ICP" ,
                  -- "Codice Fiscale " +nvl(w_cf, "null" )+ "~nAnno " + nvl(to_char(iAnno), "null" )+
                  -- "~nPratica " + nvl(to_char(num_prtr), "null" )+
                  -- "~nOgpr Repl " + nvl(to_char(num_ogpr_repl), "null" )+
                  -- "~nImposta Repl " + nvl(to_char(dImposta_Repl), "null" )+
                  -- "~nAnno Dich " + nvl(to_char(p_anno_dic), "null" )+
                  -- "~nData Acc Repl " + nvl(to_char(date(data_acc_repl), "dd/mm/yyyy" ), "null" )+
                  -- "~nImp Dovuta Repl " + nvl(to_char(dImpo_dov_repl), "null" )+
                  -- "~nImp Versato Repl " + nvl(to_char(dImpo_Ver_Repl), "null" )+
                  -- "~nNuovo Sanz S~nUtente " +g_connect.utente+
                  -- "~nInteressi Dal " + nvl(to_char(date(inte_dal), "dd/mm/yyyy" ), "null" )+
                  -- " Al " + nvl(to_char(date(inte_al), "dd/mm/yyyy" ), "null" ))
                  BEGIN
                    CALCOLO_SANZIONI_ICP(w_cf, iAnno, num_prtr, num_ogpr_repl, dImposta_Repl,
                                          p_anno_dic, data_acc_repl, dImpo_dov_Repl, dImpo_ver_Repl,
                                          'S', p_utente, inte_dal, inte_al,'S');
                  EXCEPTION
                    WHEN others THEN
                      raise_application_error(-20999,'Errore in Calcolo Sanzioni ICP');
                  END;
                END IF;

              WHEN 'TARSU' THEN
                -- MESSAGEBOX( "PRAT TRIB " , "SQLCA.CALCOLO_SANZIONI_TARSU(w_cf " +w_cf+
                -- ",iAnno " +to_char(iAnno)+ ", num_prtr " +to_char(nvl(num_prtr,0))+ ", num_ogpr_repl " +to_char(nvl(num_ogpr_repl,0))+
                -- ", dImposta_repl " +to_char(nvl(dImposta_repl,0))+
                -- ", p_anno_dic " +to_char(nvl(p_anno_dic,0))+
                -- ", data_acc_repl " + nvl(to_char(data_acc_repl), 'NULL' )+
                -- ", dImpo_dov_repl " +to_char(nvl(dImpo_dov_repl,0))+ ", 'S'" +
                -- ", p_tardiva_denuncia " + nvl(p_tardiva_denuncia, ' ' )+
                -- ", g_connect.utente " +g_connect.utente+
                -- ", inte_dal " + nvl(to_char(inte_dal), 'NULL' )+
                -- ", inte_al " + nvl(to_char(inte_al), 'NULL' )+
                -- ", dMaggTares_repl " +to_char(nvl(dMaggTares_repl,0))+
                -- ", dMaggTares_dov_repl " +to_char(nvl(dMaggTares_dov_repl,0))+ ")" )
                BEGIN
                  CALCOLO_SANZIONI_TARSU(w_cf,iAnno, num_prtr, num_ogpr_repl, dImposta_repl,
                                          p_anno_dic, data_acc_repl, dImpo_dov_repl,
                                          'S', p_tardiva_denuncia, p_utente, inte_dal, inte_al,
                                          dMaggTares_repl, dMaggTares_dov_repl);
                EXCEPTION
                  WHEN others THEN
                    raise_application_error(-20999,'Errore in Calcolo Sanzioni TARSU');
                END;

              WHEN 'TOSAP' THEN
                IF data_conc is null THEN
                  dScad_vers := uf_max_scad_titr_anno('TOSAP', data_inizio,'N');
                ELSE
                  dScad_vers := uf_max_scad_titr_anno('TOSAP', data_conc,'S');
                END IF;
                --
                IF dScad_vers is null THEN
                  w_check := 0;
                ELSE
                  BEGIN
                    CALCOLO_SANZIONI_TOSAP(w_cf, iAnno, num_prtr, num_ogpr_repl, dImposta_repl,
                                          p_anno_dic, data_dic, data_acc_repl, dImpo_dov_repl, dImpo_ver_repl,
                                          'S', p_utente, inte_dal, inte_al, 'S');
                  EXCEPTION
                    WHEN others THEN
                      raise_application_error(-20999,'Errore in Calcolo Sanzioni TOSAP');
                  END;
                END IF;

            END CASE;
            --
--            IF f_mbx_sqldberror() <> 0 THEN
IF w_check <> 0 THEN
              w_check := 0;
            ELSE
              IF p_sanz > 100 THEN
                -- Nuovo Sanzionamento
                sanz := NUOVO_SANZ;
              ELSE
                -- Vecchio Sanzionamento
                -- Se la replica va a cavallo del 1999, il sanzionamento sarà quello
                -- vecchio fino al 1998, e quello nuovo dal 1999 in poi.
                IF ianno < 1998 THEN
                  sanz := VECCHIO_SANZ;
                ELSE
                  sanz := NUOVO_SANZ;
                END IF;
              END IF;
              --
              w_check := uf_delete_sapr(num_prtr, sanz);
            END IF;
          END IF;  -- Ok su ins/upd di oggetti contribuente e p_esiste_dic = TRUE
        END IF;  -- p_sanz > 0

        END LOOP;      -- Loop RIOG oggetto per anno : FINE
      END IF; -- Non esistenza di altro accertamento per l'anno in trattamento : FINE

        --
      END LOOP; -- Loop Oggetti Multipli : FINE
      --
      if w_check <> 0 and w_check <> -9999 then
        exit;
      end if;
    ELSE                                           -- Saltato l' anno da cui si replica
      num_prtr := 0;
    END IF;
    --
    if p_pratiche_acc is null then
      select sPratiche_Acc||lpad(to_char(num_prtr),10,'0')
        into sPratiche_Acc
        from dual
      ;
    end if;
  END LOOP;
  --
  IF w_check <> 0 AND w_check <> -9999 THEN        -- I -9999 vengono annullati direttamente
      RollBack;
      raise_application_error(SQLCODE,SQLERRM);
  ELSE
      Commit;
      p_pratiche_acc := sPratiche_Acc;
  END IF;

  p_pratiche_generate := p_pratiche_acc;

  RETURN;

EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      if SQLCODE = -20999 then
        RAISE_APPLICATION_ERROR(SQLCODE,SQLERRM);
      else
        RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
      end if;
END;
/* End Procedure: REPLICA_ACCERTAMENTO */
/

