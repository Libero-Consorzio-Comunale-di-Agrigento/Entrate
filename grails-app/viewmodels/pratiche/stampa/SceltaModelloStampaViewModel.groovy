package pratiche.stampa

import com.aspose.words.SaveFormat
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.DocumentoContribuenteDTO
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.modelli.ModelliException
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.smartpnd.SmartPndService
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window
import pratiche.stampa.filename.*

import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class SceltaModelloStampaViewModel {

    private static final Logger log = Logger.getLogger(SceltaModelloStampaViewModel.class)

    final def TITOLO_LENGTH = DocumentoContribuenteDTO.TITOLO_LENGTH

    final static String NOTIFICA_PEC_PRESENTE = "Esiste già una una comunicazione con notifica PEC."
    final static String NOTIFICA_PND_PRESENTE = "Esiste già una una comunicazione con notifica PND."
    final static String DETTAGLI_COMUNICAZIONE_MANCANTI = "Non esistono dettagli comunicazione associati"
    final static def PARAMETERS_FOR_STAMPA_MODELLO = [
            (ModelliService.TipoStampa.LETTERA_GENERICA)  : [
                    'MODELLO',
                    'salvaDocumentoContribuente',
                    'nomeFile',
                    'TIPO_TRIBUTO',
                    'CF',
                    'TIPO',
                    'NI',
                    'FORMAT'
            ],
            (ModelliService.TipoStampa.PRATICA)           : [
                    'MODELLO',
                    'salvaDocumentoContribuente',
                    'nomeFile',
                    'TIPO_TRIBUTO',
                    'CF',
                    'allegaF24',
                    'allegaAvvisoAgID',
                    'TIPO',
                    'PRATICA',
                    'ridotto',
                    'VETT_PRAT',
                    'MODELLO_RIMB',
                    'TITOLO',
                    'FORMAT',
                    'niErede'
            ],
            (ModelliService.TipoStampa.ISTANZA_RATEAZIONE): [
                    'MODELLO',
                    'salvaDocumentoContribuente',
                    'nomeFile',
                    'TIPO_TRIBUTO',
                    'CF',
                    'allegaF24',
                    'allegaAvvisoAgID',
                    'PRATICA',
                    'ridotto',
                    'tipoF24',
                    'allegaPianoRateizzazione',
                    'FORMAT'
            ],
            (ModelliService.TipoStampa.COMUNICAZIONE)     : [
                    'MODELLO',
                    'salvaDocumentoContribuente',
                    'nomeFile',
                    'TIPO_TRIBUTO',
                    'CF',
                    'allegaF24',
                    'allegaAvvisoAgID',
                    'TIPO',
                    'PRATICA',
                    'ridotto',
                    'RUOLO',
                    'MODELLO_RIMB',
                    'ANNO',
                    'tipiF24',
                    'GRUPPO_TRIBUTO',
                    'FORMAT'
            ],
            (ModelliService.TipoStampa.SGRAVIO)           : [
                    'MODELLO',
                    'salvaDocumentoContribuente',
                    'nomeFile',
                    'TIPO_TRIBUTO',
                    'CF',
                    'allegaF24',
                    'allegaAvvisoAgID',
                    'TIPO',
                    'RUOLO',
                    'ANNO',
                    'TRIBUTO',
                    'OGGETTO',
                    'SEQUENZA',
                    'SEQUENZA_SGRAVIO',
                    'FORMAT',
                    'PRATICA',
                    'PROGR_SGRAVIO'
            ]
    ]

    Window self

    ModelliService modelliService
    DocumentaleService documentaleService
    IntegrazioneDePagService integrazioneDePagService
    SmartPndService smartPndService
    ContribuentiService contribuentiService
    ComunicazioniService comunicazioniService
    CommonService commonService
    SoggettiService soggettiService
    ComunicazioniTestiService comunicazioniTestiService

    def tipoStampa

    List<GruppoTributoDTO> listaGruppiTributo
    GruppoTributoDTO gruppoTributo

    def listaModelli
    def modelloSelezionato
    def consentiAllegati
    def invioAttivo
    def inviaDocumentale
    def listaTipoComunicazione
    def listaDettagliComunicazione = []
    def tipoComunicazioneSelezionato
    def paramsID

    def dettaglioComunicazioneSelezionato
    def tipoComunicazione
    def dePagAbilitato
    def salvaInDocumentiContribuente = false
    def allegato = "nessuno"
    def gestioneAgId = true
    def salvaDocCon = true
    def idDocumento
    def tipologia
    def tipoTributo
    def avvisiAgidPresenti = false
    def comunicazioneParametriDescrizione = ""
    def generazioneMassiva = false
    def invioMassivo = false
    def inviaTramiteMail = false
    def abilitaCheckboxDocumentale = true
    def abilitaCheckboxMail = true
    def isCuni = false
    def isCuniGruppoTributo = false
    def abilitaRidotto = false
    def ridotto = "SI"
    def smartPndAbilitato = false

    def tipoNotifica = 'NONE'
    def notificaPNDAttiva = false
    def notificaPECAttiva = false
    def notificaEmailAttiva = false
    def tassonomiaConPagamento = true

    def notificaPNDVisible = false
    def notificaPECVisible = false
    def notificaEmailVisible = false

    def destinazioneInvioLabel

    def notificaPecEsistente = false
    def notificaPndEsistente = false

    def abilitaCheckboxEredi

    def NOTIFICATION_FEE_POLICY = [
            DELIVERY_MODE: 'Destinatario',
            FLAT_RATE    : 'Fisso',
    ]

    def PHYSICAL_COM_TYPE = [
            AR_REGISTERED_LETTER : 'Raccomandata A/R',
            REGISTERED_LETTER_890: 'Lettera 890',
    ]

    def selectedNotificationFeePolicy = null
    def selectedPhysicalComType = null


    // Per la maschera nel caso di accoglimento istanza di rateizzazione
    def stampeIstTrasv = [
            "F24"               : false,
            "avvisoAgID"        : false,
            "pianoRateizzazione": false
    ]

    // NUOVI CAMPI
    def tipiF24 = [acconto: false, saldoDovuto: false, saldoVersato: false, unico: false]

    def nomeFile
    def soggetto
    def codFiscale
    def pratica
    def ruolo
    def sgravio
    def sgravioPratica
    def anno
    def isRuoloZero

    def tipologiaDocumentale

    def eredi = []
    def gestioneEredi = false
    StampaFilenameStrategy filenameStrategy

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parametri") Map parametri) {

        this.self = w

        paramsID = parametri.idDocumento

        this.nomeFile = parametri.nomeFile

        if (!parametri.tipoStampa) {
            throw new RuntimeException("Indicare un tipo di stampa")
        } else {
            this.tipoStampa = parametri.tipoStampa
        }

        if ((parametri.tipoStampa as ModelliService.TipoStampa) in
                [ModelliService.TipoStampa.PRATICA,
                 ModelliService.TipoStampa.ISTANZA_RATEAZIONE,
                 ModelliService.TipoStampa.COMUNICAZIONE
                ]
                && (parametri.idDocumento == null)) {
            throw new RuntimeException("Indicare l'id del documento")
        }

        this.smartPndAbilitato = smartPndService.smartPNDAbilitato()
        this.abilitaCheckboxMail = !this.smartPndAbilitato

        this.invioAttivo = documentaleService.documentaleAttivo() || smartPndService.smartPNDAbilitato()
        this.dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        this.generazioneMassiva = parametri.generazioneMassiva ?: false
        this.invioMassivo = parametri.invioMassivo ?: false
        if (generazioneMassiva && invioMassivo) {
            throw new IllegalArgumentException("Impossibile aprire la finestra sia in modalità 'Generazione massiva' che 'Invio massivo'")
        }
        this.inviaDocumentale = !this.invioAttivo ? false : this.generazioneMassiva ? false : this.invioMassivo

        if (tipoStampa in [ModelliService.TipoStampa.PRATICA, ModelliService.TipoStampa.ISTANZA_RATEAZIONE]) {
            this.idDocumento = parametri.idDocumento

            this.pratica = modelliService.getPratica(idDocumento)
            this.codFiscale = this.pratica.contribuente.codFiscale
            this.anno = pratica.anno

            isCuni = pratica.tipoTributo.tipoTributo == 'CUNI'

            if (tipoStampa == ModelliService.TipoStampa.PRATICA) {
                consentiAllegati = (pratica.importoTotale ?: 0) > 0
                tipologiaDocumentale = pratica.tipoPratica == 'S' ? 'T' : 'P'
                tipologia = documentaleService.recuperaTipoDocumento(idDocumento, tipologiaDocumentale)
                tipoTributo = pratica.tipoTributo.tipoTributo
                tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(pratica.id, tipologia)

            } else if (tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
                consentiAllegati = (pratica.importoTotale ?: 0) > 0
                tipologiaDocumentale = 'I'
                tipologia = documentaleService.recuperaTipoDocumento(idDocumento, tipologiaDocumentale)
                tipoTributo = 'TRASV'
                tipoComunicazione = 'RAI' // RATEAZIONE ACCOGLIMENTO ISTANZA  (DEFAULT)
            }

            determinaTipoModello(pratica)
            avvisiAgidPresenti = avvisiAgIDPresenti(pratica)
            notificaPNDAttiva = notificaPNDAbilitata(pratica)
            notificaPECAttiva = notificaPECAbilitata(pratica)
            notificaEmailAttiva = notificaEmailAbilitata(pratica)

            this.abilitaRidotto = (pratica.tipoPratica == 'A' || pratica.tipoPratica == 'L' || pratica.tipoPratica == 'S')
            getParametroImportoRidotto()
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {

            this.codFiscale = parametri.soggetto ? contribuentiService.getSoggettoContribuente(parametri.soggetto).codFiscale : null

            consentiAllegati = false
            tipologiaDocumentale = 'G'
            tipologia = documentaleService.recuperaTipoDocumento(null, tipologiaDocumentale)
            tipoTributo = 'ICI'
            avvisiAgidPresenti = false
            consentiAllegati = false

            notificaPNDAttiva = notificaPNDAbilitata(codFiscale)
            notificaPECAttiva = notificaPECAbilitata(codFiscale)
            notificaEmailAttiva = notificaEmailAbilitata(codFiscale)

            determinaTipoModello()
            tipoComunicazione = 'LGE' // LETTERA GENERICA (DEFAULT)

        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            if (parametri.idDocumento.tipoTributo == 'CUNI') {
                this.pratica = parametri.idDocumento.pratica ? modelliService.getPratica(parametri.idDocumento.pratica) : null
                this.codFiscale = this.pratica ? this.pratica.contribuente.codFiscale : parametri.idDocumento.codFiscale
            } else {
                this.codFiscale = parametri.idDocumento.codFiscale
            }

            this.codFiscale = this.pratica ? this.pratica.contribuente.codFiscale : parametri.idDocumento.codFiscale

            this.ruolo = parametri.idDocumento.ruolo ? modelliService.getRuolo(parametri.idDocumento.ruolo) : null
            this.isRuoloZero = parametri.idDocumento.ruolo == 0

            this.anno = this.ruolo?.annoRuolo ?: parametri.idDocumento.anno

            if (parametri.idDocumento.tipoTributo in ['ICP', 'TOSAP', 'CUNI', 'ICI', 'TASI']) {
                consentiAllegati = true
                tipologiaDocumentale = parametri.idDocumento.tipoTributo == 'CUNI' ? 'B' : 'C'
                tipologia = documentaleService.recuperaTipoDocumento(null, tipologiaDocumentale)
                tipoTributo = parametri.idDocumento.tipoTributo
                avvisiAgidPresenti = avvisiAgIDPresenti(parametri.idDocumento)

                isCuni = parametri.idDocumento.tipoTributo == 'CUNI'

                determinaTipoModello()
                tipoComunicazione = 'LCO' // COMUNICAZIONE DI PAGAMENTO (DEFAULT)
            } else {

                // TARSU

                this.idDocumento = parametri.idDocumento.ruolo

                Ruolo ruol = Ruolo.get(idDocumento)

                consentiAllegati = true
                tipologiaDocumentale = 'S'
                tipologia = documentaleService.recuperaTipoDocumento(null, tipologiaDocumentale)
                tipoTributo = ruol?.tipoTributo?.tipoTributo ?: parametri.tipoTributo

                determinaTipoModello()

                parametri.idDocumento.tipoTributo = tipoTributo
                avvisiAgidPresenti = avvisiAgIDPresenti(parametri.idDocumento)
                notificaPNDAttiva = notificaPNDAbilitata(parametri.idDocumento)
                tipoComunicazione = 'APA' // AVVISO DI PAGAMENTO (COMUNICAZIONE A RUOLO) (DEFAULT)
            }

            avvisiAgidPresenti = avvisiAgIDPresenti(parametri.idDocumento)
            notificaPNDAttiva = notificaPNDAbilitata(parametri.idDocumento)
            notificaPECAttiva = notificaPECAbilitata(parametri.idDocumento)
            notificaEmailAttiva = notificaEmailAbilitata(parametri.idDocumento)

        } else if (tipoStampa == ModelliService.TipoStampa.SGRAVIO) {


            this.sgravio = parametri.idDocumento.sgravio
            this.codFiscale = sgravio.codFiscale

            this.idDocumento = sgravio.ruolo

            this.ruolo = modelliService.getRuolo(idDocumento)
            this.anno = this.ruolo?.annoRuolo ?: parametri.idDocumento.anno

            consentiAllegati = false
            abilitaCheckboxMail = false
            abilitaCheckboxDocumentale = true
            avvisiAgidPresenti = false
            tipoTributo = 'TARSU'
            tipologiaDocumentale = 'T'
            tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, tipologiaDocumentale)

            determinaTipoModello()
        }
        setupFilenameStrategy()

        // 	Gruppo tributo - Solo CUNI  e solo se non Massiva
        //  Per le massive il GRUPPO_TRIBUTO lo pesca dalla elaborazione !
        if (isCuni && (tipoComunicazione == 'LCO') && (parametri.idDocumento?.codFiscale ?: '-' == '')) {
            isCuniGruppoTributo = true
        }

        listaGruppiTributo = []
        if (isCuniGruppoTributo) {
            TipoTributo tipoTributoRaw = TipoTributo.findByTipoTributo('CUNI')
            List<GruppoTributoDTO> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoRaw)?.toDTO(["tipoTributo"])
            listaGruppiTributo << new GruppoTributoDTO()
            listaGruppiTributo.addAll(gruppiTributo)
        }
        gruppoTributo = null

        this.comunicazioneParametriDescrizione = comunicazioniService.recuperaTitoloDocumento(idDocumento, tipologia, tipoTributo)

        if (!listaModelli?.empty) {
            modelloSelezionato = listaModelli[0]
            getParametroImportoRidotto()
        }

        destinazioneInvioLabel = smartPndAbilitato ? SmartPndService.TITOLO_SMART_PND : 'Documentale'

        if (generazioneMassiva || invioMassivo) {
            gestioneAgId = false
            salvaDocCon = false
            abilitaCheckboxMail = false
            abilitaCheckboxDocumentale = false
        }
        if (!generazioneMassiva && !invioMassivo) {
            this.nomeFile = filenameStrategy.generate([modelloSelezionato: modelloSelezionato]) ?: this.nomeFile
            if (notificaPNDAttiva || notificaPECAttiva) {
                verificaNotificheComunicazione(nomeFile)
            }
        }

        if (getIsVisibleComboboxListaDettagliComunicazione()) {
            caricaListaDettagliComunicazione()
            listaTipoComunicazione = listaTipoComunicazione ?: getListaTipoComunicazioneSmartPND()
        }

        if (!invioMassivo && !generazioneMassiva) {
            this.soggetto = contribuentiService.getContribuente([codFiscale: this.codFiscale]).soggetto

            this.eredi = soggettiService.getErediSoggetto(soggetto)
        }
    }

    @Command
    def onChangeModello() {

        this.nomeFile = filenameStrategy.generate([modelloSelezionato: modelloSelezionato]) ?: this.nomeFile

        if (consentiAllegati) {
            if (modelloSelezionato.flagF24) {
                allegato = 'F24'
            } else {
                if (!(modelloSelezionato.flagAvvisoAgid && avvisiAgidPresenti)) {
                    allegato = 'nessuno'
                }
            }
            BindUtils.postNotifyChange(null, null, this, "allegato")
        }

        getParametroImportoRidotto()
        dettaglioComunicazioneSelezionato = null
        onChangeListaDettagliComunicazione()

        gestioneEredi = modelloSelezionato.flagEredi == 'S'

        // TODO: fix temporanea relativa a #71152#note-85
        if (!smartPndAbilitato && !generazioneMassiva) {
            if (gestioneEredi) {
                abilitaCheckboxMail = false
                inviaTramiteMail = false
                abilitaCheckboxDocumentale = false
                inviaDocumentale = false
            } else {
                abilitaCheckboxMail = true
                abilitaCheckboxDocumentale = true
            }


            BindUtils.postNotifyChange(null, null, this, "abilitaCheckboxMail")
            BindUtils.postNotifyChange(null, null, this, "inviaTramiteMail")
            BindUtils.postNotifyChange(null, null, this, "abilitaCheckboxDocumentale")
            BindUtils.postNotifyChange(null, null, this, "inviaDocumentale")
        }

        BindUtils.postNotifyChange(null, null, this, "dettaglioComunicazioneSelezionato")
    }

    @Command
    onStampa() {

        // TODO: fix temporanea relativa a #71152#note-82
        if (gestioneEredi && tassonomiaConPagamento) {
            Clients.showNotification("La modalità eredi non è supportata per codici tassonomici con pagamento", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }

        // Generazione o invio massivo
        if (generazioneMassiva || invioMassivo) {

            if (invioMassivo) {
                comunicazioniService.aggiornaTitoloDocumento(idDocumento, tipologia, tipoTributo, comunicazioneParametriDescrizione)
            }

            def esito = rispostaElaborazioniMassive()

            if (tipoNotifica in ['PEC', 'EMAIL']) {

                stampaInviaPEC({ e ->
                    if (e.data) {
                        esito.comunicazioneTesto = e.data.comunicazioneTesto
                        esito.firma = e.data.firma
                        esito.oggetto = e.data.oggetto
                        esito.allegati = e.data.allegati
                        Events.postEvent(Events.ON_CLOSE, self.parent ?: self, esito)
                        return
                    }
                })
                return
            }

            // Notifica PND
            Events.postEvent(Events.ON_CLOSE, self, esito)
            return
        }

        try {

            if (inviaDocumentale) {
                comunicazioniService.aggiornaTitoloDocumento(idDocumento, tipologia, tipoTributo, comunicazioneParametriDescrizione)

                if (tipoNotifica == 'PND') {
                    stampaInviaPND()
                    Events.postEvent(Events.ON_CLOSE, self, null)
                } else if (tipoNotifica in ['PEC', 'EMAIL']) {
                    stampaInviaPEC({ e ->
                        Events.postEvent(Events.ON_CLOSE, self, null)
                    })
                } else {
                    stampaInvia()
                    Events.postEvent(Events.ON_CLOSE, self, null)
                }
            } else if (inviaTramiteMail) {
                stampaInviaMail({ e ->
                    Events.postEvent(Events.ON_CLOSE, self, null)
                })
            } else {
                stampaDownload()
                Events.postEvent(Events.ON_CLOSE, self, null)
            }
        } catch (Exception e) {

            if (e.cause instanceof ModelliException && e.cause?.message in ['NOC_COD_TRIBUTO', 'MOD_NOT_EXISTS', 'NO_VERSION_AVALAIBLE']) {
                Clients.showNotification(e.cause?.cause?.detailMessage ?: 'Errore generico', Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }

            if (e.message in ['NOC_COD_TRIBUTO', 'MOD_NOT_EXISTS', 'NO_VERSION_AVALAIBLE']) {
                Clients.showNotification(e.cause.detailMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }
            throw e
        }
    }

    private void stampaDownload() {
        def stampe = generaDocumenti()

        if (stampe.size() > 1) {
            def zipFile = zipDocuments(stampe.findAll { it.value.erede })
            commonService.download(nomeFile, zipFile)
        } else {
            def singleFile = stampe.entrySet().first()
            commonService.download(singleFile.key, singleFile.value.content)
        }
    }

    private def generaDocumenti() {

        def contenutoPrincipale = stampaModello()
        def filenamePrincipale = commonService.addExtension(nomeFile, contenutoPrincipale)
        def soggettoContribuentePrincipale = contribuentiService.getSoggettoContribuente(soggetto)
        def documentoPrincipale = [
                (filenamePrincipale): [
                        content   : contenutoPrincipale,
                        soggetto  : soggettoContribuentePrincipale,
                        erede     : false,
                        principale: true
                ]
        ]

        def documentiEredi = [:]
        if (gestioneEredi && tipoNotifica != 'PND') {
            documentiEredi = eredi.collectEntries { es ->
                def filenameErede = filenameStrategy.generate([
                        modelloSelezionato: modelloSelezionato,
                        numeroOrdineErede : es.numeroOrdine])
                def contentErede = stampaModello(es.soggettoErede, filenameErede)
                filenameErede = commonService.addExtension(filenameErede, contentErede)
                [
                        (filenameErede): [
                                content : contentErede,
                                soggetto: [
                                        id         : es.soggettoEredeId.id,
                                        ni         : es.soggettoEredeId.id,
                                        codFiscale : es.soggettoEredeId.codFiscale,
                                        cognomeNome: es.soggettoEredeId.cognomeNome
                                ],
                                erede   : true
                        ]
                ]
            }
        }

        def documenti

        if (inviaDocumentale && tipoNotifica == 'PND') {

            def docDeceduto
            def docEredi
            def docAgID

            if (allegato == 'agid') {
                def splitPrincipale = modelliService.separaAttoAvviso(documentoPrincipale.entrySet().first().value.content)
                docDeceduto = splitPrincipale.stampa
                docAgID = splitPrincipale.avvisoAgid

                docEredi = documentiEredi*.value*.content.collect { modelliService.separaAttoAvviso(it).stampa }
            } else {
                docDeceduto = documentoPrincipale.entrySet().first().value.content
                docEredi = documentiEredi*.value.content
            }

            documenti = [
                    (filenamePrincipale): [
                            content   : docDeceduto,
                            principale: true,
                            soggetto  : soggettoContribuentePrincipale,
                            erede     : false
                    ]
            ]

            if (docAgID && tassonomiaConPagamento) {
                documenti << [
                        ("avviso_agid_${soggettoContribuentePrincipale.codFiscale}${commonService.fileExtension(docAgID)}" as String): [
                                content          : docAgID,
                                soggetto         : soggettoContribuentePrincipale,
                                allegatoPagamento: true
                        ]
                ]
            }
        } else {
            documenti = documentoPrincipale + documentiEredi
        }

        return documenti
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCheckInviaDocumentale() {
        if (inviaDocumentale) {
            inviaTramiteMail = false

            if (smartPndAbilitato) {
                listaTipoComunicazione = listaTipoComunicazione ?: getListaTipoComunicazioneSmartPND()
                caricaListaDettagliComunicazione()
                inizializzaTipoNotifica()
            }

            BindUtils.postNotifyChange(null, null, this, "inviaTramiteMail")
        }

        if (smartPndAbilitato) {
            if (notificaPndEsistente || notificaPecEsistente) {
                Clients.showNotification(notificaPndEsistente ? NOTIFICA_PND_PRESENTE : NOTIFICA_PEC_PRESENTE,
                        Clients.NOTIFICATION_TYPE_WARNING, null, "top_center", 5000, true)
            }
        }

        BindUtils.postNotifyChange(null, null, this, "isVisibleComboboxListaDettagliComunicazione")
        BindUtils.postNotifyChange(null, null, this, "isVisibleTipoNotifica")
        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaPnd")
        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaPec")
        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaEmail")

        self.invalidate()
    }

    @Command
    def checkInvioMail() {
        if (inviaTramiteMail) {
            inviaDocumentale = false
            BindUtils.postNotifyChange(null, null, this, "inviaDocumentale")
            BindUtils.postNotifyChange(null, null, this, "isVisibleComboboxListaDettagliComunicazione")
            BindUtils.postNotifyChange(null, null, this, "isVisibleTipoNotifica")
        }
    }

    private def rispostaElaborazioniMassive() {
        def risposta = [:]
        risposta.modello = modelloSelezionato

        if (modelloSelezionato.tipoModello.tipoModello != "IST_TRASV%") {
            risposta.allegaF24 = allegato == 'F24'
            risposta.allegaAvvisoAgID = allegato == 'agid'
        } else {
            risposta.allegaF24 = stampeIstTrasv.F24
            risposta.allegaAvvisoAgID = stampeIstTrasv.avvisoAgID
            risposta.allegaPianoRateizzazione = stampeIstTrasv.pianoRateizzazione
        }

        risposta.inviaADocumentale = inviaDocumentale
        risposta.inviaASmartPnd = inviaDocumentale && smartPndAbilitato
        risposta.inviaTramiteMail = inviaTramiteMail
        risposta.notifica =
                [
                        tipoNotifica: tipoNotifica as SmartPndService.TipoNotifica,
                        oggetto     : comunicazioneParametriDescrizione
                ]

        risposta.tipiF24 = tipiF24

        risposta.ridotto = ridotto

        // L'invio a documentale effettua già il salvataggio nella DocumentiContribuente.
        // Se richieto si passa false per evitare che si effettui due volte.
        if (!inviaDocumentale) {
            risposta.salvaInDocumentiContribuente = salvaInDocumentiContribuente
        } else {
            risposta.salvaInDocumentiContribuente = false
        }

        risposta.notificationFeePolicy = selectedNotificationFeePolicy?.key
        risposta.physicalComType = selectedPhysicalComType?.key
        risposta.tipoComunicazione = tipoComunicazioneSelezionato
        risposta.dettaglioComunicazione = dettaglioComunicazioneSelezionato

        if (isCuni && tipoComunicazione == 'LCO') {
            risposta.gruppoTributo = gruppoTributo?.gruppoTributo
        }

        return risposta
    }

    private def parametriStampaModello(def soggettoErede = null, def nuovoNnomeFile = null) {

        def modelloRimborso = null
        if (tipoStampa == ModelliService.TipoStampa.PRATICA && pratica.tipoPratica != 'A') {
            modelloRimborso = pratica?.importoTotale > 0 ? modelloSelezionato.modello : null
        }

        def parametriStampaModello = [
                MODELLO                   : modelloSelezionato.modello,
                // L'invio a documentale effettua già il salvataggio nella DocumentiContribuente.
                // Se richieto si passa false per evitare che si effettui due volte.
                salvaDocumentoContribuente: (inviaDocumentale || (gestioneEredi && !eredi.empty && !soggettoErede)) ? false : salvaInDocumentiContribuente,
                nomeFile                  : nuovoNnomeFile ?: nomeFile,
                TIPO_TRIBUTO              : tipoTributo,
                FORMAT                    : inviaDocumentale || inviaTramiteMail ? SaveFormat.PDF : null,
                CF                        : codFiscale,
                TIPO                      : modelloSelezionato.tipoModello.tipoModello,
                NI                        : soggetto?.id,
                allegaF24                 : modelloSelezionato.tipoModello.tipoModello != ModelliService.TIPO_MODELLO_IST_TRASV ? allegato == 'F24' : stampeIstTrasv.F24,
                allegaAvvisoAgID          : modelloSelezionato.tipoModello.tipoModello != ModelliService.TIPO_MODELLO_IST_TRASV ? allegato == 'agid' : null,
                ridotto                   : ridotto,
                VETT_PRAT                 : pratica?.id,
                MODELLO_RIMB              : modelloRimborso,
                TITOLO                    : nuovoNnomeFile ?: nomeFile,
                tipoF24                   : 'R',
                allegaPianoRateizzazione  : modelloSelezionato.tipoModello.tipoModello != ModelliService.TIPO_MODELLO_IST_TRASV ? null : stampeIstTrasv.pianoRateizzazione,
                RUOLO                     : isRuoloZero ? -1 : ruolo?.id,
                ANNO                      : anno,
                tipiF24                   : tipiF24,
                TRIBUTO                   : sgravio?.codiceTributo,
                OGGETTO                   : sgravio?.oggetto,
                SEQUENZA                  : sgravio?.sequenza,
                SEQUENZA_SGRAVIO          : sgravio?.sequenzaSgravio,
                PROGR_SGRAVIO             : sgravio?.progrSgravio,
                niErede                   : soggettoErede?.id,
                GRUPPO_TRIBUTO            : gruppoTributo?.gruppoTributo,
        ]

        if (tipoStampa == ModelliService.TipoStampa.SGRAVIO) {
            parametriStampaModello.PRATICA = sgravio.pratica
        } else {
            parametriStampaModello.PRATICA = pratica?.id ?: -1
        }

        def parameters = PARAMETERS_FOR_STAMPA_MODELLO[tipoStampa]

        return parametriStampaModello.findAll { it.key in parameters }
    }

    private def stampaModello(def soggettoErede = null, def nuovoNomeFile = null) {
        def parametriStampaModello = parametriStampaModello(soggettoErede, nuovoNomeFile)
        return modelliService.stampaModello(parametriStampaModello)
    }

    private void stampaInviaPEC(def onClose = {}) {

        commonService.creaPopup("/messaggistica/email/notificheEmailSmartPND.zul", self, [
                destinatari           : invioMassivo ? [] : generaDocumenti(),
                tipoNotifica          : tipoNotifica,
                tipoTributo           : tipoTributo,
                tipoComunicazione     : tipoComunicazioneSelezionato,
                dettaglioComunicazione: dettaglioComunicazioneSelezionato,
                pratica               : pratica,
                ruolo                 : ruolo,
                anno                  : anno,
                tipologia             : tipologiaDocumentale,
                invioMassivo          : invioMassivo
        ], onClose)
    }

    private void stampaInviaPND() {
        def stampe = generaDocumenti()
        def esito = inviaDocumenti(stampe, gestioneEredi ? eredi.collect {
            [
                    id   : it.soggettoErede.id,
                    erede: true
            ]
        } : [:])

        if (esito.isNumber()) {
            notificaEsitoInvio("Documento inviato a ${smartPndAbilitato ? SmartPndService.TITOLO_SMART_PND : 'Documentale'}", false)
        } else {
            notificaEsitoInvio(esito, true)
        }
    }

    private void stampaInvia() {
        def documenti = generaDocumenti()
        def esito = inviaDocumenti(documenti)

        if (esito.isNumber()) {
            notificaEsitoInvio("Documento inviato a ${smartPndAbilitato ? SmartPndService.TITOLO_SMART_PND : 'Documentale'}", false)
        } else {
            notificaEsitoInvio(esito, true)
        }
    }

    private String inviaDocumenti(def fileStampa, def erediSoggetto = []) {

        def documenti = fileStampa.collect {
            [
                    nomeFile         : it.key,
                    documento        : it.value.content,
                    principale       : it.value.principale,
                    erede            : it.value.erede,
                    allegatoPagamento: it.value.allegatoPagamento
            ]
        }
        def result

        try {
            result = documentaleService.invioDocumento(
                    codFiscale,
                    idDocumento,
                    tipologiaDocumentale,
                    documenti,
                    tipoTributo,
                    anno,
                    [tipoNotifica: tipoNotifica == 'PND' ? SmartPndService.TipoNotifica.PND : SmartPndService.TipoNotifica.NONE,
                     oggetto     : comunicazioneParametriDescrizione],
                    selectedNotificationFeePolicy?.key,
                    selectedPhysicalComType?.key,
                    null,
                    tipoComunicazioneSelezionato,
                    null,
                    null,
                    null,
                    erediSoggetto
            )
        } catch (Exception e) {
            log.error("Errore", e)
        } finally {
            return result
        }

        return result

    }

    private void notificaEsitoInvio(def message, def error) {
        Clients.showNotification(
                message,
                error ? Clients.NOTIFICATION_TYPE_ERROR : Clients.NOTIFICATION_TYPE_INFO,
                self.parent,
                "before_center", 5000, true)
    }

    private stampaInviaMail(def onClose = {}) {

        commonService.creaPopup("/messaggistica/email/email.zul", self.parent, [
                codFiscale  : codFiscale,
                fileAllegato: generaDocumenti(),
                parametri   : [
                        tipoTributo      : tipoTributo,
                        tipoComunicazione: tipoComunicazione,
                        pratica          : pratica,
                        ruolo            : ruolo,
                        tipologia        : tipologiaDocumentale,
                        anno             : anno,
                ]
        ], onClose)
    }

    private determinaTipoModello(def domainObj = null) {

        def listaTipiModello = []
        if (tipoStampa == ModelliService.TipoStampa.PRATICA) {

            listaTipiModello = modelliService.selectTipiModello(
                    tipoTributo,
                    domainObj.tipoPratica,
                    domainObj.tipoEvento.tipoEventoDenuncia,
                    (domainObj.importoTotale ?: 0) < 0)

            if (listaTipiModello.empty) {
                listaTipiModello = modelliService.selectTipiModello(
                        tipoTributo,
                        domainObj.tipoPratica,
                        null,
                        (domainObj.importoTotale ?: 0) < 0)
            }

        } else if (tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            listaTipiModello = modelliService.selectTipiModello(
                    tipoTributo,
                    null,
                    null,
                    false,
                    ModelliService.TIPO_MODELLO_IST_TRASV)
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {
            listaTipiModello = modelliService.selectTipiModello(tipoTributo)
                    .findAll { it.tipoModello == 'GEN%' }
        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            listaTipiModello = modelliService.selectTipiModello(
                    tipoTributo,
                    null,
                    null,
                    false,
                    "COM_")
        } else if (tipoStampa == ModelliService.TipoStampa.SGRAVIO) {
            listaTipiModello = modelliService.selectTipiModello(
                    tipoTributo,
                    null,
                    null,
                    false,
                    ModelliService.TIPO_MODELLO_SGRAVIO)
        }

        listaModelli = modelliService.listaModelli(listaTipiModello.collect { it.tipoModello })
    }

    private def avvisiAgIDPresenti(def parametri) {

        if (!gestioneAgId || !dePagAbilitato) {
            return
        }

        if (tipoStampa == ModelliService.TipoStampa.PRATICA ||
                tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            return integrazioneDePagService.iuvValorizzatoPratica(parametri.id)

        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            if ((parametri.ruolo ?: 0) == 0 && (parametri.pratica ?: -1) == -1) {
                return integrazioneDePagService.iuvValorizzatoImposta(
                        parametri.codFiscale,
                        parametri.anno,
                        parametri.tipoTributo
                )
            } else if ((parametri.ruolo ?: 0) != 0) {
                return integrazioneDePagService.iuvValorizzatoRuolo(
                        parametri.codFiscale,
                        parametri.ruolo
                )
            } else if ((parametri.pratica ?: -1) != -1) {
                return integrazioneDePagService.iuvValorizzatoPratica(
                        parametri.pratica
                )
            } else {
                return false
            }
        }
    }

    private def notificaPNDAbilitata(def documento) {

        // Se non è attiva l'integrazione con DePag non è possibile notificare via PND
        if (!integrazioneDePagService.dePagAbilitato()) {
            return false
        }

        // In caso di elaborazione massiva i controlli vengono fatti in fase di elaborazione
        if (generazioneMassiva) {
            return true
        }

        if (!tassonomiaConPagamento) {
            return true
        }

        if (tipoStampa == ModelliService.TipoStampa.PRATICA ||
                tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            return tassonomiaConPagamento && integrazioneDePagService.iuvSingoloPratica(documento.id)

        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            if ((documento.ruolo ?: 0) == 0 && (documento.pratica ?: -1) == -1) {
                return tassonomiaConPagamento && integrazioneDePagService.iuvSingoloImposta(
                        documento.codFiscale,
                        documento.anno,
                        documento.tipoTributo
                )
            } else if ((documento.ruolo ?: 0) != 0) {
                return tassonomiaConPagamento || integrazioneDePagService.iuvSingoloRuolo(
                        documento.codFiscale,
                        documento.ruolo
                )
            } else if ((documento.pratica ?: -1) != -1) {
                return tassonomiaConPagamento && integrazioneDePagService.iuvSingoloPratica(documento.pratica)
            } else {
                return false
            }
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {
            return true
        }
    }

    def notificaPECAbilitata(def documento) {

        if (generazioneMassiva) {
            return true
        }

        if (tipoStampa == ModelliService.TipoStampa.PRATICA ||
                tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            return contribuenteConPec(documento.contribuente.codFiscale)
        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            if ((documento.ruolo ?: 0) == 0 && (documento.pratica ?: -1) == -1) {
                return contribuenteConPec(documento.codFiscale)
            } else if ((documento.ruolo ?: 0) != 0) {
                return contribuenteConPec(documento.codFiscale)
            } else if ((documento.pratica ?: -1) != -1) {
                return contribuenteConPec(documento.codFiscale)
            } else {
                return false
            }
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {
            return contribuenteConPec(documento)
        }
    }

    def notificaEmailAbilitata(def documento) {

        if (generazioneMassiva) {
            return true
        }

        if (tipoStampa == ModelliService.TipoStampa.PRATICA ||
                tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            return contribuenteConMail(documento.contribuente.codFiscale)
        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            if ((documento.ruolo ?: 0) == 0 && (documento.pratica ?: -1) == -1) {
                return contribuenteConMail(documento.codFiscale)
            } else if ((documento.ruolo ?: 0) != 0) {
                return contribuenteConMail(documento.codFiscale)
            } else if ((documento.pratica ?: -1) != -1) {
                return contribuenteConMail(documento.codFiscale)
            } else {
                return false
            }
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {
            return contribuenteConMail(documento)
        }
    }

    private contribuenteConContatto(def codFiscale, def tipoContatto) {

        if (!codFiscale) {
            return false
        }

        def contribuente = contribuentiService.getContribuente([codFiscale: codFiscale])
        if (!contribuente) {
            return false
        }

        def tipoTributoRecapito = tipoTributo
        if (tipoStampa == ModelliService.TipoStampa.ISTANZA_RATEAZIONE) {
            tipoTributoRecapito = pratica.tipoTributo.tipoTributo
        }
        def contatto = contribuentiService.fRecapito(contribuente.soggetto.id, tipoTributoRecapito, tipoContatto)
        if (!contatto) {
            return false
        }
        return true
    }

    private contribuenteConPec(def codFiscale) {
        return gestioneEredi || contribuenteConContatto(codFiscale, 3)
    }

    private contribuenteConMail(def codFiscale) {
        return gestioneEredi || contribuenteConContatto(codFiscale, 2)
    }

    @Command
    def onChangeTipiF24() {
        if ((modelloSelezionato.modello == 0) &&
                (!tipiF24.acconto) &&
                (!tipiF24.saldoDovuto)
                && (!tipiF24.saldoVersato)
                && (!tipiF24.unico)) {
            inviaTramiteMail = false
            BindUtils.postNotifyChange(null, null, this, "inviaTramiteMail")
        }
    }

    private def getParametroImportoRidotto() {

        if (modelloSelezionato && tipoStampa in [ModelliService.TipoStampa.PRATICA, ModelliService.TipoStampa.ISTANZA_RATEAZIONE]) {
            ridotto = modelliService.fDescrizioneTimp(modelloSelezionato.modello, "F24_IMPORTO_RIDOTTO") ?: 'SI'
            BindUtils.postNotifyChange(null, null, this, "ridotto")
        }

    }

    private def verificaNotificheComunicazione(def nomeFile) {

        if (!nomeFile?.toString()?.trim()) {
            return
        }

        def codiceFiscale = nomeFile[-16..-1].minus("00000")

        def comunicazionePndEsistente = documentaleService.esisteComunicazioneConNotificaPnd(nomeFile, codiceFiscale, pratica)
        def comunicazionePecEsistente = documentaleService.esisteComunicazioneConNotificaPec(nomeFile, codiceFiscale, pratica)

        if (comunicazionePndEsistente) {
            notificaPndEsistente = true
            BindUtils.postNotifyChange(null, null, this, "comunicazioneConNotificaPndEsistente")
        }
        if (comunicazionePecEsistente) {
            notificaPecEsistente = true
            BindUtils.postNotifyChange(null, null, this, "comunicazioneConNotificaPecEsistente")
        }
    }

    private void tipiComunicazioneVisibili() {
        if (dettaglioComunicazioneSelezionato == null) {
            notificaPNDVisible = false
            notificaPECVisible = false
            notificaEmailVisible = false
        } else {
            notificaPNDVisible = dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.PND
            notificaPECVisible = dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.PEC
            notificaEmailVisible = dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.EMAIL
        }

        BindUtils.postNotifyChange(null, null, this, "notificaPNDVisible")
        BindUtils.postNotifyChange(null, null, this, "notificaPECVisible")
        BindUtils.postNotifyChange(null, null, this, "notificaEmailVisible")
    }

    private inizializzaTipoNotifica(def dettaglioComunicazioneSelezionato = null) {
        if (!dettaglioComunicazioneSelezionato) {
            tipoNotifica = 'NONE'
        } else if (dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.PND && !isDisabledTipoNotificaPnd) {
            tipoNotifica = 'PND'
        } else if (dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.PEC && !isDisabledTipoNotificaPec) {
            tipoNotifica = 'PEC'
        } else if (dettaglioComunicazioneSelezionato?.tipoCanale?.id == TipiCanaleDTO.EMAIL && !isDisabledTipoNotificaEmail) {
            tipoNotifica = 'EMAIL'
        } else {
            tipoNotifica = 'NONE'
        }

        BindUtils.postNotifyChange(null, null, this, "tipoNotifica")
    }

    boolean getIsVisibleComboboxListaDettagliComunicazione() {
        return inviaDocumentale && smartPndAbilitato
    }

    boolean getIsVisibleTipoNotifica() {
        return inviaDocumentale && smartPndAbilitato
    }

    boolean getIsDisabledTipoNotificaPnd() {
        // Prima condizione per invio massivo, seconda per invio puntuale
        return (invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.PND || tipoComunicazioneSelezionato?.tagPnd == null)) ||
                (!invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.PND || !notificaPNDAttiva || notificaPndEsistente || tipoComunicazioneSelezionato?.tagPnd == null))
    }

    boolean getIsDisabledTipoNotificaPec() {
        // Prima condizione per invio massivo, seconda per invio puntuale
        return (invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.PEC || tipoComunicazioneSelezionato?.tagMail == null)) ||
                (!invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.PEC || !notificaPECAttiva || notificaPecEsistente || notificaPndEsistente || tipoComunicazioneSelezionato?.tagMail == null))
    }

    boolean getIsDisabledTipoNotificaEmail() {
        // Prima condizione per invio massivo, seconda per invio puntuale
        return (invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.EMAIL || tipoComunicazioneSelezionato?.tagMail == null)) ||
                (!invioMassivo && (dettaglioComunicazioneSelezionato?.tipoCanale?.id != TipiCanaleDTO.EMAIL || !notificaEmailAttiva || tipoComunicazioneSelezionato?.tagMail == null))
    }

    @Command
    onChangeListaDettagliComunicazione() {

        tipoComunicazioneSelezionato =
                listaTipoComunicazione.find { it.tipoComunicazione == dettaglioComunicazioneSelezionato?.tipoComunicazionePnd }

        tipiComunicazioneVisibili()

        tassonomiaConPagamento = tipoComunicazioneSelezionato?.codiceTassonomia == null ? false : smartPndService.tassonomiaConPagamento(tipoComunicazioneSelezionato?.codiceTassonomia)

        if (tipoStampa in [ModelliService.TipoStampa.PRATICA, ModelliService.TipoStampa.ISTANZA_RATEAZIONE]) {
            notificaPNDAttiva = notificaPNDAbilitata(pratica)
            notificaPECAttiva = notificaPECAbilitata(pratica)
            notificaEmailAttiva = notificaEmailAbilitata(pratica)
        } else if (tipoStampa == ModelliService.TipoStampa.LETTERA_GENERICA) {
            notificaPNDAttiva = notificaPNDAbilitata(codFiscale)
            notificaPECAttiva = notificaPECAbilitata(codFiscale)
            notificaEmailAttiva = notificaEmailAbilitata(codFiscale)
        } else if (tipoStampa == ModelliService.TipoStampa.COMUNICAZIONE) {
            notificaPNDAttiva = notificaPNDAbilitata(paramsID)
            notificaPECAttiva = notificaPECAbilitata(paramsID)
            notificaEmailAttiva = notificaEmailAbilitata(paramsID)
        } else if (tipoStampa == ModelliService.TipoStampa.SGRAVIO) {
            notificaPNDAttiva = tassonomiaConPagamento
            notificaPECAttiva = contribuenteConPec(codFiscale)
            notificaEmailAttiva = contribuenteConMail(codFiscale)
        }

        inizializzaTipoNotifica(dettaglioComunicazioneSelezionato)

        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaPnd")
        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaPec")
        BindUtils.postNotifyChange(null, null, this, "isDisabledTipoNotificaEmail")
        BindUtils.postNotifyChange(null, null, this, "isSendablePNDForDocumento")
    }

    private def caricaListaDettagliComunicazione() {
        listaDettagliComunicazione = comunicazioniService.getListaDettagliComunicazione(
                [
                        tipoTributo      : tipoTributo,
                        tipoComunicazione: tipoComunicazione,
                        tipiCanale       : [TipiCanaleDTO.EMAIL, TipiCanaleDTO.PEC, TipiCanaleDTO.PND]
                ])

        if (listaDettagliComunicazione.empty) {
            Clients.showNotification(
                    DETTAGLI_COMUNICAZIONE_MANCANTI,
                    Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        } else {
            listaDettagliComunicazione = [null, *listaDettagliComunicazione]
        }

        BindUtils.postNotifyChange(null, null, this, "listaDettagliComunicazione")
    }

    private def getListaTipoComunicazioneSmartPND() {
        def listaTipoComunicazioneAll = smartPndService.listaTipologieComunicazione()
        return listaTipoComunicazioneAll.findAll { it.tagPnd || it.tagMail }
    }

    private def zipDocuments(def files) {
        byte[] zipFile = null
        new ByteArrayOutputStream().withCloseable { baos ->
            new ZipOutputStream(baos).withCloseable { zios ->
                files.each { k, v ->
                    def singleFileName = k

                    zios.putNextEntry(new ZipEntry(singleFileName))
                    zios.write(v.content, 0, v.content.length)
                    zios.closeEntry()
                }
            }

            zipFile = baos.toByteArray()
        }
        return zipFile
    }

    private setupFilenameStrategy() {
        switch (tipoStampa) {
            case ModelliService.TipoStampa.PRATICA:
                filenameStrategy = new StampaFilenamePratica(pratica, codFiscale)
                break
            case ModelliService.TipoStampa.COMUNICAZIONE:
                filenameStrategy = new StampaFilenameComunicazione(anno, codFiscale, pratica, ruolo)
                break
            case ModelliService.TipoStampa.ISTANZA_RATEAZIONE:
                filenameStrategy = new StampaFilenameIstanzaRateazione(pratica, codFiscale)
                break
            case ModelliService.TipoStampa.LETTERA_GENERICA:
                filenameStrategy = new StampaFilenameLetteraGenerica(codFiscale)
                break
            case ModelliService.TipoStampa.SGRAVIO:
                filenameStrategy = new StampaFilenameSgravio(anno, ruolo, codFiscale)
                break
            default:
                filenameStrategy = new StampaFilenameGeneric(codFiscale)
                break
        }
    }

}
