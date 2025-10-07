package pratiche.denunce

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.denunce.ComponentiConsistenzaService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class ComponentiConsistenzaViewModel {

    // Componenti
    Window self

    // Services
    CommonService commonService
    ComponentiConsistenzaService componentiConsistenzaService


    // Comuni
    def listaDati = []
    def datoSelezionato
    def ordinamentoSelezionato
    def filtroAttivo = false
    def filtri = [
            situazioneAl : new Date(),
            componentiDa : null,
            componentiA  : null,
            consistenzaDa: null,
            consistenzaA : null,
            flagAp       : true
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
        this.ordinamentoSelezionato = "Alfabetico"
        onRicerca()
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCheckOrdinamento() {
        caricaDati()
    }

    @Command
    def onExportXls() {

        Map fields = [
                "cognomeNome"     : "Contribuente",
                "codFiscale"      : "Cod. Fiscale",
                "componenti"      : "Componenti",
                "consistenza"     : "Consistenza",
                "tributo"         : "Tributo",
                "categoria"       : "Categoria",
                "tipoTariffa"     : "Tariffa",
                "pratica"         : "Pratica",
                "flagAbPrincipale": "Ab.Princ."
        ]


        def formatters = [
                "flagAbPrincipale": Converters.flagString,
                "componenti"      : Converters.decimalToInteger,
                "tributo"         : Converters.decimalToInteger,
                "categoria"       : Converters.decimalToInteger,
                "tipoTariffa"     : Converters.decimalToInteger,
                "pratica"         : Converters.decimalToInteger,
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPONENTI_CONSISTENZA,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaDati, fields, formatters)
    }

    @Command
    def onRicerca() {
        commonService.creaPopup("/pratiche/denunce/componentiConsistenzaRicerca.zul", self,
                [
                        filtri: filtri
                ], { e ->
            if (e.data?.filtriAggiornati) {
                filtri = e.data.filtriAggiornati
                caricaDati()
            }
        })
    }

    private def caricaDati() {

        datoSelezionato = null

        listaDati = componentiConsistenzaService.getListaDati(filtri, ordinamentoSelezionato)

        BindUtils.postNotifyChange(null, null, this, "datoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaDati")

        controllaFiltroAttivo()
    }

    private def controllaFiltroAttivo() {
        filtroAttivo = (!isSameDay(filtri.situazioneAl, new Date())) ||
                (filtri.componentiDa != null) ||
                (filtri.componentiA != null) ||
                (filtri.consistenzaDa != null) ||
                (filtri.consistenzaA != null) ||
                (!filtri.flagAp)

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private def isSameDay(Date data1, Date data2) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")
        return sdf.format(data1).equals(sdf.format(data2))
    }

}
