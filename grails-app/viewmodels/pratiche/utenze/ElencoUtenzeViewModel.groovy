package pratiche.utenze

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.UtenzeService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.CampiOrdinamento
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ElencoUtenzeViewModel {

    Window self

    //Servizi
    OggettiService oggettiService
    UtenzeService utenzeService
    CommonService commonService

    String statoSoggetti
    String statoUtenze

    /// Paginazione
    def pagingList = [:]

    String totaleContribuenti = ""
    String totaleUtenze = ""

    def orderFields = []

    boolean filtroAttivo = false

    def utenzaTariSelezionata


    def listaUtenzeTari

    /// Interfaccia
    def filtro = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        orderFields = CampiOrdinamento.values()

        inizializzaFiltro()
        initPagingList()
        apriMascheraRicerca()
    }

    @Command
    onRefresh() {

        caricaLista()

    }

    @Command
    onChangeOrderBy() {

        caricaLista()

    }

    @Command
    onControlloUtenzeContribuente() {

        String codiceFiscale = utenzaTariSelezionata.codFiscale
        String anno = filtro.anno

        apriMascheraControlloUtenze(anno, codiceFiscale)

        utenzaTariSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "utenzaTariSelezionata")

    }

    @Command
    onControlloUtenzeGenerale() {

        String codiceFiscale = UtenzeService.ALL_FISCAL_CODE
        String anno = filtro.anno

        apriMascheraControlloUtenze(anno, codiceFiscale)
    }

    @Command
    onVisualizzaContribuentiOggetto() {

        def oggettoId = utenzaTariSelezionata.oggetto as Long

        commonService.creaPopup(
                "/sportello/contribuenti/contribuentiOggetto.zul",
                self,
                [
                        oggetto: utenzaTariSelezionata.oggetto,
                        pratica: null,
                        anno   : "Tutti"
                ],
                {

                }
        )

    }

    @Command
    onVisualizzaPraticheOggetto() {

        commonService.creaPopup(
                "/pratiche/praticheOggetto.zul",
                self,
                [oggetto: utenzaTariSelezionata.oggetto],
                {}

        )
    }

    @Command
    onContribuentiToXls() {

        Map fields

        List lista = (utenzeService.getUtenzeTari(filtro, Integer.MAX_VALUE, 0) as HashMap).lista

        if (lista.empty) {
            return
        }

        fields = [
                "oggetto"         : "Oggetto",
                "soggnome"        : "Contribuente",
                "codFiscale"      : "Codice Fiscale",
                "indiOgge"        : "Indirizzo",
                "tributo"         : "Tributo",
                "categoria"       : "Categoria",
                "tipoTariffa"     : "Tipo Tariffa",
                "consistenza"     : "Consistenza",
                "dal"             : "Valido Dal",
                "al"              : "Valido Al",
                "note"            : "Note",
                "flagDomestica"   : "Domestica",
                "flagAbPrincipale": "A",
                "numeroFamiliari" : "Componenti",
                "desCategoria"    : "Descrizione Categoria",
                "sezione"         : "Sezione",
                "foglio"          : "Foglio",
                "numero"          : "Numero",
                "subalterno"      : "Subalterno",
                "categoriaCatasto": "Categoria Catasto",
                "residente"       : "Residente",
                "descrizioneStato": "Stato",
                "dataUltEve"      : "Data Ultimo Evento",
                "indirizzoRes"    : "Indirizzo Residenza",
                "numCivicoRes"    : "Civico Residenza",
                "comuneRes"       : "Comune Residenza",
                "capRes"          : "CAP Residenza",
                "soggnomeP"       : "Presso",
                "tipoOccupazione" : "Tipo Occupazione"
        ]


        String fileName = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.LISTA_UTENZE_TARI,
                [anno: filtro.anno])

        def formatters = [
                "oggetto"    : Converters.decimalToInteger,
                "tributo"    : Converters.decimalToInteger,
                "categoria"  : Converters.decimalToInteger,
                "tipoTariffa": Converters.decimalToInteger]

        XlsxExporter.exportAndDownload(fileName, lista, fields, formatters)
    }

    @Command
    openCloseFiltri() {
        apriMascheraRicerca()
    }

    @Command
    def onCambioPagina() {
        caricaLista()

    }

    @Command
    def onChangeStato() {
        initPagingList()
        caricaLista()
    }

    @Command
    void onChangeTipoUtenza() {
        initPagingList()
        caricaLista()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("ni") def ni) {

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    private void initPagingList() {

        pagingList = [
                activePage: 0,
                pageSize  : 30,
                totalSize : 0
        ]

    }

    private void caricaLista() {

        def result = utenzeService.getUtenzeTari(filtro, pagingList.pageSize, pagingList.activePage)

        listaUtenzeTari = result.lista
        def numeroTotaleUtenze = result.totaleUtenze
        def numeroContribuenti = result.totaleContribuenti

        totaleContribuenti = "Totale Contribuenti: ${numeroContribuenti}"
        totaleUtenze = "Totale Utenze: ${numeroTotaleUtenze}"
        pagingList.totalSize = numeroTotaleUtenze

        BindUtils.postNotifyChange(null, null, this, "pagingList")
        BindUtils.postNotifyChange(null, null, this, "totaleContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totaleUtenze")
        BindUtils.postNotifyChange(null, null, this, "listaUtenzeTari")
        deselectUtenzaSelezionata()
    }

    private apriMascheraRicerca() {

        commonService.creaPopup(
                "/pratiche/utenze/elencoUtenzeRicerca.zul",
                self,
                [filtroRicerca: filtro],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtro = event.data.parRicerca
                            aggiornaFiltroAttivo()
                            initPagingList()
                            caricaLista()
                        }
                    }
                }
        )


    }

    private void aggiornaFiltroAttivo() {

        filtroAttivo = filtro.flagContenzioso != utenzeService.DEFAULT_FLAG_CONTENZIOSO ||
                filtro.flagInclCessati != utenzeService.DEFAULT_FLAG_INCL_CESSATI ||
                filtro.tipoAbitazione != utenzeService.DEFAULT_TIPO_ABITAZIONE ||
                filtro.tipoOccupazione != utenzeService.DEFAULT_TIPO_OCCUPAZIONE ||
                filtro.numeroCivicoDa ||
                filtro.numeroCivicoA ||
                filtro.categoriaDa ||
                filtro.categoriaA ||
                filtro.tariffaDa ||
                filtro.tariffaA ||
                filtro.nome ||
                filtro.cognome ||
                filtro.nInd ||
                filtro.codContribuente ||
                filtro.indirizzo ||
                filtro.codiceFiscale ||
                filtro.codiceTributo.id != 0L ||
                filtro.tipoEvento != utenzeService.DEFAULT_TIPO_EVENTO

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private apriMascheraControlloUtenze(String anno, String codiceFiscale) {

        commonService.creaPopup(
                "/pratiche/utenze/elencoUtenzeDaControllare.zul",
                self,
                [anno: anno, codiceFiscale: codiceFiscale],
                { event ->
                    if (event.data.status == UtenzeService.NO_USERS_FOUND) {
                        String message = event.data.message
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                    }
                }
        )

    }

    private inizializzaFiltro() {
        filtro = [
                anno           : Calendar.getInstance().get(Calendar.YEAR),
                flagContenzioso: UtenzeService.DEFAULT_FLAG_CONTENZIOSO,
                flagInclCessati: UtenzeService.DEFAULT_FLAG_INCL_CESSATI,
                tipoAbitazione : UtenzeService.DEFAULT_TIPO_ABITAZIONE,
                statoSoggetti  : "T",
                statoUtenze    : "T",
                orderByType    : CampiOrdinamento.ALFA
        ]
    }

    private void deselectUtenzaSelezionata() {
        utenzaTariSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "utenzaTariSelezionata")
    }


    @Command
    def onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }
}
