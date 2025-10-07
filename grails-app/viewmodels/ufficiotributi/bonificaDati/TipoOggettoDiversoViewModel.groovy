package ufficiotributi.bonificaDati

import java.util.List;

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.oggetti.OggettiService

import org.zkoss.bind.annotation.Default
import org.zkoss.bind.annotation.AfterCompose
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listbox
import org.zkoss.zul.Listitem
import org.zkoss.zul.Window

class TipoOggettoDiversoViewModel extends HelpAnomaliePraticheViewModel {

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

	@Init init(@ContextParam( ContextType.COMPONENT) Window w
			, @ExecutionArgParam("anomaliaSelezionata") def anomaliaSelezionata
			, @ExecutionArgParam("praticaSelezionata") AnomaliaPraticaDTO praticaSelezionata
			, @ExecutionArgParam("lettura") @Default("true") Boolean lettura) {
			
		super.init(w, anomaliaSelezionata, praticaSelezionata)
		
		this.lettura = lettura

		ogcoHelp = gestioneAnomalieService.getTiogNonAnomali(anomaliaSelezionata.anno, praticaSelezionata.anomalia.oggetto.id, oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo, anomaliaSelezionata.flagImposta)
	}

	@Command onRiporta () {
		super.onRiporta()
		oggettoContribuente.oggettoPratica.tipoOggetto = ogcoHelpSelezionato.oggettoPratica.tipoOggetto
		BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "tipoOggetto")
	}


	@Command onDropTipoOggetto(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
		DropEvent event = (DropEvent) ctx.getTriggerEvent()
		if (event.dragged.value instanceof OggettoContribuenteDTO) {
            OggettoContribuenteDTO rifOgg = event.dragged.value
            oggettoContribuente.oggettoPratica.tipoOggetto = rifOgg.oggettoPratica.tipoOggetto
        } else {
            def ogge = event.dragged.value
            oggettoContribuente.oggettoPratica.tipoOggetto = catastoCensuarioService.trasformaTipoOggetto(ogge.TIPOOGGETTO)
        }
		BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "tipoOggetto")		
	}
	
	/**
	 * Il componente dragable è tutto il listItem, ma invece che far
	 * vedere il primo valore del listItem (che in questo caso è l'anno)
	 * facciamo vedere il valore che verra' veramente droppato
	 * (in questo caso oggettoPratica.valore).
	 * @param l Listbox
	 * @return
	 */
	@Command setDragMessage (@ContextParam(ContextType.COMPONENT) Listbox l) {
		List<Listitem> lItems = l.getItems()
		for (Listitem lItem in lItems) {
			lItem.setWidgetOverride("getDragMessage_","function(){return '"+lItem.value.oggettoPratica.tipoOggetto.tipoOggetto.toString()+" - "+lItem.value.oggettoPratica.tipoOggetto.descrizione.substring(0, 10)+"..."+"';}")
		}
	}
	
	@AfterCompose
	void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

		if(this.lettura) {
			componenti.each {
				it.disabled = true
			}
		}
	}
}
