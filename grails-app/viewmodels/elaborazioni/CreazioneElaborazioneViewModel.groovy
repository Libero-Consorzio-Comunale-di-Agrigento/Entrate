package elaborazioni

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.TipoElaborazione
import it.finmatica.tr4.jobs.CreazioneElaborazioneJob
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CreazioneElaborazioneViewModel {

    // componenti
    Window self

    def springSecurityService

    ElaborazioniService elaborazioniService

    def nomeElaborazione
    def tipoElaborazione
    def titolo
    def dettagli = []
    def tipoPratica
    def tipoTributo
    def ruolo
    def anno
    def creaElaborazioniSeparate = false
    def creaElaborazioniAAT = false
    def creaDettagliEredi = false
    def selectAllDetails
    def autoExportAnagrTrib

	List<GruppoTributoDTO> listaGruppiTributo
	GruppoTributoDTO gruppoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("nomeElaborazione") String nomeElaborazione,
         @ExecutionArgParam("tipoElaborazione") String tipoElaborazione,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tipoPratica") @Default('') String tipoPratica,
         @ExecutionArgParam("ruolo") @Default('-1') Long ruolo,
         @ExecutionArgParam("anno") @Default('-1') Long anno,
         @ExecutionArgParam("pratiche") def pratiche,
         @ExecutionArgParam("selectAllDetails") @Default('0') Boolean selectAllDetails,
         @ExecutionArgParam("autoExportAnagrTrib") @Default('0') Boolean autoExportAnagrTrib) {

        this.self = w

        this.nomeElaborazione = nomeElaborazione
        this.tipoElaborazione = TipoElaborazione.findById(tipoElaborazione)
        this.tipoPratica = tipoPratica == '' ? null : tipoPratica
        this.tipoTributo = TipoTributo.get(tipoTributo)
        this.ruolo = ruolo == -1 ? null : ruolo
        this.anno = anno == -1 ? null : anno
        this.selectAllDetails = selectAllDetails
        this.autoExportAnagrTrib = autoExportAnagrTrib
		
		// 	Gruppo tributo - Solo CUNI
		listaGruppiTributo = []
		if(tipoTributo == 'CUNI') {
			TipoTributo tipoTributoRaw = TipoTributo.findByTipoTributo(tipoTributo)
			List<GruppoTributoDTO> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoRaw)?.toDTO(["tipoTributo"])
			listaGruppiTributo << new GruppoTributoDTO()
			listaGruppiTributo.addAll(gruppiTributo)
		}
		gruppoTributo = null

        // Si associa a dettagli l'elengo delle pratiche.
        // Se null e si è passato il ruolo l'elenco verrà recuperato nel job
        this.dettagli = pratiche

        titolo = "Elaborazione Massiva"
    }

	@Command
	def onChangeGruppoTributo() {

	}
	
    @Command
    onSalvaElaborazione() {
		
        def pattern = /^[a-zA-Z0-9\-_]*$/
        def matcher = nomeElaborazione =~ pattern

        if (!matcher.find()) {
            Clients.showNotification("Caratteri ammessi: numeri, lettere, - e _.", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 2000, true)
            return
        }
        CreazioneElaborazioneJob.triggerNow([codiceUtenteBatch       : springSecurityService.currentUser.id,
                                             codiciEntiBatch         : springSecurityService.principal.amministrazione.codice,
                                             nomeElaborazione        : nomeElaborazione,
                                             tipoElaborazione        : tipoElaborazione,
                                             tipoTributo             : tipoTributo,
											 gruppoTributo			 : gruppoTributo?.gruppoTributo,
                                             tipoPratica             : tipoPratica,
                                             ruolo                   : ruolo,
                                             anno                    : anno,
                                             dettagli                : dettagli,
                                             creaElaborazioniSeparate: creaElaborazioniSeparate,
                                             creaElaborazioniAAT     : creaElaborazioniAAT,
                                             creaDettagliEredi           : creaDettagliEredi,
                                             selectAllDetails        : selectAllDetails,
                                             autoExportAnagrTrib     : autoExportAnagrTrib
        ])

        Clients.showNotification("Avvio creazione elaborazione.", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)

        onChiudi()
    }

    @Command
    def onChiudi() {
        Events.postEvent("onClose", self, null)
    }
}
