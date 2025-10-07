package ufficiotributi.imposte


import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoOccupazione
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaImposteContribuenteRicercaViewModel {

    // services
    def springSecurityService

    // componenti
    Window self

    def tipoOccupazione = [null] +
            [codice: TipoOccupazione.P.id, descrizione: 'Solo Permanenti'] +
            [codice: TipoOccupazione.T.id, descrizione: 'Solo Temporanee']

    def tipoOccupazioneSelected

    def filtroTipoLista = [null] +
            [codice: 'X-XX', descrizione: 'Tutto, qualsiasi decorrenza'] +
            [codice: 'X-AC', descrizione: 'Tutto, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'T-AC', descrizione: 'Temporanee, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'P-AC', descrizione: 'Permanenti, anno corrente (decorrenza dal 01/01)'] +
            [codice: 'P-AP', descrizione: 'Permanenti, anni precedenti (decorrenza prima del 01/01)']

    def mapParametri = [
            cognome                : "",
            nome                   : "",
            cf                     : "",
            daDataPratica          : null,
            aDataPratica           : null,
            daDataCalcolo          : null,
            aDataCalcolo           : null,
            tipoOccupazione        : null,
            tipoContatto           : null,
            personaFisica          : true,
            personaGuridica        : true,
            intestazioniParticolari: true
    ]
    def tipoListaOriginale = null
    def tipoListaSelezionato = null
    def listaTipiContatto
    def tipoContattoSelezionato = null
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") def filtri,
         @ExecutionArgParam("tipoTributo") def tt) {

        this.self = w

        mapParametri = filtri ?: mapParametri
        tipoListaOriginale = mapParametri.tipoLista

        tipoListaSelezionato = filtroTipoLista.find { it?.codice == tipoListaOriginale }

        tipoOccupazioneSelected = tipoOccupazione.find { it != null && it.codice == mapParametri.tipoOccupazione }

        listaTipiContatto = [null] + OggettiCache.TIPI_CONTATTO.valore.sort { it.tipoContatto }

        tipoContattoSelezionato = listaTipiContatto.find {
            if (it?.tipoContatto) {
                it.tipoContatto == mapParametri.tipoContatto
            }
        }

        tipoTributo = tt
    }

    @Command
    def onCerca() {

        mapParametri.tipoOccupazione = tipoOccupazioneSelected?.codice

        mapParametri.tipoLista = tipoListaSelezionato?.codice

        mapParametri.tipoContatto = tipoContattoSelezionato?.tipoContatto

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    def svuotaFiltri() {

        mapParametri = [
                cognome                : "",
                nome                   : "",
                cf                     : "",
                daDataPratica          : null,
                aDataPratica           : null,
                daDataCalcolo          : null,
                aDataCalcolo           : null,
                tipoOccupazione        : null,
                tipoContatto           : null,
                personaFisica          : true,
                personaGiuridica       : true,
                intestazioniParticolari: true
        ]

        tipoOccupazioneSelected = tipoOccupazione.find { it != null && it.codice == mapParametri.tipoOccupazione }

        tipoListaSelezionato = filtroTipoLista.find { it?.codice == tipoListaOriginale }

        tipoContattoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "tipoListaSelezionato")
        BindUtils.postNotifyChange(null, null, this, "tipoOccupazioneSelected")
        BindUtils.postNotifyChange(null, null, this, "tipoContattoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
