package ufficiotributi.imposte

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.SpecieRuolo
import it.finmatica.tr4.commons.TipoRuolo
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.imposte.FiltroRicercaListeDiCaricoRuoli
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class RuoliRicercaViewModel {

    // componenti
    Window self

    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    def specieRuolo = [null,
                       [codice: SpecieRuolo.ORDINARIO.specieRuolo, descrizione: '0 - Ordinario'],
                       [codice: SpecieRuolo.COATTIVO.specieRuolo, descrizione: '1 - Coattivo']
    ]

    def tipoRuolo = [null,
                     [codice: TipoRuolo.PRINCIPALE.tipoRuolo, descrizione: 'P - Principale'],
                     [codice: TipoRuolo.SUPPLETTIVO.tipoRuolo, descrizione: 'S - Suppletivo']
    ]

    def tipiEmissione = [null,
                         [codice: 'A', descrizione: 'Acconto'],
                         [codice: 'S', descrizione: 'Saldo'],
                         [codice: 'T', descrizione: 'Totale'],
                         [codice: 'X', descrizione: 'Altro']]

    // parametri
    FiltroRicercaListeDiCaricoRuoli mapParametri

    def listaCodiciTributo = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") def parametriRicerca) {

        this.self = w

        listaCodiciTributo = [new CodiceTributoDTO([id: null, descrizione: "(Tutti)"])] +
                OggettiCache.CODICI_TRIBUTO.valore.findAll { it?.tipoTributo?.tipoTributo == parametriRicerca.tipoTributo }
                        .sort { it.id }

        mapParametri = parametriRicerca ?: new FiltroRicercaListeDiCaricoRuoli()
    }

    @Command
    onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    onSvuotaFiltri() {

        mapParametri = new FiltroRicercaListeDiCaricoRuoli()
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
