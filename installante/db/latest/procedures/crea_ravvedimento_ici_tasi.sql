--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_ravvedimento_ici_tasi stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure         CREA_RAVVEDIMENTO_ICI_TASI
/***************************************************************************
  NOME:        CREA_RAVVEDIMENTO_ICI_TASI
  DESCRIZIONE: Crea una pratica di ravvedimento ICI/IMU o TASI partendo
               dagli oggetti dichiarati e/o accertati.
               Richiamata dalla procedure CREA_RAVVEDIMENTO.
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  021   20/12/2024  AB      #76723
                            sistemato il parametro di f_get_data_inizio_da_mese e
                            f_get_data_fine_da_mese per l'anno di ogco
  020   04/12/2024  AB      #76723
                            gestiti per bene i vari periodi nel corso dell'anno
                            sistemata la ricerca del valore, mesi_possesso,
                            mesi_possesso_1sem,, da_mese_possesso e detrazione
  019   24/07/2024  RV      #72159
                            Aggiunta gestione RIOG
  018   05/02/2024  AB      #69241
                            Commentata la seconda valorizzazione del w_vlore non andava bene per i riog
  017   22/01/2024  AB      #69241
                            Determinazione corretta del valore, usciva null se non avevano dei riog
                            sistemato recuperandolo dalla dichiarazione
  016   04/01/2024  AB      #69241
                            Determinazione corretta del valore
  015   23/02/2023  AB      Issue #62651
                            Aggiunta la eliminazione sanzioni per deceduti
  014   16/09/2022  VD      Corretta valorizzazione campo TIPO_RAVVEDIMENTO
                            in tabella PRATICHE_TRIBUTO: se il flag infrazione
                            passato come parametro e' "O", il tipo ravvedimento
                            e' "D", altrimenti e' null (e non viceversa).
  013   04/05/2022  VD      Aggiunta memorizzazione data versamento in nuovo
                            campo data_scadenza di pratiche_tributo.
                            La data della pratica viene sempre valorizzata
                            con la data di sistema.
  012   21/10/2021  VD      Aggiunto controllo sequenza tipi ravvedimento
                            - se tipo_versamento = 'A' non deve esistere un
                            altro ravvedimento unico
                            - se tipo_versamento = 'S' non deve esistere un
                            altro ravvedimento unico
                            - se tipo_versamento = 'U' non deve esistere un
                            altro ravvedimento in acconto o a saldo
                            La presenza di un altro ravvedimento dello stesso
                            tipo di quello che si sta creando e' gia' controllata
                            nella query successiva.
  011   12/10/2021  VD      Modificato richiamo procedures CALCOLO_IMPOSTA...
                            per gestire la presenza di ravvedimento in acconto
                            e ravvedimento a saldo.
  010   07/06/2021  VD      Modificata gestione data pratice in inserimento
                            tabella PRATICHE_TRIBUTO: ora viene inserita la più
                            piccolata tra la data di versamento e la data di
                            sistema.
                            Lo stesso valore viene utilizzato come parametro
                            nel richiamo della procedure NUMERA_PRATICHE.
  009   27/05/2021  VD      Modificata gestione data pratica su tabella
                            PRATICHE_TRIBUTO: ora viene sempre inserita la data
                            di sistema (e non la data di versamento che potrebbe
                            essere > della data di sistema e causare un errore
                            nel trigger della tabella).
  008   28/09/2020  VD      Aggiunta gestione per aggiornamento immobili: se la
                            pratica viene passata come parametro, si eliminano
                            oggetti_imposta, oggetti_pratica , e sanzioni_pratica.
  007   26/08/2020  VD      Aggiunto parametro per identificare da dove e'
                            chiamata la procedure: se e' nullo, viene chiamata
                            da TributiWeb altrimenti da TR4.
  006   24/08/2020  VD      Corretto tipo_evento in inserimento pratiche_tributo:
                            ora riporta il tipo versamento (e non "U" fisso)
  005   05/05/2020  VD      Aggiunti codici sanzione relativi a ravvedimento
                            lungo nel test di esistenza della pratica di
                            ravvedimento.
  004   09/03/2020  VD      Gestione nuova tipologia di scadenza per
                            ravvedimento (tipo_scadenza = 'R')
  003   25/07/2018  VD      Si elimina la pratica creata se non contiene
                            sanzioni.
  002   27/10/2017  VD      Modificato controllo di esistenza pratica: aggiunte
                            nuove sanzioni nell'elenco dei codici controllati
  001   13/04/2015  VD      Aggiunta valorizzazione tipo_tributo in inserimento
                            CONTATTI_CONTRIBUENTE
  000   01/12/2008  --      Prima emissione
***************************************************************************/
(a_cod_fiscale      IN  VARCHAR2
,a_anno             IN  NUMBER
,a_data_versamento  IN  DATE
,a_tipo_versamento  IN  VARCHAR2
,a_flag_infrazione  IN  VARCHAR2
,a_utente           IN  VARCHAR2
,a_tipo_tributo     IN  varchar2
,a_pratica          IN OUT NUMBER
,a_provenienza      IN  varchar2 default null
) IS
 CURSOR sel_ogge (p_anno        number
                 ,p_cod_fiscale varchar2
                 ) IS
  SELECT
      ogpo.*,
      case when ogpo.flag_possesso_pogr = 'S' then
        case when (nvl(ogpo.mesi_possesso,12) + nvl(ogpo.da_mese_possesso,1) - 1) != 12 then
          null
        else
          ogpo.flag_possesso_pogr
        end
      else
        ogpo.flag_possesso_pogr
      end flag_possesso
  FROM (
    SELECT OGGE.OGGETTO,
           OGPR.OGGETTO_PRATICA   oggetto_pratica_rif,
           OGGE.COD_VIA,
           OGGE.NUM_CIV,
           OGGE.SUFFISSO,
           OGGE.INTERNO,
           OGGE.INDIRIZZO_LOCALITA,
           ARVI.DENOM_UFF,
           OGGE.SEZIONE,
           OGGE.FOGLIO,
           OGGE.NUMERO,
           OGGE.SUBALTERNO,
           OGGE.ZONA,
           OGGE.PARTITA,
           OGGE.PROTOCOLLO_CATASTO,
           OGGE.ANNO_CATASTO,
  --       OGPR.TIPO_OGGETTO,
           pogr.TIPO_OGGETTO,
  --       F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'CA') categoria_catasto,
  --       F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'CL') classe_catasto,
           nvl(F_GET_RIOG_DATA(pogr.oggetto,pogr.inizio_validita,'CA',null),pogr.categoria_catasto) as categoria_catasto,
           nvl(F_GET_RIOG_DATA(pogr.oggetto,pogr.inizio_validita,'CL',null),pogr.classe_catasto) as classe_catasto,
  --       nvl(f_valore_da_rendita(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'RE'),nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),
  --                           p_anno,F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'CA'),ogpr.imm_storico)
  --          ,f_valore(ogpr.valore, nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto), prtr.anno, p_anno, ogpr.categoria_catasto, prtr.tipo_pratica, ogpr.flag_valore_rivalutato))
  --            VALORE,
