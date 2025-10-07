package it.finmatica.zkutils

import grails.util.Holders
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import org.zkoss.bind.BindUtils
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.ListModelList

/// BandBox per i Comuni, specifico per le Forniture AE
/// Prevede un parametro aggiuntivo "progrDoc" che consente di filtrare l'elenco dei Comuni alle sole corrispondenze
/// con i valori di "COD_ENTE_COMUNALE" dei record di "FORNITURE_AE", tutti i record, con quello specifico DOCUMENTO_ID
/// Non filtra se "progrDoc = 0

class BandboxComuniFAE extends BandboxComuni {
    
    Long provStato = 0
    Long progrDoc = 0

    public BandboxComuniFAE() {

        super()
    }

    @Override
    protected void loadData() {
        def elencoComuni = Holders.grailsApplication.mainContext.getBean("ad4ComuniService").listaComuniFAE(getOggetto()[getProprieta()], provStato, progrDoc, paging.getPageSize(), paging.getActivePage())

        if (elencoComuni.lista.isEmpty()) {
            Events.postEvent(Events.ON_ERROR, this, "dato_non_valido")
        }

        lista.setModel(new ListModelList<Ad4ComuneDTO>(elencoComuni.lista))
        paging.setTotalSize(elencoComuni.totale)
    }

	public Long getProgrDoc() {
		return this.progrDoc
	}
	public void setProgrDoc(Long value){
		this.progrDoc = value
	}

	public Long getProvStato() {
		return this.provStato
	}
	public void setProvStato(Long value){
		this.provStato = value
	}
}
