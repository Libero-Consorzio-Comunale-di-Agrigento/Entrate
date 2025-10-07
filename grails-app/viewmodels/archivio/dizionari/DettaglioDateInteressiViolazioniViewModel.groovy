package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.interessiViolazioni.InteressiViolazioniService
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.DateInteressiViolazioni
import it.finmatica.tr4.dto.DateInteressiViolazioniDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Bandbox
import org.zkoss.zul.Window

import org.hibernate.SessionFactory

class DettaglioDateInteressiViolazioniViewModel {

    // Componenti
    Window self

    SessionFactory sessionFactory

    // Service
    InteressiViolazioniService interessiViolazioniService
    CommonService commonService
    CompetenzeService competenzeService

    DateInteressiViolazioniDTO date
    Boolean existing = false

    Boolean lettura = true
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("date") DateInteressiViolazioniDTO div,
         @ExecutionArgParam("existing") Boolean ex) {

        this.self = w

        this.date = div
        this.existing = ex      /// (this.date.isTransient() == false)

        aggiornaCompetenze()

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    def onSalva() {

        if (areRequiredFieldsEmptyAndNotify()) {
            return
        }

        if (isOverlappingAndNotify()) {
            return
        }
        
        interessiViolazioniService.salvaDate(this.date.toDomain())

        existing = true
        BindUtils.postNotifyChange(null, null, this, "existing")

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        
        Events.postEvent(Events.ON_CLOSE, self, [salvato: true])
    }

    private def areRequiredFieldsEmptyAndNotify() {

        def errors = interessiViolazioniService.validaDate(date)

        if (!errors.empty) {
            Clients.showNotification(errors.join('\n'),Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return true
        }

        return false
    }

    def isOverlappingAndNotify() {

        def errors = []

        if((!this.existing) && (this.date.getDomainObject())) {
            errors << "Esiste gia' un dettaglio con queste impostazioni!"
        }
        else {
            if (interessiViolazioniService.existsOverlappingDate(this.date)) {
                errors << "Esistono periodi intersecanti"
            }
        }

        if (!errors.empty) {
            Clients.showNotification(errors.join('\n'),Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return true
        }

        return false
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def aggiornaCompetenze() {

        String tipoTributo = this.date?.tipoTributo?.tipoTributo ?: '-'
        lettura = (competenzeService.tipoAbilitazioneUtente(tipoTributo) != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        BindUtils.postNotifyChange(null, null, this, "lettura")
    }
}