-- AB 2/12/2024
--           nvl(f_valore_da_rendita(f_get_rendita_riog(pogr.oggetto,null,pogr.inizio_validita),
--                                   nvl(pogr.tipo_oggetto,ogge.tipo_oggetto),p_anno,
--                                   nvl(F_GET_RIOG_DATA(pogr.oggetto,pogr.inizio_validita,'CA',null),pogr.categoria_catasto),
--                                   pogr.imm_storico)
--              ,f_valore(ogpr.valore,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),prtr.anno,p_anno,
--                                    nvl(F_GET_RIOG_DATA(pogr.oggetto,pogr.inizio_validita,'CA',null),pogr.categoria_catasto),
--                                    prtr.tipo_pratica,ogpr.flag_valore_rivalutato))
--                VALORE,
--
-- AB 2/12/2024 nuovo valore preso come esempio da ogca
           decode(f_rendita_data_riog(ogge.oggetto
                                     ,pogr.inizio_validita
                                     )
                 ,null, f_valore(pogr.valore
                                ,nvl(pogr.tipo_oggetto, ogpr.tipo_oggetto)
                                ,pogr.anno
                                ,p_anno
                                ,nvl(pogr.categoria_catasto
                                    ,ogge.categoria_catasto
                                    )
                                ,pogr.tipo_pratica
                                ,'S'
                                )
                 ,f_valore_da_rendita(f_rendita_data_riog(ogge.oggetto
                                     ,pogr.inizio_validita
                                     )
                                     ,nvl(pogr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,p_anno
                                     ,nvl(pogr.categoria_catasto
                                         ,ogge.categoria_catasto
                                         )
                                     ,pogr.imm_storico
                                     )
                 )  valore,
--
  -- AB 22/01/2024 commentato perche non usciva il valore se non riog
  --         f_valore_da_rendita(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'RE'),nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),
  --                             p_anno,F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'CA'),ogpr.imm_storico) VALORE,
  -- AB 04/01/2024 commentato perchè non rivalutava
  --         nvl((to_number(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'RE')) *
  --              decode(OGGE.TIPO_OGGETTO
  --                    ,1,nvl(molt.moltiplicatore,1)
  --                    ,3,nvl(molt.moltiplicatore,1)
  --                      ,1
  --                    )
  --             ),OGPR.VALORE
  --            ) VALORE,
  --       OGCO.PERC_POSSESSO,
           pogr.perc_possesso,
  --       decode(prtr.anno,p_anno,OGCO.MESI_POSSESSO,12) mesi_possesso,
  --       decode(prtr.anno,p_anno,OGCO.MESI_POSSESSO_1SEM,6) mesi_possesso_1sem,
                greatest(pogr.inizio_validita,
                                            f_get_data_inizio_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso))) pogr_get_da_mese,
--
               f_get_mesi_possesso(a_tipo_tributo,
                                   pogr.cod_fiscale,
                                   p_anno,
                                   pogr.oggetto,
                                   greatest(pogr.inizio_validita,
                                            f_get_data_inizio_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso))),
                                   least(pogr.fine_validita,
                                         f_get_data_fine_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                                  nvl(ogog.mesi_possesso,12)),
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso), --20/12/2024 AB aggiunta la decode per anno per prendere i dati di ogco
                                                                  ogog.da_mese_possesso)))) mesi_possesso,
               f_get_mesi_possesso_1sem(greatest(pogr.inizio_validita,
                                                 f_get_data_inizio_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso))),
                                        least(pogr.fine_validita,
                                              f_get_data_fine_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                                  nvl(ogog.mesi_possesso,12)),
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso), --20/12/2024 AB aggiunta la decode per anno per prendere i dati di ogco
                                                                  ogog.da_mese_possesso)))) mesi_possesso_1sem,
               --       decode(prtr.anno,p_anno,ogco.da_mese_possesso,1) da_mese_possesso,
               f_titolo_da_mese_possesso('A',
                                         greatest(pogr.inizio_validita,
                                                  f_get_data_inizio_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso)))) da_mese_possesso,
/* AB 2/12/2024 sostituito
           f_get_mesi_possesso(a_tipo_tributo,pogr.cod_fiscale,p_anno,pogr.oggetto
                              ,greatest(pogr.inizio_validita,f_get_data_inizio_da_mese(p_anno,ogog.da_mese_possesso))
                              ,least(pogr.fine_validita,f_get_data_fine_da_mese(p_anno,ogog.mesi_possesso,ogog.da_mese_possesso))
                              ) mesi_possesso,
           f_get_mesi_possesso_1sem(greatest(pogr.inizio_validita,f_get_data_inizio_da_mese(p_anno,ogog.da_mese_possesso))
                                  ,least(pogr.fine_validita,f_get_data_fine_da_mese(p_anno,ogog.mesi_possesso,ogog.da_mese_possesso))
                              ) mesi_possesso_1sem,
  --       decode(prtr.anno,p_anno,ogco.da_mese_possesso,1) da_mese_possesso,
           f_titolo_da_mese_possesso('A',greatest(pogr.inizio_validita,f_get_data_inizio_da_mese(p_anno,ogog.da_mese_possesso))
                              ) da_mese_possesso,
*/
  --       OGCO.MESI_ESCLUSIONE,
  --       OGCO.MESI_RIDUZIONE,
           case when pogr.anno < p_anno then null else pogr.mesi_esclusione end mesi_esclusione,
           case when pogr.anno < p_anno then null else pogr.mesi_riduzione end mesi_riduzione,
  --       OGCO.FLAG_POSSESSO,
           pogr.flag_possesso as flag_possesso_pogr,
  --       OGCO.FLAG_ESCLUSIONE,
  --       OGCO.FLAG_RIDUZIONE,
  --       OGCO.FLAG_AB_PRINCIPALE,
           pogr.flag_esclusione,
           pogr.flag_riduzione,
           pogr.flag_ab_principale,
           OGPR.FLAG_PROVVISORIO,
           decode( OGGE.COD_VIA, NULL, INDIRIZZO_LOCALITA, DENOM_UFF||decode( num_civ,NULL,'', ', '||num_civ )
                  ||decode( suffisso,NULL,'', '/'||suffisso )) indirizzo,
