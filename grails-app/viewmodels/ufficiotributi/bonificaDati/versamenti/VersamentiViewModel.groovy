package ufficiotributi.bonificaDati.versamenti

import document.FileNameGenerator
import it.finmatica.tr4.AnciVer
import it.finmatica.tr4.WrkVersamenti
import it.finmatica.tr4.anomalie.Causale
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.bonificaDati.versamenti.BonificaVersamentiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

class VersamentiViewModel {

    @Wire('#versamentiDettaglioAnomalia #dettagliAnomalieListBox')
    Listbox dettagliAnomalieListBox

    @Wire('#versamentiDettaglioAnomalia')
    def versamentiDettaglioAnomalia

    @Wire('#anomalieLayout')
    def anomalieLayout

    @Wire('#anomalieListBox')
    Listbox anomalieListBox

    @Wire('#popupFiltriDettagli')
    Popup popupFiltriDettagli

    def tipiRavvedimento = [
            'null': 'Non trattato',
            'N'   : 'Ravv. su Versamento',
            'O'   : 'Ravv. su Omessa Denuncia',
            'I'   : 'Ravv. su Infedele Denuncia'
    ]

    BonificaVersamentiService bonificaVersamentiService

    final MAX_NUM_RIGHE_ANOMALIE = 10

    Window self

	CompetenzeService competenzeService
    CommonService commonService

    def anci

    def incassi = [
            'ANCI',
            'F24'
    ]
    def incassoSelezionato = incassi[1]

    def listaAnni = []
    def annoSelezionato = 1992

    def tipiAnomalie
    def causali
    def tipoAnomaliaSelezionata
    def causaliSelezionate = []
    def tipiTributo = [:]
    def tipoTributoSelezionato
    def idDocumenti
    def idDocumentoSelezionato
	
	def cbTributiInScrittura = [:]
	
    def listaAnomalie = []
    def selezionaTutteAnomalie = false
    def anomaliaSelezionata

    def numeroRigheAnomalie = calcolaNumeroDiRighe()
    def visualizzaAnomalieNonSelezionate = true

    def listaDettaglioAnomalie = [:]
    def dettaglioAnomaliaSelezionato

    def listaDettaglioAnomaliePaginazione = [
            max       : 15,
            offset    : 0,
            activePage: 0
    ]

    def sortDettagliBy = null

    def filtriDettaglio

    def totaleVersamenti = 0

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        onCambiaTipoIncasso()

