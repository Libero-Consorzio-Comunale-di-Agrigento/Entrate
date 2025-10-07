package elaborazioni


import it.finmatica.tr4.elaborazioni.ElaborazioneMassiva
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.TipoAttivita
import it.finmatica.tr4.elaborazioni.TipoAttivitaElaborazioni
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class FiltriDettagliViewModel {

    // componenti
    Window self

    def listaAttivita
    def attivitaSelezionata
    def elaborazione
    def tipiAttivita
    def destinazioneInvioLabel

    ElaborazioniService elaborazioniService
    SmartPndService smartPndService

    def filtri = [
            codFiscale    : null,
            cognome       : null,
            nome          : null,
            stampa        : 'T',
            tipografia    : 'T',
            documentale   : 'T',
            agid          : 'T',
            appio         : 'T',
            esportaAT     : 'T',
            controlloAT   : 'T',
            allineamentoAT: 'T',
            presenzaErrori: 'T',
            selezionati   : 'T',
            attivita      : null
    ]

    def tipoMassivaPratica = false
    def tipoBollettazione = false
    def tipoAnagrafeTributaria = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def filtri,
         @ExecutionArgParam("idElaborazione") def idElaborazione
    ) {
        this.self = w
        this.filtri = filtri ?: this.filtri

        listaAttivita = [null] + elaborazioniService.attivitaElaborazione(idElaborazione as Long)

        elaborazione = ElaborazioneMassiva.get(idElaborazione as Long)
        def tipoElaborazione = elaborazione?.tipoElaborazione?.id
        tipoMassivaPratica = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE
        tipoBollettazione = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA
        tipoAnagrafeTributaria = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_ANAGRAFE_TRIBUTARIA

        this.destinazioneInvioLabel = smartPndService.smartPNDAbilitato() ? SmartPndService.TITOLO_SMART_PND : 'Documentale'

        this.tipiAttivita = TipoAttivita.findAll().collectEntries {
            [(it.id): TipoAttivitaElaborazioni.findByTipoAttivitaAndTipoElaborazione(it, elaborazione.tipoElaborazione) != null]
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCerca() {
        filtri.idAttivita = attivitaSelezionata?.idAttivita
        Events.postEvent(Events.ON_CLOSE, self, [filtri: filtri, filtriAttivi: filtriAttivi()])
    }

    @NotifyChange(["filtri"])
    @Command
    def onSvuotaFiltri() {
        filtri.codFiscale = null
        filtri.cognome = null
        filtri.nome = null
        filtri.stampa = 'T'
        filtri.tipografia = 'T'
        filtri.documentale = 'T'
        filtri.agid = 'T'
        filtri.appio = 'T'
        filtri.esportaAT = 'T'
        filtri.controlloAT = 'T'
        filtri.allineamentoAT = 'T'
        filtri.presenzaErrori = 'T'
        filtri.selezionati = 'T'
        filtri.attivita = null
    }

    private boolean filtriAttivi() {
        return (filtri.nome || filtri.cognome || filtri.codFiscale || filtri.tipografia != 'T' || filtri.stampa != 'T'
                || filtri.agid != 'T' || filtri.presenzaErrori != 'T' || filtri.selezionati != 'T' || filtri.attivita
                || filtri.documentale != 'T' || filtri.appio != 'T'
                || filtri.esportaAT != 'T' || filtri.controlloAT != 'T' || filtri.allineamentoAT != 'T')
    }
}
