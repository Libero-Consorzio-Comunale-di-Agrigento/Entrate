package messaggistica.email

import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.DocumentoContribuenteDTO
import it.finmatica.tr4.smartpnd.SmartPndService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class NotificheEmailSmartPNDViewModel extends AbstractEmailViewModel {
    private static Log log = LogFactory.getLog(NotificheEmailSmartPNDViewModel)

    final def TITOLO_LENGTH = DocumentoContribuenteDTO.TITOLO_LENGTH

    // componenti
    Window self

    ContribuentiService contribuentiService
    ComunicazioniTestiService comunicazioniTestiService
    DocumentaleService documentaleService

    def listaComunicazioneTesti
    def dettaglioComunicazioneSelezionato
    def comunicazioneTestoSelezionato
    def destinatari
    def tipoNotifica
    def tipoTributo

    def oggetto
    def note
    def testo

    def pratica
    def ruolo
    def anno
    def tipologia
    def tipoComunicazione
    def invioMassivo

    def precedentiAllegati = []
    def deceduto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("destinatari") def destinatari,
         @ExecutionArgParam("tipoNotifica") def tipoNotifica,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tipoComunicazione") def tipoComunicazione,
         @ExecutionArgParam("dettaglioComunicazione") def dettaglioComunicazione,
         @ExecutionArgParam("pratica") def pratica,
         @ExecutionArgParam("ruolo") def ruolo,
         @ExecutionArgParam("anno") def anno,
         @ExecutionArgParam("tipologia") def tipologia,
         @ExecutionArgParam("invioMassivo") def invioMassivo
    ) {

        super.init(w)

        listaAllegati = []

        this.self = w
        this.destinatari = destinatari
        this.tipoNotifica = tipoNotifica
        this.pratica = pratica
        this.ruolo = ruolo
        this.anno = anno
        this.tipologia = tipologia
        this.tipoTributo = tipoTributo
        this.tipoComunicazione = tipoComunicazione
        this.invioMassivo = invioMassivo

        def tipoTributoRecapito = tipoTributo
        // Istanza di rateazione, si prende il tipo tributo della pratica rateizzata
        if (tipologia == 'I') {
            tipoTributoRecapito = pratica?.tipoTributo?.tipoTributo
        }

        destinatari.each {
            it.value.recapito = contribuentiService.fRecapito(getSoggetto(it).id, tipoTributoRecapito, tipoNotifica == 'EMAIL' ? 2 : 3)

            it.value.daInviare = it.value.recapito?.trim() ? true : false
        }

        deceduto = destinatari.find { !it.value.erede }
        if (destinatari.any { it.value.erede }) {
            this.destinatari = destinatari.findAll { it.value.erede }
        }

        this.dettaglioComunicazioneSelezionato = dettaglioComunicazione

        this.listaComunicazioneTesti = comunicazioniTestiService.getListaComunicazioneTesti(
                [
                        tipoTributo      : dettaglioComunicazioneSelezionato?.tipoTributo?.tipoTributo,
                        tipoComunicazione: dettaglioComunicazioneSelezionato?.tipoComunicazione,
                        tipoCanale       : dettaglioComunicazioneSelezionato?.tipoCanale
                ]
        )

    }

    @Command
    def onChangeComunicazioneTestoSelezionato() {
        oggetto = comunicazioneTestoSelezionato?.oggetto
        note = comunicazioneTestoSelezionato?.note

        if (destinatari.size() == 1) {
            testo = messaggisticaService.generaMessaggio(
                    Messaggio.TIPO.APP_IO_EMAIL,
                    comunicazioneTestoSelezionato,
                    getSoggetto(destinatari.entrySet()[0]).codFiscale,
                    anno,
                    pratica?.id,
                    ruolo?.id
            ).testo
        } else {
            testo = comunicazioneTestoSelezionato?.testo
        }

        def allegatiTesto =
                messaggisticaService.convertToAllegatiMessaggio(
                        comunicazioniTestiService.getListaAllegatiTesto(comunicazioneTestoSelezionato) ?: []
                )
        listaAllegati -= precedentiAllegati
        listaAllegati += allegatiTesto

        precedentiAllegati = allegatiTesto

        BindUtils.postNotifyChange(null, null, this, "oggetto")
        BindUtils.postNotifyChange(null, null, this, "note")
        BindUtils.postNotifyChange(null, null, this, "testo")
        BindUtils.postNotifyChange(null, null, this, "listaAllegati")
    }

    @Command
    def onDownload(@BindingParam("allegato") def allegato) {
        AMedia amedia = commonService.fileToAMedia(allegato.key, allegato.value.content)
        Filedownload.save(amedia)
    }

    @Command
    def onInviaMessaggio() {
        if (!checkInvio()) {
            return
        }
        if (!invioMassivo) {
            notificaPEC()
        } else {
            comunicazioneTestoSelezionato.testoModificato = testo
            comunicazioneTestoSelezionato.oggettoModificato = oggetto

            Events.postEvent(Events.ON_CLOSE, self, [
                    comunicazioneTesto: comunicazioneTestoSelezionato,
                    firma             : testoFirma,
                    oggetto           : oggetto,
                    allegati          : listaAllegati
            ]
            )
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onApriSoggetto(@BindingParam("idSoggetto") def idSoggetto) {

        commonService.creaPopup("/archivio/soggetto.zul", self, [idSoggetto: idSoggetto], {
            destinatari.each {
                it.value.recapito = contribuentiService.fRecapito(getSoggetto(it).id, tipoTributo, tipoNotifica == 'EMAIL' ? 2 : 3)
                it.value.daInviare = it.value.recapito?.trim() ? true : false
            }
            BindUtils.postNotifyChange(null, null, this, "destinatari")
        })
    }

    @Override
    def changeFirmaSelezionata() {
        testoFirma = firmaSelezionata?.firma
        BindUtils.postNotifyChange(null, null, this, "testoFirma")
    }

    private def checkInvio() {

        if (!invioMassivo) {

            if (!destinatari || destinatari.findAll { it.value.daInviare }.isEmpty()) {
                Clients.showNotification("Indicare almeno un destinatario", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
                return false
            }

            if (destinatari.find {
                it.value.daInviare && !it.value.recapito?.trim()
            } != null) {
                Clients.showNotification("Sono presenti destinatari senza recapito", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
                return false
            }
        }

        if (!comunicazioneTestoSelezionato) {
            Clients.showNotification("Selezionare un testo", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return false
        }

        if (!oggetto) {
            Clients.showNotification("Inserire l'oggetto", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return false
        }

        if (!testo?.trim()) {
            Clients.showNotification("Il campo del testo non può essere vuoto", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return false
        }

        return true
    }

    private notificaPEC() {


        def tipoNotifica = SmartPndService.TipoNotifica.PEC
        if (this.tipoNotifica == 'EMAIL') {
            tipoNotifica = SmartPndService.TipoNotifica.EMAIL
        }

        comunicazioneTestoSelezionato.testoModificato = testo

        def esito = ""
        destinatari.findAll { it.value.daInviare }.each {

            def testo = messaggisticaService.generaMessaggio(
                    Messaggio.TIPO.APP_IO_EMAIL,
                    comunicazioneTestoSelezionato,
                    getSoggetto(deceduto).codFiscale,
                    anno,
                    pratica?.id,
                    ruolo?.id,
                    it.value.erede ? getSoggetto(it).id : null
            ).testo

            esito = documentaleService.invioDocumento(
                    getSoggetto(deceduto).codFiscale,
                    pratica?.id ?: ruolo?.id,
                    tipologia,
                    [
                            [nomeFile: it.key, documento: it.value.content, principale: true],
                            *listaAllegati.findAll { a -> it.key != a.nome }.collect
                                    { a -> [nomeFile: a.nome, documento: a.contenuto] }
                    ],
                    tipoTributo,
                    anno,
                    [tipoNotifica: tipoNotifica, oggetto: oggetto],
                    null,
                    null,
                    null,
                    tipoComunicazione,
                    null,
                    null,
                    testo,
                    [],
                    [:],
                    it.value.erede ? it.value.soggetto : null
            )

        }

        if (!esito.isNumber()) {
            Clients.showNotification(
                    "Errore nell'invio - $esito",
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self.parent,
                    "before_center", 5000, true)
        } else {
            Clients.showNotification(
                    "Documento inviato con successo",
                    Clients.NOTIFICATION_TYPE_INFO,
                    self.parent,
                    "before_center", 5000, true)
        }

        onChiudi()
    }

    private getSoggetto(def destinatario) {

        def dest = [:]

        dest.id = destinatario.value.soggetto.ni
        dest.codFiscale = destinatario.value.soggetto.codFiscale

        return dest
    }

}
