package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class EmissioneRuoloViewModel {

    Window self

    ImposteService imposteService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    IntegrazioneDePagService integrazioneDePagService
    CommonService commonService

    RuoloDTO ruolo
    String codFiscale
    def lettura

    def parametriCalcolo = [:]

    def decorrenzaCessazione = []
    def familiari = []
    def nonResidentiAbPri = []

    def errori = []
    def tariffeMancanti = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") def dr,
         @ExecutionArgParam("contribuente") def ct,
         @ExecutionArgParam("lettura") def lt) {

        this.self = w

        lettura = lt || (dr.codFiscale != '%')

        ruolo = Ruolo.get(dr.ruolo).toDTO()
        codFiscale = dr.codFiscale

        parametriCalcolo = imposteService.inizializzaParametriCalcoloEmissioneRuolo(ruolo, dr.codFiscale)

        def cfSingolo = false

        if (!codFiscale.contains('%')) {
            cfSingolo = true
        }

        //Pre-caricamento liste
        decorrenzaCessazione = decorrenzaCessazione ?:
                (cfSingolo ? imposteService.decorrenzaCessazione(ruolo, codFiscale) : imposteService.decorrenzaCessazione(ruolo))
        familiari = familiari ?:
                (cfSingolo ? imposteService.familiari(ruolo, codFiscale) : imposteService.familiari(ruolo))
        nonResidentiAbPri = nonResidentiAbPri ?:
                (cfSingolo ? imposteService.contribuentiNonResidentiConAbitazionePrincipale(ruolo, codFiscale) : imposteService.contribuentiNonResidentiConAbitazionePrincipale(ruolo))

    }

    @Command
    def onTipoCalcolo() {

        if (parametriCalcolo.tipoCalcolo == 'T') {
            parametriCalcolo.flagTariffeRuolo = false
            BindUtils.postNotifyChange(null, null, this, "parametriCalcolo")
        }
    }

    @Command
    def onTariffeRuolo() {

        if (parametriCalcolo.flagTariffeRuolo) {
            parametriCalcolo.flagCalcoloTariffaBase = true
            BindUtils.postNotifyChange(null, null, this, "parametriCalcolo")
        }
    }

    @Command
    onTipoEmissione() {

        if (parametriCalcolo.tipoEmissione != 'A') {
            parametriCalcolo.percAcconto = null
            BindUtils.postNotifyChange(null, null, this, "parametriCalcolo")
        }
    }

    @Command
    onRicalcolo() {
        parametriCalcolo.ricalcoloDal = null
        parametriCalcolo.ricalcoloAl = null
        BindUtils.postNotifyChange(null, null, this, "parametriCalcolo")
    }

    @Command
    onElaboraRuolo() {

        if (parametriCalcolo.ricalcolo && parametriCalcolo.ricalcoloDal > parametriCalcolo.ricalcoloAl) {
            Clients.showNotification("'Ricalcolo dal' deve essere maggiore o uguale a 'Ricalcola al'."
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return
        }

        errori = imposteService.contribuentiUtenzeDomesticheIncoerenti(ruolo.annoRuolo, ruolo.id, codFiscale)
        tariffeMancanti = imposteService.tariffeMancanti(parametriCalcolo)

        if (errori || tariffeMancanti) {

            Clients.showNotification("Sono presenti Segnalazioni Bloccanti e/o Tariffe Mancanti"
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)

            commonService.creaPopup(
                    "sportello/contribuenti/emissioneRuoloErrori.zul",
                    self,
                    [
                            parametriCalcolo: parametriCalcolo,
                            errori          : errori,
                            tariffeMancanti : tariffeMancanti,
                            ruolo           : ruolo
                    ], {})

        } else {

            imposteService.emissioneRuolo(parametriCalcolo)

            if (integrazioneDePagService.dePagAbilitato() && !("%" in codFiscale)) {
                def message = integrazioneDePag()
                if (!message.empty) {
                    Clients.showNotification(message
                            , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
                }
            }

            Events.postEvent(Events.ON_CLOSE, self, [elaborato: true])
        }


    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


    @Command
    def onExportDecorrenzaCessazioneXls() {

        def fields = [
                "ruolo.id"      : "Ruolo",
                "tipoRuolo"     : "T.Ruolo",
                "annoRuolo"     : "Anno",
                "annoEmissione" : "Anno Em.",
                "progrEmissione": "Pr.",
                "dataEmissione" : "Emissione",
                "invioConsorzio": "Invio",
                "ni"            : "N.Ind.",
                "cognomeNome"   : "Cognome e Nome",
                "codFiscale"    : "Cod.Fiscale",
                "decorrenza"    : "decorrenza",
                "familiariDal"  : "Familiari Dal",
                "cessazione"    : "Cessazione",
                "familiariAl"   : "Familiari Al",
                "flagAbPri"     : "Ab.Principale"
        ]

        def converters = [
                tipoRuolo: { value -> value.tipoRuolo == 1 ? "Principale" : "Suppletivo" }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DECORRENZA_CESSAZIONE,
                [idRuolo: ruolo.id])

        XlsxExporter.exportAndDownload(nomeFile, decorrenzaCessazione, fields, converters)
    }

    @Command
    def onExportFamiliariXls() {

        def fields = [
                "ruolo.id"      : "Ruolo",
                "tipoRuolo"     : "T.Ruolo",
                "annoRuolo"     : "Anno",
                "annoEmissione" : "Anno Em.",
                "progrEmissione": "Pr.",
                "dataEmissione" : "Emissione",
                "invioConsorzio": "Invio",
                "ni"            : "N.Ind.",
                "cognomeNome"   : "Cognome e Nome",
                "codFiscale"    : "Cod.Fiscale",
                "decorrenza"    : "decorrenza",
                "flagAbPri"     : "Ab.Principale"
        ]

        def converters = [
                tipoRuolo: { value -> value.tipoRuolo == 1 ? "Principale" : "Suppletivo" }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.FAMILIARI,
                [idRuolo: ruolo.id])

        XlsxExporter.exportAndDownload(nomeFile, familiari, fields, converters)
    }

    @Command
    def onExportNonResidentiAbPriXls() {


        def fields = [
                "ruolo.id"       : "Ruolo",
                "tipoRuolo"      : "T.Ruolo",
                "annoRuolo"      : "Anno",
                "annoEmissione"  : "Anno Em.",
                "progrEmissione" : "Pr.",
                "dataEmissione"  : "Emissione",
                "invioConsorzio" : "Invio",
                "ni"             : "N.Ind.",
                "cognomeNome"    : "Cognome e Nome",
                "codFiscale"     : "Cod.Fiscale",
                "decorrenza"     : "decorrenza",
                "cessazione"     : "Cessazione",
                "familiariDal"   : "Familiari Dal",
                "familiariAl"    : "Familiari Al",
                "numeroFamiliari": "Nr.Familiari"
        ]

        def converters = [
                tipoRuolo: { value -> value.tipoRuolo == 1 ? "Principale" : "Suppletivo" }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.FAMILIARI,
                [idRuolo: ruolo.id])

        XlsxExporter.exportAndDownload(nomeFile, nonResidentiAbPri, fields, converters)
    }


    private def integrazioneDePag() {
        return integrazioneDePagService.aggiornaDovutoRuolo(
                codFiscale,
                ruolo.id
        )
    }
}
