package archivio.dizionari

import it.finmatica.tr4.codifiche.CodificheEventiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioEventiViewModel {


    // Componenti
    Window self

    // Services
    def springSecurityService
    CodificheEventiService codificheEventiService

    // Dati
    def evento
    def tipo
    def isModifica
    def tipoEvento

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("evento") def ev,
         @ExecutionArgParam("tipo") def tp,
         @ExecutionArgParam("tipoEvento") def tpe,
         @ExecutionArgParam("isModifica") def ism) {

        this.self = w

        // isModifica = true l'utente sta modificando o eliminando un evento/tipoevento esistente, = false ne sta aggiungendo uno nuovo
        this.isModifica = ism

        // Indica se l'entità in questione è un Tipo Evento o Evento
        this.tipo = tp

        // Indica il tipo evento selezionato, serve per impostarlo come attributo 'tipoEvento' nella creazione di un nuovo Evento
        this.tipoEvento = tpe

        this.evento = ev ?: [:]

    }

    // Eventi interfaccia

    @Command
    onSalva() {

        if (this.tipo.equals("tipoevento")) {
            def dto = codificheEventiService.getTipoEventoDTO(this.evento, this.isModifica)

            //Se true esiste già un tipoevento con lo stesso identificatore
            if (dto instanceof String) {
                Clients.showNotification(dto, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                return
            }

            //Converto in maiuscolo la descrizione prima di salvarla
            dto.descrizione = dto.descrizione.toUpperCase()

            codificheEventiService.salvaTipoEvento(dto)

        } else if (this.tipo.equals("evento")) {

            // Imposto l'attributo tipoEvento uguale al Tipo Evento selezionato
            this.evento.tipoEvento = this.tipoEvento
            def dto = codificheEventiService.getEventoDTO(this.evento, this.isModifica)

            //Converto in maiuscolo la descrizione prima di salvarla
            dto.descrizione = dto.descrizione.toUpperCase()

            codificheEventiService.salvaEvento(dto)
        }
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
