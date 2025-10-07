package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.RuoliAutomaticiDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.apache.log4j.Logger
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class RuoliAutomaticiViewModel extends TabListaGenericaTributoViewModel{

    private static final Logger log = Logger.getLogger(RuoliAutomaticiViewModel.class)

    Window self

    // Service
    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Modello
    def listaRuoliAutomatici = []
    def ruoloAutomaticoSelezionato
    def listaRuoli
    def filtroAttivo = false
    def filtri = [:]

    def tipoEmissione = [
            A: "Acconto",
            S: "Saldo",
            T: "Totale",
            X: ''
    ]

    def tipoRuolo = [
            1: 'P - Principale',
            2: 'S - Suppletivo'
    ]

	Boolean abilitaNuovo = false
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        abilitaNuovo = (competenzeService.tipoAbilitazioneUtente('TARSU') == CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        caricaDati()
    }
	
	@Command
	def onSelezioneRuolo() {
		
		aggiornaCompetenze()
	}

    @Command
    def onNuovo() {
        visualizzaModifica(new RuoliAutomaticiDTO([tipoTributo: OggettiCache.TIPI_TRIBUTO.valore.find {
            it.tipoTributo == 'TARSU'
        }]))
    }

    @Command
    def onModifica() {
        visualizzaModifica(ruoloAutomaticoSelezionato)
    }

    @Command
    def onDuplica() {
		
        def raDup = new RuoliAutomaticiDTO()
        InvokerHelper.setProperties(raDup, ruoloAutomaticoSelezionato.properties)
        raDup.ruolo = Ruolo.get(raDup.ruolo.id).toDTO()
        raDup.id = null
        visualizzaModifica(raDup)
    }

    @Command
    def onCancella() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        ruoloAutomaticoSelezionato.toDomain().delete(flush: true)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        caricaDati()
                    }
                })
    }

    @Command
    def openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/ruoliAutomaticRicerca.zul", self, [filtri: filtri.clone()], { event ->
            if (event.data?.filtri) {
                this.filtri = event.data.filtri
            }
            caricaDati(filtri)
        })
    }

    @Command
    def onRuoliAutomaticiToXls() {

        Map fields

        fields = [
                "daData"              : "Da",
                "aData"               : "A",
                "ruolo.tipoRuolo"     : "Tipo Ruolo",
                "ruolo.annoRuolo"     : "Anno Ruolo",
                "ruolo.annoEmissione" : "Anno Emissione",
                "ruolo.progrEmissione": "Progr. Emissione",
                "ruolo.dataEmissione" : "Emissione",
                "ruolo.tipoEmissione" : "Tipo Emissione",
                "ruolo.id"            : "Ruolo",
                "note"                : "Note"
        ]

        def tipiEmissione = [
                A: 'Acconto',
                S: 'Saldo',
                T: 'Totale',
                X: ''
        ]

        def converters = [
                "ruolo.tipoRuolo"    : { tr -> tr == 1 ? 'P - Principale' : "S - Suppletivo" },
                "ruolo.tipoEmissione": { te -> tipiEmissione[te] }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.RUOLI_AUTOMATICI,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaRuoliAutomatici, fields, converters)
    }

    private caricaDati(def filtri = [:]) {

        filtroAttivo = !filtri?.findAll { it.value != null }?.isEmpty()

        listaRuoliAutomatici = listeDiCaricoRuoliService.elencoRuoliAutomatici(filtri)
        ruoloAutomaticoSelezionato = null
		
		aggiornaCompetenze()

        BindUtils.postNotifyChange(null, null, this, "listaRuoliAutomatici")
        BindUtils.postNotifyChange(null, null, this, "ruoloAutomaticoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private visualizzaModifica(RuoliAutomaticiDTO dto) {
        commonService.creaPopup("archivio/dizionari/dettaglioRuoloAutomatico.zul",
                self,
                [ruoloAutomatico: dto], { e ->
            caricaDati()
        })
    }
}
