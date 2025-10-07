package archivio.dizionari

import it.finmatica.tr4.categorie.CategorieService
import it.finmatica.tr4.codiciTributo.CodiciTributoService
import it.finmatica.tr4.coefficientiNonDomestici.CoefficientiNonDomesticiService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.CoefficientiNonDomesticiDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCoefficientiNonDomesticiViewModel extends TabListaGenericaTributoViewModel {

    final coefficienteFormat = '#,##0.0000'

    // Servizi
    CodiciTributoService codiciTributoService
    CategorieService categorieService
    CoefficientiNonDomesticiService coefficientiNonDomesticiService

    // Componenti
    Window self
    def labels

    // Modello
    Collection<CodiceTributoDTO> listaCodiciTributo
    Collection<CategoriaDTO> listaCategorie
    Collection<CoefficientiNonDomesticiDTO> listaCoefficientiNonDomestici

    CodiceTributoDTO codiceTributoSelezionato
    CoefficientiNonDomesticiDTO coefficienteNonDomesticoSelezionato

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false


    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("annoTributo") def annoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)


        //  TODO dovrei spostarlo in un metodo chiamato al cambio del tipo tributo ? Ovvero : possono esserci modifiche ai CodiciTributo che devo riflettere tra un refresh e l'altro del viewModel ?
        listaCodiciTributo = codiciTributoService.getByCriteria(tipoTributoSelezionato.tipoTributo)
        codiceTributoSelezionato = listaCodiciTributo[0]

        labels = commonService.getLabelsProperties('dizionario')
    }

    String infoCategoria(def coeff, List listaCategorie = this.listaCategorie) {
        CategoriaDTO elem = listaCategorie.find { it.categoria == coeff.categoria && it.codiceTributo.id == coeff.tributo }
        return elem ? elem.categoria + " - " + elem.descrizione : coeff.categoria
    }

    private def infoTributo(def coefficiente) {
        def trb = listaCodiciTributo.find { it.id == coefficiente.tributo }
        return "${trb?.id ?: ''}  - ${trb?.descrizione ?: ''}"
    }

    // Eventi interfaccia
    @Override
    @Command
    void onRefresh() {
        coefficienteNonDomesticoSelezionato = null

        // Chiamo il servizio solo se ho un codice tributo selezionato
        if (codiceTributoSelezionato) {

            listaCategorie = categorieService.getByCriteria(["codiceTributo": codiceTributoSelezionato.id])

            filtro << ['annoTributo': this.selectedAnno]
            filtro << ['codiceTributo': codiceTributoSelezionato.id]
            listaCoefficientiNonDomestici = coefficientiNonDomesticiService.getByCriteria(filtro, filtroAttivo)

            BindUtils.postNotifyChange(null, null, this, "coefficienteNonDomesticoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "listaCoefficientiNonDomestici")
        }

        BindUtils.postNotifyChange(null, null, this, "codiceTributoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaCodiciTributo")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return coefficientiNonDomesticiService.countByCriteria(['annoTributo'  : selectedAnno,
                                                                'codiceTributo': codiceTributoSelezionato.id]) == 0 &&
                !coefficientiNonDomesticiService.getListaAnniDuplicabiliByCodiceTributo(codiceTributoSelezionato.id).empty
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaCoefficientiNonDomesticiDaAnno.zul", self,
                ['anno'         : selectedAnno,
                 'codiceTributo': codiceTributoSelezionato.id],
                { event ->
                    if (event.data?.anno) {
                        Clients.showNotification("Duplicazione da anno ${event.data.anno} avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        onRefresh()
                    }
                })
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficientiNonDomestici.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : coefficienteNonDomesticoSelezionato.clone(),
                        "isModifica"    : true,
                        "isLettura"     : lettura
                ], { event -> if (event.data?.coefficiente) modifyElement(event.data.coefficiente) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficientiNonDomestici.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : null,
                        "isModifica"    : false,
                ], { event -> if (event.data?.coefficiente) addElement(event.data.coefficiente) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficientiNonDomestici.zul", self,
                [
                        "listaCategorie": listaCategorie,
                        "annoTributo"   : this.selectedAnno,
                        "codiceTributo" : this.codiceTributoSelezionato.id,
                        "selezionato"   : this.coefficienteNonDomesticoSelezionato.clone(),
                        "isModifica"    : false,
                ], { event -> if (event.data?.coefficiente) addElement(event.data.coefficiente) })
    }


    @Command
    def onElimina() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        coefficientiNonDomesticiService.elimina(coefficienteNonDomesticoSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls(@BindingParam("modalita") def modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = []
        def listaCategorieXls = []

        if (mode == ExportXlsMode.PARAMETRI) {
            lista += listaCoefficientiNonDomestici
            listaCategorieXls = listaCategorie
        } else if (mode == ExportXlsMode.TUTTI) {
            lista += coefficientiNonDomesticiService.getByCriteria([:], filtroAttivo)
            listaCategorieXls += categorieService.getByCriteria([:])
        }

        if (lista) {
            Map fields = getExportableFieldMap()
            def converters = [
                    tributoConDescrizione  : { c -> infoTributo(c) },
                    categoriaConDescrizione: { c -> infoCategoria(c, listaCategorieXls) },
            ]
            def bigDecimalFormats = [
                    coeffPotenziale: coefficienteFormat,
                    coeffProduzione: coefficienteFormat,
            ]
            def nomeFile = getNomeFileXls(mode)

            XlsxExporter.exportAndDownload(nomeFile, lista, fields, converters, bigDecimalFormats)
        }
    }

    private def getNomeFileXls(String modalita) {
        return "CoefficientiNonDomestici_${tipoTributoSelezionato.tipoTributoAttuale}${modalita == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
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
        commonService.creaPopup("/archivio/dizionari/listaCoefficientiNonDomesticiRicerca.zul", self,
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

    private static def getExportableFieldMap() {
        return [
                "tributoConDescrizione"  : "Codice Tributo",
                "anno"                   : "Anno",
                "categoriaConDescrizione": "Categoria",
                "coeffPotenziale"        : "Coefficiente Potenziale",
                "coeffProduzione"        : "Coefficiente Produzione",
        ]
    }

    private def modifyElement(CoefficientiNonDomesticiDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(coefficienteNonDomesticoSelezionato, elementFromEvent)) {
            coefficientiNonDomesticiService.elimina(coefficienteNonDomesticoSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(CoefficientiNonDomesticiDTO elementFromEvent) {
        coefficientiNonDomesticiService.salva(elementFromEvent)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    /**
     * Il mapping-id per la classe CoefficientiNonDomestici è dato dalla tripla : { anno, tributo, categoria}
     * ma solo la categoria è modificabile tramite interfaccia.
     *
     * @see it.finmatica.tr4.CoefficientiNonDomestici
     */
    private static def isPrimaryModified(CoefficientiNonDomesticiDTO source, CoefficientiNonDomesticiDTO dest) {
        return !(source.categoria.equals(dest.categoria))
    }


}
