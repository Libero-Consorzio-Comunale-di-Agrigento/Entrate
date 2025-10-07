package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.DetrazioneDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.DetrazioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaDetrazioniViewModel extends TabListaGenericaTributoViewModel {

    DetrazioniService detrazioniService

    List<DetrazioneDTO> listaDetrazioni = []
    DetrazioneDTO detrazioneSelezionata
    def labels

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
    void onRefresh() {
        listaDetrazioni = detrazioniService.getDetrazioni([
                tipoTributo         : tipoTributoSelezionato.tipoTributo,
                daAnno              : filtro?.daAnno,
                aAnno               : filtro?.aAnno,
                daDetrazione        : filtro?.daDetrazione,
                aDetrazione         : filtro?.aDetrazione,
                daDetrazioneBase    : filtro?.daDetrazioneBase,
                aDetrazioneBase     : filtro?.aDetrazioneBase,
                aDetrazioneFiglio   : filtro?.aDetrazioneFiglio,
                daDetrazioneFiglio  : filtro?.daDetrazioneFiglio,
                aDetrazioneMaxFigli : filtro?.aDetrazioneMaxFigli,
                daDetrazioneMaxFigli: filtro?.daDetrazioneMaxFigli,
                flagPertinenze      : filtro?.flagPertinenze == 'Con' ? true : (filtro?.flagPertinenze == 'Senza' ? false : null)
        ]).sort { -it.anno }

        BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")

        detrazioneSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
    }

    @Command
    onAggiungiDetrazione() {

        commonService.creaPopup("/archivio/dizionari/nuovaDetrazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        detrazione : null,
                        modifica   : false,
                        lettura    : lettura
                ],
                { event -> onRefresh() }
        )
    }

    @Command
    onModificaDetrazione() {

        commonService.creaPopup("/archivio/dizionari/nuovaDetrazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        detrazione : detrazioneSelezionata,
                        modifica   : true,
                        lettura    : lettura
                ],
                { event -> onRefresh() }
        )
    }

    @Command
    onDuplicaDetrazione() {

        DetrazioneDTO detrazioneDTO = new DetrazioneDTO()
        detrazioneDTO.anno = detrazioneSelezionata.anno
        detrazioneDTO.detrazione = detrazioneSelezionata.detrazione
        detrazioneDTO.detrazioneBase = detrazioneSelezionata.detrazioneBase
        detrazioneDTO.detrazioneFiglio = detrazioneSelezionata.detrazioneFiglio
        detrazioneDTO.detrazioneMaxFigli = detrazioneSelezionata.detrazioneMaxFigli
        detrazioneDTO.flagPertinenze = detrazioneSelezionata.flagPertinenze

        commonService.creaPopup("/archivio/dizionari/nuovaDetrazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        detrazione : detrazioneDTO,
                        modifica   : false,
                        lettura    : lettura
                ],
                { event -> onRefresh() }
        )
    }

    @Command
    onEliminaDetrazione() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        detrazioniService.cancellaDetrazione(detrazioneSelezionata)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    onExportXlsDetrazioni() {

        Map fields = [
                "anno"              : "Anno",
                "detrazioneBase"    : "Detrazione Base",
                "detrazione"        : "Detrazione",
                "detrazioneFiglio"  : "Detrazione Figlio",
                "detrazioneMaxFigli": "Detrazione Max Figli",
                "flagPertinenze"    : "Pertinenze"
        ]

        def formatters = ["flagPertinenze": Converters.flagString]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DETRAZIONI,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaDetrazioni, fields, formatters)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaDetrazioniRicerca.zul", self, [filtro: filtro], { event ->
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
