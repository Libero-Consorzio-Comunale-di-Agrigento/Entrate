package it.finmatica.zkutils

import grails.util.Holders
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import org.zkoss.bind.BindUtils
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.ListModelList

class BandboxComuni extends CustomBandbox {

    public BandboxComuni() {
        super()

        Executions.createComponents("/commons/bandboxComuni.zul", this, null)

        Selectors.wireVariables(this, this, null)
        Selectors.wireComponents(this, this, false)
        Selectors.wireEventListeners(this, this)
    }

    protected void loadData() {
        def elencoComuni = Holders.grailsApplication.mainContext.getBean("ad4ComuniService").listaComuni(getOggetto()[getProprieta()], paging.getPageSize(), paging.getActivePage())

        if (elencoComuni.lista.isEmpty()) {
            Events.postEvent(Events.ON_ERROR, this, "dato_non_valido")
        }

        lista.setModel(new ListModelList<Ad4ComuneDTO>(elencoComuni.lista))
        paging.setTotalSize(elencoComuni.totale)
    }

    @Override
    protected void controllaSingoloElemento() {

        // Nel caso ci sia solo un elemento restituito dalla ricerca, viene selezionato in automatico
        if (lista.model?.size() == 1) {
            getOggetto()[getProprieta()] = lista.model[0].denominazione
            setValue(lista.model[0].denominazione)
            Events.postEvent(Events.ON_SELECT, this, lista.model[0])
            close()
        }
    }

}
