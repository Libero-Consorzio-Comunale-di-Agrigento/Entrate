package it.finmatica.zkutils

import grails.util.Holders

import it.finmatica.tr4.dto.CfaAccTributiDTO

import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Listen
import org.zkoss.zul.ListModelList

class BandboxCfaAccTributi extends CustomBandbox {

	def numeroAcc

	Integer annoAcc = 2020
	Integer esercizio = 0
	Integer allowEmpty = 0

	public BandboxCfaAccTributi () {

		super()
		
		Executions.createComponents("/commons/bandboxCfaAccTributi.zul", this, null)
		
		Selectors.wireVariables(this, this, null)
		Selectors.wireComponents(this, this, false)
		Selectors.wireEventListeners(this, this)
	}

	protected void loadData() {

		if (getOggetto() != null) {
			if (getOggetto()[getProprieta()] == null) {
				getOggetto().numeroAcc = 0
				getOggetto().descrizioneAcc = ""
				getOggetto().descrizioneCompleta = ""
			}
		}
		else {
			def accTributi = newOggetto()
			setOggetto(accTributi)
		}

		def filtro = getOggetto()
		filtro.esercizio = esercizio ?: 0
		filtro.annoAcc = annoAcc ?: 0

		def elenco = Holders.grailsApplication.mainContext.getBean("datiContabiliService").getCfaAccTributiBandBox(filtro, paging.getPageSize(), paging.getActivePage(), allowEmpty)
		lista.setModel(new ListModelList<CfaAccTributiDTO>(elenco.lista))
		paging.setTotalSize(elenco.totale)
	}

	def newOggetto() {

		def accTributi = new CfaAccTributiDTO()
		accTributi.numeroAcc = numeroAcc ?: 0
		accTributi.descrizioneAcc = ""
		accTributi.descrizioneCompleta = ""

		return accTributi
	}

    void setOggettoEx(def oggetto) {
        if (oggetto != null) {
            setOggetto(oggetto)
        }
        else {
			setOggetto(newOggetto())
        };
    }

    def getOggettoEx() {
        return getOggetto()
    }

    String getIdentificativo() {
        return this.getAttribute("identificativo")
    }

	public Integer getAnnoAcc() {
		return this.annoAcc
	}

	public void setAnnoAcc(Integer annoAcc){
		this.annoAcc = annoAcc
	}
	
	public Integer getEsercizio() {
		return this.esercizio
	}

	public void setEsercizio(Integer esercizio){
		this.esercizio = esercizio
	}
	
	public void setAllowEmpty(Integer allowEmpty) {
		this.allowEmpty = allowEmpty
	}
	
	public Integer getAllowEmpty() {
		return this.allowEmpty
	}
	
	@Override
	@Listen("onSelect = listbox")
	public void selectData() {

		if (lista.getSelectedItem()) {

			getOggetto()[getProprieta()] = (lista.getSelectedItem().getValue().hasProperty(getProprieta()) ? 
													(lista.getSelectedItem().getValue()[getProprieta()] ?: "") : "")
			getOggetto()[getIdentificativo()] = (lista.getSelectedItem().getValue().hasProperty(getIdentificativo()) ? 
													(lista.getSelectedItem().getValue()[getIdentificativo()] ?: 0) : 0)
			setValue(getOggetto()[getProprieta()])

			Events.postEvent(Events.ON_SELECT, this, lista.getSelectedItem().getValue())

			close()
		}
	}

	@Override
	protected void controllaSingoloElemento() {}

}
