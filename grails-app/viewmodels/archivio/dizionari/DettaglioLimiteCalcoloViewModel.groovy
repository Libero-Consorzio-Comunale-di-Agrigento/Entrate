package archivio.dizionari

import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.dto.LimiteCalcoloDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioLimiteCalcoloViewModel {

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
    def labels
    def listaTipiOccupazione = [
		[ codice: null, descrizione: '' ],
		[ codice: TipoOccupazione.P.id, descrizione: TipoOccupazione.P.descrizione ],
		[ codice: TipoOccupazione.T.id, descrizione: TipoOccupazione.T.descrizione ],
	]
	
    // Comuni
    def listaAnni = null

    boolean modificabile = false
    boolean esistente = false

    // Dati
    LimiteCalcoloDTO limiteCalcolo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("annoTributo") Short aa,
         @ExecutionArgParam("limiteCalcolo") LimiteCalcoloDTO lc,
         @ExecutionArgParam("modifica") boolean md,
         @ExecutionArgParam("duplica") boolean dp) {

        this.self = w

        annoCorrente = (aa != null) ? (aa as Short) : Calendar.getInstance().get(Calendar.YEAR)

        tipoTributo = competenzeService.tipiTributoUtenza().find { it.tipoTributo == tt }
        modificabile = md

        listaAnni = canoneUnicoService.getElencoAnni()

        if (lc != null) {
            limiteCalcolo = lc
            annoTributo = this.limiteCalcolo.anno
            esistente = true
        } else {
            limiteCalcolo = new LimiteCalcoloDTO()
            limiteCalcolo.tipoTributo = tipoTributo
            annoTributo = annoCorrente
            esistente = false
        }
		
		caricaListaGruppiTributo()

        if (dp) {
            onCopia()
        } else {
            impostaLimiteCalcolo()
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
    onCopia() {

        limiteCalcolo = canoneUnicoService.duplicaLimiteCalcolo(limiteCalcolo)
        esistente = false

        impostaLimiteCalcolo()

    }

    @Command
    onElimina() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        eliminaLimiteCalcolo()
                    }
                })
    }

    @Command
    onSalva() {

        if (!completaLimiteCalcolo()) return
        if (!verificaLimiteCalcolo()) return

        def report = canoneUnicoService.salvaLimiteCalcolo(limiteCalcolo)

        if (report.result != 0) {
            visualizzaReport(report, "")
            return
        }
        aggiornaStato = true

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato])
    }

    /// Funzioni interne ######################################################################################################

	def caricaListaGruppiTributo() {
		
		// Gruppo tributo - Solo CUNI
		listaGruppiTributo = []
		if(tipoTributo.tipoTributo in ['CUNI']) {
			TipoTributo tipoTributoRaw = tipoTributo.toDomain()
			List<GruppoTributoDTO> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoRaw)?.toDTO(["tipoTributo"])
			
			/// Non si può cambiare il Gruppo_Tributo se già assegnato, solo toglierlo
			if(limiteCalcolo.gruppoTributo != null) {
				gruppiTributo = gruppiTributo.findAll { it.gruppoTributo == limiteCalcolo.gruppoTributo } 
			} 
			
			listaGruppiTributo << new GruppoTributoDTO()
			listaGruppiTributo.addAll(gruppiTributo)
		}
		
		gruppoTributo = listaGruppiTributo.find { it.gruppoTributo == limiteCalcolo.gruppoTributo }
		
        BindUtils.postNotifyChange(null, null, this, "listaGruppiTributo")
        BindUtils.postNotifyChange(null, null, this, "gruppoTributo")
	}

    ///
    /// *** Attiva tariffa impostata
    ///
    def impostaLimiteCalcolo() {
		
		def tipoOccupazione = limiteCalcolo.tipoOccupazione?.tipoOccupazione
		tipoOccupazioneSelected = listaTipiOccupazione.find { it.codice == tipoOccupazione }
		
        BindUtils.postNotifyChange(null, null, this, "tipoOccupazioneSelected")
		BindUtils.postNotifyChange(null, null, this, "limiteCalcolo")
		
        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "esistente")
    }

    ///
    /// *** Elimina il Limite Calcolo corrente ed esce
    ///
    def eliminaLimiteCalcolo() {

        def report = canoneUnicoService.eliminaLimiteCalcolo(limiteCalcolo)

        if (report.result != 0) {
            visualizzaReport(report, "")
        }

        def message = "Eliminazione avvenuta con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        aggiornaStato = true
        onChiudi()
    }

    ///
    /// *** Completa tariffa prima di verifica e salvataggio
    ///
    private boolean completaLimiteCalcolo() {

        String message = ""
        boolean result = true

        limiteCalcolo.anno = annoTributo as Short
		
		limiteCalcolo.gruppoTributo = gruppoTributo?.gruppoTributo
		limiteCalcolo.tipoOccupazione = tipoOccupazioneSelected?.codice
		
        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    ///
    /// *** Verifica coerenza dati Limite Calcolo
    ///
    private boolean verificaLimiteCalcolo() {

        String message = ""
        boolean result = true

        def report = canoneUnicoService.verificaLimiteCalcolo(limiteCalcolo)
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
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
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