--
           decode(PRTR.TIPO_TRIBUTO,
                  'ICI',
                  f_detrazione_raop_ici(OGCO.DETRAZIONE,
                                        --OGCO.MESI_POSSESSO,
                                        f_get_mesi_possesso(a_tipo_tributo,
                                                            pogr.cod_fiscale,
                                                            p_anno,
                                                            pogr.oggetto,
                                                            greatest(pogr.inizio_validita,
                                                                     f_get_data_inizio_da_mese(p_anno,
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso))),
                                                            least(pogr.fine_validita,
                                                                  f_get_data_fine_da_mese(p_anno,
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                                                                      nvl(ogog.mesi_possesso,12)),
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso), --20/12/2024 AB aggiunta la decode per anno per prendere i dati di ogco
                                                                                                      ogog.da_mese_possesso)))),
                                        PRTR.ANNO,
                                        p_anno),
                  f_detrazione_raop_tasi(OGCO.DETRAZIONE,
                                         -- OGCO.MESI_POSSESSO,
                                         f_get_mesi_possesso(a_tipo_tributo,
                                                             pogr.cod_fiscale,
                                                             p_anno,
                                                             pogr.oggetto,
                                                             greatest(pogr.inizio_validita,
                                                                     f_get_data_inizio_da_mese(p_anno,
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso))),
                                                            least(pogr.fine_validita,
                                                                  f_get_data_fine_da_mese(p_anno,
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                                                                      nvl(ogog.mesi_possesso,12)),
                                                                                               decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso), --20/12/2024 AB aggiunta la decode per anno per prendere i dati di ogco
                                                                                                      ogog.da_mese_possesso)))),
                                         PRTR.ANNO,
                                         p_anno)) detrazione,
--
/*
           decode(PRTR.TIPO_TRIBUTO,'ICI'
                  ,f_detrazione_raop_ici(OGCO.DETRAZIONE,
                  --OGCO.MESI_POSSESSO,
                            f_get_mesi_possesso(a_tipo_tributo,pogr.cod_fiscale,p_anno,pogr.oggetto
                              ,greatest(pogr.inizio_validita,f_get_data_inizio_da_mese(p_anno,ogog.da_mese_possesso))
                              ,least(pogr.fine_validita,f_get_data_fine_da_mese(p_anno,ogog.mesi_possesso,ogog.da_mese_possesso))
                            ),
                            PRTR.ANNO,p_anno)
                  ,f_detrazione_raop_tasi(OGCO.DETRAZIONE,
                  -- OGCO.MESI_POSSESSO,
                            f_get_mesi_possesso(a_tipo_tributo,pogr.cod_fiscale,p_anno,pogr.oggetto
                              ,greatest(pogr.inizio_validita,f_get_data_inizio_da_mese(p_anno,ogog.da_mese_possesso))
                              ,least(pogr.fine_validita,f_get_data_fine_da_mese(p_anno,ogog.mesi_possesso,ogog.da_mese_possesso))
                            ),
                            PRTR.ANNO,p_anno)
                  ) detrazione,
*/
           PRTR.ANNO anno_dic,
  --       ogpr.imm_storico,
           pogr.imm_storico,
           ogpr.oggetto_pratica_rif_ap,
           prtr.tipo_pratica,
  --       ogpr.FLAG_VALORE_RIVALUTATO,
           pogr.flag_valore_rivalutato,
           ogim.tipo_rapporto,
  --       decode(prtr.anno,p_anno,ogco.mesi_occupato,to_number(null)) mesi_occupato,
  --       decode(prtr.anno,p_anno,ogco.mesi_occupato_1sem,to_number(null)) mesi_occupato_1sem
           decode(prtr.anno,p_anno,pogr.mesi_occupato,to_number(null)) mesi_occupato,
           decode(prtr.anno,p_anno,pogr.mesi_occupato_1sem,to_number(null)) mesi_occupato_1sem,
        -- Questo flag ci serve per evitare forzature sui mesi_possesso quando anno_dichiarazione <> anno_calcolo
           case when extract(year from POGR.INIZIO_VALIDITA) = p_anno OR
                     extract(year from POGR.FINE_VALIDITA) = p_anno then
             'S'
           else
             null
           end flag_riog_anno,
           to_char(ROWNUM) as num_ordine
      FROM ARCHIVIO_VIE ARVI,
           OGGETTI OGGE,
           MOLTIPLICATORI MOLT,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_PRATICA OGPR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI_IMPOSTA OGIM,
           PERIODI_OGCO_RIOG POGR,
           OGGETTI_OGIM OGOG
     WHERE ogge.cod_via         = arvi.cod_via (+) and
           OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA and
           MOLT.ANNO(+)         = p_anno AND
           MOLT.CATEGORIA_CATASTO(+)  = F_MAX_RIOG(OGPR.OGGETTO_PRATICA,p_anno,'CA') AND
           OGPR.PRATICA               = PRTR.PRATICA and
  --       PRTR.PRATICA_RIF   is null and
           PRTR.TIPO_PRATICA  in ('D','A') AND
           OGPR.OGGETTO          = OGGE.OGGETTO and
           OGCO.OGGETTO_PRATICA  = OGIM.OGGETTO_PRATICA and
           OGCO.COD_FISCALE      = p_cod_fiscale and
           PRTR.TIPO_TRIBUTO||'' = a_tipo_tributo and
           OGIM.ANNO             = p_anno and
           OGIM.COD_FISCALE      = p_cod_fiscale and
           OGIM.FLAG_CALCOLO     = 'S' and
           --
           POGR.COD_FISCALE     = p_cod_fiscale and
           POGR.TIPO_TRIBUTO    = a_tipo_tributo and
           POGR.OGGETTO         = OGGE.OGGETTO and
