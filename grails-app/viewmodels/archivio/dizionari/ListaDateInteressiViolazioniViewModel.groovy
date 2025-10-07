package archivio.dizionari

import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.interessiViolazioni.InteressiViolazioniService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.DateInteressiViolazioni
import it.finmatica.tr4.dto.DateInteressiViolazioniDTO
import it.finmatica.tr4.export.XlsxExporter
import org.apache.log4j.Logger
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window
import document.FileNameGenerator

class ListaDateInteressiViolazioniViewModel extends TabListaGenericaTributoViewModel{

    private static final Logger log = Logger.getLogger(ListaDateInteressiViolazioniViewModel.class)

    Window self

    // Service
    InteressiViolazioniService interessiViolazioniService

    // Modello
    List<DateInteressiViolazioniDTO> listaElementi = []
    DateInteressiViolazioniDTO elementoSelezionato

    def filtroAttivo = false
    def filtri = [:]

	Boolean abilitaNuovo = false
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        abilitaNuovo = (competenzeService.tipoAbilitazioneUtente(tipoTributo) == CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        caricaDati(filtri)
    }
	
	@Command
	def onSelezioneElemento() {
		
		aggiornaCompetenze()
	}

    @Command
    def onNuovo() {
        visualizzaModifica(new DateInteressiViolazioniDTO([tipoTributo: OggettiCache.TIPI_TRIBUTO.valore.find {
            it.tipoTributo == 'TARSU'
        }]), false)
    }

    @Command
    def onModifica() {
        visualizzaModifica(elementoSelezionato, true)
    }

    @Command
    def onDuplica() {
		
        def raDup = new DateInteressiViolazioniDTO()
        InvokerHelper.setProperties(raDup, elementoSelezionato.properties)
        visualizzaModifica(raDup, false)
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
                        elementoSelezionato.toDomain().delete(flush: true)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        caricaDati(filtri)
                    }
                })
    }

    @Command
    def openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaDateInteressiViolazioniRicerca.zul", self, 
            [
                filtri: filtri.clone()
            ],
            { event ->
                if (event.data?.filtri) {
                    this.filtri = event.data.filtri
                }
                caricaDati(filtri)
            }
        )
    }

    @Command
    def onDateInteressiViolazioniToXls() {

        Map fields  = [
                "anno"           : "Anno",
                "dataAttoDa"     : "Data Atto Da",
                "dataAttoA"      : "Data Atto A",
                "dataInizio"     : "Data Inizio",
                "dataFine"       : "Data Fine",
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DATE_INTERESSI_VIOLAZIONI,
                [:]
        )

        XlsxExporter.exportAndDownload(nomeFile, listaElementi, fields)
    }

    private caricaDati(def filtri = [:]) {

        filtroAttivo = !filtri?.findAll { it.value != null }?.isEmpty()

        listaElementi = interessiViolazioniService.getListaDate(filtri)
        elementoSelezionato = null
		
		aggiornaCompetenze()

        BindUtils.postNotifyChange(null, null, this, "listaElementi")
        BindUtils.postNotifyChange(null, null, this, "elementoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private visualizzaModifica(DateInteressiViolazioniDTO dto, Boolean existing) {

        commonService.creaPopup("archivio/dizionari/dettaglioDateInteressiViolazioni.zul",
                self,
                [
                    date : dto,
                    existing : existing
                ],
                { e ->
                    caricaDati(filtri)
                }
        )
    }
}
