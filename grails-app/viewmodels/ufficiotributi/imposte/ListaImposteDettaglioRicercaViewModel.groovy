package ufficiotributi.imposte


import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaImposteDettaglioRicercaViewModel {

    // services
    def springSecurityService

    // componenti
    Window self

    def filtroTipoLista = [null] +
            [codice: 'X-XX', descrizione: 'Tutto, qualsiasi decorrenza'] +
            [codice: 'X-AC', descrizione: 'Tutto, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'T-AC', descrizione: 'Temporanee, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'P-AC', descrizione: 'Permanenti, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'P-AP', descrizione: 'Permanenti, anni precedenti (decorrenza prima del 01/01)']

    def mapParametri = [
            nome                   : "",
            cognome                : "",
            cf                     : "",
            indirizzo              : null,
            numeroCivico           : null,
            suffisso               : null,
            interno                : null,
            sezione                : null,
            foglio                 : null,
            numero                 : null,
            subalterno             : null,
            daDataDecorrenza       : null,
            aDataDecorrenza        : null,
            daDataCessazione       : null,
            aDataCessazione        : null,
            personaGiuridica       : true,
            personaFisica          : true,
            intestazioniParticolari: true
    ]
    def tipoListaOriginale = null
    def tipoListaSelezionato = null
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") def parametriRicerca,
         @ExecutionArgParam("tipoTributo") def tt) {

        this.self = w
        this.tipoTributo = tt

        mapParametri = parametriRicerca ?: mapParametri
        tipoListaOriginale = mapParametri.tipoLista;

        tipoListaSelezionato = filtroTipoLista.find { it?.codice == tipoListaOriginale }
    }

    @Command
    def onCerca() {

        mapParametri.tipoLista = tipoListaSelezionato?.codice;

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    def svuotaFiltri() {

        mapParametri = [
                nome                   : "",
                cognome                : "",
                cf                     : "",
                indirizzo              : null,
                numeroCivico           : null,
                suffisso               : null,
                interno                : null,
                sezione                : null,
                foglio                 : null,
                numero                 : null,
                subalterno             : null,
                daDataDecorrenza       : null,
                aDataDecorrenza        : null,
                daDataCessazione       : null,
                aDataCessazione        : null,
                personaFisica          : true,
                personaGiuridica       : true,
                intestazioniParticolari: true
        ]

        tipoListaSelezionato = filtroTipoLista.find { it?.codice == tipoListaOriginale }

        BindUtils.postNotifyChange(null, null, this, "tipoListaSelezionato")
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
