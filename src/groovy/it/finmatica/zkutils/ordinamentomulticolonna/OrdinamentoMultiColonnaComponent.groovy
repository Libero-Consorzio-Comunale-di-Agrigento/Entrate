package it.finmatica.zkutils.ordinamentomulticolonna


import org.apache.commons.lang.SerializationUtils
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.IdSpace
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Listen
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Div
import org.zkoss.zul.ListModelList
import org.zkoss.zul.Listbox

class OrdinamentoMultiColonnaComponent extends Div implements IdSpace {

    private final def CSS_ASC = "z-column-sort-asc_ z-listheader-sort-asc_"
    private final def CSS_DSC = "z-column-sort-dsc_ z-listheader-sort-dsc_"
    final static def VERSO_ASC = "ASC"
    final static def VERSO_DSC = "DESC"

    @Wire
    Listbox campiOrdinamentoListbox

    def campiOrdinamento = [:]

    def ordinamentoCss = [
            0: '',
            1: CSS_ASC,
            2: CSS_DSC
    ]

    def ordinePredefinito
    private def listboxData

    OrdinamentoMultiColonnaComponent() {
        super()

        Executions.createComponents("/commons/ordinamentoMultiColonnaComponent.zul", this, null)

        Selectors.wireVariables(this, this, null)
        Selectors.wireComponents(this, this, false)
        Selectors.wireEventListeners(this, this)
    }

    def setOrdinePredefinito(def ordinePredefinito) {
        this.ordinePredefinito = ordinePredefinito
    }

    def getCampiOrdinamento() {
        return campiOrdinamento
    }

    void setCampiOrdinamento(def campiOrdinamento) {
        this.campiOrdinamento = campiOrdinamento ?: [:]

        this.campiOrdinamento.each { k, v ->
            if (v.cssOrdinamento == null) {
                v.cssOrdinamento = v.verso == VERSO_ASC ? CSS_ASC : CSS_DSC
            }
            if (v.posizione == null) {
                v.posizione = this.campiOrdinamento.max { it.value.posizione }.value.posizione + 1
            }
        }

        generaLista()
    }

    private generaLista() {

        listboxData = campiOrdinamento.sort { it.value.posizione }.values()

        campiOrdinamentoListbox.model = new ListModelList(listboxData)
        campiOrdinamentoListbox.invalidate()
    }

    def cambiaOrdinamento(def campo) {

        if (campiOrdinamento[campo]?.attivo) {
            switch (campiOrdinamento[campo].verso) {
                case VERSO_ASC:
                    campiOrdinamento[campo].verso = VERSO_DSC
                    campiOrdinamento[campo].cssOrdinamento = ordinamentoCss[2]
                    break
                case VERSO_DSC:
                    campiOrdinamento[campo].verso = VERSO_ASC
                    campiOrdinamento[campo].cssOrdinamento = ordinamentoCss[1]
                    break
            }
        }

        // Si ordinano i parametri in base alla posizione
        campiOrdinamento = campiOrdinamento.sort { it.value.posizione }
        return campiOrdinamento
    }

    @Listen("onClick = button#reset")
    void onRipristinaOrdinePredefinito() {
        ripristinaOrdinePredefinito()
        generaLista()
        Events.postEvent(Events.ON_CHANGE, this, null)
    }

    private ripristinaOrdinePredefinito() {
        campiOrdinamento.each {
            it.value.verso = ordinePredefinito[it.key].verso
            it.value.posizione = ordinePredefinito[it.key].posizione
            it.value.attivo = ordinePredefinito[it.key].attivo
            it.value.cssOrdinamento = ordinePredefinito[it.key].cssOrdinamento
        }
    }

    @Listen("onCambiaDirezioneOrdinamentoClick = #campiOrdinamentoListbox")
    void onCambiaDirezioneOrdinamentoClick(Event event) {
        if (campiOrdinamento[event.data.id].attivo) {
            cambiaOrdinamento(event.data.id)
            generaLista()
            Events.postEvent(Events.ON_CHANGE, this, null)
        }
    }

    @Listen("onAttivaClick = #campiOrdinamentoListbox")
    void onAttivaClick(Event event) {
        campiOrdinamento[event.data.id].attivo = !campiOrdinamento[event.data.id].attivo
        if (!campiOrdinamento[event.data.id].attivo) {
            campiOrdinamento[event.data.id].cssOrdinamento = ""
        } else {
            campiOrdinamento[event.data.id].cssOrdinamento =
                    campiOrdinamento[event.data.id].verso == VERSO_ASC ? ordinamentoCss[1] : ordinamentoCss[2]
        }

        generaLista()
        Events.postEvent(Events.ON_CHANGE, this, null)
    }

    @Listen("onDrop = #campiOrdinamentoListbox")
    void drop(Event event) {
        swapMapKeys(
                campiOrdinamento,
                event.origin.dragged.value,
                event.origin.target.value
        )
        generaLista()
        Events.postEvent(Events.ON_CHANGE, this, null)
    }

    private def swapMapKeys(Map map, def campo1, def campo2) {
        def entry1 = map.find { it.value.posizione == campo1.posizione }
        def entry2 = map.find { it.value.posizione == campo2.posizione }

        if (entry1 && entry2) {
            def tmpPos = entry1.value.posizione
            entry1.value.posizione = entry2.value.posizione
            entry2.value.posizione = tmpPos
        }

        return map
    }


    private clonaParametri(def parametri) {
        return SerializationUtils.clone(parametri)
    }
}
