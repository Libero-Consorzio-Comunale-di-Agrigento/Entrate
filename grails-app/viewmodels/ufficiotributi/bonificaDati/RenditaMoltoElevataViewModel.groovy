package ufficiotributi.bonificaDati

import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.imposte.ImposteService

import org.zkoss.bind.annotation.AfterCompose
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zul.Listbox
import org.zkoss.zul.Listitem
import org.zkoss.zul.Window

import java.text.NumberFormat
import java.util.List;

class RenditaMoltoElevataViewModel extends HelpAnomaliePraticheViewModel {

    def ImposteService imposteService

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anomaliaSelezionata") def anomaliaSelezionata
         , @ExecutionArgParam("praticaSelezionata") AnomaliaPraticaDTO praticaSelezionata
		 , @ExecutionArgParam("lettura") @Default("true") Boolean lettura) {
		 
        super.init(w, anomaliaSelezionata, praticaSelezionata)

		this.lettura = lettura

        ogcoHelp = []

        def tempList = gestioneAnomalieService.getOgcoNonAnomali(anomaliaSelezionata.tipoAnomalia,
                anomaliaSelezionata.anno,
                praticaSelezionata.anomalia.oggetto.id,
                oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo,
                anomaliaSelezionata.categorie)

        // Si eliminano gli oggetti con rendita non compatibile con quella di riferimento impostata
        tempList.each {

            def rendita = oggettiService.getRenditaOggettoPratica(it.oggettoPratica.valore
                    , it.oggettoPratica.tipoOggetto.tipoOggetto ?: it.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , it.oggettoPratica.pratica.anno
                    , it.oggettoPratica.categoriaCatasto ?: it.oggettoPratica.oggetto.categoriaCatasto)

            if (
            // Definiti valore minimo e massimo
            (anomaliaSelezionata.renditaDa > 0 && anomaliaSelezionata.renditaA > 0 && (rendita < anomaliaSelezionata.renditaDa || rendita > anomaliaSelezionata.renditaA)) ||
                    // Definita solo rendita da
                    (anomaliaSelezionata.renditaDa > 0 && anomaliaSelezionata.renditaA == 0 && rendita < anomaliaSelezionata.renditaDa) ||
                    // Definita solo rendita a
                    (anomaliaSelezionata.renditaA > 0 && anomaliaSelezionata.renditaDa == 0 && rendita > anomaliaSelezionata.renditaA)
            ) {
                ogcoHelp << it
            }
        }

        // FIXME: estendere la gestione come indicato nella 27325
        /*
        listaFiltriCatasto = [new FiltroRicercaOggetto([
                categoriaCatasto: oggettoContribuente.oggettoPratica.categoriaCatasto,
                sezione         : oggettoContribuente.oggettoPratica.oggetto.sezione,
                foglio          : oggettoContribuente.oggettoPratica.oggetto.foglio,
                numero          : oggettoContribuente.oggettoPratica.oggetto.numero,
                subalterno      : oggettoContribuente.oggettoPratica.oggetto.subalterno,
                partita         : oggettoContribuente.oggettoPratica.oggetto.partita,
                zona            : oggettoContribuente.oggettoPratica.oggetto.zona

        ])]
        caricaListaCatasto()
        */
    }

    /**
     * Il componente dragable è tutto il listItem, ma invece che far
     * vedere il primo valore del listItem (che in questo caso è l'anno)
     * facciamo vedere il valore che verra' veramente droppato
     * (in questo caso oggettoPratica.valore).
     * @param l Listbox
     * @return
     */
    @Command
    setDragMessage(@ContextParam(ContextType.COMPONENT) Listbox l) {
        List<Listitem> lItems = l.getItems()
        for (Listitem lItem in lItems) {
            if (lItem.value.oggettoPratica.valore != null)
                lItem.setWidgetOverride("getDragMessage_", "function(){return '" + NumberFormat.getCurrencyInstance().format(lItem.value.oggettoPratica.valore) + "';}")
        }
    }


    @Command
    onRiporta() {
        super.onRiporta()
        if (ogcoHelpSelezionato) {
            oggettoContribuente.oggettoPratica.valore = oggettiService.getFValore(ogcoHelpSelezionato.oggettoPratica.valore
                    , ogcoHelpSelezionato.oggettoPratica.tipoOggetto?.tipoOggetto ?: ogcoHelpSelezionato.oggettoPratica.oggetto.tipoOggetto?.tipoOggetto
                    , ogcoHelpSelezionato.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto.categoriaCatasto
                    , oggettoContribuente.oggettoPratica.pratica.tipoPratica
                    , oggettoContribuente.oggettoPratica.flagValoreRivalutato)
            oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                    , oggettoContribuente.oggettoPratica.tipoOggetto?.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)
        } else {
            oggettoContribuente.oggettoPratica.valore = imposteService.getValoreDaRendita(oggettoContribuente.oggettoPratica.pratica.anno, immobileCatastoSelezionato.RENDITA, 3,
                    null, null, null,
                    immobileCatastoSelezionato.CATEGORIACATASTO, null)
            oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita = immobileCatastoSelezionato.RENDITA
        }   
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica.oggettoPraticaRendita, "rendita")
    }


    @Command
    onDropValore(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        if (event.dragged.value instanceof OggettoContribuenteDTO) {
            OggettoContribuenteDTO rifOgg = event.dragged.value
            oggettoContribuente.oggettoPratica.valore = oggettiService.getFValore(rifOgg.oggettoPratica.valore
                    , rifOgg.oggettoPratica.tipoOggetto.tipoOggetto ?: rifOgg.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , rifOgg.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto.categoriaCatasto
                    , oggettoContribuente.oggettoPratica.pratica.tipoPratica
                    , oggettoContribuente.oggettoPratica.flagValoreRivalutato)
            oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                    , oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)
        } else {
            def ogg = event.dragged.value

            oggettoContribuente.oggettoPratica.valore = imposteService.getValoreDaRendita(oggettoContribuente.oggettoPratica.pratica.anno, ogg.RENDITA, 3,
                    null, null, null,
                    ogg.CATEGORIACATASTO, null)
            oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita = ogg.RENDITA
        }
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica.oggettoPraticaRendita, "rendita")
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
