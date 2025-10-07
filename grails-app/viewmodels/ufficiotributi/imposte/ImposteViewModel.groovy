package ufficiotributi.imposte

import document.FileNameGenerator
import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.CampiOrdinamento
import it.finmatica.tr4.imposte.FiltroRicercaImposte
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.chart.model.DefaultPieModel
import org.zkoss.chart.model.DefaultSingleValueCategoryModel
import org.zkoss.chart.model.SingleValueCategoryModel
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.text.DecimalFormat

class ImposteViewModel {

    @Wire("#listBoxPerOggetto")
    Listbox listBoxPerOggetto

    // services
    def springSecurityService
    TributiSession tributiSession

    ImposteService imposteService
    ModelliService modelliService
    DocumentaleService documentaleService
    CommonService commonService
    CompetenzeService competenzeService
    ComunicazioniService comunicazioniService

    IntegrazioneDePagService integrazioneDePagService

    // componenti
    Window self

    Boolean modifica = false
    def selectedTab

    // dati
    def tipoTributo
    Boolean tributo

    List<Short> anno
    List<Short> listaAnni
    List<TipoTributoDTO> listaTipiTributo = []

    def listaImposte = []
    def listaImposteContribuenti = []
    def listaImposteDettaglio = []
    def listaImpostePerOggetti = []
    def listaImpostePerCategorie = []
    def listaImpostePerAliquota = []
    def listaImpostePerAliquoteCategorie = []
    def listaImpostePerTipologie = []

    def selectedImposta

    def selectedAnyContribuente = false
    def selectedContribuenti = [:]
    def selectedContribuente

    def selectedAnyDettaglio = false
    def selectedDettagli = [:]
    def selectedDettaglio

    def selectedPerOggetti
    def selectedPerCategorie
    def selectedPerAliquote
    def selectedPerAliquoteCategorie
    def selectedPerTipologie

    def totaleImposte = 0
    def totaleUtenze = 0
    def totaleContribuenti = 0
    def totaleImpostePerAliquote = 0
    def totaleImposteDettPerAliquote = 0
    def totaleNumeroPerAliquote = 0
    def totaleImpostePerCategorie = 0
    def totaleImpostePerAliquoteCategorie = 0
    def totaleImposteDettPerAliquoteCategorie = 0
    def totaleImpostePerOggetti = 0
    def totaleImposteErPerOggetti = 0
    def totaleImposteDettaglio = 0
    def totaleImposteErDettaglio = 0
    def totaleDetrazione = 0
    def totaleDetrazioneFigli = 0
    def totaleAddMaggECA = 0
    def totaleAddProv = 0
    def totaleIVA = 0
    def totaleMaggTares = 0
    def totaleImposteContribuenti = 0
    def totaleImposteErContribuenti = 0
    def totaleImposteContribuentiVersato = 0
    def totaleImposteContribuentiDovuto = 0
    def totaliImposteContribuentiTARSU = [
            totalImpostaRuolo      : 0,
            totalSgravioTot        : 0,
            totalVersato           : 0,
            totalDovuto            : 0,
            totalImposta           : 0,
            totalAddMaggEca        : 0,
            totalAddizionalePro    : 0,
            totalIva               : 0,
            totalImportoPf         : 0,
            totalImportoPv         : 0,
            totalMaggiorazioneTares: 0
    ]

    // ordinamento
    def ordinamentoContribuenti = [tipo: CampiOrdinamento.CONTRIBUENTE, ascendente: true]
    def ordinamentoDettaglio = [tipo: CampiOrdinamento.CONTRIBUENTE, ascendente: true]
    def ordinamentoPerOggetti = [tipo: CampiOrdinamento.CONTRIBUENTE, ascendente: true]

    def elencoTipiLista = [
            [codice: 'X-XX', descrizione: 'Tutto, qualsiasi decorrenza'],
            [codice: 'X-AC', descrizione: 'Tutto, anno corrente (decorrenza dal 01/01)'],
            [codice: 'T-AC', descrizione: 'Temporanee, anno corrente (decorrenza dal 01/01)'],
            [codice: 'P-AC', descrizione: 'Permanenti, anno corrente (decorrenza dal 01/01)'],
            [codice: 'P-AP', descrizione: 'Permanenti, anni precedenti (decorrenza prima del 01/01)']
    ]

    def descrListaContribuenti = ""
    def descrListaDettaglio = ""
    def descrListaPerOggetti = ""

    // paginazione
    def pagingContribuenti = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    def pagingDettaglio = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    def pagingPerOggetti = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    SingleValueCategoryModel modelPerCategoria
    PieModel modelPerCategoriaFree
    SingleValueCategoryModel modelPerAliquota
    PieModel modelPerAliquotaFree
    String titoloTortaPerAliquota

    // filtro
    FiltroRicercaImposte filtroRicercaImposte

    boolean filtroAttivoContribuenti = false
    boolean filtroAttivoDettaglio = false
    boolean filtroAttivoPerOggetti = false
    boolean listaImposteAggiornata = false

    //Tab A rimborso, Da Pagare, Saldati
    def dovSoglia
    def tipoFiltroContribuenti

    def abilitaStampa = false
    def contribuentiProps = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        filtroRicercaImposte = tributiSession.filtroRicercaImposte ?: new FiltroRicercaImposte()

        listaTipiTributo = competenzeService.tipiTributoUtenza()

        tipoTributo = listaTipiTributo.find { it.tipoTributo == filtroRicercaImposte.tipoTributo }
        if (tipoTributo == null) {
            tipoTributo = listaTipiTributo[0]
        }
        tributo = filtroRicercaImposte.tributo
        aggiornaAbilitazione()

        listaAnni = imposteService.getListaAnniImposte(tipoTributo?.tipoTributo)
        anno = listaAnni.findAll { it in filtroRicercaImposte.anni }

        selectedTab = 0
        verificaCampiFiltroContribuenti()

        if (anno.size() > 0) {
            onRicercaImposte()
        }