--           POGR.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA and   20/12/2024 AB avevo aggiunto anche questa condizione, è molto forte seppur qui immagino corretta
--                                                             poi l'ho tolta perchè ho sistemato il controllo sulla data_inizio_validita che non era corretto per l'anno di ogco
--                                                             Mi resta il dubbio per anni successivi dove potrebbe non esserci ogog
           POGR.INIZIO_VALIDITA <= TO_DATE('3112'||p_anno,'ddmmyyyy') and
           POGR.FINE_VALIDITA >= TO_DATE('0101'||p_anno,'ddmmyyyy') and
           POGR.INIZIO_VALIDITA <= f_get_data_fine_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                                  nvl(ogog.mesi_possesso,12)),
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso), --20/12/2024 AB aggiunta la decode per anno per prendere i dati di ogco
                                                                  ogog.da_mese_possesso)) and
           POGR.FINE_VALIDITA >= f_get_data_inizio_da_mese(p_anno,
                                                           decode(p_anno,ogco.anno,nvl(ogog.da_mese_possesso,ogco.da_mese_possesso),
                                                                  ogog.da_mese_possesso)) and
           --
/* AB 02/12/2024 sostituito questo controllo
           POGR.INIZIO_VALIDITA <= f_get_data_fine_da_mese(p_anno,
                                                           nvl(ogog.mesi_possesso,ogco.mesi_possesso),
                                                           nvl(ogog.da_mese_possesso,ogco.da_mese_possesso)) and
           POGR.FINE_VALIDITA >= f_get_data_inizio_da_mese(p_anno,
                                                           nvl(ogog.da_mese_possesso,ogco.da_mese_possesso)) and
*/           --
           OGIM.OGGETTO_PRATICA = OGOG.OGGETTO_PRATICA (+) and
           OGIM.ANNO = OGOG.ANNO (+)  and
           OGIM.COD_FISCALE = OGOG.COD_FISCALE (+)
      ORDER BY
            OGGE.OGGETTO ASC,
            POGR.INIZIO_VALIDITA ASC
           ) OGPO
    ;
w_errore                       varchar(2000) := NULL;
errore                         exception;
w_denuncia                     number;
w_anno_scadenza                number;
w_comune                       varchar2(6);
w_delta_anni                   number;
w_scadenza                     date;
w_scadenza_acc                 date;
w_scadenza_present             date;
w_scadenza_pres_aa             date;
w_scadenza_pres_rav            date;
w_conta_ravv                   number;
w_conta_ogim                   number;
w_oggetto_pratica              number      := NULL;
w_valore                       number(15,2);
w_mesi_possesso                number;
w_da_mese_possesso                number;
w_mesi_possesso_1sem           number;
w_mesi_riduzione               number;
w_mesi_esclusione              number;
w_numera                       varchar2(2000);
w_conta_sanzioni               number;
w_stato_sogg                   number(2);
FUNCTION F_DATA_SCAD
(a_anno           IN     number
,a_tipo_vers      IN     varchar2
,a_tipo_scad      IN     varchar2
,a_data_scadenza  IN OUT date
) return string
IS
w_err               varchar2(2000);
w_data              date;
BEGIN
   w_err := null;
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_tributo    = a_tipo_tributo
         and scad.anno            = a_anno
         and nvl(scad.tipo_versamento,' ')
                                  = nvl(a_tipo_vers,' ')
         and scad.tipo_scadenza   = a_tipo_scad
      ;
      a_data_scadenza := w_data;
      Return w_err;
   EXCEPTION
      when no_data_found then
         if a_tipo_scad = 'V' then
            w_err := 'Scadenza di pagamento '||f_descrizione_titr(a_tipo_tributo,a_anno)||' ';
            if a_tipo_vers = 'A' then
               w_err := w_err||'in acconto';
            elsif a_tipo_vers = 'S' then
               w_err := w_err||'a saldo';
            else
               w_err := w_err||'unico';
            end if;
            w_err := w_err||' non prevista per anno '||to_char(a_anno);
         else
            w_err := 'Scadenza di presentazione denuncia '||a_tipo_tributo||' non prevista per anno '||
                     to_char(a_anno);
         end if;
         Return w_err;
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
END F_DATA_SCAD;
BEGIN
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into w_comune
        from dati_generali
           ;
   END;
   w_anno_scadenza := to_number(to_char(a_data_versamento,'yyyy'));
 -------------------------------------------------------------------------
 -- Controlli prima della creazione---------------------------------------
 -------------------------------------------------------------------------
 --DBMS_OUTPUT.Put_Line('1 - Controlli prima della creazione');
 --DBMS_OUTPUT.Put_Line('2 - Controllo dell''anno della pratica');
   -- (VD - 28/09/2020): i seguenti controlli vengono eseguiti solo nel
   --                    caso di creazione di una nuova pratica
   -- Controllo dell'anno della pratica
   if a_pratica is null then
      if a_anno < 1998 then
         w_errore  := 'Gestione Non Prevista per Anni con Vecchio sanzionamento';
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('3 - Controllo di esistenza di dichiarazioni precedenti');
         -- Controllo di esistenza di dichiarazioni precedenti
         BEGIN
           select max(1)
             into w_denuncia
             from pratiche_tributo prtr
                , rapporti_tributo ratr
            where prtr.pratica       = ratr.pratica
              and ratr.cod_fiscale   = a_cod_fiscale
              and prtr.tipo_pratica in ('D','A')
              and decode(prtr.tipo_pratica,'D','S',prtr.flag_denuncia) = 'S'
              and nvl(prtr.stato_accertamento,'D') = 'D'
              and prtr.tipo_tributo||'' = a_tipo_tributo
              and prtr.anno         <= a_anno
                ;
         EXCEPTION
             WHEN OTHERS THEN
                 w_denuncia := 0;
         END;
         if nvl(w_denuncia,0) = 0 then
            a_pratica := null;
            w_errore  := '4 - Non esistono dichiarazioni precedenti ('||a_cod_fiscale||')';
         end if;
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('5 - Correttivo per Scadenze (personalizzazioni)');
         -- Correttivo per Scadenze (personalizzazioni).
         w_delta_anni := 0;
         -- Lumezzane.
         if w_comune = '017096' then
            w_delta_anni := 1;
         end if;
         w_errore := F_DATA_SCAD(a_anno + w_delta_anni,null,'D',w_scadenza_present);
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('6 - Determinazione delle scadenze');
         w_scadenza_pres_aa := w_scadenza_present;
         w_errore := F_DATA_SCAD(a_anno,'A','V',w_scadenza_acc);
      end if;
      -- (VD - 13/10/2021): Aggiunto controllo su data ravvedimento rispetto
      --                    a data scadenza versamento in acconto
      if w_errore is null then
         if a_tipo_versamento = 'A' and
            a_data_versamento <= w_scadenza_acc then
            w_errore := 'La data del ravvedimento ('||to_char(a_data_versamento,'dd/mm/yyyy')||
                        ') è inferiore alla data di scadenza del versamento in acconto ('||
                        to_char(w_scadenza_acc,'dd/mm/yyyy')||') - Ravvedimento non possibile';
         end if;
      end if;
      if w_errore is null then
         w_errore := F_DATA_SCAD(a_anno,'S','V',w_scadenza);
      end if;
      -- (VD - 13/10/2021): Aggiunto controllo su data ravvedimento rispetto
      --                    a data scadenza versamento a saldo
      if w_errore is null then
         if a_tipo_versamento = 'S' and
            a_data_versamento <= w_scadenza then
            w_errore := 'La data del ravvedimento ('||to_char(a_data_versamento,'dd/mm/yyyy')||
                        ') è inferiore alla data di scadenza del versamento a saldo ('||
                        to_char(w_scadenza,'dd/mm/yyyy')||') - Ravvedimento non possibile';
         end if;
      end if;
