package archivio.dizionari

import it.finmatica.tr4.Detrazione
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.DetrazioneDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.DetrazioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class NuovaDetrazioneViewModel {

    Window self
    CommonService commonService
    DetrazioniService detrazioniService
    CompetenzeService competenzeService

    TipoTributoDTO tipoTributo
    DetrazioneDTO detrazione
	
	boolean lettura
    boolean inModifica
    def labels
    boolean flagPertinenze
    Short anno

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("tipoTributo") String tt
         , @ExecutionArgParam("detrazione") DetrazioneDTO det
         , @ExecutionArgParam("modifica") boolean m
		 , @ExecutionArgParam("lettura") boolean lt) {
		 
        this.self = w
		
		lettura = lt
        inModifica = m

        tipoTributo = competenzeService.tipiTributoUtenza().find { it.tipoTributo == tt }

        if (!inModifica) {
            if (det == null) {
                detrazione = new DetrazioneDTO()
                acquireDetrazione()
            } else {
                detrazione = det
                acquireDetrazione(det)
            }
        } else {
            detrazione = Detrazione.findByTipoTributoAndAnno(tipoTributo.getDomainObject(), det.anno).toDTO()
            acquireDetrazione(detrazione)
        }

        labels = commonService.getLabelsProperties('dizionario')
    }

    private void acquireDetrazione(def detrazione = null) {
        if (!detrazione) {
            Calendar now = Calendar.getInstance()
            anno = now.get(Calendar.YEAR) as Short
            flagPertinenze = false
            return
        }

        anno = new Short(detrazione.anno)
        flagPertinenze = detrazione.flagPertinenze == "S"
    }


    @Command
    onSalva() {
        composeDetrazione()

        if (!inModifica && detrazioniService.existsDetrazione(tipoTributo, detrazione)) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted, 'una Detrazione', 'questo Anno')
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        detrazioniService.salvaDetrazione(tipoTributo, detrazione, inModifica)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    private void composeDetrazione() {
        detrazione.anno = anno.shortValue()
        detrazione.flagPertinenze = flagPertinenze ? 'S' : null
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