        initDovSoglia()
    }

    @Command
    def onRicercaImposte() {

        caricaListaImporto()
        verificaCampiFiltroContribuenti()
        listaImposteAggiornata = true
        BindUtils.postNotifyChange(null, null, this, "listaImposteAggiornata")
    }

    private void caricaListaImporto() {

        listaImposte = imposteService.listaImposte(tipoTributo.tipoTributo, anno, tributo)
        selectedImposta = null

        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "selectedImposta")

        totaleImposte = listaImposte.sum { it.importo } ?: 0
        totaleUtenze = listaImposte.sum { it.totUtenze } ?: 0
        totaleContribuenti = listaImposte.sum { it.totContribuenti } ?: 0

        BindUtils.postNotifyChange(null, null, this, "totaleImposte")
        BindUtils.postNotifyChange(null, null, this, "totaleUtenze")
        BindUtils.postNotifyChange(null, null, this, "totaleContribuenti")
    }

    @Command
    def onSelectedImposta() {

        listaImposteContribuenti = []
        listaImposteDettaglio = []
        listaImpostePerOggetti = []
        listaImpostePerCategorie = []
        listaImpostePerAliquota = []
        listaImpostePerAliquoteCategorie = []
        listaImpostePerTipologie = []

        abilitaStampa = false
        contribuentiProps = [:]

        if (selectedImposta) {
            switch (selectedTab) {
                case 0:
                    caricaListaContribuenti()            // CONTRIBUENTI
                    resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.TUTTI)
                    break
                case 1:
                    caricaListaContribuenti()            // A RIMBORSO
                    resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.A_RIMBORSO)
                    break
                case 2:
                    caricaListaContribuenti()            // DA PAGARE
                    resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.DA_PAGARE)
                    break
                case 3:
                    caricaListaContribuenti()            // SALDATI
                    resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.SALDATI)
                    break
                case 4:
                    caricaListaDettaglio()                // DETTAGLIO IMPOSTE
                    break
                case 5:
                    caricaListaPerOggetti()                // IMPOSTE PER OGGETTI
                    break
                case 6:
                    caricaListaPerCategorie()            // PER CATEGORIE
                    break
                case 7:
                    caricaListaPerAliquote()            // PER TIPO ALIQUOTA
                    break
                case 8:
                    caricaListaPerAliquoteCategorie()    // PER TIPO ALIQUOTA / CATEGORIA
                    break
                case 9:
                    caricaListaPerTipologie()            // PER TIPOLOGIE
                    break
            }
        }
    }

    @Command
    def onCalcolaImposta() {

        Window w = Executions.createComponents("/ufficiotributi/imposte/calcoloImposta.zul", self,
                [anno: selectedImposta?.anno, tipoTributo: tipoTributo, cognomeNome: "Tutti", contribuente: "%"])
        w.onClose { event ->
            if (event.data) {
                if (event.data.calcoloEseguito == true) {

                    caricaListaImporto()
                    onSvuotaTutto()
                    onSelectedImposta()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onDovutoVersato() {
        commonService.creaPopup("/imposta/dovutoVersato.zul", self, [
                tipoTributo: tipoTributo.tipoTributo, anno: selectedImposta?.anno])
    }

    @Command
    def onApriInsolventi() {
        commonService.creaPopup("/ufficiotributi/imposte/insolventi.zul", self, [tipoTributo: tipoTributo, impostaSelezionata: selectedImposta, gruppoTributo: tributo])
    }

    @Command
    def onSelectTabs() {

        switch (selectedTab) {
            case 0:
                resetParametriContribuenti()
                verificaCampiFiltroContribuenti()
                verificaParametroDovSoglia()
                break
            case 1:
                resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.A_RIMBORSO)
                verificaCampiFiltroContribuenti()
                verificaParametroDovSoglia()
                break
            case 2:
                resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.DA_PAGARE)
                verificaCampiFiltroContribuenti()
                verificaParametroDovSoglia()
                break
            case 3:
                resetParametriContribuenti(imposteService.TIPI_FILTRO_CONTRIBUENTI.SALDATI)
                verificaCampiFiltroContribuenti()
                verificaParametroDovSoglia()
                break
            case 4:
                verificaCampiFiltroDettaglio()
                break
            case 5:
                verificaCampiFiltroPerOggetti()
                listBoxPerOggetto?.invalidate()
                break
            case [6, 7, 8, 9]:
                break
        }

        if (selectedImposta) {
            if (selectedTab == 0) {
                caricaListaContribuenti()            // CONTRIBUENTI
            }
            if (selectedTab == 1) {
                caricaListaContribuenti()            // A RIMBORSO
            }
            if (selectedTab == 2) {
                caricaListaContribuenti()            // DA PAGARE
            }
            if (selectedTab == 3) {
                caricaListaContribuenti()            // SALDATI
            }
            if (selectedTab == 4 && listaImposteDettaglio.size() == 0) {
                caricaListaDettaglio()                // DETTAGLIO IMPOSTE
            }
            if (selectedTab == 5 && listaImpostePerOggetti.size() == 0) {
                caricaListaPerOggetti()                // IMPOSTE PER OGGETTI
            }
            if (selectedTab == 6 && listaImpostePerCategorie.size() == 0) {
                caricaListaPerCategorie()            // PER CATEGORIE
            }
            if (selectedTab == 7 && listaImpostePerAliquota.size() == 0) {
                caricaListaPerAliquote()            // PER TIPO ALIQUOTA
            }
            if (selectedTab == 8 && listaImpostePerAliquoteCategorie.size() == 0) {
                caricaListaPerAliquoteCategorie()    // PER TIPO ALIQUOTA / CATEGORIA
            }
            if (selectedTab == 9 && listaImpostePerTipologie.size() == 0) {
                caricaListaPerTipologie()            // PER TIPOLOGIE
            }
        }
    }

    @Command
    def onChangeTipoTributo() {

        filtroRicercaImposte.tipoTributo = tipoTributo?.tipoTributo
        aggiornaAbilitazione()
        salvaFiltroRicercaImposte()
        onSvuotaTutto()
    }

    @Command
    def onCheckGruppoOTributo() {

        filtroRicercaImposte.tributo = tributo
        salvaFiltroRicercaImposte()
        onSvuotaTutto()
    }

    @Command
    def onChangeAnno() {

        filtroRicercaImposte.anni = anno
        salvaFiltroRicercaImposte()
        onSvuotaTutto()
    }

    @Command
    onSvuotaTutto() {

        listaAnni = imposteService.getListaAnniImposte(tipoTributo.tipoTributo)
        BindUtils.postNotifyChange(null, null, this, "listaAnni")
        anno = listaAnni.findAll { it in anno }

        listaImposte = []
        listaImposteContribuenti = []
        listaImposteDettaglio = []
        listaImpostePerOggetti = []
        listaImpostePerCategorie = []
        listaImpostePerAliquota = []
        listaImpostePerAliquoteCategorie = []
        listaImpostePerTipologie = []

        selectedImposta = null

        selectedContribuentiReset()
        selectedContribuente = null

        selectedDettagliReset()
        selectedDettaglio = null

        selectedPerOggetti = null
        selectedPerCategorie = null
        selectedPerAliquote = null
        selectedPerAliquoteCategorie = null
        selectedPerTipologie = null

        filtroAttivoContribuenti = false
        pagingContribuenti.activePage = 0
        pagingContribuenti.totalSize = 0

        filtroAttivoDettaglio = false
        pagingDettaglio.activePage = 0
        pagingDettaglio.totalSize = 0

        filtroAttivoPerOggetti = false
        pagingPerOggetti.activePage = 0
        pagingPerOggetti.totalSize = 0

        totaleImposte = 0
        totaleUtenze = 0
        totaleContribuenti = 0
        totaleImpostePerAliquote = 0
        totaleImposteDettPerAliquote = 0
        totaleNumeroPerAliquote = 0
        totaleImpostePerCategorie = 0
        totaleImpostePerAliquoteCategorie = 0
        totaleImposteDettPerAliquoteCategorie = 0
        totaleImpostePerOggetti = 0
        totaleImposteErPerOggetti = 0
        totaleImposteDettaglio = 0
        totaleImposteErDettaglio = 0
        totaleImposteContribuenti = 0
        totaleImposteErContribuenti = 0
        listaImposteAggiornata = false
        totaleImposteContribuentiVersato = 0
        totaleImposteContribuentiDovuto = 0

        selectedTab = 0
        tipoFiltroContribuenti = null

        abilitaStampa = false
        contribuentiProps = [:]

        onRefreshListe()
    }

    private void onRefreshListe() {

        BindUtils.postNotifyChange(null, null, this, "selectedTab")
        BindUtils.postNotifyChange(null, null, this, "anno")

        BindUtils.postNotifyChange(null, null, this, "selectedImposta")

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoContribuenti")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoDettaglio")
        BindUtils.postNotifyChange(null, null, this, "listaImposteAggiornata")

        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "listaImposteContribuenti")
        BindUtils.postNotifyChange(null, null, this, "listaImposteDettaglio")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerCategorie")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerAliquota")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerAliquoteCategorie")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerTipologie")

        BindUtils.postNotifyChange(null, null, this, "pagingContribuenti")
        BindUtils.postNotifyChange(null, null, this, "pagingDettaglio")

        BindUtils.postNotifyChange(null, null, this, "selectedContribuente")
        BindUtils.postNotifyChange(null, null, this, "selectedDettaglio")
        BindUtils.postNotifyChange(null, null, this, "selectedPerOggetti")
        BindUtils.postNotifyChange(null, null, this, "selectedPerCategorie")
        BindUtils.postNotifyChange(null, null, this, "selectedPerAliquote")
        BindUtils.postNotifyChange(null, null, this, "selectedPerAliquoteCategorie")
        BindUtils.postNotifyChange(null, null, this, "selectedPerTipologie")

        BindUtils.postNotifyChange(null, null, this, "totaleImposte")
        BindUtils.postNotifyChange(null, null, this, "totaleUtenze")
        BindUtils.postNotifyChange(null, null, this, "totaleContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleImpostePerAliquote")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteDettPerAliquote")
        BindUtils.postNotifyChange(null, null, this, "totaleNumeroPerAliquote")
        BindUtils.postNotifyChange(null, null, this, "totaleImpostePerCategorie")
        BindUtils.postNotifyChange(null, null, this, "totaleImpostePerAliquoteCategorie")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteDettPerAliquoteCategorie")
        BindUtils.postNotifyChange(null, null, this, "totaleImpostePerOggetti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteErPerOggetti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteDettaglio")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteErDettaglio")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteErContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuentiVersato")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuentiDovuto")
    }

    @Command
    def onChangeDovSoglia() {
        tributiSession.dovSoglia = (Double) dovSoglia
        BindUtils.postNotifyChange(null, null, this, "dovSoglia")
        caricaListaContribuenti()
    }

    private def verificaParametroDovSoglia() {
        dovSoglia = tributiSession.dovSoglia ?: (Double) 1.00
        BindUtils.postNotifyChange(null, null, this, "dovSoglia")
    }

    // Aggiorna flag modifica da diritti su tributo
    def aggiornaAbilitazione() {
        modifica = competenzeService.tipoAbilitazioneUtente(tipoTributo?.tipoTributo) == 'A'
        BindUtils.postNotifyChange(null, null, this, "modifica")
    }

    private def initDovSoglia() {

        def parametro = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DOV_SOGLIA' }?.valore

        if (parametro && parametro.isNumber()) {
            dovSoglia = parametro as Double
        } else {
            dovSoglia = 1.00
        }

        tributiSession.dovSoglia = dovSoglia
    }

    private def resetParametriContribuenti(def tipoFiltroContribuenti = null) {
        pagingContribuenti.activePage = 0
        this.tipoFiltroContribuenti = tipoFiltroContribuenti
        BindUtils.postNotifyChange(null, null, this, "pagingContribuenti")
    }


    // Descrizione tipo lista in base a filtro
    def descrizioneTipoLista(def parRicerca) {

        String descrizione = ""

        def codice = parRicerca?.tipoLista

        def tipoLista = elencoTipiLista.find { it.codice == codice }
        if (tipoLista != null) descrizione = tipoLista.descrizione

        return descrizione
    }

    def salvaFiltroRicercaImposte() {

        tributiSession.filtroRicercaImposte = filtroRicercaImposte
    }

    private void caricaListaContribuenti(boolean keepMultiSelection = false) {

        def parRicerca = completaParametriContribuenti()


        parRicerca.nomeTabImposte = tipoFiltroContribuenti


        def documentoContribuenti = imposteService.listaImposteContribuenti(
                selectedImposta.anno,
                tipoTributo.tipoTributo,
                parRicerca,
                ordinamentoContribuenti,
                pagingContribuenti.pageSize,
                pagingContribuenti.activePage,
                null,
                selectedImposta.servizio)


        listaImposteContribuenti = documentoContribuenti.records
        pagingContribuenti.totalSize = documentoContribuenti.totalCount

        // calcolo totali
        def totals = documentoContribuenti.totals
        if (tipoTributo.tipoTributo == "TARSU") {
            totaliImposteContribuentiTARSU = totals
        } else {
            totaleImposteContribuenti = totals.totalImposta
            totaleImposteErContribuenti = totals.totalImpostaErariale
            totaleImposteContribuentiVersato = totals.totalVersato
            totaleImposteContribuentiDovuto = totals.totalDovuto
        }

        if (!keepMultiSelection) {
            selectedContribuentiReset()
        }

        selectedContribuente = null

        descrListaContribuenti = descrizioneTipoLista(parRicerca)

        BindUtils.postNotifyChange(null, null, this, "descrListaContribuenti")
        BindUtils.postNotifyChange(null, null, this, "pagingContribuenti")
        BindUtils.postNotifyChange(null, null, this, "listaImposteContribuenti")
        BindUtils.postNotifyChange(null, null, this, "selectedContribuente")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteErContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuentiVersato")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteContribuentiDovuto")
        BindUtils.postNotifyChange(null, null, this, "totaliImposteContribuentiTARSU")
    }

    private def completaParametriContribuenti() {

        return filtroRicercaImposte.preparaRicercaContribuenti()
    }

    private def applicaParametriContribuenti(def parRicerca) {

        filtroRicercaImposte.applicaRicercaContribuenti(parRicerca)
        listaImposteContribuenti = []
        listaImposteDettaglio = []
        listaImpostePerOggetti = []
        salvaFiltroRicercaImposte()
    }

    def verificaCampiFiltroContribuenti() {

        filtroAttivoContribuenti = filtroRicercaImposte.isDirtyContribuenti()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoContribuenti")
    }

    def selectedContribuentiReset() {

        selectedContribuenti = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedContribuenti")
        selectedAnyContribuenteRefresh()
    }

    def selectedAnyContribuenteRefresh() {

        selectedAnyContribuente = (selectedContribuenti.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyContribuente")
    }

    @Command
    def openFiltriContribuenti() {

        def parRicerca = completaParametriContribuenti()

        if (selectedImposta) {
            commonService.creaPopup("/ufficiotributi/imposte/listaImposteContribuenteRicerca.zul",
                    self, [parRicerca: parRicerca, tipoTributo: tipoTributo],
                    { event ->
                        if (event.data) {
                            if (event.data.status == "Cerca") {
                                applicaParametriContribuenti(event.data.parRicerca)
                                onCercaContribuente()
                            }
                        }
                        verificaCampiFiltroContribuenti()
                    })
        }
    }

    @Command
    def onCercaContribuente() {
        pagingContribuenti.activePage = 0
        caricaListaContribuenti()
    }

    @Command
    def onRefreshContribuenti() {
        pagingContribuenti.activePage = 0
        contribuentiProps = [:]
        caricaListaContribuenti()
    }

    @Command
    def onPagingContribuenti() {

        caricaListaContribuenti(true)
    }

    @Command
    def onChangeOrdinamentoContribuenti(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        ordinamentoContribuenti.tipo = CampiOrdinamento.getAt(valore)
        ordinamentoContribuenti.ascendente = event.isAscending()

        caricaListaContribuenti()
    }

    @Command
    def onModificaContribuente() {

        apriMascheraContribuente(selectedContribuente.ni)
    }

    @Command
    def onStampaContribuenti() {

        def daStampare = []

        def contribuenti = selectedContribuenti
                .findAll { it.value }
                .collect { it.key }

        daStampare = contribuentiProps.findAll { it.key in contribuenti }
                .collect { it.value }


        stampaDocumenti(daStampare)
    }

    @Command
    def onCheckAllContribuenti() {

        selectedAnyContribuenteRefresh()

        selectedContribuenti = [:]

        if (!selectedAnyContribuente) {

            def parRicerca = completaParametriContribuenti()
            parRicerca.nomeTabImposte = tipoFiltroContribuenti

            def caricoContribuenti = imposteService.listaImposteContribuenti(selectedImposta.anno, tipoTributo.tipoTributo, parRicerca,
                    ordinamentoContribuenti, Integer.MAX_VALUE,
                    0, null, selectedImposta.servizio)


            def listContribuenti = caricoContribuenti.records

            listContribuenti.each() { it ->
                (selectedContribuenti << [(it.ni): true])
                onCheckContribuente(it)
            }
        }

        BindUtils.postNotifyChange(null, null, this, "selectedContribuenti")
        selectedAnyContribuenteRefresh()
    }

    @Command
    def onCheckContribuente(@BindingParam("detail") def detail) {

        selectedAnyContribuenteRefresh()


        // Recupero le informazioni del contribuente selezionato
        if (contribuentiProps.get(detail.ni) == null) {

            contribuentiProps << [
                    (detail.ni): [
                            "codFiscale": detail.codFiscale,
                            "imposta"   : detail.imposta,
                            "pratica"   : detail.pratica,
                            "ruolo"     : detail.ruolo
                    ]]
        }

        checkAbilitazioneStampa()
    }

    @Command
    def onCalcolaImpostaContribuente() {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/calcoloImposta.zul",
                self,
                [
                        anno       : selectedImposta.anno,
                        tipoTributo: tipoTributo,
                        cognomeNome: selectedContribuente.contribuente,
                        codFiscale : selectedContribuente.codFiscale
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.calcoloEseguito == true) {

                    onSelectedImposta()
                    onRefreshListe()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onContribuentiToXls() {

        def annoTributo = selectedImposta.anno
        def servizio = selectedImposta.servizio

        def fields
        def converters = [:]

        if (tipoTributo.tipoTributo == "CUNI") {
            fields = [
                    'ni'              : 'Numero individuale',
                    'contribuente'    : 'Contribuente',
                    'codFiscale'      : 'Codice Fiscale',
                    'importo'         : 'Importo',
                    'versato'         : 'Versato',
                    'tardivo'         : 'Tardivo',
                    'dovuto'          : 'Dovuto',
                    'residente'       : 'Residente',
                    'statoDescrizione': 'Stato',
                    'dataUltEvento'   : 'Data Evento',
                    'indirizzoRes'    : 'Indirizzo Res.',
                    'civicoRes'       : 'Civico Res.',
                    'comuneRes'       : 'Comune Res.',
                    'capRes'          : 'CAP Res.',
                    'cognomeNomeP'    : 'Presso',
                    'mailPec'         : 'Indirizzo PEC'
            ]
        } else if (tipoTributo.tipoTributo == "TARSU") {
            fields = [
                    'ni'                : 'Numero individuale',
                    'csoggnome'         : 'Contribuente',
                    'codFiscale'        : 'Codice Fiscale',
                    'impostaRuolo'      : 'Importo',
                    'sgravioTot'        : 'Sgravio',
                    'versato'           : 'Versato',
                    'dovuto'            : 'di cui Dovuto',
                    'imposta'           : 'di cui Imposta',
                    'addMaggEca'        : 'di cui ECA',
                    'addizionalePro'    : 'di cui Add.Prov.',
                    'iva'               : 'di cui IVA',
                    'importoPf'         : 'di cui Quota Fissa',
                    'importoPv'         : 'di cui Quota Variabile',
                    'maggiorazioneTares': 'di cui C.Pereq.',
                    'residente'         : 'Residente',
                    'statoDescrizione'  : 'Stato',
                    'dataUltEvento'     : 'Data Evento',
                    'indirizzoRes'      : 'Indirizzo Res.',
                    'civicoRes'         : 'Civico Res.',
                    'comuneRes'         : 'Comune Res.',
                    'capRes'            : 'CAP Res.',
                    'cognomeNomeP'      : 'Presso',
                    'mailPec'           : 'Indirizzo PEC',
                    'ruolo'             : 'Ruolo'
            ]

            converters << [ruolo: Converters.decimalToInteger]

        } else {
            fields = [
                    'ni'              : 'Numero individuale',
                    'contribuente'    : 'Contribuente',
                    'codFiscale'      : 'Codice Fiscale',
                    'imposta'         : 'Imposta',
                    'impostaErariale' : 'Imposta Erariale',
                    'residente'       : 'Residente',
                    'statoDescrizione': 'Stato',
                    'dataUltEvento'   : 'Data Evento',
                    'indirizzoRes'    : 'Indirizzo Res.',
                    'civicoRes'       : 'Civico Res.',
                    'comuneRes'       : 'Comune Res.',
                    'capRes'          : 'CAP Res.',
                    'cognomeNomeP'    : 'Presso',
                    'mailPec'         : 'Indirizzo PEC'
            ]
        }

        def parRicerca = completaParametriContribuenti()
        parRicerca.nomeTabImposte = tipoFiltroContribuenti

        /*def caricoContribuenti = imposteService.listaImposteContribuenti(annoTributo, tipoTributo.tipoTributo, parRicerca,
                ordinamentoContribuenti, Integer.MAX_VALUE,
                0, null, servizio)

        def listaContribuenti = caricoContribuenti.records*/

        def generatorTitle

        switch (tipoFiltroContribuenti) {
            case imposteService.TIPI_FILTRO_CONTRIBUENTI.A_RIMBORSO:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.IMPOSTE_A_RIMBORSO
                break
            case imposteService.TIPI_FILTRO_CONTRIBUENTI.DA_PAGARE:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.IMPOSTE_DA_PAGARE
                break
            case imposteService.TIPI_FILTRO_CONTRIBUENTI.SALDATI:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.IMPOSTE_SALDATE
                break
            default:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.IMPOSTE_CONTRIBUENTI
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                generatorTitle,
                [tipoTributo: tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        converters << [ni       : Converters.decimalToInteger,
                       residente: Converters.flagString]

        XlsxExporter.export(nomeFile, {
            imposteService.listaImposteContribuenti(annoTributo, tipoTributo.tipoTributo, parRicerca,
                    ordinamentoContribuenti, Integer.MAX_VALUE,
                    0, null, servizio).records
        }, pagingContribuenti.totalSize, fields, converters, springSecurityService)
    }

    @Command
    def onCalcolaCompensazioni() {

        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [
                        tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.CALCOLO_COMPENSAZIONI_IMPOSTE_JOB,
                        modalitaCodFiscale: 'H',
                        modalitaAnno      : 'H',
                        datiContribuenti  : [
                                lista: selectedContribuenti.findAll { it.value },
                                anno : selectedImposta.anno + 1
                        ]

                ], { e ->
            Clients.showNotification("Elaborazione avviata", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

        })
    }

    @Command
    def onGeneraVersamentiInCompensazione() {

        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [
                        tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.GENERA_VERSAMENTI_JOB,
                        modalitaCodFiscale: 'H',
                        modalitaAnno      : 'H',
                        datiContribuenti  : [
                                lista: selectedContribuenti.findAll { it.value },
                                anno : selectedImposta.anno
                        ]

                ], { e ->

            Clients.showNotification("Elaborazione avviata", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

        })

    }

    @Command
    def onCalcolaRimborsi() {
        commonService.creaPopup("/sportello/contribuenti/calcoloAccertamenti.zul", self,
                [
                        anno                         : selectedImposta.anno,
                        tributo                      : tipoTributo.tipoTributo,
                        modalitaCognomeNomeCodFiscale: 'H',
                        modalitaAnno                 : 'D',
                        listaContribuenti            : selectedContribuenti.findAll { it.value }


                ],
                { e ->
                    if (e.data && (e.data).elaborazioneEseguita) {
                        Clients.showNotification("Avviata elaborazione di calcolo dei rimborsi.",
                                Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                    }

                }
        )
    }

    @Command
    def onCalcolaAccertamenti() {

        commonService.creaPopup("/sportello/contribuenti/calcoloAccertamenti.zul", self,
                [
                        anno                         : selectedImposta.anno,
                        tributo                      : tipoTributo.tipoTributo,
                        modalitaCognomeNomeCodFiscale: 'H',
                        modalitaAnno                 : 'D',
                        listaContribuenti            : selectedContribuenti.findAll { it.value }

                ],
                { e ->
                    if (e.data && (e.data).elaborazioneEseguita) {
                        Clients.showNotification("Avviata elaborazione di calcolo degli accertamenti.",
                                Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                    }
                }
        )

    }

    @Command
    def onCalcolaSolleciti() {

        commonService.creaPopup("/pratiche/solleciti/calcoloSolleciti.zul", self,
                [
                        tipoTributo                  : tipoTributo.tipoTributo,
                        anno                         : selectedImposta.anno,
                        modalitaCognomeNomeCodFiscale: 'H',
                        modalitaAnno                 : 'D',
                        listaContribuenti            : selectedContribuenti.findAll { it.value },
                        contribuentiProps            : contribuentiProps
                ],
                { e ->
                    if (e.data && (e.data).elaborazioneEseguita) {
                        Clients.showNotification("Avviata elaborazione di calcolo dei solleciti.",
                                Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                    }
                }
        )
    }


// Apre maschera gestione contribuente
    private apriMascheraContribuente(def idSogg) {

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${idSogg}','_blank');")
    }

    private void caricaListaDettaglio(boolean keepMultiSelection = false) {

        def parRicerca = completaParametriDettaglio()
        def documentiDettaglio = imposteService.listaImposteDettaglio(selectedImposta.anno, tipoTributo.tipoTributo, parRicerca,
                ordinamentoDettaglio, pagingDettaglio.pageSize, pagingDettaglio.activePage,
                null, selectedImposta.servizio)

        listaImposteDettaglio = documentiDettaglio.result
        pagingDettaglio.totalSize = documentiDettaglio.total

        totaleImposteDettaglio = documentiDettaglio.impostaTotale
        totaleImposteErDettaglio = documentiDettaglio.impostaErarialeTotale
        totaleDetrazione = documentiDettaglio.detrazioneTotale
        totaleDetrazioneFigli = documentiDettaglio.detrazioneFigliTotale
        totaleAddMaggECA = documentiDettaglio.addMaggECATotale
        totaleAddProv = documentiDettaglio.addProvTotale
        totaleIVA = documentiDettaglio.ivaTotale
        totaleMaggTares = documentiDettaglio.maggTaresTotale

        if (!keepMultiSelection) {
            selectedDettagliReset()
        }

        selectedDettaglio = null

        descrListaDettaglio = descrizioneTipoLista(parRicerca)
        BindUtils.postNotifyChange(null, null, this, "descrListaDettaglio")

        BindUtils.postNotifyChange(null, null, this, "pagingDettaglio")
        BindUtils.postNotifyChange(null, null, this, "listaImposteDettaglio")
        BindUtils.postNotifyChange(null, null, this, "selectedDettaglio")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteDettaglio")
        BindUtils.postNotifyChange(null, null, this, "totaleImposteErDettaglio")
        BindUtils.postNotifyChange(null, null, this, "totaleDetrazione")
        BindUtils.postNotifyChange(null, null, this, "totaleDetrazioneFigli")
        BindUtils.postNotifyChange(null, null, this, "totaleAddMaggECA")
        BindUtils.postNotifyChange(null, null, this, "totaleAddProv")
        BindUtils.postNotifyChange(null, null, this, "totaleIVA")
        BindUtils.postNotifyChange(null, null, this, "totaleMaggTares")
    }

    private def eliminaImposta(def oggettoImposta) {

        imposteService.eliminaImposta(oggettoImposta)
        onRefreshDettaglio()
    }

    private def completaParametriDettaglio() {

        return filtroRicercaImposte.preparaRicercaDettaglio()
    }

    private def applicaParametriDettaglio(def parRicerca) {

        filtroRicercaImposte.applicaRicercaDettaglio(parRicerca)
        listaImposteContribuenti = []
        listaImposteDettaglio = []
        listaImpostePerOggetti = []
        salvaFiltroRicercaImposte()
    }

    def verificaCampiFiltroDettaglio() {

        filtroAttivoDettaglio = filtroRicercaImposte.isDirtyDettaglio()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoDettaglio")
    }

    @Command
    def onChangeOrdinamentoDettaglio(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        ordinamentoDettaglio.tipo = CampiOrdinamento.getAt(valore)
        ordinamentoDettaglio.ascendente = event.isAscending()
        caricaListaDettaglio()
    }

    def selectedDettagliReset() {

        selectedDettagli = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedDettagli")
        selectedAnyDettaglioRefresh()
    }

    def selectedAnyDettaglioRefresh() {

        selectedAnyDettaglio = (selectedDettagli.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyDettaglio")
    }

    @Command
    def openFiltriDettaglio() {

        def parRicerca = completaParametriDettaglio()

        if (selectedImposta) {
            Window w = Executions.createComponents("/ufficiotributi/imposte/listaImposteDettaglioRicerca.zul", self, [parRicerca: parRicerca, tipoTributo: tipoTributo])
            w.onClose { event ->
                if (event.data) {
                    if (event.data.status == "Cerca") {
                        applicaParametriDettaglio(event.data.parRicerca)
                        onCercaDettaglio()
                    }
                }
                verificaCampiFiltroDettaglio()
            }
            w.doModal()
        }
    }

    @Command
    def onCercaDettaglio() {

        pagingDettaglio.activePage = 0
        caricaListaDettaglio()
    }

    @Command
    def onRefreshDettaglio() {

        caricaListaDettaglio()
    }

    @Command
    def onPagingDettaglio() {

        caricaListaDettaglio(true)
    }

    @Command
    def onModificaDettaglio() {

        apriMascheraContribuente(selectedDettaglio.ni)
    }

    @Command
    def onEliminaDettaglio() {

        def oggettoImposta = selectedDettaglio?.oggettoImposta

        if (oggettoImposta) {

            String messaggio = "Eliminare la voce d'imposta?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                eliminaImposta(oggettoImposta)
                            }
                        }
                    }
            )
        }
    }

    @Command
    def onStampaDettagli() {

        def daStampare = []
        def dettagli = []

        for (e in selectedDettagli) {
            if (e.value != false) {
                dettagli << e.key
            }
        }

        def parRicercca = completaParametriDettaglio()
        def elencoDettagli = imposteService.listaImposteDettaglio(selectedImposta.anno, selectedImposta.tipoTributo, parRicercca,
                ordinamentoDettaglio, Integer.MAX_VALUE, 0, null, null)
        def allDettagli = elencoDettagli.result

        def listDettagli = allDettagli.findAll { it.uniqueId in dettagli }
        listDettagli.each {
            daStampare << [codFiscale: it.codFiscale, imposta: it.imposta, pratica: it.praticaBase]
        }

        stampaDocumenti(daStampare)
    }

    @Command
    def onCheckAllDettagli() {

        selectedAnyDettaglioRefresh()

        selectedDettagli = [:]

        if (!selectedAnyDettaglio) {

            def parRicercca = completaParametriDettaglio()
            def caricoDettagli = imposteService.listaImposteDettaglio(selectedImposta.anno, tipoTributo.tipoTributo, parRicercca,
                    ordinamentoDettaglio, Integer.MAX_VALUE, 0, null, selectedImposta.servizio)

            def listDetails = caricoDettagli.result

            listDetails.each() { it -> (selectedDettagli << [(it.uniqueId): true]) }
        }

        BindUtils.postNotifyChange(null, null, this, "selectedDettagli")
        selectedAnyDettaglioRefresh()
    }

    @Command
    def onCheckDettaglio(@BindingParam("detail") def detail) {

        selectedAnyDettaglioRefresh()
    }

    @Command
    def onCalcolaImpostaDettaglio() {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/calcoloImposta.zul",
                self,
                [
                        anno       : selectedImposta.anno,
                        tipoTributo: tipoTributo,
                        cognomeNome: selectedDettaglio.contribuente,
                        codFiscale : selectedDettaglio.codFiscale
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.calcoloEseguito == true) {

                    onSelectedImposta()
                    onRefreshListe()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onDettagliToXls() {


        def tipoTributo = this.tipoTributo.tipoTributo
        def annoTributo = selectedImposta.anno
        def tributo = selectedImposta.tributo?.id
        def servizio = selectedImposta.servizio

        def converters = [
                tipoOccupazione: { to -> to?.tipoOccupazione },
                residente      : Converters.flagBooleanToString
        ]

        def fields = [
                'id'               : 'Oggetto',
                'tipoOggetto'      : 'Tipo Oggetto',
                'contribuente'     : 'Contribuente',
                'codFiscale'       : 'Codice Fiscale',
                'tipoOccupazione'  : 'Occ.',
                'imposta'          : 'Imposta',
                'indirizzoCompleto': 'Indirizzo',
                'indirizzo'        : 'Via',
                'numCivico'        : 'Numero Civico',
                'suffisso'         : 'Suffisso',
                'consistenza'      : 'Consistenza',
                'partita'          : 'Partita',
                'progrPartita'     : 'Progr.Partita',
                'sez'              : 'Sezione',
                'foglio'           : 'Foglio',
                'numero'           : 'Numero',
                'sub'              : 'Sub.',
                'zona'             : 'Zona',
                'numProtocollo'    : 'Protocollo',
                'annoProtocollo'   : 'Anno',
                'categoriaCatasto' : 'Categoria Catasto',
                'classe'           : 'Classe'

        ]

        if (tipoTributo == 'ICI' || tipoTributo == 'TASI') {
            fields << [
                    'impostaErariale'      : 'Imposta Erariale',
                    'valoreDichiarato'     : 'Valore Dichiarato',
                    'valoreRiog'           : 'Valore Riog',
                    'percPossesso'         : '% Poss.',
                    'flagPossesso'         : 'P',
                    'flagEsclusione'       : 'E',
                    'flagRiduzione'        : 'R',
                    'flagAbPrincipale'     : 'A',
                    'flagRivalutato'       : 'Rivalutato',
                    'storico'              : 'Storico',
                    'tipoAliquota'         : 'Tipo Aliquota',
                    'aliquota'             : 'Aliquota',
                    'detrazioneTotale'     : 'Detrazione Totale',
                    'detrazioneFigliTotale': 'Det. Figli Totale'
            ]

            converters << [storico: Converters.flagBooleanToString]
            converters << [flagPossesso: Converters.flagBooleanToString]
            converters << [flagEsclusione: Converters.flagBooleanToString]
            converters << [flagRiduzione: Converters.flagBooleanToString]
            converters << [flagAbPrincipale: Converters.flagBooleanToString]
            converters << [flagRivalutato: Converters.flagBooleanToString]

        } else if (tipoTributo == 'TARSU') {
            fields << [
                    'percPossesso'    : '% Poss.',
                    'codiceTributo'   : 'Tributo',
                    'categoria'       : 'Categoria',
                    'tipoTariffaDesc' : 'Tipo Tariffa',
                    'domestica'       : 'Domestica',
                    'flagAbPrincipale': 'Ab. Principale',
                    'addMaggEca'      : 'ECA',
                    'addProvinciale'  : 'Add. Prov.',
                    'iva'             : 'IVA',
                    'maggTares'       : 'C.Pereq.',
                    'dataDecorrenza'  : 'Decorrenza',
                    'dataCessazione'  : 'Cessazione'
            ]
            converters << [domestica: Converters.flagBooleanToString]
            converters << [flagAbPrincipale: Converters.flagBooleanToString]

        } else if (tipoTributo != 'TARSU' && tipoTributo != 'ICI' && tipoTributo != 'TASI') {
            fields << [
                    'categoria'       : 'Categoria',
                    'tipoTariffaDesc' : 'Tipo Tariffa',
                    'domestica'       : 'Domestica',
                    'flagAbPrincipale': 'Ab. Principale'
            ]
            converters << [domestica: Converters.flagBooleanToString]
            converters << [flagAbPrincipale: Converters.flagBooleanToString]
        }

        fields << [
                'tipoRapporto'    : 'Tipo Rapp.',
                'residente'       : 'Residente',
                'statoDescrizione': 'Stato',
                'dataUltEvento'   : 'Data Evento',
                'indirizzoRes'    : 'Indirizzo Res.',
                'civicoRes'       : 'Civico Res.',
                'comuneRes'       : 'Comune Res.',
                'capRes'          : 'CAP Res.',
                'cognomeNomeP'    : 'Presso',
                'mailPec'         : 'Indirizzo PEC'

        ]

        def parRicercca = completaParametriDettaglio()

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_DETTAGLI,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.export(nomeFile, {
            def caricoDettagli = imposteService.listaImposteDettaglio(annoTributo, tipoTributo, parRicercca,
                    ordinamentoDettaglio, Integer.MAX_VALUE, 0, null, servizio)

            return caricoDettagli.result
        }, pagingDettaglio.totalSize, fields, converters, springSecurityService)

    }

    private void caricaListaPerOggetti(boolean keepMultiSelection = false) {

        def parRicerca = completaParametriPerOggetti()
        def documentiPerOggetti = imposteService.listaImposteDettaglio(selectedImposta.anno, tipoTributo.tipoTributo, parRicerca,
                ordinamentoPerOggetti, pagingPerOggetti.pageSize, pagingPerOggetti.activePage,
                null, selectedImposta.servizio)

        listaImpostePerOggetti = documentiPerOggetti.result
        pagingPerOggetti.totalSize = documentiPerOggetti.total

        totaleImpostePerOggetti = documentiPerOggetti.impostaTotale
        totaleImposteErPerOggetti = documentiPerOggetti.impostaErarialeTotale

        if (!keepMultiSelection) {
            selectedPerOggettiReset()
        }

        selectedPerOggetti = null

        descrListaPerOggetti = descrizioneTipoLista(parRicerca)
        BindUtils.postNotifyChange(null, null, this, "descrListaPerOggetti")

        BindUtils.postNotifyChange(null, null, this, "pagingPerOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaImpostePerOggetti")
        BindUtils.postNotifyChange(null, null, this, "selectedPerOggetti")
        BindUtils.postNotifyChange(null, null, this, "totaleImpostePerOggetti")
    }

    private def eliminaImpostaPerOggetti(def oggettoImposta) {

        imposteService.eliminaImposta(oggettoImposta)
        onRefreshPerOggetti()
    }

    private def completaParametriPerOggetti() {

        return filtroRicercaImposte.preparaRicercaOggetti()
    }

    private def applicaParametriPerOggetti(def parRicerca) {

        filtroRicercaImposte.applicaRicercaOggetti(parRicerca)
        listaImposteContribuenti = []
        listaImposteDettaglio = []
        listaImpostePerOggetti = []
        salvaFiltroRicercaImposte()
    }

    def verificaCampiFiltroPerOggetti() {

        filtroAttivoPerOggetti = filtroRicercaImposte.isDirtyOggetti()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoPerOggetti")
    }

    @Command
    def onChangeOrdinamentoPerOggetti(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        ordinamentoPerOggetti.tipo = CampiOrdinamento.getAt(valore)
        ordinamentoPerOggetti.ascendente = event.isAscending()
        caricaListaPerOggetti()
    }

    def selectedPerOggettiReset() {

        selectedPerOggetti = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedPerOggetti")
        selectedAnyPerOggettiRefresh()
    }

    def selectedAnyPerOggettiRefresh() {

    }

    @Command
    def openFiltriPerOggetti() {

        def parRicerca = completaParametriPerOggetti()

        if (selectedImposta) {
            Window w = Executions.createComponents("/ufficiotributi/imposte/listaImposteDettaglioRicerca.zul", self, [parRicerca: parRicerca, tipoTributo: tipoTributo])
            w.onClose { event ->
                if (event.data) {
                    if (event.data.status == "Cerca") {
                        applicaParametriPerOggetti(event.data.parRicerca)
                        onCercaPerOggetti()
                    }
                }
                verificaCampiFiltroPerOggetti()
            }
            w.doModal()
        }
    }

    @Command
    def onCercaPerOggetti() {

        pagingPerOggetti.activePage = 0
        caricaListaPerOggetti()
    }

    @Command
    def onRefreshPerOggetti() {

        caricaListaPerOggetti()
    }

    @Command
    def onPagingPerOggetti() {

        caricaListaPerOggetti(true)
    }

    @Command
    def onModificaPerOggetti() {

        apriMascheraContribuente(selectedPerOggetti.ni)
    }

    @Command
    def onEliminaPerOggetti() {

        def oggettoImposta = selectedPerOggetti?.oggettoImposta

        if (oggettoImposta) {

            String messaggio = "Eliminare la voce d'imposta?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                eliminaImpostaPerOggetti(oggettoImposta)
                            }
                        }
                    }
            )
        }
    }

    @Command
    def onPerOggettiToXls() {

        def tipoTributo = this.tipoTributo.tipoTributo
        def annoTributo = selectedImposta.anno
        def tributo = selectedImposta.tributo?.id
        def servizio = selectedImposta.servizio

        String etichettaCategoria = ""

        if (annoTributo < 2021) {
            etichettaCategoria = 'Categoria/Zona'
        } else {
            etichettaCategoria = 'Zona'
        }

        def fields = [
                'contribuente'     : 'Cognome e Nome',
                'codFiscale'       : 'Codice Fiscale',
                'id'               : 'Oggetto',
                'descrizione'      : 'Descrizione',
                'indirizzoCompleto': 'Indirizzo',
                'sez'              : 'Sez.',
                'foglio'           : 'Fgl.',
                'numero'           : 'Num.',
                'sub'              : 'Sub.',
                'imposta'          : 'Imposta',
        ]
        if (tipoTributo != 'CUNI') {
            fields << [
                    'impostaErariale': 'Imposta Erariale',
            ]
        }
        fields << [
                'dataDecorrenza'  : 'Decorrenza',
                'dataCessazione'  : 'Cessazione',
                'codiceTributo'   : 'Codice Tributo',
                'categoriaDescr'  : etichettaCategoria,
                'tariffaDescr'    : 'Tipologia',
                'tipoOccupazione' : 'Occ.',
                'esenzione'       : 'Es.',
                'quantita'        : 'Quantita\'',
                'larghezza'       : 'Larghezza',
                'profondita'      : 'Altezza o Profondita\'',
                'consistenzaReale': 'Sup. Reale',
                'consistenza'     : 'Superficie',
                'residente'       : 'Residente',
                'statoDescrizione': 'Stato',
                'dataUltEvento'   : 'Data Evento',
                'indirizzoRes'    : 'Indirizzo Res.',
                'civicoRes'       : 'Civico Res.',
                'comuneRes'       : 'Comune Res.',
                'capRes'          : 'CAP Res.',
                'cognomeNomeP'    : 'Presso',
                'mailPec'         : 'Indirizzo PEC'
        ]

        def pagingToXls = pagingPerOggetti

        Integer xlsRigheMax = Integer.MAX_VALUE
        Integer xlsRighePage
        Integer xlsRighePageMax

        xlsRighePageMax = (pagingToXls.totalSize / xlsRigheMax)
        xlsRighePage = (pagingToXls.totalSize > xlsRigheMax) ? pagingToXls.activePage : 0
        if (xlsRighePage >= xlsRighePageMax) xlsRighePage = xlsRighePageMax

        def parRicercca = completaParametriPerOggetti()
        def caricoPerOggetti = imposteService.listaImposteDettaglio(annoTributo, tipoTributo, parRicercca, ordinamentoPerOggetti,
                xlsRigheMax, xlsRighePage, null, servizio)

        def converters = [
                tipoOccupazione: { to -> to ? "${to?.tipoOccupazione}" : null },
                esenzione      : { e -> (e ? 'E' : null) },
                residente      : Converters.flagString
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_PER_OGGETTO,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.exportAndDownload(nomeFile, caricoPerOggetti.result,
                fields,
                converters)

    }

    @Command
    def onPerCategorieToXls() {

        def annoTributo = selectedImposta.anno

        def fields = [
                "codiceCategoria"     : "Codice",
                "descrizioneCategoria": "Categoria",
                "imposta"             : "Imposta"
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_PER_CATEGORIE,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.exportAndDownload(nomeFile,
                listaImpostePerCategorie,
                fields)
    }

    @Command
    def onPerAliquotaToXls() {

        def annoTributo = selectedImposta.anno

        def fields = [
                "aliquota"     : "Aliquota %",
                "descrizione"  : "Categoria",
                "totaleImposta": "Imposta"
        ]

        def listaFormattata = []

        listaImpostePerAliquota.each {

            if (it.descrizione == "Totale anno:") {
                return
            }

            if (it.dettaglio.size == 0) {
                listaFormattata << it
            } else {
                it.dettaglio.each { dett ->
                    dett.totaleImposta = dett.imposta
                    listaFormattata << dett
                }
            }
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_PER_ALIQUOTE,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.exportAndDownload(nomeFile,
                listaFormattata,
                fields)
    }

    @Command
    def onPerAliquoteCategorieToXls() {

        def annoTributo = selectedImposta.anno

        def lista = imposteService.listaImpostePerAliquotaCategorie(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)


        def fields = [
                "aliquota"   : "Aliquota %",
                "categoria"  : "Codice",
                "descrizione": "Categoria",
                "impostaAnno": "Imposta"
        ]

        def listaFormattata = []

        lista.each {

            if (it.dettaglio.size == 0) {
                listaFormattata << it
            } else {
                it.dettaglio.each { dett ->

                    // Se si tratta di un'aliquota multipla modifico la descrizione di ogni dettaglio
                    if (it.descrizione == "(Aliquote Multiple)") {
                        dett.descrizione = "(Aliquote Multiple) " + dett.descrizione
                    }

                    if (dett.impostaAnno == 0 && dett.impostaDettaglio > 0) {
                        dett.impostaAnno = dett.impostaDettaglio
                    }
                    listaFormattata << dett
                }
            }
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_PER_ALIQUOTE_CATEGORIE,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.exportAndDownload(nomeFile,
                listaFormattata,
                fields)
    }

    @Command
    def onPerTipologieToXls() {

        def annoTributo = selectedImposta.anno

        def lista = imposteService.listaImpostePerTipologia(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)


        def fields = [
                "descrizione": "",
                "acconto"    : "Acconto",
                "saldo"      : "Saldo",
                "totale"     : "Totale"
        ]

        def listaFormattata = [
                [descrizione: "Terreni",
                 acconto    : lista[0].impostaAccontoTerreniAnno,
                 saldo      : lista[0].impostaSaldoTerreniAnno,
                 totale     : lista[0].impostaTerreniAnno],
                [descrizione: "Aree",
                 acconto    : lista[0].impostaAccontoAreeAnno,
                 saldo      : lista[0].impostaSaldoAreeAnno,
                 totale     : lista[0].impostaAreeAnno],
                [descrizione: "Abitazione Principale",
                 acconto    : lista[0].impostaAccontoAbPrincipaleAnno,
                 saldo      : lista[0].impostaSaldoAbPrincipaleAnno,
                 totale     : lista[0].impostaAbPrincipaleAnno],
                [descrizione: "Altri",
                 acconto    : lista[0].impostaAccontoAltriAnno,
                 saldo      : lista[0].impostaSaldoAltriAnno,
                 totale     : lista[0].impostaAltriAnno],
                [descrizione: "Detrazioni",
                 acconto    : lista[0].detrazioneAccontoAnno,
                 saldo      : lista[0].detrazioneSaldoAnno,
                 totale     : lista[0].detrazioneAnno]
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPOSTE_PER_TIPOLOGIE,
                [tipoTributo: this.tipoTributo.tipoTributoAttuale,
                 anno       : annoTributo])

        XlsxExporter.exportAndDownload(nomeFile,
                listaFormattata,
                fields)
    }

    private void caricaListaPerCategorie() {

        listaImpostePerCategorie = imposteService.listaImpostePerCategoria(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)

        totaleImpostePerCategorie = listaImpostePerCategorie.sum { it.imposta }

        onRefreshListe()
    }

    @Command
    def onRefreshPerCategorie() {

        totaleImpostePerCategorie = 0

        caricaListaPerCategorie()
    }

    private void caricaListaPerAliquote() {

        listaImpostePerAliquota = imposteService.listaImpostePerAliquota(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)

        totaleImpostePerAliquote = 0
        totaleImposteDettPerAliquote = 0
        totaleNumeroPerAliquote = 0

        listaImpostePerAliquota.each {

            def totale = it
            def dettagli = totale.dettaglio

            totaleImpostePerAliquote += it.totaleImposta ?: 0

            if (dettagli.size() > 0) {
                dettagli.each {

                    totaleImposteDettPerAliquote += it.imposta ?: 0
                    totaleNumeroPerAliquote += it.numero ?: 0
                }
            } else {
                totaleImposteDettPerAliquote += it.totaleImposta ?: 0
                totaleNumeroPerAliquote += it.numero ?: 0
            }
        }
        /*listaImpostePerAliquota << [
                aliquota     : null,
                descrizione  : '-------------------------------------------------------------------------------------------------------------',
                totaleImposta: null,
                dettaglio    : [],
                totali       : true
        ]*/
        listaImpostePerAliquota << [
                aliquota     : null,
                descrizione  : 'Totale anno:',
                totaleImposta: totaleImposteDettPerAliquote,
                dettaglio    : [],
                totali       : true
        ]

        onRefreshListe()
    }

    @Command
    def onRefreshPerAliquote() {

        caricaListaPerAliquote()
    }

    private void caricaListaPerAliquoteCategorie() {

        listaImpostePerAliquoteCategorie = imposteService.listaImpostePerAliquotaCategorie(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)

        totaleImpostePerAliquoteCategorie = listaImpostePerAliquoteCategorie.sum { it.impostaAnno ?: 0 }
        totaleImposteDettPerAliquoteCategorie = listaImpostePerAliquoteCategorie.sum { it.impostaDettaglio ?: 0 }

        listaImpostePerAliquoteCategorie << [
                descrizione     : "Totali:",
                impostaDettaglio: totaleImposteDettPerAliquoteCategorie,
                impostaAnno     : totaleImpostePerAliquoteCategorie
        ]

        onRefreshListe()
    }

    @Command
    def onRefreshPerAliquoteCategorie() {

        caricaListaPerAliquoteCategorie()
    }

    private void caricaListaPerTipologie() {

        listaImpostePerTipologie = imposteService.listaImpostePerTipologia(selectedImposta.anno, tipoTributo.tipoTributo, selectedImposta.tributo?.id)

        onRefreshListe()
    }

    @Command
    def onRefreshPerTipologie() {

        caricaListaPerTipologie()
    }

    @Command
    def onMostraGrafico(@BindingParam("categoria") String categoria, @BindingParam("popup") Popup torta) {

        modelPerCategoria = new DefaultSingleValueCategoryModel()
        for (Map cat in listaImpostePerCategorie) {
            if (cat.codiceCategoria =~ $/^${categoria}/$) {
                modelPerCategoria.setValue(cat.codiceCategoria, cat.imposta ?: 0)
            }
        }
        torta?.open(self, "middle_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerCategoria")
    }

    @Command
    def onMostraGraficoFree(@BindingParam("categoria") String categoria, @BindingParam("popup") Popup torta) {

        modelPerCategoriaFree = new SimplePieModel()
        for (Map cat in listaImpostePerCategorie) {
            if (cat.codiceCategoria =~ $/^${categoria}/$) {
                modelPerCategoriaFree.setValue(cat.codiceCategoria, cat.imposta ?: 0)
            }
        }
        torta?.open(self, "top_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerCategoriaFree")
    }

    @Command
    def onTortaPerAliquota(@BindingParam("aliquota") Map aliquota, @BindingParam("popup") Popup torta) {

        titoloTortaPerAliquota = "Imposta per aliquota " + aliquota.aliquota + "%"
        modelPerAliquota = new DefaultPieModel()
        for (Map det in aliquota.dettaglio) {
            modelPerAliquota.setValue((det.descrizione.size() > 15) ? det.descrizione.substring(0, 15) + "..." : det.descrizione
                    , det.imposta ?: 0)
        }
        torta?.open(self, "middle_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerAliquota")
        BindUtils.postNotifyChange(null, null, this, "titoloTortaPerAliquota")
    }

    @Command
    def onTortaPerAliquotaFree(@BindingParam("aliquota") Map aliquota, @BindingParam("popup") Popup torta) {

        titoloTortaPerAliquota = "Imposta per aliquota " + aliquota.aliquota + "%"
        modelPerAliquotaFree = new SimplePieModel()
        for (Map det in aliquota.dettaglio) {
            modelPerAliquotaFree.setValue(det.descrizione, det.imposta ?: 0)
        }
        torta?.open(self, "top_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerAliquotaFree")
        BindUtils.postNotifyChange(null, null, this, "titoloTortaPerAliquota")
    }

    @Command
    def onTortaPerAliquote(@BindingParam("popup") Popup torta) {

        DecimalFormat fmtPerc = new DecimalFormat("#,##0.00")

        String percentuale
        String descrizione

        def listaAliquote = listaImpostePerAliquota.findAll { !(it.totali ?: false) }

        titoloTortaPerAliquota = "Imposta per aliquota"
        modelPerAliquota = new DefaultPieModel()
        for (Map det in listaAliquote) {
            if (det.aliquota != null) {
                percentuale = fmtPerc.format(det.aliquota)
                descrizione = "Aliquota ${percentuale}%"
            } else {
                descrizione = det.descrizione
            }
            modelPerAliquota.setValue(descrizione, det.totaleImposta ?: 0)
        }
        torta?.open(self, "middle_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerAliquota")
        BindUtils.postNotifyChange(null, null, this, "titoloTortaPerAliquota")
    }

    @Command
    def onTortaPerAliquoteFree(@BindingParam("popup") Popup torta) {

        DecimalFormat fmtPerc = new DecimalFormat("#,##0.00")

        String percentuale
        String descrizione

        def listaAliquote = listaImpostePerAliquota.findAll { !(it.totali ?: false) }

        titoloTortaPerAliquota = "Imposta per aliquote"
        modelPerAliquotaFree = new SimplePieModel()
        for (Map det in listaAliquote) {
            if (det.aliquota != null) {
                percentuale = fmtPerc.format(det.aliquota)
                descrizione = "Aliquota ${percentuale}%"
            } else {
                descrizione = det.descrizione
            }
            modelPerAliquotaFree.setValue(descrizione, det.totaleImposta ?: 0)
        }
        torta?.open(self, "top_center")
        BindUtils.postNotifyChange(null, null, this, "modelPerAliquotaFree")
        BindUtils.postNotifyChange(null, null, this, "titoloTortaPerAliquota")
    }

    @Command
    onChiudiRiepilogoJob(@BindingParam("popup") Component popupStatoJob) {

        popupStatoJob.close()
    }

    @Command
    onCaricaListaJob(@BindingParam("lista") Include listaJob) {

        listaJob?.invalidate()
    }

    @Command
    onInviaAppIO() {
        def tipoDocumento = documentaleService.recuperaTipoDocumento(null, 'C')
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, tipoDocumento)
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : selectedContribuente.codFiscale,
                 tipoTributo      : tipoTributo,
                 tipoComunicazione: tipoComunicazione,
                 pratica          : null,
                 tipologia        : "C",
                 anno             : selectedImposta.anno
                ])

    }

    // Stampa elenco documenti
    def stampaDocumenti(def daStampare) {

        Short anno = selectedImposta.anno

        String tipoTributoNow = tipoTributo.tipoTributo

        Long ruolo = -1
        Long ruoloAgid = 0
        Long elaborazione = 1
        String elaborazioneID

        if (daStampare.size() == 1) {

            def pratica = daStampare[0]
            def praticaBase = (pratica.pratica != null) ? pratica.pratica : -1
            def codFiscale = pratica.codFiscale

            def parametri = [:]

            if (tipoTributoNow in ['ICI', 'TASI', 'CUNI', 'ICP', 'TOSAP']) {
                parametri = [

                        tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                        idDocumento: [
                                tipoTributo: tipoTributoNow,
                                ruolo      : ruoloAgid,
                                codFiscale : codFiscale,
                                anno       : anno,
                                pratica    : praticaBase
                        ],
                        // nomeFile   : nomeFile
                ]
            } else if (tipoTributoNow in ['TARSU']) {

                parametri = [
                        tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                        idDocumento: [
                                ruolo     : daStampare[0].ruolo,
                                anno      : anno,
                                codFiscale: codFiscale
                        ],
                        // nomeFile   : nomeFile,
                ]
            }

            commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", null, [parametri: parametri])
        } else {

            elaborazioneID = anno.toString() + elaborazione.toString().padLeft(8, "0")

            Window w = Executions.createComponents("/elaborazioni/creazioneElaborazione.zul",
                    null,
                    [
                            nomeElaborazione: "COM_${elaborazioneID}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                            tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA,
                            tipoTributo     : tipoTributoNow,
                            ruolo           : ruolo,
                            pratiche        : daStampare,
                            anno            : anno
                    ]
            )
            w.doModal()
        }
    }

    private checkAbilitazioneStampa() {

        // Il controllo sul ruolo viene applicato solo per il tipo tributo TARSU
        if (tipoTributo.tipoTributo != "TARSU") {
            abilitaStampa = true
            BindUtils.postNotifyChange(null, null, this, "abilitaStampa")
            return
        }

        def contribuenti = selectedContribuenti
                .findAll { it.value }
                .collect { it.key }
        abilitaStampa = contribuentiProps.find {
            it.key in contribuenti && it.value.ruolo == null
        } == null

        BindUtils.postNotifyChange(null, null, this, "abilitaStampa")

    }

}