--dbms_output.put_line('Scadenze - Pres. '||to_char(w_scadenza_present,'dd/mm/yyyy')||' Acc. '||
--to_char(w_scadenza_acc,'dd/mm/yyyy')||' Sal. '||to_char(w_scadenza,'dd/mm/yyyy')||' delta '||
--to_char(w_delta_anni));
--
-- In questo test  si fa riferimento  con quanto concordato  con San Lazzaro  che a sua volta
-- fa riferimento alla circolare applicativa  184/E del 2001  in cui si dice che se nell`anno
-- del ravvedimento esistono denunce  dell`anno stesso con data  della pratica > alla data di
-- scadenza registrata  nei parametri  di input, la data di scadenza  entro cui ravvedersi e`
-- la data di scadenza  della presentazione  della denuncia  dell`anno successivo, altrimenti
-- e` la data di scadenza dell`anno del ravvedimento  in quanto trattasi di omesso o parziale
-- o tardivo pagamento a fronte di una denuncia senza alcuna variazione.
-- La circolare  in particolare  recita  "bisogna assumere  il termine di presentazione della
-- dichiarazione e non l`altro di un anno dall`omissione o dall`errore"  poiche` il regime di
-- autotassazione in materia di ICI e` analogo a quello previsto  per le imposte erariali sui
-- redditi.
-- Dall`indicatore  a_flag_infrazione  si sa se si e` in un caso o in un altro  poiche` viene
-- settato  solo in presenza  di denunce nell`anno con data superiore alla data di scadenza e
-- in questi casi puo` assumere solo i valore I = Infedele oppure O = Omessa.
-- In definitiva, se questo flag e` nullo non si aggiunge un anno alla data di scadenza della
-- presentazione della denuncia.
-- (VD - 09/03/2020): si seleziona la nuova tipologia di scadenza 'R'
--
      if w_errore is null then
         if a_flag_infrazione is null then
            w_errore := F_DATA_SCAD(a_anno + w_delta_anni,null,'R',w_scadenza_pres_rav);
         else
            w_errore := F_DATA_SCAD(a_anno + w_delta_anni + 1,null,'R',w_scadenza_pres_rav);
         end if;
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('7 - La Data del Ravvedimento e` > alla Scadenza per Ravvedersi');
         if a_data_versamento > w_scadenza_pres_rav then
            w_errore := 'La Data del Ravvedimento '||to_char(a_data_versamento,'dd/mm/yyyy')||
                     ' e` > della Scadenza per Ravvedersi '||to_char(w_scadenza_pres_rav,'dd/mm/yyyy') ||
                     '('||a_cod_fiscale||')';
         end if;
      end if;
      -- (VD - 21/10/2021): Aggiunto controllo su sequenza ravvedimenti.
      --                    Non e' possibile creare un ravvedimento "unico"
      --                    o un ravvedimento in acconto se è gia' presente
      --                    un ravvedimento in acconto per l'anno
      if w_errore is null then
         BEGIN
            select count(*)
              into w_conta_ravv
              from pratiche_tributo prtr
             where prtr.cod_fiscale                  = a_cod_fiscale
               and prtr.anno                         = a_anno
               and prtr.tipo_tributo||''             = a_tipo_tributo
               and nvl(prtr.stato_accertamento,'D')  ='D'
               and prtr.tipo_pratica                 = 'V'
               and ((a_tipo_versamento = 'A' and prtr.tipo_evento = 'U') or
                    (a_tipo_versamento = 'S' and prtr.tipo_evento = 'U') or
                    (a_tipo_versamento = 'U' and prtr.tipo_evento in ('A','S'))
                   )
                  ;
            if w_conta_ravv > 0 then
               w_errore := 'Tipo versamento indicato non compatibile con ravvedimento gia'' presente ('||a_cod_fiscale||')';
            end if;
         END;
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('8 - Esistono altre Pratiche di Ravvedimento per questo Pagamento');
         BEGIN
            select count(*)
              into w_conta_ravv
              from sanzioni_pratica sapr
                  ,pratiche_tributo prtr
             where sapr.pratica                      = prtr.pratica
               and prtr.cod_fiscale                  = a_cod_fiscale
               and prtr.anno                         = a_anno
               and prtr.tipo_tributo||''             = a_tipo_tributo
               and nvl(prtr.stato_accertamento,'D')  ='D'
               and prtr.tipo_pratica                 = 'V'
               --
               -- (VD - 27/10/2017): aggiunti nuovi codici sanzione
               -- (VD - 05/05/2020): aggiunti nuovi codici sanzione (ravv.lungo)
               --
               and (    a_tipo_versamento            = 'A'
                    and sapr.cod_sanzione           in (151,152,155,157,158,165,166) --(151,152,155)
                    or  a_tipo_versamento            = 'S'
                    and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                        511,512,513,514)     --(153,154,156)
                    or  a_tipo_versamento            = 'U'
                    and sapr.cod_sanzione           in (151,152,153,154,155,165,166,
                                                        156,157,158,159,160,167,168,
                                                        511,512,513,514)     --(151,152,153,154,155,156)
                   )
                  ;
            if w_conta_ravv > 0 then
               w_errore := 'Esistono altre Pratiche di Ravvedimento per questo Pagamento ('||a_cod_fiscale||')';
            end if;
         END;
      end if;
      if w_errore is null then
         -----------------------------------------------------------------------------------------------
         -- verifica dell'imposta--------------------------------------------------------------------
         -----------------------------------------------------------------------------------------------
         --DBMS_OUTPUT.Put_Line('10b - Verifica dell''imposta');
         if a_tipo_tributo = 'ICI' then
            CALCOLO_IMPOSTA_ICI(a_anno, a_cod_fiscale ,a_utente, 'N');
         elsif a_tipo_tributo = 'TASI' then
            CALCOLO_IMPOSTA_TASI(a_anno, a_cod_fiscale ,a_utente, 'N');
         else
            w_errore := 'Tipo Tributo non gestito ('||a_tipo_tributo||')';
         end if;
         if w_errore is null then
            select count (1)
              into w_conta_ogim
              from oggetti_imposta  ogim
                 , oggetti_pratica  ogpr
                 , pratiche_tributo prtr
             where OGIM.ANNO             = a_anno
               and OGIM.COD_FISCALE      = a_cod_fiscale
               and OGIM.FLAG_CALCOLO     = 'S'
               and ogim.oggetto_pratica  = ogpr.oggetto_pratica
               and ogpr.pratica          = prtr.pratica
               and prtr.tipo_tributo||'' = a_tipo_tributo
                 ;
               if w_conta_ogim = 0 then
                  w_errore := 'Il contribuente '||a_cod_fiscale||' non ha oggetti '||a_tipo_tributo||' validi per l''anno '||to_char(a_anno);
               end if;
         end if;
      end if;
      if w_errore is null then
         -----------------------------------------------------------------------------------------------
         -- Insermento della pratica--------------------------------------------------------------------
         -----------------------------------------------------------------------------------------------
         --DBMS_OUTPUT.Put_Line('11 - Insermento della pratica');
         a_pratica := null;
         PRATICHE_TRIBUTO_NR(a_pratica);
         begin
            Insert into PRATICHE_TRIBUTO
                ( PRATICA
                , COD_FISCALE
                , TIPO_TRIBUTO
                , ANNO
                , TIPO_PRATICA
                , TIPO_EVENTO
                , DATA
                , UTENTE
                , DATA_VARIAZIONE
                , TIPO_RAVVEDIMENTO
                , DATA_SCADENZA
                , DATA_RIF_RAVVEDIMENTO
                )
            Values
                ( a_pratica
                , a_cod_fiscale
                , a_tipo_tributo
                , a_anno
                , 'V'
                , a_tipo_versamento
                , trunc(sysdate)
                , a_utente
                , trunc(sysdate)
                , decode(a_flag_infrazione,'O','D',a_flag_infrazione)
                , a_data_versamento
                , a_data_versamento
                )
                ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Errore in inserimento pratica per '||a_cod_fiscale;
                   raise errore;
         end;
         begin
            Insert into RAPPORTI_TRIBUTO
                ( PRATICA
                , COD_FISCALE
                , TIPO_RAPPORTO)
            Values
                ( a_pratica
                , a_cod_fiscale
                , NULL)
                ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Errore in inserimento ratr per '||a_cod_fiscale;
                   raise errore;
         end;
         begin
            Insert into contatti_contribuente
                ( cod_fiscale
                , data
                , numero
                , anno
                , tipo_contatto
                , tipo_richiedente
                , testo
                , tipo_tributo)
            Values
                ( a_cod_fiscale
                , trunc(sysdate)
                , NULL
                , a_anno
                , 10
                , 2
                , NULL
                , a_tipo_tributo)
                ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Errore in inserimento coco per '||a_cod_fiscale;
                   raise errore;
         end;
      end if;
      if w_errore is not null then
         raise ERRORE;
      end if;
   end if;
   -- (VD - 28/09/2020): In caso di aggiornamento immobili, si eliminano
   --                    oggetti_imposta, oggetti_pratica e sanzioni_pratica
   if a_pratica is not null then
      begin
        delete sanzioni_pratica
         where pratica = a_pratica;
        delete from aliquote_ogco alog
         where (alog.cod_fiscale,alog.oggetto_pratica) in
               (select prtr.cod_fiscale, ogpr.oggetto_pratica
                  from pratiche_tributo prtr,
                       oggetti_pratica  ogpr
                 where prtr.pratica = a_pratica
                   and prtr.pratica = ogpr.pratica);
        delete from detrazioni_ogco deog
         where (deog.cod_fiscale,deog.oggetto_pratica) in
               (select prtr.cod_fiscale, ogpr.oggetto_pratica
                  from pratiche_tributo prtr,
                       oggetti_pratica  ogpr
                 where prtr.pratica = a_pratica
                   and prtr.pratica = ogpr.pratica);
        delete oggetti_imposta
         where oggetto_pratica in (select oggetto_pratica from oggetti_pratica
                                    where pratica = a_pratica);
        delete oggetti_pratica
         where pratica = a_pratica;
      EXCEPTION
          WHEN OTHERS THEN
                w_errore := 'Errore in eliminazione dati pratica '||a_cod_fiscale;
                raise errore;
      end;
   end if;
   if w_errore is null then
      ----------------------------------------------------
      --- Inserimento degli oggetti-----------------------
      ----------------------------------------------------
      FOR rec_ogge in sel_ogge(a_anno,a_cod_fiscale)
      LOOP
         --DBMS_OUTPUT.Put_Line('12 - Inserimento Oggetto_Pratica');
         -- Inserimento Oggetto_Pratica
