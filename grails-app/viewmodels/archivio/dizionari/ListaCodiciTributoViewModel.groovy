package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCodiciTributoViewModel extends TabListaGenericaTributoViewModel {

    CanoneUnicoService canoneUnicoService

    boolean modifica = false
    def labels

    // Tab panel
    def selectedTab = null

    // Interfaccia
    def filtriList = [
            descrizione: ''
    ]
    boolean filtroAttivoList = false

    // Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Codici Tributo
    def elencoCodiciTributo = []
    def listaCodiciTributo = []
    def codiceTributoSelezionato = null

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    def onCaricaPrimoTab() {

    }

    @Command
    def onSelectTabs() {

    }

    @Command
    void onRefresh() {

        modifica = (competenzeService.tipoAbilitazioneUtente(tipoTributoSelezionato.tipoTributo) ?: '') == 'A'
        BindUtils.postNotifyChange(null, null, this, "modifica")

        caricaListaCodiciTributo()

        self.invalidate()
    }

    @Command
    def onCodiceTributoSelected() {

    }

    @Command
    def onModificaCodiceTributo() {

        modificaCodiceTributo(codiceTributoSelezionato.dto, modifica)
    }

    @Command
    def onEliminaCodiceTributo() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        canoneUnicoService.eliminaCodiceTributo(codiceTributoSelezionato.dto.toDomain())

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })

    }

    @Command
    def onCodiciTributoToXls() {

        Map fields
        def converters = [
                "flagStampaCc"        : Converters.flagBooleanToString,
                "flagCalcoloInteressi": Converters.flagBooleanToString,
                "flagRuolo"           : Converters.flagBooleanToString,
        ]

        def filtriNow = [ tipoTributo: tipoTributoSelezionato.tipoTributo, noCUNILegacy : true ]

        def lista = canoneUnicoService.getElencoCodiciTributo(filtriNow)

        if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
            fields = ["id"                  : "Codice",
                      "nome"                : "Nome",
                      "descrizione"         : "Descrizione",
                      "tipoTributo"         : "Tipo Precedente",
                      "contoCorrente"       : "Codice Gruppo Tributo",
                      "descrizioneCc"       : "Nome Gruppo Tributo",
                      "flagStampaCc"        : "Stampa C/C",
                      "flagRuolo"           : "Sospeso",
                      "flagCalcoloInteressi": "Calcolo Interessi",
                      "codEntrata"          : "Codice Entrata"]
        } else {
            fields = ["id"                  : "Codice",
                      "descrizione"         : "Descrizione",
                      "nome"                : "Descrizione Ruolo",
                      "contoCorrente"       : "Numero C/C",
                      "descrizioneCc"       : "Descrizione C/C",
                      "flagStampaCc"        : "Stampa C/C",
                      "flagRuolo"           : "A Ruolo",
                      "flagCalcoloInteressi": "Calcolo Interessi",
                      "codEntrata"          : "Codice Entrata"]
        }

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CODICI_TRIBUTO,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])


        XlsxExporter.exportAndDownload(nomeFile, lista, fields, converters)
    }

    @Command
    def onNuovoCodiceTributo() {

        modificaCodiceTributo(null, true)
    }

    // Verifica impostazioni filtro
    def aggiornaFiltroAttivoList() {

        filtroAttivoList = (filtriList.descrizione != '')

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoList")
    }

    // Apre finestra visualizza/modifica del codice tributo
    private def modificaCodiceTributo(CodiceTributoDTO codiceTributo, boolean modifica) {

        Window w = Executions.createComponents(
                "/archivio/dizionari/dettaglioCodiceTributo.zul",
                self,
                [
                        tipoTributo  : tipoTributoSelezionato.tipoTributo,
                        codiceTributo: codiceTributo,
                        modifica     : modifica && !lettura
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaCodiciTributo()
                }
            }
        }
        w.doModal()
    }

    // Rilegge elenco Codici Tributo
    private def caricaListaCodiciTributo() {

        def filtriNow = [
                tipoTributo         : tipoTributoSelezionato.tipoTributo,
                daCodice            : filtro.daCodice,
                aCodice             : filtro.aCodice,
                nome                : filtro.nome,
                descrizione         : filtro.descrizione,
                tributoPrecedente   : filtro.tributoPrecedente,
                contoCorrente       : filtro.contoCorrente,
                descrizioneCc       : filtro.descrizioneCc,
                flagStampaCc        : (filtro.flagStampaCc == 'Con') ? true : (filtro.flagStampaCc == 'Senza') ? false : null,
                flagRuolo           : (filtro.flagRuolo == 'Con') ? true : (filtro.flagRuolo == 'Senza') ? false : null,
                flagCalcoloInteressi: (filtro.flagCalcoloInteressi == 'Con') ? true : (filtro.flagCalcoloInteressi == 'Senza') ? false : null,
                codEntrata          : filtro.codEntrata,
                noCUNILegacy        : true
        ]

        listaCodiciTributo = canoneUnicoService.getElencoCodiciTributo(filtriNow)
        BindUtils.postNotifyChange(null, null, this, "listaCodiciTributo")

        codiceTributoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "codiceTributoSelezionato")
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCodiciTributoRicerca.zul", self, [filtro: filtro, tipoTributo: tipoTributoSelezionato.tipoTributo], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }
}
