package archivio.dizionari

import it.finmatica.tr4.CodiciAttivita
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.codifiche.CodificheBaseService
import it.finmatica.tr4.commons.OggettiCacheMap
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCodificheBaseViewModel {


    // Componenti
    Window self

    OggettiCacheMap oggettiCacheMap

    // Services
    def springSecurityService
    CodificheBaseService codificheBaseService


    // Comuni
    boolean isModifica = false
    boolean esistente = false
    boolean isClone = false

    String tipoCodifica
    String intestazioneTipo
    String intestazioneDescrizione
    String intestazioneOrdine

    def textboxMaxLength
    def listaCodSoggetto

    // Dati
    def codificaGenerica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codificaGenerica") def cd,
         @ExecutionArgParam("tipoCodifica") def tcd,
         @ExecutionArgParam("intestazioneTipo") def it,
         @ExecutionArgParam("intestazioneDescrizione") def id,
         @ExecutionArgParam("intestazioneOrdine") def io,
         @ExecutionArgParam("isModifica") boolean md,
         @ExecutionArgParam("isClone") boolean ic,
         @ExecutionArgParam("listaCodSoggetto") def lcs) {

        self = w

        // isModifica = true l'utente sta modificando una entry già esistente, se = false ne sta aggiungendo una nuova
        isModifica = md
        tipoCodifica = tcd
        intestazioneTipo = it
        intestazioneDescrizione = id
        intestazioneOrdine = io
        codificaGenerica = cd ?: [:]
        esistente = (cd != null)
        isClone = ic
        listaCodSoggetto = lcs

        //Applica il relativo attributo 'maxlength' in dettaglioCodificheBase.zul nel caso di CodiciAttivita e TipoStato
        if (tipoCodifica.equalsIgnoreCase("codiciattività")) {
            textboxMaxLength = CodiciAttivita.constraints.get("codAttivita").properties.get("maxSize")
        }        else if (tipoCodifica.equalsIgnoreCase("stati")) {
            textboxMaxLength = TipoStato.constraints.get("tipoStato").properties.get("maxSize")
        }
    }

    // Eventi interfaccia
    @Command
    onSalva() {

        def dto = codificheBaseService.getCodifica(codificaGenerica, tipoCodifica, isModifica)

        if (dto instanceof String) {
            Clients.showNotification(dto, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        //Nel caso dei recapiti non è possibile aggiungerne uno nuovo se questo ha codice < 10
        if (tipoCodifica == "recapiti" && dto.id < 10) {
            Clients.showNotification("Non è possibile aggiungere un Recapito con valore minore di 10", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        //Converto in maiuscolo la descrizione prima di salvarla (solo nel caso non si tratti di Stati o CodiciAttività, questi possono essere minuscoli)
        if (tipoCodifica != "stati" && tipoCodifica != "codiciAttività") {
            dto.descrizione = dto.descrizione.toUpperCase()
        }

        //Per gli Stati, converto il tipo in maiuscolo
        if (tipoCodifica == "stati") {
            dto.tipoStato = dto.tipoStato.toUpperCase()
        }

        codificheBaseService.salvaCodifica(dto)
        oggettiCacheMap.refresh()

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
