package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Tab
import org.zkoss.zul.Window

class EmissioneRuoloErroriViewModel {

    Window self

    @Wire('#tabTariffe')
    Tab tabTariffe

    //Comuni
    def parametriCalcolo
    def errori
    def tariffeMancanti
    def ruolo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parametriCalcolo") def pc,
         @ExecutionArgParam("errori") def err,
         @ExecutionArgParam("tariffeMancanti") def tm,
         @ExecutionArgParam("ruolo") def rl) {

        this.self = w

        this.parametriCalcolo = pc
        this.errori = err
        this.tariffeMancanti = tm
        this.ruolo = rl
    }

    @AfterCompose
    void postInit() {
        //Nel caso ci siano solamente tariffe, imposto come tab selezionata quella relativa
        if (errori.isEmpty() && !tariffeMancanti.isEmpty()) {
            tabTariffe.selected = true
        }
    }

    @Command
    def onExportErroriXls() {

        def fields = [
                "ruolo.id"   : "Ruolo",
                "tipoRuolo"  : "T.Ruolo",
                "anno"       : "Anno",
                "annoEm"     : "Anno Em.",
                "prEm"       : "Pr.",
                "dataEm"     : "Emissione",
                "invio"      : "Invio",
                "ni"         : "N.Ind.",
                "cognomeNome": "Cognome e Nome",
                "codFiscale" : "Cod.Fiscale",
                "tributo"    : "Tributo",
                "categoria"  : "Cat.",
                "descrizione": "Messaggio"
        ]

        def converters = [
                tipoRuolo: { value -> value.tipoRuolo == 1 ? "Principale" : "Suppletivo" }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.SEGNALAZIONI_BLOCCANTI,
                [idRuolo: ruolo.id])

        XlsxExporter.exportAndDownload(nomeFile, errori, fields, converters)
    }

    @Command
    def onExportTariffeMancantiXls() {

        def fields = [
                "RUOLO"        : "Ruolo",
                "TRUOLO"       : "T.Ruolo",
                "ANNO"         : "Anno",
                "ANNOEMISSIONE": "Anno Em.",
                "PREMISSIONE"  : "Pr.",
                "DATAEMISSIONE": "Emissione",
                "INVIO"        : "Invio",
                "TRIBUTO"      : "Tributo",
                "CATEGORIA"    : "Categoria",
                "TIPO_TARIFFA" : "Tipo Tariffa"
        ]

        //Aggiungo campi relativi al ruolo
        tariffeMancanti.each {
            it.RUOLO = ruolo.id
            it.TRUOLO = ruolo.tipoRuolo == 1 ? "Principale" : "Suppletivo"
            it.ANNOEMISSIONE = ruolo.annoEmissione
            it.PREMISSIONE = ruolo.progrEmissione
            it.DATAEMISSIONE = ruolo.dataEmissione
            it.INVIO = ruolo.invioConsorzio
        }

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.TARIFFE_MANCANTI,
                [idRuolo: ruolo.id])

        XlsxExporter.exportAndDownload(nomeFile, tariffeMancanti, fields)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


}