--         if rec_ogge.oggetto = 255333
--         and rec_ogge.mesi_possesso = 9 then
--             w_errore := 'Qui passa con mesi 3';
--                   raise errore;
--         end if;
         w_oggetto_pratica:= null;
         OGGETTI_PRATICA_NR(w_oggetto_pratica);
         w_valore := rec_ogge.valore;
--       AB 05/02/2024 commenatata questa rivalutazione perchè faccio tutto nella select
--       facendolo qui non andava bene nel caso di riog perchè l'anno_dic non era corretto per i riog
/*
         w_valore := nvl(f_valore(rec_ogge.valore
                                 ,rec_ogge.tipo_oggetto
                                 ,rec_ogge.anno_dic
                                 ,a_anno
                                 ,rec_ogge.categoria_catasto
                                 ,rec_ogge.tipo_pratica
                                 ,rec_ogge.FLAG_VALORE_RIVALUTATO
                                 )
                        ,0);
*/
         begin
            Insert into OGGETTI_PRATICA
              ( OGGETTO_PRATICA, OGGETTO, PRATICA
              , ANNO, IMM_STORICO, CATEGORIA_CATASTO
              , CLASSE_CATASTO, VALORE, FLAG_PROVVISORIO
              , OGGETTO_PRATICA_RIF, UTENTE, DATA_VARIAZIONE
              , OGGETTO_PRATICA_RIF_AP, NOTE, TIPO_OGGETTO
              , NUM_ORDINE)
            Values
              ( w_oggetto_pratica, rec_ogge.oggetto, a_pratica
              , a_anno, rec_ogge.imm_storico, rec_ogge.categoria_catasto
              , rec_ogge.classe_catasto, w_valore, rec_ogge.flag_provvisorio
              , rec_ogge.oggetto_pratica_rif, a_utente, trunc(sysdate)
              , rec_ogge.oggetto_pratica_rif_ap
              , decode(a_provenienza, null, 'Ravvedimento Manuale',
                                            'Ravvedimento Automatico'), rec_ogge.tipo_oggetto
              , rec_ogge.num_ordine
              )
            ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Errore in inserimento oggetto_pratica per '||a_cod_fiscale
                               ||' '||to_char(nvl(w_oggetto_pratica,0))||' '||to_char(nvl(a_pratica,0));
                   raise errore;
         end;
         -- 27/06/2014 SC Att.     Ravvedimento: pertinenza di
         --      DBMS_OUTPUT.Put_Line('12a - Aggiornemento Oggetto_Pratica - Aggiornamento ogpr_rif_ap ');
         -- Inserimento Oggetto_Pratica - Aggiornamento ogpr_rif_ap
         --         if rec_ogge.oggetto_pratica_rif_ap is not null then
         --            AGGIORNAMENTO_OGPR_RIF_AP(w_oggetto_pratica, rec_ogge.oggetto_pratica_rif_ap);
         --         end if;
         --DBMS_OUTPUT.Put_Line('13 - Inserimento Oggetto_Contribuente');
         -- Inserimento Oggetto_Contribuente
