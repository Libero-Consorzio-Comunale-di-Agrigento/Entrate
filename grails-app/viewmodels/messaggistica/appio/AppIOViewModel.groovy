package messaggistica.appio


import groovy.json.JsonOutput
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.email.MessaggisticaService
import it.finmatica.tr4.smartpnd.SmartPndService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class AppIOViewModel {

    private static Log log = LogFactory.getLog(AppIOViewModel)

    // componenti
    Window self

    // servizi
    def contribuentiService
    MessaggisticaService messaggisticaService
    ComunicazioniService comunicazioniService
    ComunicazioniTestiService comunicazioniTestiService
    DocumentaleService documentaleService
    SmartPndService smartPndService

    // Model
    Messaggio messaggio = new Messaggio([tipo: Messaggio.TIPO.APP_IO])
    def note

    def massiva
    def contribuente
    def codFiscale
    def parametro
    def pratica
    def anno
    def ruolo
    def tipoTributo
    def tipoDocumento

    def listaDettagliComunicazione
    def dettaglioComunicazioneSelezionato

    def listaComunicazioneTesti
    def comunicazioneTestoSelezionato


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tipoComunicazione") def tipoComunicazione,
         @ExecutionArgParam("massiva") @Default('false') Boolean massiva,
         @ExecutionArgParam("codFiscale") def codFiscale,
         @ExecutionArgParam("pratica") def pratica,
         @ExecutionArgParam("ruolo") def ruolo,
         @ExecutionArgParam("anno") def anno,
         @ExecutionArgParam("tipologia") def tipologia) {

        this.self = w

        this.listaDettagliComunicazione = []

        this.tipoTributo = tipoTributo
        this.tipoDocumento = documentaleService.recuperaTipoDocumento(pratica, tipologia)

        // Se il tipo comunicazione passato è null si carica la lista dettagli di default.
        if (tipoComunicazione) {
            listaDettagliComunicazione = comunicazioniService.getListaDettagliComunicazione(
                    [
                            tipoTributo: tipoTributo.tipoTributo,
                            tipoComunicazione: tipoComunicazione,
                            tipiCanale       : [TipiCanaleDTO.APPIO],
                    ])
        }

        if (listaDettagliComunicazione.empty) {
            listaDettagliComunicazione = comunicazioniService.getDettagliComunicazioneFallback([
                    tipiCanale: [TipiCanaleDTO.APPIO]
            ])
        }

        this.listaComunicazioneTesti = comunicazioniTestiService.getListaComunicazioneTesti(
                [
                        tipoTributo      : dettaglioComunicazioneSelezionato?.tipoTributo?.tipoTributo,
                        tipoComunicazione: dettaglioComunicazioneSelezionato?.tipoComunicazione,
                        tipoCanale       : dettaglioComunicazioneSelezionato?.tipoCanale?.id
                ]
        )

        this.massiva = massiva
        if (!this.massiva) {
            this.codFiscale = codFiscale
            this.contribuente = Contribuente.findByCodFiscale(codFiscale)
            this.pratica = pratica
            this.anno = anno
            this.ruolo = ruolo
        }

    }

    @Command
    onChangeDettaglioComunicazioneSelezionato() {
        this.listaComunicazioneTesti = comunicazioniTestiService.getListaComunicazioneTesti(
                [tipoTributo      : dettaglioComunicazioneSelezionato.tipoTributo.tipoTributo,
                 tipoComunicazione: dettaglioComunicazioneSelezionato.tipoComunicazione,
                 tipoCanale: dettaglioComunicazioneSelezionato.tipoCanale]
        )
        BindUtils.postNotifyChange(null, null, this, "listaComunicazioneTesti")
        BindUtils.postNotifyChange(null, null, this, "comunicazioneTestoSelezionato")
    }

    @Command
    onChangeComunicazioneTestoSelezionato() {
        generaMessaggio()
    }

    private def generaMessaggio() {

        messaggio = messaggisticaService.generaMessaggio(Messaggio.TIPO.APP_IO,
                comunicazioneTestoSelezionato,
                codFiscale ?: contribuente?.codFiscale,
                anno,
                pratica,
                ruolo,
                null,
                massiva
        )

        BindUtils.postNotifyChange(null, null, this, "messaggio")
    }

    @Command
    def onInviaMessaggio() {

        def msg = validate()
        if (!msg.isEmpty()) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return
        }

        if (messaggio.testo.length() > MessaggisticaService.MAX_LENGTH) {
            msg = "Il testo supera la lunghezza massima di ${MessaggisticaService.MAX_LENGTH} caratteri e verra' trocato in fase di spedizione.\nProseguire?"
            Messagebox.show(msg, "Invio messaggio", Messagebox.OK | Messagebox.CANCEL,
                    Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
                public void onEvent(Event evt) throws InterruptedException {
                    if (evt.getName().equals("onOK")) {
                        inviaMessaggio()
                    }
                }
            }
            )
        } else {
            inviaMessaggio()
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private validate() {
        def errMessage = ""

        // L'oggetto non può essere vuoto
        if (!messaggio.oggetto?.trim()) {
            errMessage += "Il campo 'Oggetto' non puo' essere vuoto\n"
        }

        // Campo messaggio obbligatorio
        if (!messaggio.testo?.trim()) {
            errMessage += "Il messaggio non puo' essere vuoto\n"
        }

        return errMessage
    }

    private inviaMessaggio() {
        if (!massiva) {
            inviaMessaggioSingolo()
        } else {
            inviaMessaggioMassivo()
        }
    }

    private inviaMessaggioSingolo() {
        def msgId = null
        try {
            msgId = messaggisticaService.inviaAppIO(
                    codFiscale,
                    messaggio.oggetto,
                    messaggio.testo,
                    dettaglioComunicazioneSelezionato.tag,
                    dettaglioComunicazioneSelezionato.tipoComunicazionePnd,
                    comunicazioniService.generaParametriSmartPND(codFiscale, anno, pratica ?: ruolo, tipoTributo?.tipoTributo, tipoDocumento)
            )
        } catch (Exception e) {
            Clients.showNotification(e.message, Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            e.printStackTrace()
            return
        }

        def noteMessaggio = note
        if (smartPndService.smartPNDAbilitato()) {
            def smartPndNote = "Inviato a SmartPND"
            if (!noteMessaggio.empty) {
                noteMessaggio += " - "
            }

            noteMessaggio += smartPndNote
        }

        log.info "Salvataggio in documenti_contribuente"
        def dc = new DocumentoContribuente(
                titolo: "Messaggio inviato ad AppIO per ${codFiscale}",
                contribuente: Contribuente.findByCodFiscale(codFiscale),
                documento: messaggisticaService.zip(JsonOutput.toJson(messaggio)),
                idMessaggio: smartPndService.smartPNDAbilitato() ? null : msgId,
                idComunicazionePnd: smartPndService.smartPNDAbilitato() ? msgId : null,
                note: noteMessaggio,
                tipoCanale: dettaglioComunicazioneSelezionato?.tipoCanale?.id,
                validitaDal: new Date()
        )

        Clients.showNotification("Messaggio inviato correttamente", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 5000, true)

        contribuentiService.caricaDocumento(dc)
        Events.postEvent(Events.ON_CLOSE, self, [esito: 'inviato'])
    }

    private inviaMessaggioMassivo() {
        Events.postEvent(Events.ON_CLOSE, self, [
                tipoTributo         : dettaglioComunicazioneSelezionato.tipoTributo.tipoTributo,
                tipoComunicazione   : dettaglioComunicazioneSelezionato.tipoComunicazione,
                comunicazioneTesto  : comunicazioneTestoSelezionato,
                tag                 : dettaglioComunicazioneSelezionato.tag,
                tipoComunicazionePnd: dettaglioComunicazioneSelezionato.tipoComunicazionePnd,
                messaggio           : [oggetto: messaggio.oggetto,
                                       testo  : messaggio.testo,
                                       note   : note]
        ])
    }
}
