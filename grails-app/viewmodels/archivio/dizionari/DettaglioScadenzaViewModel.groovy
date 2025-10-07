package archivio.dizionari

import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.dto.ScadenzaDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioScadenzaViewModel {

    // Services
    def springSecurityService

    CommonService commonService
    CanoneUnicoService canoneUnicoService
    CompetenzeService competenzeService

    // Componenti
    Window self

    // Generali
    boolean aggiornaStato = false
    /// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh

    Short annoCorrente
    TipoTributoDTO tipoTributo
    def annoTributo

	List<GruppoTributoDTO> listaGruppiTributo = []
	GruppoTributoDTO gruppoTributo
	def tipoOccupazioneSelected

	def listaTipiOccupazione = [
		[ codice: null, descrizione: '' ],
		[ codice: TipoOccupazione.P.id, descrizione: TipoOccupazione.P.descrizione ],
		[ codice: TipoOccupazione.T.id, descrizione: TipoOccupazione.T.descrizione ],
	]

    def tipologiaRata = null
    def tipologiaScadenza = null
    def tipologiaVersamento = null

    // Comuni
    def listaAnni = null
    def listRata = [
            [codice: null, descrizione: ""],
            [codice: 0, descrizione: "Unica"],
            [codice: 1, descrizione: "Prima"],
            [codice: 2, descrizione: "Seconda"],
            [codice: 3, descrizione: "Terza"],
            [codice: 4, descrizione: "Quarta"],
            [codice: 5, descrizione: "Quinta"],
            [codice: 6, descrizione: "Sesta"]
    ]
    def listTipo = [
            [codice: 'D', descrizione: "Dichiarazione"],
            [codice: 'V', descrizione: "Versamento"],
            [codice: 'R', descrizione: "Ravvedimento"],
            [codice: 'T', descrizione: "Terremoto"]
    ]
    def listVersamento = [
            [codice: null, descrizione: ""],
            [codice: 'A', descrizione: "Acconto"],
            [codice: 'S', descrizione: "Saldo"],
            [codice: 'U', descrizione: "Unico"]
    ]

    boolean modificabile = false
    boolean esistente = false
    def labels

    // Dati
    ScadenzaDTO scadenza

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("annoTributo") Short aa,
         @ExecutionArgParam("scadenza") ScadenzaDTO sc,
         @ExecutionArgParam("modifica") boolean md,
         @ExecutionArgParam("duplica") boolean dp) {

        this.self = w

        annoCorrente = (aa != null) ? (aa as Short) : Calendar.getInstance().get(Calendar.YEAR)

        tipoTributo = competenzeService.tipiTributoUtenza().find { it.tipoTributo == tt }
        modificabile = md

        listaAnni = canoneUnicoService.getElencoAnni()

		// Gruppo tributo - Solo CUNI
		listaGruppiTributo = []
		if(tipoTributo.tipoTributo in ['CUNI']) {
			TipoTributo tipoTributoRaw = tipoTributo.toDomain()
			List<GruppoTributoDTO> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoRaw)?.toDTO(["tipoTributo"])
			listaGruppiTributo << new GruppoTributoDTO()
			listaGruppiTributo.addAll(gruppiTributo)
		}

        if (sc != null) {
            scadenza = sc
            annoTributo = this.scadenza.anno
            esistente = true
        } else {
            scadenza = new ScadenzaDTO()
            scadenza.tipoTributo = tipoTributo
            annoTributo = annoCorrente
            esistente = false
        }
		
		gruppoTributo = listaGruppiTributo.find { it.gruppoTributo == scadenza.gruppoTributo }

        if (dp) {
            onCopia()
        } else {
            impostaScadenza()
        }

        labels = commonService.getLabelsProperties('dizionario')
    }

    /// Eventi interfaccia ######################################################################################################

    @Command
    def onSelectAnno() {

    }

	@Command
	def onChangeGruppoTributo() {

	}
	
    @Command
    def onSelectTipoOccupazione() {

    }

    @Command
    def onSelectRata() {

    }

    @Command
    def onSelectTipo() {

    }

    @Command
    def onSelectVersamento() {

    }

    @Command
    onCopia() {

        scadenza = canoneUnicoService.duplicaScadenza(scadenza, true)
        esistente = false

        impostaScadenza()

    }

    @Command
    onElimina() {

        String messaggio = "Sicuri di voler eliminare la scadenza?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaScadenza()
                        }
                    }
                }
        )
    }

    @Command
    onSalva() {

        if (!completaScadenza()) return
        if (!verificaScadenza()) return

        def report = canoneUnicoService.salvaScadenza(scadenza)

        def savedMessage = "Salvataggio avvenuto con successo"
        visualizzaReport(report, savedMessage)

        if (report.result == 0) {
            aggiornaStato = true
        }

        if (report.result == 0) {
            if (scadenza.getDomainObject() == null) {
                onChiudi()
            }
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato])
    }

    /// Funzioni interne ######################################################################################################

    ///
    /// *** Attiva tariffa impostata
    ///
    def impostaScadenza() {

		def tipoOccupazione = scadenza.tipoOccupazione?.tipoOccupazione
		tipoOccupazioneSelected = listaTipiOccupazione.find { it.codice == tipoOccupazione }
		
        tipologiaRata = listRata.find { it.codice == scadenza.rata }
        tipologiaScadenza = listTipo.find { it.codice == scadenza.tipoScadenza }
        tipologiaVersamento = listVersamento.find { it.codice == scadenza.tipoVersamento }

        BindUtils.postNotifyChange(null, null, this, "tipoOccupazioneSelected")
        BindUtils.postNotifyChange(null, null, this, "scadenza")

        BindUtils.postNotifyChange(null, null, this, "tipologiaScadenza")
        BindUtils.postNotifyChange(null, null, this, "tipologiaVersamento")

        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "esistente")
    }

    ///
    /// *** Elimina la tariffa corrente ed esce
    ///
    def eliminaScadenza() {

        def report = canoneUnicoService.eliminaScadenza(scadenza)

        visualizzaReport(report, "Eliminazione eseguita con successo !")

        if (report.result == 0) {

            aggiornaStato = true
            onChiudi()
        }
    }

    ///
    /// *** Completa tariffa prima di verifica e salvataggio
    ///
    private boolean completaScadenza() {

        String message = ""
        boolean result = true

        scadenza.anno = annoTributo as Short

        scadenza.rata = tipologiaRata?.codice
        scadenza.tipoScadenza = tipologiaScadenza?.codice
        scadenza.tipoVersamento = tipologiaVersamento?.codice
		
		if(scadenza.tipoScadenza in ['V']) {
			scadenza.gruppoTributo = gruppoTributo?.gruppoTributo
			scadenza.tipoOccupazione = tipoOccupazioneSelected?.codice
		}
		else {
			scadenza.gruppoTributo = null
			scadenza.tipoOccupazione = null
		}
		
        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    ///
    /// *** Verifica coerenza dati Scadenza
    ///
    private boolean verificaScadenza() {

        String message = ""
        boolean result = true

        def report = canoneUnicoService.verificaScadenza(scadenza)
        if (report.result != 0) {
            message = report.message
        }

        if (message.size() > 0) {

            message = "Attenzione: \n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    ///
    /// *** Visualizza report
    ///
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }
    }
}
