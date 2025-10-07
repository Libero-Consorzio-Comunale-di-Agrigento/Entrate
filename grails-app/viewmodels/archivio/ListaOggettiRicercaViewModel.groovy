package archivio

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.OggettoTributo
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaOggettiRicercaViewModel {
    Window self

    // paginazione bandbox
    int activePage = 0
    int pageSize = 10
    int totalSize

    // services
    OggettiService oggettiService
    CommonService commonService
    CompetenzeService competenzeService

    // dati
    def listaOggetti
    List<CategoriaCatastoDTO> listaCategorieCatasto
    List<TipoOggettoDTO> listaTipiOggetto
    List<FonteDTO> listaFonti
    def winHeight
    List listaTipiTributo
    FiltroRicercaOggetto filtroRicercaOggetto
    List<FiltroRicercaOggetto> listaFiltri = []

    boolean listaVisibile
    boolean inPratica
    boolean ricercaContribuente
    def oggettoSelezionato
    String tipoTributo

    def filtri
	def filtriGeoloc = [
			latitudineDa	 : null,
			latitudineA		 : null,
			longitudineDa	 : null,
			longitudineA	 : null,
			aLatitudineDa	 : null,
			aLatitudineA	 : null,
			aLongitudineDa	 : null,
			aLongitudinea	 : null,
    ]

    // Competenze
    def cbTributiAbilitati = [:]
    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true
    ]

    @NotifyChange([
            "listaTipiOggetto",
            "listaCategorieCatasto",
            "listaFonti",
            "filtroRicercaOggetto"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("filtri") def f
         , @ExecutionArgParam("listaVisibile") boolean lv
         , @ExecutionArgParam("inPratica") boolean ip
         , @ExecutionArgParam("ricercaContribuente") boolean rc
         , @ExecutionArgParam("tipo") @Default("") tipo) {

        this.self = w

        listaFiltri = f ?: []
        filtroRicercaOggetto = listaFiltri.empty ? new FiltroRicercaOggetto(id: 0) : listaFiltri[0]
        listaVisibile = lv
        inPratica = ip
        ricercaContribuente = rc

        // Verifica le competenze
        verificaCompetenze()

        filtroRicercaOggetto.cbTributi.IMU = (filtroRicercaOggetto.cbTributi.IMU) ? (cbTributiAbilitati['ICI'] ? cbTributiAbilitati['ICI'] : false) : filtroRicercaOggetto.cbTributi.IMU
        filtroRicercaOggetto.cbTributi.TASI = (filtroRicercaOggetto.cbTributi.TASI) ? (cbTributiAbilitati['TASI'] ? cbTributiAbilitati['TASI'] : false) : filtroRicercaOggetto.cbTributi.TASI
        filtroRicercaOggetto.cbTributi.TARI = (filtroRicercaOggetto.cbTributi.TARI) ? (cbTributiAbilitati['TARSU'] ? cbTributiAbilitati['TARSU'] : false) : filtroRicercaOggetto.cbTributi.TARI
        filtroRicercaOggetto.cbTributi.PUBBLICITA = (filtroRicercaOggetto.cbTributi.PUBBLICITA) ? (cbTributiAbilitati['ICP'] ? cbTributiAbilitati['ICP'] : false) : filtroRicercaOggetto.cbTributi.PUBBLICITA
        filtroRicercaOggetto.cbTributi.COSAP = (filtroRicercaOggetto.cbTributi.COSAP) ? (cbTributiAbilitati['TOSAP'] ? cbTributiAbilitati['TOSAP'] : false) : filtroRicercaOggetto.cbTributi.COSAP

        tipoTributo = tipo
        if (tipoTributo.length() > 0) {
            def lista = OggettoTributo.createCriteria().list {
                eq("tipoTributo.tipoTributo", tipoTributo)
                order("tipoOggetto", "asc")
            }.toDTO().tipoOggetto.tipoOggetto
            listaTipiOggetto = []
            lista.each {
                listaTipiOggetto.add(TipoOggetto.findByTipoOggetto(it).toDTO())
            }
        } else
            listaTipiOggetto = TipoOggetto.listOrderByTipoOggetto().toDTO()

        listaCategorieCatasto = CategoriaCatasto.findAllFlagReale(sort: "categoriaCatasto").toDTO()
        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        aggiornaFiltriGeolocalizzazioneDa()
        aggiornaFiltriGeolocalizzazioneA()

        BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
    }

    @Command
	def onChangeDaLatitudineDa() {

		filtroRicercaOggetto.latitudineDa = oggettiService.tryParseCoordinate(filtriGeoloc.latitudineDa)
		filtriGeoloc.latitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.latitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeDaLatitudineA() {

		filtroRicercaOggetto.latitudineA = oggettiService.tryParseCoordinate(filtriGeoloc.latitudineA)
		filtriGeoloc.latitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.latitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeDaLongitudineDa() {

		filtroRicercaOggetto.longitudineDa = oggettiService.tryParseCoordinate(filtriGeoloc.longitudineDa)
		filtriGeoloc.longitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.longitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeDaLongitudineA() {

		filtroRicercaOggetto.longitudineA = oggettiService.tryParseCoordinate(filtriGeoloc.longitudineA)
		filtriGeoloc.longitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.longitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeALatitudineDa() {

		filtroRicercaOggetto.aLatitudineDa = oggettiService.tryParseCoordinate(filtriGeoloc.aLatitudineDa)
		filtriGeoloc.aLatitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLatitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeALatitudineA() {

		filtroRicercaOggetto.aLatitudineA = oggettiService.tryParseCoordinate(filtriGeoloc.aLatitudineA)
		filtriGeoloc.aLatitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLatitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeALongitudineDa() {

		filtroRicercaOggetto.aLongitudineDa = oggettiService.tryParseCoordinate(filtriGeoloc.aLongitudineDa)
		filtriGeoloc.aLongitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLongitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @Command
	def onChangeALongitudineA() {

		filtroRicercaOggetto.aLongitudineA = oggettiService.tryParseCoordinate(filtriGeoloc.aLongitudineA)
		filtriGeoloc.aLongitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLongitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggetto")
	}

    @NotifyChange([
            "listaFiltri",
            "filtroRicercaOggetto",
            "listaOggetti",
            "activePage",
            "totalSize"
    ])
    @Command
    onSvuotaFiltri() {
        filtroRicercaOggetto = new FiltroRicercaOggetto(id: 0)
        filtroRicercaOggetto.cbTributi.IMU = (filtroRicercaOggetto.cbTributi.IMU) ? (cbTributiAbilitati['ICI'] ? cbTributiAbilitati['ICI'] : false) : filtroRicercaOggetto.cbTributi.IMU
        filtroRicercaOggetto.cbTributi.TASI = (filtroRicercaOggetto.cbTributi.TASI) ? (cbTributiAbilitati['TASI'] ? cbTributiAbilitati['TASI'] : false) : filtroRicercaOggetto.cbTributi.TASI
        filtroRicercaOggetto.cbTributi.TARI = (filtroRicercaOggetto.cbTributi.TARI) ? (cbTributiAbilitati['TARSU'] ? cbTributiAbilitati['TARSU'] : false) : filtroRicercaOggetto.cbTributi.TARI
        filtroRicercaOggetto.cbTributi.PUBBLICITA = (filtroRicercaOggetto.cbTributi.PUBBLICITA) ? (cbTributiAbilitati['ICP'] ? cbTributiAbilitati['ICP'] : false) : filtroRicercaOggetto.cbTributi.PUBBLICITA
        filtroRicercaOggetto.cbTributi.COSAP = (filtroRicercaOggetto.cbTributi.COSAP) ? (cbTributiAbilitati['TOSAP'] ? cbTributiAbilitati['TOSAP'] : false) : filtroRicercaOggetto.cbTributi.COSAP

        listaFiltri = []

        listaOggetti = []
        oggettoSelezionato = null
        activePage = 0
        totalSize = 0

        aggiornaFiltriGeolocalizzazioneDa()
        aggiornaFiltriGeolocalizzazioneA()
    }

    @NotifyChange([
            "listaFiltri",
            "listaOggetti",
            "totalSize",
            "activePage"
    ])
    @Command
    onCerca() {
        if (listaFiltri.empty) listaFiltri << filtroRicercaOggetto
        if (listaVisibile) {
            def lista = oggettiService.listaOggetti(listaFiltri, pageSize, activePage, ["archivioVie"])
            listaOggetti = lista.lista
            totalSize = lista.totale
            self.invalidate()
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: listaFiltri])
        }
    }

    @NotifyChange(["filtroRicercaOggetto"])
    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtroRicercaOggetto.indirizzo = (event.data.denomUff ?: "")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onScegliOggetto() {
        if (!controlloTipoOggetto() && tipoTributo.length() > 0) {
            Messagebox.show("Impossibile utilizzare un Oggetto di tipo " + oggettoSelezionato.tipoOggetto + " con pratiche " + tipoTributo + ".", "Ricerca Oggetto", Messagebox.OK, Messagebox.ERROR)
        } else
            Events.postEvent(Events.ON_CLOSE, self, [status: "Oggetto", filtri: filtri, idOggetto: oggettoSelezionato.id])
    }

    @Command
    onNuovoOggetto() {
        Window w = Executions.createComponents("/archivio/oggetto.zul", self, [oggetto: -1])
        w.doModal()
    }

    @NotifyChange([
            "listaOggetti",
            "totalSize",
            "activePage"
    ])
    @Command
    onRefresh() {
        def lista = oggettiService.listaOggetti(listaFiltri, pageSize, activePage, ["archivioVie"])
        listaOggetti = lista.lista
        totalSize = lista.totale
    }

    @Command
    onChangeTipoTributo() {
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    @Command
    onChangeTipoPratica() {
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    @NotifyChange([
            "listaFiltri",
            "filtroRicercaOggetto"
    ])
    @Command
    onAggiungiFiltro() {
        if (filtroRicercaOggetto.campiRicerca) {
            boolean pratica = filtroRicercaOggetto.inPratica
            int idx = listaFiltri.findIndexOf { it.id == filtroRicercaOggetto.id }
            if (idx >= 0)
                listaFiltri[idx] = filtroRicercaOggetto
            else
                listaFiltri << filtroRicercaOggetto

            filtroRicercaOggetto = new FiltroRicercaOggetto(id: listaFiltri.max { it.id }.id + 1)
            filtroRicercaOggetto.inPratica = pratica
            filtroRicercaOggetto.cbTributi.IMU = (filtroRicercaOggetto.cbTributi.IMU) ? (cbTributiAbilitati['ICI'] ? cbTributiAbilitati['ICI'] : false) : filtroRicercaOggetto.cbTributi.IMU
            filtroRicercaOggetto.cbTributi.TASI = (filtroRicercaOggetto.cbTributi.TASI) ? (cbTributiAbilitati['TASI'] ? cbTributiAbilitati['TASI'] : false) : filtroRicercaOggetto.cbTributi.TASI
            filtroRicercaOggetto.cbTributi.TARI = (filtroRicercaOggetto.cbTributi.TARI) ? (cbTributiAbilitati['TARSU'] ? cbTributiAbilitati['TARSU'] : false) : filtroRicercaOggetto.cbTributi.TARI
            filtroRicercaOggetto.cbTributi.PUBBLICITA = (filtroRicercaOggetto.cbTributi.PUBBLICITA) ? (cbTributiAbilitati['ICP'] ? cbTributiAbilitati['ICP'] : false) : filtroRicercaOggetto.cbTributi.PUBBLICITA
            filtroRicercaOggetto.cbTributi.COSAP = (filtroRicercaOggetto.cbTributi.COSAP) ? (cbTributiAbilitati['TOSAP'] ? cbTributiAbilitati['TOSAP'] : false) : filtroRicercaOggetto.cbTributi.COSAP

            aggiornaFiltriGeolocalizzazioneDa()
            aggiornaFiltriGeolocalizzazioneA()
        }
    }

    @NotifyChange(["filtroRicercaOggetto"])
    @Command
    onOpenCloseInPratica() {
        filtroRicercaOggetto.inPratica = !filtroRicercaOggetto.inPratica
    }

    @NotifyChange([
            "listaFiltri",
            "filtroRicercaOggetto"
    ])
    @Command
    onEliminaFiltro(@BindingParam("f") FiltroRicercaOggetto f) {
        listaFiltri.remove(f)
        filtroRicercaOggetto = new FiltroRicercaOggetto(id: 0)
        filtroRicercaOggetto.cbTributi.IMU = (filtroRicercaOggetto.cbTributi.IMU) ? (cbTributiAbilitati['ICI'] ? cbTributiAbilitati['ICI'] : false) : filtroRicercaOggetto.cbTributi.IMU
        filtroRicercaOggetto.cbTributi.TASI = (filtroRicercaOggetto.cbTributi.TASI) ? (cbTributiAbilitati['TASI'] ? cbTributiAbilitati['TASI'] : false) : filtroRicercaOggetto.cbTributi.TASI
        filtroRicercaOggetto.cbTributi.TARI = (filtroRicercaOggetto.cbTributi.TARI) ? (cbTributiAbilitati['TARSU'] ? cbTributiAbilitati['TARSU'] : false) : filtroRicercaOggetto.cbTributi.TARI
        filtroRicercaOggetto.cbTributi.PUBBLICITA = (filtroRicercaOggetto.cbTributi.PUBBLICITA) ? (cbTributiAbilitati['ICP'] ? cbTributiAbilitati['ICP'] : false) : filtroRicercaOggetto.cbTributi.PUBBLICITA
        filtroRicercaOggetto.cbTributi.COSAP = (filtroRicercaOggetto.cbTributi.COSAP) ? (cbTributiAbilitati['TOSAP'] ? cbTributiAbilitati['TOSAP'] : false) : filtroRicercaOggetto.cbTributi.COSAP

        aggiornaFiltriGeolocalizzazioneDa()
        aggiornaFiltriGeolocalizzazioneA()
    }

    @NotifyChange([
            "filtroRicercaOggetto",
            "listaCategorieCatasto"
    ])
    @Command
    onChangeCategoria(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {
        if (event?.getValue() && !filtroRicercaOggetto.categoriaCatasto) {
            CategoriaCatastoDTO categoriaPers = new CategoriaCatastoDTO(categoriaCatasto: event.getValue())
            listaCategorieCatasto << categoriaPers
            filtroRicercaOggetto.categoriaCatasto = categoriaPers
        }
    }

	private def aggiornaFiltriGeolocalizzazioneDa() {

		filtriGeoloc.latitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.latitudineDa)
		filtriGeoloc.latitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.latitudineA)
		filtriGeoloc.longitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.longitudineDa)
		filtriGeoloc.longitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.longitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
	}

	private def aggiornaFiltriGeolocalizzazioneA() {

		filtriGeoloc.aLatitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLatitudineDa)
		filtriGeoloc.aLatitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLatitudineA)
		filtriGeoloc.aLongitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLongitudineDa)
		filtriGeoloc.aLongitudineA = oggettiService.formatCoordinateSexagesimalNS(filtroRicercaOggetto.aLongitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtriGeoloc")
	}

    private boolean controlloTipoOggetto() {
        boolean check = false
        listaTipiOggetto.each {
            if (it.tipoOggetto.equals(oggettoSelezionato.tipoOggetto.tipoOggetto)) {
                check = true
            }
        }
        return check
    }

    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
        }

        cbTributi.each { k, v ->
            if (competenzeService.tipiTributoUtenza().find { it.tipoTributo == k } == null) {
                cbTributi[k] = false
            }
        }
    }
}
