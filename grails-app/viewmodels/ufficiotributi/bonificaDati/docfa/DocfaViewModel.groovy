package ufficiotributi.bonificaDati.docfa

import document.FileNameGenerator
import it.finmatica.tr4.bonificaDati.docfa.BonificaDocfaService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DocfaViewModel {

    Window self

    CommonService commonService
    CompetenzeService competenzeService
    BonificaDocfaService bonificaDocfaService

    // filtro
    boolean filtroAttivoDetails = false

    def filtro = [:]

    def elencoDocfa = []
    def listaDocfa
    def anomaliaSelezionata
    int activePageDocfa = 0
    int pageSizeDocfa = 30
    def lunghezzaMassimaNote = 4

    // Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    def sortDocfaBy = null
	
	boolean modifica = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
		
        this.self = w
		
		modifica = ((competenzeService.tipoAbilitazioneUtente('ICI') == 'A') ||
					(competenzeService.tipoAbilitazioneUtente('TASI') == 'A'))

        caricaDocfa(true)
    }

    @Command
    def onMostraNota(@BindingParam("nota") def nota,
                     @BindingParam("titolo") def titolo) {

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/docfa/docfaNota.zul",
                self,
                [
                        titolo   : titolo,
                        nota     : nota
                ])
        w.doModal()
    }

    @Command
    openFiltriDetails() {
        commonService.creaPopup("/ufficiotributi/bonificaDati/docfa/ricercaDocfa.zul",
                self,
                [parRicerca: filtro],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtro = event.data.docDaCercare
                            aggiornaFiltroAttivo()
                            caricaDocfa(true)
                        }
                    }

                    BindUtils.postNotifyChange(null, null, this, "filtroAttivoDetails")
                }
        )
    }

    @Command
    def onPaging() {
        caricaDocfa(false)
    }

    @Command
    onDocfaSort(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("property") String property) {
        sortDocfaBy = [property: property, direction: event.ascending ? 'asc' : 'desc']
        caricaDocfa(true)
    }

    @Command
    onEliminaAnomalia(@BindingParam("docfa") def docfa) {

        docfa = docfa ?: anomaliaSelezionata

        String messaggio = "Eliminazione della registrazione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.CANCEL | Messagebox.YES, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            docfa.getDomainObject().delete(failOnError: true, flush: true)
                            caricaDocfa(true)
                            Clients.showNotification("Docfa eliminato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                                    null, "middle_center", 3000, true)
                        }
                    }
                })
    }

    @Command
    def onCorreggiAnomalia(@BindingParam("docfa") def docfa) {

        docfa = docfa ?: anomaliaSelezionata

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/docfa/bonificaDocfa.zul",
                self,
                [
						docfa : docfa,
						modifica : modifica
				]
		)
        w.onClose { event ->
        }
        w.doModal()
    }

    @Command
    def onDocfaToXls() {

        def fields = [
                'documentoId'        : 'Documento',
                'cognomeDic'         : 'Cognome Dichiarante',
                'nomeDic'            : 'Nome Dichiarante',
                'causale.descrizione': 'Causale',
                'note1'              : 'Note 1',
                'note2'              : 'Note 2',
                'note3'              : 'Note 3',
                'note4'              : 'Note 4',
                'note5'              : 'Note 5',
                'comuneDic'          : 'Comune Dichiarante',
                'provinciaDic'       : 'Pr',
                'indirizzoDic'       : 'Indirizzo Dichiarante',
                'civicoDic'          : 'Civico',
                'capDic'             : 'CAP',
                'cognomeTec'         : 'Cognome Tecnico',
                'nomeTec'            : 'Nome Tecnico',
                'codFiscaleTec'      : 'Cod.Fis. Tecnico',
                'alboTec'            : 'Albo',
                'numIscrizioneTec'   : 'N.Iscr.',
                'provIscrizioneTec'  : 'Prov.Iscr.',
                'unitaDestOrd'       : 'Unità Dest.Ord.',
                'unitaDestSpec'      : 'Unità Dest.Spec',
                'unitaNonCensite'    : 'Unità Non Cens.',
                'unitaSoppresse'     : 'Unità Soppresse',
                'unitaVariate'       : 'Unità Variate',
                'unitaCostituite'    : 'Unità Costriuite'
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ANOMALIE_DOCFA,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, elencoDocfa as List, fields)
    }

    private void caricaDocfa(boolean resetPaginazione, boolean restorePagina = false) {

        if ((elencoDocfa.size() == 0) || (resetPaginazione != false)) {

            def activePageOld = pagingList.activePage

            pagingList.activePage = 0
            elencoDocfa = bonificaDocfaService.getAnomalie(sortDocfaBy, filtro)
            pagingList.totalSize = elencoDocfa.size()

            if (restorePagina != false) {
                if (activePageOld < ((pagingList.totalSize / pagingList.pageSize) + 1)) {
                    pagingList.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        listaDocfa = elencoDocfa.subList(fromIndex, toIndex)

        anomaliaSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "anomaliaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaDocfa")
    }

    private void aggiornaFiltroAttivo() {
        filtroAttivoDetails = filtro.documento != null
    }
}