        inizializzaFiltriDettaglio()

    }

    @Command
    @NotifyChange([
            'anci', 'listaAnni', 'tipiAnomalie', 'causali', 'tipoTributoSelezionato',
            'idDocumentoSelezionato', 'listaAnomalie', 'anomaliaSelezionata', 'causaliSelezionate',
            'causaliSelezionateSel'
    ])
    onCambiaTipoIncasso() {

        // Se anci
        anci = incassoSelezionato == incassi[0]

        // lista dei tributi
        costrusiciTributi()

        // Costruisce la lista degli anni
        costruisciListaAnni(incassoSelezionato)

        // Costruisce la lista delle anomalie/causali
        costruisciTipiAnomalieCausali(incassoSelezionato, tipoTributoSelezionato)

        // Lista dei documenti id
        costruiscidDocumenti()

        resetView()

    }

    @NotifyChange("causaliSelezionateSel")
    @Command
    onSelectTipoCausale() {
    }

    @Command
    @NotifyChange(['anci', 'causali', 'causaliSelezionateSel'])
    onSelezionaTipoTributo() {
        costruisciTipiAnomalieCausali(incassoSelezionato, tipoTributoSelezionato)
    }

    @NotifyChange([
            'listaAnomalie', 'numeroRigheAnomalie', 'selezionaTutteAnomalie',
            'visualizzaAnomalieNonSelezionate', 'listaDettaglioAnomalie', 'anomaliaSelezionata',
            'totaleVersamenti'
    ])
    @Command
    onRicercaAnomalie() {

        resetOrdinamento()
        listaDettaglioAnomalie = [:]
        ricercaAnomalie()
        selezionaTutteAnomalie = false
        visualizzaAnomalieNonSelezionate = true
        anomaliaSelezionata = null

        // reset della paginazione
        listaDettaglioAnomaliePaginazione.offset = 0
        listaDettaglioAnomaliePaginazione.activePage = 0

        //Calcolo totale
        totaleVersamenti = 0
        listaAnomalie.each {
            totaleVersamenti += it.totaleVersato
        }

        anomalieListBox.invalidate()
        anomalieLayout.invalidate()
    }

    @NotifyChange([
            'listaAnomalie', 'visualizzaAnomalieNonSelezionate',
            'numeroRigheAnomalie'
    ])
    @Command
    def toggleVisualizzazioneAnomalie() {

        if (listaAnomalie.findAll { it.selected }.isEmpty()) {
            return
        }

        if (visualizzaAnomalieNonSelezionate) {
            listaAnomalie.each {
                it.visible = it.selected
            }
        } else {
            listaAnomalie.each { it.visible = true }
        }

        visualizzaAnomalieNonSelezionate = !visualizzaAnomalieNonSelezionate
        numeroRigheAnomalie = calcolaNumeroDiRighe()

    }

    @NotifyChange([
            'visualizzaAnomalieNonSelezionate',
            'numeroRigheAnomalie',
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione',
            'listaAnomalie'
    ])
    @Command
    def onSelezionaAnomalia() {

        anomaliaSelezionata.selected = !anomaliaSelezionata.selected

        // reset della paginazione
        listaDettaglioAnomaliePaginazione.offset = 0
        listaDettaglioAnomaliePaginazione.activePage = 0

        // reset dell'ordinamento
        if (anci) {
            resetOrdinamento()
        }

        // In caso di ANCI non è prevista multiselezione
        if (anci) {
            visualizzaAnomalieNonSelezionate = false
            // Si nascondono le anomalie non selezionate
            listaAnomalie.findAll { it.rowNum != anomaliaSelezionata.rowNum }.each { it.visible = false }
            numeroRigheAnomalie = calcolaNumeroDiRighe()
        } else {
            if (listaAnomalie.findAll { it.selected }.isEmpty()) {
                listaDettaglioAnomalie = [:]
                anomaliaSelezionata = null
                BindUtils.postNotifyChange(null, null, this, "anomaliaSelezionata")
                return
            }
        }
        if (selezionaTutteAnomalie) {
            selezionaTutteAnomalie = false
            BindUtils.postNotifyChange(null, null, this, "selezionaTutteAnomalie")
        }

        onCaricaDettagliAnomalie()

    }

    @NotifyChange([
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione'
    ])
    @Command
    def onPaging() {
        onCaricaDettagliAnomalie()
    }

    @NotifyChange([
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione'
    ])
    @Command
    onDettagliAnomaliaSort(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("property") String property) {
        sortDettagliBy = [property: property, direction: event.ascending ? 'asc' : 'desc']
        onCaricaDettagliAnomalie()
    }

    @Command
    def onCaricaDettagliAnomalie() {

        def tipoAnomAnno = [:]

        // In caso di ANCI non è prevista multiselezione
        if (anci) {
            tipoAnomAnno = [
                    tipoAnomalia: anomaliaSelezionata.tipoAnomalia,
                    anno        : anomaliaSelezionata.anno
            ]
        } else {
            tipoAnomAnno = listaAnomalie.findAll { it.selected }.collect {
                [
                        tipoAnomalia: it.tipoAnomalia,
                        anno        : it.anno
                ]
            }
            anomaliaSelezionata = listaAnomalie.findAll { it.selected }[0]
        }

        // Si recuperano i dettagli delle anomalie selezionate
        listaDettaglioAnomalie = bonificaVersamentiService.getDettagliAnomalie(
                incassoSelezionato, tipoAnomAnno,
                listaDettaglioAnomaliePaginazione,
                filtriDettaglio,
                sortDettagliBy
        )

        // Se veniamo dal popup di ricerca
        popupFiltriDettagli.close()

        // Reset della tabella per la corretta impaginazione
        versamentiDettaglioAnomalia.invalidate()

        BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomalie")
        BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomaliePaginazione")
        BindUtils.postNotifyChange(null, null, this, "filtriDettaglioAttivi")
        BindUtils.postNotifyChange(null, null, this, "anomaliaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "visualizzaAnomalieNonSelezionate")
    }

    @Command
    def onPulisciFiltri() {
        inizializzaFiltriDettaglio()

        BindUtils.postNotifyChange(null, null, this, "filtriDettaglio")
    }

    @Command
    def onApplicaFilti() {
        // reset della paginazione
        listaDettaglioAnomaliePaginazione.offset = 0
        listaDettaglioAnomaliePaginazione.activePage = 0

        onCaricaDettagliAnomalie()
    }

    @Command
    def onDettaglioVersamentiToXls() {

        def tipoAnomAnno = listaAnomalie.findAll { it.selected }.collect {
            [
                    tipoAnomalia: it.tipoAnomalia,
                    anno        : it.anno
            ]
        }

        def datiExportVersamenti = bonificaVersamentiService.versamentiToXlsx(filtriDettaglio, tipoAnomAnno, sortDettagliBy)

        def versamenti = datiExportVersamenti.versamenti
        def campi = datiExportVersamenti.campi

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.BONIFICA_VERSAMENTI_DETTAGLIO,
                [date: true])

        XlsxExporter.exportAndDownload(nomeFile,
                versamenti, campi)
    }


    @Command
    def onCloseFiltri() {
        popupFiltriDettagli.close()
    }

    @Command
    def onCorreggiAnomalia(@BindingParam("anomaliaSelezionata") def anom) {
		
		String tipoTributo = anom.tipoTributo ?: ''
		Boolean lettura = (tipoTributo != '') && !cbTributiInScrittura[tipoTributo]
		
        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/bonificaVersamento.zul",
                self,
                [id         : dettaglioAnomaliaSelezionato.id,
                 tipoIncasso: incassoSelezionato,
				 lettura	: lettura
                ])
        w.onClose { event ->
            onCaricaDettagliAnomalie()
        }
        w.doModal()
    }

    @Command
    def onEliminaVersamento(@BindingParam("anomaliaSelezionata") def anom) {

        String messaggio = "Eliminazione della registrazione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.CANCEL | Messagebox.YES, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            bonificaVersamentiService.eliminaVersamento(incassoSelezionato, anom)
                            onCaricaDettagliAnomalie()
                            Clients.showNotification("Versamento eliminato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                                    null, "middle_center", 3000, true)
                        }
                    }
                })
    }

    @Command
    def onDettaglioVersato(@BindingParam("anomaliaSelezionata") def anom) {

        // Solo per WRK
        def versamento = WrkVersamenti.findByProgressivo(new BigDecimal(anom.id))

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/versamentoDettaglioPopup.zul",
                self,
                [
                        versamento: versamento
                ])

        w.doModal()
    }

    @Command
    def onCambiaStatoAnomalia(@BindingParam("anomaliaSelezionata") def anom) {
		
		if((anom.tipoTributo) && (cbTributiInScrittura[anom.tipoTributo] == true)) {
			bonificaVersamentiService.cambiaStato(incassoSelezionato, anom)
			BindUtils.postNotifyChange(null, null, anom, "flagOk")
		}
    }

    void costruisciListaAnni(def incasso) {

        listaAnni = ['(tutti)']

        switch (incasso) {
            case incassi[0]:
                // ANCI
                listaAnni += AnciVer.createCriteria().list() {
                    'in'('tipoAnomalia', [(byte) 51, (byte) 52, (byte) 53, (byte) 54])
                    projections {
                        distinct("annoFiscale")
                    }
                    order('annoFiscale')
                }
                break
            default:
                // Altri tipi di incasso
                listaAnni += WrkVersamenti.createCriteria().list() {
                    projections {
                        distinct("anno")
                    }
                    order('anno')
                }
                break
        }

        annoSelezionato = listaAnni[0]
    }


    @Command
    def onApriCaricaArchivi() {

        def tt = null
        def readOnly = false
        if (!anci) {
            if (tipoTributoSelezionato.key == 'tutti') {
                tt = tipiTributo.find { it.key == listaAnomalie[0].tipoTributo }
            } else {
                tt = tipoTributoSelezionato
                readOnly = true
            }
        }

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/bonificaVersamentiCaricaArchivi.zul",
                self,
                [tipoTributo: tt,
                 tipoIncasso: incassoSelezionato,
                 readOnly   : readOnly,
				 codFiscale : '%'
                ]
        )
        w.onClose { event ->
            ricercaAnomalie()
            onCaricaDettagliAnomalie()

            BindUtils.postNotifyChange(null, null, this, "listaAnomalie")
            BindUtils.postNotifyChange(null, null, this, "anomaliaSelezionata")
            BindUtils.postNotifyChange(null, null, this, "visualizzaAnomalieNonSelezionate")
            BindUtils.postNotifyChange(null, null, this, "numeroRigheAnomalie")
            BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomalie")
            BindUtils.postNotifyChange(null, null, this, "filtriDettaglio")
        }
        w.doModal()
    }

    @NotifyChange([
            'selezionaTutteAnomalie',
            'visualizzaAnomalieNonSelezionate',
            'numeroRigheAnomalie',
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione',
            'listaAnomalie'
    ])
    @Command
    def onSelezionaTutteAnomalie() {
        listaAnomalie.each {
            it.selected = selezionaTutteAnomalie
        }

        onCaricaDettagliAnomalie()
    }

    @NotifyChange([
            'selezionaTutteAnomalie',
            'visualizzaAnomalieNonSelezionate',
            'numeroRigheAnomalie',
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione',
            'listaAnomalie'
    ])
    @Command
    def onCheckAnomalia(@BindingParam("anom") def anom) {
        anomaliaSelezionata = anom
        onSelezionaAnomalia()
    }

    @Command
    def onSelezionaIdDocumento() {
        filtriDettaglio.documentoId = idDocumentoSelezionato
    }

    void costruisciTipiAnomalieCausali(def incasso, def tipoTributo = [tutti: '(tutti)']) {

        tipiAnomalie = []
        causali = []

        switch (incasso) {
            case incassi[0]:
                // ANCI
                tipiAnomalie = TipoAnomalia.findAllByTipoBonifica('V').sort { it.tipoAnomalia }
                tipoAnomaliaSelezionata = tipiAnomalie[0]
                break
            default:
                causali = Causale.createCriteria().list() {
                    if (tipoTributo.key != 'tutti') {
                        eq('tipoTributo.tipoTributo', tipoTributo.key)
                    }
					else {
						def elencoTipiTributo = this.tipiTributo.collect { it. key }.findAll  { it != 'tutti' }
                        'in'('tipoTributo.tipoTributo', elencoTipiTributo)
					}

                    order('causale')
                    order('tipoTributo.tipoTributo')
                }.toDTO(['tipoTributo'])

                causaliSelezionate = []
                break
        }
    }

    void costruiscidDocumenti() {
        idDocumenti = []
        idDocumenti << '(tutti)'
        idDocumenti += WrkVersamenti.createCriteria().list() {
            projections {
                distinct("documentoId")
            }
            order('documentoId')
        }
        idDocumentoSelezionato = idDocumenti[0]
    }

    void costrusiciTributi() {
        // Tipi tributo
        tipiTributo << [tutti: '(tutti)']
        competenzeService.tipiTributoUtenza().each {
            tipiTributo << [(it.tipoTributo): it.tipoTributoAttuale + ' - ' + it.descrizione]
			if(competenzeService.utenteAbilitatoScrittura(it.tipoTributo)) {
				cbTributiInScrittura << [(it.tipoTributo): true]
			}
        }
        if (!anci) {
            tipoTributoSelezionato = tipiTributo.iterator().next()
        } else {
            tipoTributoSelezionato = tipiTributo.find { it.key == 'ICI' }
        }
    }

    String getCausaliSelezionateSel() {

        def causaliSel = ""

        causaliSelezionate.each { it ->
            if (!causaliSel.isEmpty()) {
                causaliSel += ", "
            }
            if (tipoTributoSelezionato.key == 'tutti') {
                causaliSel += """$it.causale - $it.tipoTributo.tipoTributoAttuale"""
            } else {
                causaliSel += it.causale
            }
        }

        return causaliSel
    }

    boolean getFiltriDettaglioAttivi() {
        boolean filtriAttivi = false

        filtriDettaglio.each {
            filtriAttivi |= (it.value != null && it.value && it.key != "documentoId")
            //Escludo il documentoId, altrimenti attiva il filtro se selezionato
        }

        return filtriAttivi

    }

    private void ricercaAnomalie() {
        listaAnomalie = bonificaVersamentiService.getAnomalie(incassoSelezionato,
                incassoSelezionato == 'ANCI' ? tipoAnomaliaSelezionata : causaliSelezionate.collect { c -> c.domainObject },
                annoSelezionato == '(tutti)' ? null : annoSelezionato,
                tipoTributoSelezionato.key == 'tutti' ? null : tipoTributoSelezionato.key,
                idDocumentoSelezionato == '(tutti)' ? null : idDocumentoSelezionato)
        numeroRigheAnomalie = calcolaNumeroDiRighe()
    }

    private def calcolaNumeroDiRighe() {
        def numRows = 0
        if (visualizzaAnomalieNonSelezionate && listaAnomalie.findAll { it.visible }.size() > MAX_NUM_RIGHE_ANOMALIE) {
            numRows = MAX_NUM_RIGHE_ANOMALIE
        }

        return numRows
    }

    private resetOrdinamento() {
        sortDettagliBy = null
        // Si resetta l'eventuale ordinamento impostato
        dettagliAnomalieListBox.listhead.children.each {
            ((Listheader) it).sortDirection = 'natural'
        }
    }

    private void resetView() {
        listaAnomalie = null
        anomaliaSelezionata = null
        visualizzaAnomalieNonSelezionate = true
        numeroRigheAnomalie = calcolaNumeroDiRighe()
        selezionaTutteAnomalie = false
        listaDettaglioAnomalie = [:]
        inizializzaFiltriDettaglio()

        BindUtils.postNotifyChange(null, null, this, "listaAnomalie")
        BindUtils.postNotifyChange(null, null, this, "anomaliaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "visualizzaAnomalieNonSelezionate")
        BindUtils.postNotifyChange(null, null, this, "numeroRigheAnomalie")
        BindUtils.postNotifyChange(null, null, this, "selezionaTutteAnomalie")
        BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomalie")
        BindUtils.postNotifyChange(null, null, this, "filtriDettaglio")
    }

    private def inizializzaFiltriDettaglio() {

        filtriDettaglio = [
                soloSoggetti    : false,
                codiceFiscale   : null,
                importoVersatoDa: null,
                importoVersatoA : null,
                dataPagamentoDa : null,
                dataPagamentoA  : null,
                documentoId     : null
        ]
    }

}
