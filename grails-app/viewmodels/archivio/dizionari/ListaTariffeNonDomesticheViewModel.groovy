package archivio.dizionari

import it.finmatica.tr4.categorie.CategorieService
import it.finmatica.tr4.codiciTributo.CodiciTributoService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.TariffaNonDomesticaDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tariffeNonDomestiche.TariffeNonDomesticheService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaTariffeNonDomesticheViewModel extends TabListaGenericaTributoViewModel {

    final tariffaFormat = '#,##0.00000'

    // Servizi
    CodiciTributoService codiciTributoService
    CategorieService categorieService
    TariffeNonDomesticheService tariffeNonDomesticheService

    // Componenti
    Window self

    // Modello
    Collection<CodiceTributoDTO> listaCodiciTributo
    Collection<CategoriaDTO> listaCategorie
    Collection<TariffaNonDomesticaDTO> listaTariffeNonDomestiche

    CodiceTributoDTO codiceTributoSelezionato
    TariffaNonDomesticaDTO tariffaNonDomesticaSelezionata

    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("annoTributo") def annoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        // TODO dovrei spostarlo in un metodo chiamato al cambio del tipo tributo ? Ovvero : possono esserci modifiche ai CodiciTributo che devo riflettere tra un refresh e l'altro del viewModel ?
        listaCodiciTributo = codiciTributoService.getByCriteria(tipoTributoSelezionato.tipoTributo)
        codiceTributoSelezionato = listaCodiciTributo[0]
        labels = commonService.getLabelsProperties('dizionario')
    }

    String infoCodiceTributo(def tariffa) {
        CodiceTributoDTO elem = listaCodiciTributo.find { it.id == tariffa.tributo }
        return elem ? elem.id + " - " + elem.descrizione : tariffa.tributo
    }

    String infoCategoria(def tariffa, List listaCategorie = this.listaCategorie) {
        CategoriaDTO elem = listaCategorie.find { it.categoria == tariffa.categoria && it.codiceTributo.id == tariffa.tributo }
        return elem ? elem.categoria + " - " + elem.descrizione : tariffa.categoria
    }

    // Eventi interfaccia
    @Override
    @Command
    void onRefresh() {
        tariffaNonDomesticaSelezionata = null

        // Chiamo il servizio solo se ho un codice tributo selezionato
        if (codiceTributoSelezionato) {

            listaCategorie = categorieService.getByCriteria(["codiceTributo": codiceTributoSelezionato.id])

            filtro << ['annoTributo': this.selectedAnno]
            filtro << ['codiceTributo': codiceTributoSelezionato.id]
            listaTariffeNonDomestiche = tariffeNonDomesticheService.getByCriteria(filtro, filtroAttivo)

            BindUtils.postNotifyChange(null, null, this, "tariffaNonDomesticaSelezionata")
            BindUtils.postNotifyChange(null, null, this, "listaTariffeNonDomestiche")
        }

        BindUtils.postNotifyChange(null, null, this, "codiceTributoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaCodiciTributo")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return tariffeNonDomesticheService.countByCriteria(['annoTributo'  : selectedAnno,
                                                            'codiceTributo': codiceTributoSelezionato.id]) == 0 &&
                !tariffeNonDomesticheService.getListaAnniDuplicabiliByCodiceTributo(codiceTributoSelezionato.id).empty
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaTariffaNonDomesticaDaAnno.zul", self,
                ['anno'         : selectedAnno,
                 'codiceTributo': codiceTributoSelezionato.id], { event ->
            if (event.data?.anno) {
                Clients.showNotification("Duplicazione da anno ${event.data.anno} avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                onRefresh()
            }
        })
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaNonDomestica.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : tariffaNonDomesticaSelezionata.clone(),
                        "isModifica"    : true,
                        "isLettura"     : lettura
                ], { event -> if (event.data?.tariffa) modifyElement(event.data.tariffa) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaNonDomestica.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : null,
                        "isModifica"    : false,
                ], { event -> if (event.data?.tariffa) addElement(event.data.tariffa) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaNonDomestica.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : this.tariffaNonDomesticaSelezionata.clone(),
                        "isModifica"    : false,
                ], { event -> if (event.data?.tariffa) addElement(event.data.tariffa) })
    }


    @Command
    def onElimina() {
        Messagebox.show("Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        tariffeNonDomesticheService.elimina(tariffaNonDomesticaSelezionata)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = []
        def listaCategorieXls = []

        if (mode == ExportXlsMode.PARAMETRI) {
            lista += listaTariffeNonDomestiche
            listaCategorieXls += listaCategorie
        } else if (mode == ExportXlsMode.TUTTI) {
            listaCategorieXls += categorieService.getByCriteria([:])
            lista += tariffeNonDomesticheService.getByCriteria([:], false)
        }

        def converters = [
                categoriaConDescrizione: { c -> infoCategoria(c, listaCategorieXls) },
                tributoConDescrizione  : { c -> infoCodiceTributo(c) }
        ]

        if (lista) {
            Map fields = [
                    tributoConDescrizione  : "Codice Tributo",
                    anno                   : "Anno",
                    categoriaConDescrizione: "Categoria",
                    tariffaQuotaFissa      : "Tariffa Quota Fissa",
                    tariffaQuotaVariabile  : "Tariffa Quota Variabile",
                    importoMinimi          : "Importo Minimi"
            ]

            def bigDecimalFormat = [
                    'tariffaQuotaFissa'     : tariffaFormat,
                    'tariffaQuotaVariabile' : tariffaFormat,
                    'importoMinimi'         : tariffaFormat
            ]
            def nomeFile = getNomeFileXls(mode)

            XlsxExporter.exportAndDownload(nomeFile, lista, fields, converters, bigDecimalFormat)
        }
    }

    private def getNomeFileXls(String modalita) {
        return "TariffeNonDomestiche_${tipoTributoSelezionato.tipoTributoAttuale}${modalita == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
    }

    /**
     * NOTE : meccanismo copiato PARZIALMENTE da MoltiplicatoriViewModel
     */
    @Command
    def onSelectAnno() {
        filtro << ['annoTributo': selectedAnno]
        onRefresh()
        BindUtils.postNotifyChange(null, null, this, "selectedAnno")
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaTariffeNonDomesticheRicerca.zul", self,
                [
                        filtro: filtro,
                ], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def modifyElement(TariffaNonDomesticaDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(tariffaNonDomesticaSelezionata, elementFromEvent)) {
            tariffeNonDomesticheService.elimina(tariffaNonDomesticaSelezionata)
        }

        addElement(elementFromEvent)
    }

    private def addElement(TariffaNonDomesticaDTO elementFromEvent) {
        tariffeNonDomesticheService.salva(elementFromEvent)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    /**
     * Il mapping-id per la classe CoefficientiNonDomestici è dato dalla tripla : { anno, tributo, categoria}
     * ma solo la categoria è modificabile tramite interfaccia.
     *
     * @see it.finmatica.tr4.TariffaNonDomestica
     */
    private static def isPrimaryModified(TariffaNonDomesticaDTO source, TariffaNonDomesticaDTO dest) {
        return !(source.categoria.equals(dest.categoria))
    }
}
