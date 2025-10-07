package ufficiotributi.bonificaDati.nonDichiarati


import document.FileNameGenerator
import it.finmatica.tr4.bonificaDati.nonDichiarati.BonificaNonDichiaratiService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class NonDichiaratiRenditaViewModel {

    Window self

    BonificaNonDichiaratiService bonificaNonDichiaratiService

    def listaStatus = [
            [status: 0, descrizione: "-"],
            [status: 1, descrizione: "Avvertimento"],
            [status: 2, descrizione: "Problema"],
            [status: 3, descrizione: "Errore"],
            [status: 9, descrizione: "Fatto"]
    ]

    boolean datiSoggetti = true

    def immobiliTotale = 0
    def immobiliLista = 0
    def listaImmobiliTotale
    def listaImmobili

    def immobileSelezionato

    def pagingImmobili = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    def cessatiDopo = new Date('01/01/1990')
    def seCessati = true
    def sovrascriviIntersecati = false

    def immobiliDaProcessare = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("totale") def totale,
         @ExecutionArgParam("immobili") def immobili,
         @ExecutionArgParam("datiSoggetti") def datiSoggetti) {

        this.self = w

        this.datiSoggetti = (datiSoggetti != null) ? datiSoggetti : true

        this.listaImmobiliTotale = immobili
        this.immobiliTotale = totale
        this.immobiliLista = immobili.findAll { it.idOggetto != null }.size()

        verificaImmobiliDaProcessare()
        onRefreshImmobili()
    }

    @Command
    def onSelezionaImmobile() {

    }

    @Command
    def onRefreshImmobili() {

        listaImmobiliTotale = listaImmobiliTotale.sort { i1, i2 -> i1.status <=> i2.status ?: i1.codFiscale <=> i2.codFiscale ?: i1.estremiCatasto <=> i2.estremiCatasto }

        pagingImmobili.activePage = 0
        pagingImmobili.totalSize = this.listaImmobiliTotale.size()
        BindUtils.postNotifyChange(null, null, this, "pagingImmobili")

        onPagingImmobili()
    }

    @Command
    def onPagingImmobili() {

        def toTake = pagingImmobili.pageSize
        def toDrop = toTake * pagingImmobili.activePage
        this.listaImmobili = this.listaImmobiliTotale.drop(toDrop).take(toTake)

        this.listaImmobili.each {

            def status = it.status
            it.statusDescr = listaStatus.find { it.status == status }?.descrizione
        }

        BindUtils.postNotifyChange(null, null, this, "listaImmobili")
    }

    @Command
    def onProcedi() {

        impostaRenditaImmobili()
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    listToXls(@BindingParam("totale") int totale) throws Exception {

        Map fields = [
                "idImmobile"   : "Immobile",
                "idOggetto"    : "Oggetto",
                "tipoImmobile" : "Tipo",
                "codFiscale"   : "Cod.Fis.",
                "dirittoEsteso": "Possesso",
                "sezione"      : "Sez.",
                "foglio"       : "Fgl.",
                "numero"       : "Num.",
                "subalterno"   : "Sub.",
                "categoria"    : "Ctg.",
                "classe"       : "Classe",
                "statusDescr"  : "Stato",
                "message"      : "Messaggio"
        ]


        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.OGGETTI_IMPOSTA_RENDITA,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaImmobiliTotale, fields)
    }

    private impostaRenditaImmobili() {

        def sovrascriviSeStatus1 = this.sovrascriviIntersecati

        bonificaNonDichiaratiService.impostaRenditaImmobili(this.listaImmobiliTotale, cessatiDopo, seCessati, sovrascriviSeStatus1)

        onRefreshImmobili()

        verificaImmobiliDaProcessare()

        if (immobiliDaProcessare != false) {

            Messagebox.show("Operazione eseguita, tuttavia non e' stato possibile processare tutti gli immobili.\n\n" +
                    "Controllare le colonne 'Stato' e 'Messaggio' per ulteriori informazioni.",
                    "Inserimento Oggetto/Rendite", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {

            Messagebox.show("Oggetto/Rendite inseriti", "Inserimento Oggetto/Rendite", Messagebox.OK, Messagebox.INFORMATION)
        }
    }

    private verificaImmobiliDaProcessare() {

        def daProcessare = 0

        this.listaImmobiliTotale.each {

            if ((it.status == 0) || (it.status == 1)) daProcessare++
        }

        immobiliDaProcessare = (daProcessare > 0) ? true : false

        BindUtils.postNotifyChange(null, null, this, "immobiliDaProcessare")
    }
}
