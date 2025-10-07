package pratiche.utenze

import it.finmatica.tr4.contribuenti.UtenzeService
import it.finmatica.tr4.dto.ArchivioVieDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ElencoUtenzeRicercaViewModel {

    Window self

    UtenzeService utenzeService

    def filtro

    def codiciTributo
    def tipiAbitazione
    def tipiOccupazione
    def tipiEvento

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtroRicerca") def pRicerca) {

        this.self = w
        filtro = pRicerca

        this.tipiAbitazione = utenzeService.TIPI_ABITAZIONE
        this.tipiOccupazione = utenzeService.TIPI_OCCUPAZIONE
        this.tipiEvento = utenzeService.TIPI_EVENTO
        this.codiciTributo = utenzeService.CODICI_TRIBUTO


        setInitialCombo(filtro)
    }

    @Command
    def onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: filtro])
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def archivioVieDTO = event.data as ArchivioVieDTO
        filtro.indirizzo = archivioVieDTO.denomUff
        filtro.codIndirizzo = archivioVieDTO.id
        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCancellaFiltri() {

        filtro.cognome = null
        filtro.nome = null
        filtro.codiceFiscale = null
        filtro.nInd = null
        filtro.codContribuente = null
        filtro.indirizzo = null
        filtro.numeroCivicoDa = null
        filtro.numeroCivicoA = null
        filtro.categoriaDa = null
        filtro.categoriaA = null
        filtro.tariffaDa = null
        filtro.tariffaA = null

        filtro.flagContenzioso = UtenzeService.DEFAULT_FLAG_CONTENZIOSO
        filtro.flagInclCessati = UtenzeService.DEFAULT_FLAG_INCL_CESSATI
        filtro.anno = Calendar.getInstance().get(Calendar.YEAR)
        filtro.tipoEvento = utenzeService.DEFAULT_TIPO_EVENTO
        filtro.tipoOccupazione = utenzeService.DEFAULT_TIPO_OCCUPAZIONE
        filtro.tipoAbitazione = UtenzeService.DEFAULT_TIPO_ABITAZIONE
        filtro.codiceTributo = utenzeService.DEFAULT_CODICE_TRIBUTO
        filtro.codIndirizzo = 0L
        setInitialCombo(filtro)

        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    private void setInitialCombo(def filtro) {
        filtro.codiceTributo = filtro.codiceTributo ?: utenzeService.DEFAULT_CODICE_TRIBUTO
        filtro.tipoEvento = filtro.tipoEvento ?: utenzeService.DEFAULT_TIPO_EVENTO
        filtro.tipoOccupazione = filtro.tipoOccupazione ?: utenzeService.DEFAULT_TIPO_OCCUPAZIONE

    }
}
