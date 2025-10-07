package ufficiotributi.bonificaDati.nonDichiarati

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zul.Window

class NonDichiaratiRicercaViewModel {

    Window self

    List<CategoriaCatastoDTO> listaCategorieCatasto
    CategoriaCatastoDTO categoriaCatastoSelected

    def filtri = [
            immobile    : null,
            sezione     : "",
            foglio      : "",
            numero      : "",
            subalterno  : "",
            zona        : "",
            partita     : "",
            categoria   : "",
            classe      : "",
            indirizzo   : "",
            numCivDa    : "",
            numCivA     : "",
            numCivTipo  : "E",        // "P", "D" oppure 'E'
            tipoImmobile: "E"        // "F", "T" oppure 'E'
    ]

    @NotifyChange([
            "listaCategorieCatasto",
            "filtri"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def f) {

        this.self = w

        listaCategorieCatasto = CategoriaCatasto.findAllFlagReale(sort: "categoriaCatasto").toDTO()

        def categoriaVuota = new CategoriaCatastoDTO(categoriaCatasto: "", descrizione: "Nessuna categoria", eccezione: "", flagReale: false)
        listaCategorieCatasto.add(0, categoriaVuota)

        filtri = f ?: filtri

        categoriaCatastoSelected = listaCategorieCatasto.find {
            it.categoriaCatasto == filtri.categoria
        }
    }

    @Command
    onSvuotaFiltri() {

        filtri.immobile = null
        filtri.sezione = ""
        filtri.foglio = ""
        filtri.numero = ""
        filtri.subalterno = ""
        filtri.zona = ""
        filtri.partita = ""
        filtri.classe = ""
        filtri.indirizzo = ""
        filtri.numCivDa = ""
        filtri.numCivA = ""
        filtri.numCivTipo = 'E'        // 'P', 'D' oppure 'E'
        filtri.tipoImmobile = 'E'        // "F", "T" oppure 'E'


        categoriaCatastoSelected = null

        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "categoriaCatastoSelected")
    }

    @Command
    onCerca() {

        filtri.categoria = (categoriaCatastoSelected != null) ? categoriaCatastoSelected.categoriaCatasto : ""

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: filtri])
    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onChangeCategoria(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {

        if (event?.getValue() && !filtri.categoria) {

            CategoriaCatastoDTO categoriaPers = new CategoriaCatastoDTO(categoriaCatasto: event.getValue())
            listaCategorieCatasto << categoriaPers
            filtri.categoria = categoriaPers
        }
    }
}
