package messaggistica.email

import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.dto.DocumentoContribuenteDTO
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.smartpnd.SmartPndService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class EmailViewModel extends AbstractEmailViewModel {
    private static Log log = LogFactory.getLog(EmailViewModel)

    final def TITOLO_LENGTH = DocumentoContribuenteDTO.TITOLO_LENGTH

    // Service
    ComunicazioniService comunicazioniService
    ComunicazioniTestiService comunicazioniTestiService
    SmartPndService smartPndService

    // Model
    Messaggio messaggio = new Messaggio([tipo: Messaggio.TIPO.EMAIL])
    def note
    def indirizziMittente = []
    def indirizziDestinatario = []
    def emailMittente

    def codFiscale
    boolean abilitaModificaAllegato = false
    def fileAllegato
    def nomeFile
    def smartPndAbilitato = false
    def listaAllegatiPassati = []
    def listaDettagliComunicazione
    def dettaglioComunicazioneSelezionato
    def dettagliComunicazioneFilter
    def listaComunicazioneTesti
    def comunicazioneTestoSelezionato
    def inviaEmailSmartPndParams
    def generaMessaggioParams

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codFiscale") def codFiscale,
         @ExecutionArgParam("fileAllegato") def aMedia,
         @ExecutionArgParam('parametri') def parametri
    ) {
        super.init(w)

        this.codFiscale = codFiscale

        smartPndAbilitato = smartPndService.smartPNDAbilitato()

        indirizziMittente = messaggisticaService.caricaIndirizziMittenteEscludiNonDefiniti()
        indirizziDestinatario = messaggisticaService.indirizziDestinatario(codFiscale)

        if (aMedia instanceof AMedia) {
            aggiungiAllegato(aMedia)
            abilitaModificaAllegato = true
        } else if (aMedia instanceof Map && !aMedia.isEmpty()) {
            aMedia.each {
                aggiungiAllegato(commonService.fileToAMedia(it.key, it.value.content))
            }
            abilitaModificaAllegato = true
        }

        this.generaMessaggioParams = [
                codFiscale: codFiscale,
                anno      : parametri?.anno,
                pratica   : parametri?.pratica,
                ruolo     : parametri?.ruolo,
        ]
        this.inviaEmailSmartPndParams = [
                pratica    : parametri?.pratica,
                ruolo      : parametri?.ruolo,
                tipologia  : parametri?.tipologiaDocumentale,
                tipoTributo: parametri?.tipoTributo ?: 'TRASV',
                anno       : parametri?.anno,
        ]
        this.dettagliComunicazioneFilter = [
                tipoTributo      : parametri?.tipoTributo ?: 'TRASV',
                tipoComunicazione: parametri?.tipoComunicazione ?: 'LGE',
                tipiCanale       : [TipiCanaleDTO.EMAIL]
        ]

        if (smartPndAbilitato) {
            listaDettagliComunicazione = comunicazioniService.getListaDettagliComunicazione(dettagliComunicazioneFilter)
        }

        caricaComunicazioneTesti()
        caricaFirme()
        generaMessaggio()
    }

    void caricaComunicazioneTesti() {
        def comunicazioneTestiFilter = dettaglioComunicazioneSelezionato ? [
                tipoTributo      : dettaglioComunicazioneSelezionato.tipoTributo.tipoTributo,
                tipoComunicazione: dettaglioComunicazioneSelezionato.tipoComunicazione,
                tipoCanale       : dettaglioComunicazioneSelezionato.tipoCanale
        ] : [
                tipoTributo      : dettagliComunicazioneFilter.tipoTributo,
                tipoComunicazione: dettagliComunicazioneFilter.tipoComunicazione,
                tipiCanale       : dettagliComunicazioneFilter.tipiCanale
        ]

        listaComunicazioneTesti = [null] + comunicazioniTestiService.getListaComunicazioneTesti(comunicazioneTestiFilter)
        comunicazioneTestoSelezionato = listaComunicazioneTesti.first()

        BindUtils.postNotifyChange(null, null, this, "comunicazioneTestoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaComunicazioneTesti")
    }

    @Command
    onChangeDettaglioComunicazioneSelezionato() {
        caricaComunicazioneTesti()

        if (smartPndAbilitato) {
            emailMittente = smartPndService.listaTipologieComunicazione()?.find { it.tipoComunicazione == dettaglioComunicazioneSelezionato?.tipoComunicazionePnd }?.emailMittente
        }

        BindUtils.postNotifyChange(null, null, this, "emailMittente")
    }

    @Command
    onChangeComunicazioneTestoSelezionato() {
        generaMessaggio()
    }

    private def generaMessaggio() {
        messaggio = messaggisticaService.generaMessaggio(Messaggio.TIPO.EMAIL,
                comunicazioneTestoSelezionato,
                generaMessaggioParams.codFiscale,
                generaMessaggioParams.anno,
                generaMessaggioParams.pratica?.id,
                generaMessaggioParams.ruolo?.id)

        listaAllegati = messaggio.allegati
        listaAllegati += listaAllegatiPassati

        calcolaDimensioneTotaleAllegati()

        BindUtils.postNotifyChange(null, null, this, "messaggio")
        BindUtils.postNotifyChange(null, null, this, "listaAllegati")
    }

    @Command
    def onInviaMail() {

        if (smartPndAbilitato) {
            messaggio.mittente = [indirizzo: emailMittente]
        }

        if (!listaAllegati.empty && !listaAllegati.any { it.principale == true }) {
            setPrincipale(listaAllegati.first())
        }

        messaggio.allegati = listaAllegati
        def msg = validate()
        if (!msg.isEmpty()) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        messaggio.destinatario = messaggisticaService.estraiIndirizzo(messaggio.destinatario)

        messaggisticaService.inviaEmail(messaggio, codFiscale, note, dettaglioComunicazioneSelezionato, inviaEmailSmartPndParams)
        Clients.showNotification("Messaggio inviato correttamente", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 5000, true)

        Events.postEvent(Events.ON_CLOSE, self, [esito: 'inviato'])
    }

    private setPrincipale(def allegato) {
        allegato?.principale = true
    }

    @Command
    def onGestioneContatti() {

        commonService.creaPopup("/messaggistica/email/contatti.zul", self, [:], {
            indirizziMittente = messaggisticaService.caricaIndirizziMittenteEscludiNonDefiniti()

            if (messaggio.mittente != null) {
                messaggio.mittente = indirizziMittente.find { it.origine = messaggio.mittente.origine }
            }

            BindUtils.postNotifyChange(null, null, this, "indirizziMittente")
            BindUtils.postNotifyChange(null, null, this, "messaggio")
        })
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

// Al primo caricamento della dialog dopo il login, cliccando sul
// bottone per allegare i documenti non viene aperta la finestra.
// Si usa un timer per invalidarlo.
    @Command
    def invalidaFinestra() {
        self.invalidate()
    }

    @Override
    def changeFirmaSelezionata() {
        messaggio.firma = firmaSelezionata?.firma
        BindUtils.postNotifyChange(null, null, this, "messaggio")
    }

    private validate() {
        def errMessage = ""

        // Da: campo obbligatorio
        if (!smartPndAbilitato && !messaggio.mittente?.indirizzo?.trim()) {
            errMessage += "Specificare il mittente nel campo 'Da'\n"
        }

        if (smartPndAbilitato && !emailMittente?.trim()) {
            errMessage += "Mittente non definito:controllare il Dettaglio Comunicazione selezionato\n"
        }

        // A: campo obbligatorio
        if (!messaggio.destinatario?.trim()) {
            errMessage += "Specificare il destinatario nel campo 'A'\n"
        } else {
            def destEmail = messaggisticaService.estraiIndirizzo(messaggio.destinatario)
            if (!messaggisticaService.validaIndirizzo(destEmail)) {
                errMessage += "Indirizzo '${destEmail}' in 'A' non valido.\n"
            }
        }

        // L'oggetto non può essere vuoto
        if (!messaggio.oggetto?.trim()) {
            errMessage += "Il campo 'Oggetto' non puo' essere vuoto\n"
        }

        // Verifica che Cc e Ccn contengano indirizzi validi
        def splitCc = messaggisticaService.splitIndirizzi(messaggio.copiaConoscenza)

        splitCc.each {
            if (!messaggisticaService.validaIndirizzo(it)) {
                errMessage += "Indirizzo '${it}' in 'Cc' non valido.\n"
            }
        }

        def splitCcn = messaggisticaService.splitIndirizzi(messaggio.copiaConoscenzaNascosta)

        splitCcn.each {
            if (!messaggisticaService.validaIndirizzo(it)) {
                errMessage += "Indirizzo '${it}' in 'Ccn' non valido.\n"
            }
        }

        // Campo messaggio obbligatorio
        if (!messaggio.testo?.trim()) {
            errMessage += "Il messaggio non puo' essere vuoto\n"
        }

        if (smartPndAbilitato && dettaglioComunicazioneSelezionato == null) {
            errMessage += "Dettaglio Comunicazione obbligatorio"
        }

        return errMessage
    }

    private aggiungiAllegato(AMedia aMedia) {

        fileAllegato = aMedia.getStreamData()
        def format = ".$aMedia.format"
        nomeFile = aMedia.name.endsWith(format) ? "${aMedia.name}" : "${aMedia.name}$format"
        def bytes = fileAllegato.bytes

        // Se il file e' gia' presente non si aggiunge
        if (messaggio.allegati.find { it.nome == nomeFile } != null) {
            Clients.showNotification("File ${nomeFile} gia' aggiunto agli allegati", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        def allegato = [nome: nomeFile, contenuto: bytes, dimensione: commonService.humanReadableSize(bytes.size())]
        setPrincipale(allegato)
        listaAllegatiPassati << allegato

        calcolaDimensioneTotaleAllegati()

        BindUtils.postNotifyChange(null, null, this, "messaggio")
    }

}