/* AB 3/12/2024 i valori dei mesi_possesso e mesi_1_sem sono gia determinati correttamente nella select
         if rec_ogge.anno_dic <> a_anno
            and rec_ogge.flag_riog_anno is null then
            w_mesi_possesso      := 12;
            w_da_mese_possesso   := 1;
            w_mesi_possesso_1sem := 6;
            if rec_ogge.flag_riduzione = 'S' then
               w_mesi_riduzione := 12;
            else
               w_mesi_riduzione := null;
            end if;
            if rec_ogge.flag_esclusione = 'S' then
               w_mesi_esclusione := 12;
            else
               w_mesi_esclusione := null;
            end if;
         else
*/
            w_mesi_possesso      := nvl(rec_ogge.mesi_possesso,12);
            w_da_mese_possesso   := rec_ogge.da_mese_possesso;
            w_mesi_possesso_1sem := rec_ogge.mesi_possesso_1sem;
            w_mesi_riduzione     := rec_ogge.mesi_riduzione;
            w_mesi_esclusione    := rec_ogge.mesi_esclusione;
--         end if;
         begin
             insert into OGGETTI_CONTRIBUENTE
               ( COD_FISCALE, OGGETTO_PRATICA, ANNO
               , TIPO_RAPPORTO, PERC_POSSESSO, MESI_POSSESSO
               , MESI_POSSESSO_1SEM, MESI_ESCLUSIONE, MESI_RIDUZIONE
               , DETRAZIONE , FLAG_POSSESSO, FLAG_ESCLUSIONE
               , FLAG_RIDUZIONE, FLAG_AB_PRINCIPALE, UTENTE
               , TIPO_RAPPORTO_K, MESI_OCCUPATO, MESI_OCCUPATO_1SEM
               , DA_MESE_POSSESSO )
             values
               ( a_cod_fiscale, w_oggetto_pratica, a_anno
               , NULL, rec_ogge.perc_possesso, w_mesi_possesso
               , w_mesi_possesso_1sem, w_mesi_esclusione, w_mesi_riduzione
               , rec_ogge.detrazione, rec_ogge.flag_possesso, rec_ogge.flag_esclusione
               , rec_ogge.flag_riduzione, rec_ogge.flag_ab_principale, a_utente
               , rec_ogge.tipo_rapporto, rec_ogge.mesi_occupato, rec_ogge.mesi_occupato_1sem
               , w_da_mese_possesso )
                ;
         EXCEPTION
             WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento oggetto_contribuente per '||a_cod_fiscale;
                   raise errore;
         end;
         --DBMS_OUTPUT.Put_Line('14 - Inserimento Detrazioni_Oggetto');
         -- Inserimento Detrazioni_Oggetto
         begin
             insert into DETRAZIONI_OGCO
                   ( COD_FISCALE, OGGETTO_PRATICA, ANNO, MOTIVO_DETRAZIONE
                   , DETRAZIONE, NOTE, DETRAZIONE_ACCONTO, tipo_tributo)
              select cod_fiscale, w_oggetto_pratica, anno, motivo_detrazione
                   , detrazione, note, detrazione_acconto, tipo_tributo
                from detrazioni_ogco
               where cod_fiscale     = a_cod_fiscale
                 and anno            = a_anno
                 and oggetto_pratica = rec_ogge.oggetto_pratica_rif
                 and tipo_tributo    = a_tipo_tributo
                   ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Errore in inserimento detrazioni_OGCO per '||a_cod_fiscale;
                   raise errore;
         end;
         --DBMS_OUTPUT.Put_Line('15 - Inserimento Aliquote_Oggetto');
         -- Inserimento Aliquote_Oggetto
         INSERIMENTO_ALOG_RAVV(a_cod_fiscale, rec_ogge.oggetto_pratica_rif, w_oggetto_pratica, a_tipo_tributo);
         --DBMS_OUTPUT.Put_Line('16 - Inserimento Oggetto_Imposta');
         -- Inserimento Oggetto_Imposta
         begin
            insert into OGGETTI_IMPOSTA
                  ( COD_FISCALE, OGGETTO_PRATICA, ANNO
                  , IMPOSTA, IMPOSTA_ACCONTO, IMPOSTA_DOVUTA
                  , IMPOSTA_DOVUTA_ACCONTO, DETRAZIONE, DETRAZIONE_ACCONTO
                  , FLAG_CALCOLO, UTENTE, NOTE, TIPO_TRIBUTO, TIPO_RAPPORTO )
           values ( a_cod_fiscale, w_oggetto_pratica, a_anno
                  , 0, NULL, NULL
                  , NULL, NULL, NULL
                  , NULL, a_utente, NULL, a_tipo_tributo, rec_ogge.tipo_rapporto )
                  ;
         EXCEPTION
            WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento oggetto imposta per '||a_cod_fiscale;
                  raise errore;
         end;
      END LOOP;
      -- 27/06/2014 SC Att.     Ravvedimento: pertinenza di
      -- Inserimento Oggetto_Pratica - Aggiornamento ogpr_rif_ap
      --DBMS_OUTPUT.Put_Line('17 - Aggiornamento Oggetto_Pratica - Aggiornamento ogpr_rif_ap dopo loop');
      FOR C_OGPR IN (select oggetto_pratica, oggetto_pratica_rif_ap
                       from oggetti_pratica
                      where pratica = a_pratica) LOOP
          if c_ogpr.oggetto_pratica_rif_ap is not null then
             AGGIORNAMENTO_OGPR_RIF_AP(c_ogpr.oggetto_pratica, c_ogpr.oggetto_pratica_rif_ap);
          end if;
      END LOOP;
   -------------------------------------------------------------------------
   ---Calcoli---------------------------------------------------------------
   -------------------------------------------------------------------------
      --DBMS_OUTPUT.Put_Line('21 - Calcolo Imposta');
      -- Calcolo Imposta
      if a_tipo_tributo = 'ICI' then
         CALCOLO_IMPOSTA_ICI(a_anno, a_cod_fiscale ,a_utente, 'S', a_tipo_versamento);
      else
         CALCOLO_IMPOSTA_TASI(a_anno, a_cod_fiscale ,a_utente, 'S', a_tipo_versamento);
      end if;
      --DBMS_OUTPUT.Put_Line('22 - Calcolo Sanzioni');
      -- Calcolo Sanzioni
      if a_tipo_tributo = 'ICI' then
         CALCOLO_SANZIONI_RAOP_ICI(a_pratica, a_tipo_versamento, a_data_versamento, a_utente, a_flag_infrazione);
      else
         CALCOLO_SANZIONI_RAOP_TASI(a_pratica, a_tipo_versamento, a_data_versamento, a_utente, a_flag_infrazione);
      end if;
   end if;
   --
   -- (VD - 25/07/2018): se la pratica appena inserita non contiene sanzioni
   --                    viene cancellata, non si esegue la numerazione e si
   --                    restituisce null
   --
   begin
     select count(*)
       into w_conta_sanzioni
       from sanzioni_pratica
      where pratica = a_pratica
      group by pratica;
   exception
     when others then
       w_conta_sanzioni := 0;
   end;
   --
   if w_conta_sanzioni = 0 then
      -- (VD - 13/10/2021): prima di eliminare la pratica si eliminano
      --                    eventuali aliquote_ogco e detrazioni_ogco
      delete from aliquote_ogco alog
       where (alog.cod_fiscale,alog.oggetto_pratica) in
             (select prtr.cod_fiscale, ogpr.oggetto_pratica
                from pratiche_tributo prtr,
                     oggetti_pratica  ogpr
               where prtr.pratica = a_pratica
                 and prtr.pratica = ogpr.pratica);
      delete from detrazioni_ogco deog
       where (deog.cod_fiscale,deog.oggetto_pratica) in
             (select prtr.cod_fiscale, ogpr.oggetto_pratica
                from pratiche_tributo prtr,
                     oggetti_pratica  ogpr
               where prtr.pratica = a_pratica
                 and prtr.pratica = ogpr.pratica);
      begin
        delete from pratiche_tributo
         where pratica = a_pratica;
      exception
        when others then
          w_errore := substr('Eliminazione pratica ravv. priva di sanzioni per '||a_cod_fiscale||
                      ' ('||sqlerrm||')',1,2000);
          raise errore;
      end;
      a_pratica := to_number(null);
   else
      -- Numerazione pratica
      begin
        select valore
          into w_numera
          from installazione_parametri
         where parametro = 'N_AUTO_RAV'
        ;
      EXCEPTION
        WHEN OTHERS THEN
           w_numera := 'N';
      end;
      if w_numera = 'S' then
         numera_pratiche( a_tipo_tributo, 'V', null, a_cod_fiscale, a_anno, a_anno
                        , least(trunc(sysdate),a_data_versamento)
                        , least(trunc(sysdate),a_data_versamento));
      end if;
        -- (AB - 23/02/2023): se il contribuente è deceduto, si eliminano
        --                    le sanzioni lasciando solo imposta evasa,
        --                    interessi e spese di notifica
       BEGIN
          select stato
            into w_stato_sogg
            from soggetti sogg, contribuenti cont
           where sogg.ni = cont.ni
             and cont.cod_fiscale = a_cod_fiscale
          ;
       EXCEPTION
          WHEN others THEN
             w_errore := 'Errore in ricerca SOGGETTI '||SQLERRM;
             RAISE errore;
       END;
       if w_stato_sogg = 50 then
          ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
       end if;
   end if;
   if w_errore is not null then
      a_pratica := null;
      raise errore;
   end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CREA_RAVVEDIMENTO_ICI_TASI */
/
