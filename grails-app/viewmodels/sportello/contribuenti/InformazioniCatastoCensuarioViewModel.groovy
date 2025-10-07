package sportello.contribuenti

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.TipoOggettoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class InformazioniCatastoCensuarioViewModel {

    Window self

    def titoloPagina = ""

    def oggetto
    def listaImmobili
    def listaProprietari
    String annotazione = ""
    def oggettoSelezionato
    def oggettoSelezionatoPrecedente

    //service
    CatastoCensuarioService catastoCensuarioService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("oggetto") def oggettoContribuente) {
        this.self = w
        oggetto = oggettoContribuente

        listaImmobili = []

        def tipoOggetto = ''
        if (oggettoContribuente.tipoOggetto instanceof TipoOggettoDTO) {
            tipoOggetto = oggettoContribuente?.tipoOggetto?.tipoOggetto as Integer
        } else {
            tipoOggetto = oggettoContribuente.tipoOggetto as Integer
        }

        if (tipoOggetto >= 3 || oggettoContribuente.TIPOOGGETTO == 'F'
                || (oggettoContribuente.tipoOggetto in [TipoOggetto, TipoOggettoDTO] && oggettoContribuente.tipoOggetto?.tipoOggetto == 3)) {
            listaImmobili = catastoCensuarioService.getImmobiliCatastoUrbano(
                    [new FiltroRicercaOggetto(
                            [
                                    sezione   : oggetto.sezione ?: oggetto.SEZIONE,
                                    foglio    : oggetto.foglio ?: oggetto.FOGLIO,
                                    numero    : oggetto.numero ?: oggetto.NUMERO,
                                    subalterno: oggetto.subalterno ?: oggetto.SUBALTERNO
                            ])], true
            )
        } else if (tipoOggetto in [1, 2] || oggettoContribuente.TIPOOGGETTO == 'T') {

            listaImmobili = catastoCensuarioService.getTerreniCatastoUrbano(
                    [new FiltroRicercaOggetto(
                            [
                                    sezione   : oggetto.sezione ?: oggetto.SEZIONE,
                                    foglio    : oggetto.foglio ?: oggetto.FOGLIO,
                                    numero    : oggetto.numero ?: oggetto.NUMERO,
                                    subalterno: oggetto.subalterno ?: oggetto.SUBALTERNO
                            ])], true
            )
        }

        listaImmobili.sort { a, b ->
            a.DATAEFFICACIAINIZIO <=> b.DATAEFFICACIAINIZIO ?: b.DATAEFFICACIAFINE <=> a.DATAEFFICACIAFINE
        }

        if (!listaImmobili.isEmpty()) {
            oggettoSelezionato = listaImmobili[0]
        }

        caricaListaProprietari()

        creaTitolo()
    }

    @NotifyChange("listaProprietari")
    @Command
    def onSelezionaOggetto() {
        if (oggettoSelezionatoPrecedente?.IDIMMOBILE != oggettoSelezionato?.IDIMMOBILE) {
            caricaListaProprietari()
            oggettoSelezionatoPrecedente = oggettoSelezionato
        }
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Annotazioni", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    onOpenSituazioneContribuente(@BindingParam("cf") String cf) {

        def ni = Contribuente.findByCodFiscale(cf)?.soggetto?.id

        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    private def creaTitolo() {
        titoloPagina = oggetto.oggetto != null ? "Oggetto: ${oggetto.oggetto}" : "Immobile: ${oggetto.IDIMMOBILE}"
        titoloPagina += oggetto.indirizzo ? " - ${oggetto.indirizzo}" : ""

        def sez = (oggetto.sezione ?: oggetto.SEZIONE)
        titoloPagina += sez ? " - Sez.: ${sez}" : ""
        def fgl = oggetto.foglio ?: oggetto.FOGLIO
        titoloPagina += fgl ? " - Fgl.: ${fgl}" : ""
        def num = oggetto.numero ?: oggetto.NUMERO
        titoloPagina += num ? " - Num.: ${num}" : ""
        def sub = oggetto.subalterno ?: oggetto.SUBALTERNO
        titoloPagina += sub ? " - Sub.: ${sub}" : ""

        return titoloPagina
    }

    private caricaListaProprietari() {
        if (!listaImmobili.isEmpty()) {
            listaProprietari = catastoCensuarioService.getProprietariCatastoCensuario(
                    oggettoSelezionato.IDIMMOBILE, oggettoSelezionato.TIPOOGGETTO
            )
            listaProprietari.each {
                it.contribuente = (Contribuente.findByCodFiscale(it.CODFISCALE)?.soggetto?.id != null)
            }
        }
    }

}
