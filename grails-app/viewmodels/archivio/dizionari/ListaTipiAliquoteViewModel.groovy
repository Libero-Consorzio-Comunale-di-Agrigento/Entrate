package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.TipoAliquotaDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaTipiAliquoteViewModel extends TabListaGenericaTributoViewModel {

    AliquoteService aliquoteService
    OggettiCacheMap oggettiCacheMap

    List<TipoAliquotaDTO> listaTipiAliquota
    TipoAliquotaDTO tipoAliquotaSelezionato
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
        listaTipiAliquota = null
        if (tipoTributoSelezionato.tipoTributo in ['ICI', 'TASI'])
            listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll {
                (it.tipoTributo.tipoTributo == tipoTributoSelezionato.tipoTributo &&
                        (filtro.da ? it.tipoAliquota >= filtro.da : true) &&
                        (filtro.a ? it.tipoAliquota <= filtro.a : true) &&
                        (filtro.descrizione ? isDescrizioneMatchingFiltroDescrizione(it.descrizione) : true))
            }

        BindUtils.postNotifyChange(null, null, this, "listaTipiAliquota")
        tipoAliquotaSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "tipoAliquotaSelezionato")
    }

    private boolean isDescrizioneMatchingFiltroDescrizione(String descrizione) {
        String descrizioneFilter = filtro.descrizione.toLowerCase().replaceAll(/\%/, '.*')
        return descrizione.toLowerCase().matches(descrizioneFilter)
    }

    @Command
    onAggiungiTipoAliquota() {
        aggiungiTipoAliquota(null, false)
    }

    @Command
    onDuplicaTipoAliquota() {

        TipoAliquotaDTO tipoAliquotaDTO = commonService.clona(tipoAliquotaSelezionato)

        aggiungiTipoAliquota(tipoAliquotaDTO, false)
    }

    @Command
    onModificaTipoAliquota() {

        commonService.creaPopup("/archivio/dizionari/tipoAliquota.zul", self,
                [
                        tipoTributo : tipoTributoSelezionato,
                        tipoAliquota: commonService.clona(tipoAliquotaSelezionato),
                        modifica    : true,
                        lettura     : lettura
                ],
                { event ->
                    if (event.data) {
                        if (!event.data.chiudi) {
                            oggettiCacheMap.refresh(OggettiCache.TIPI_ALIQUOTA)
                            oggettiCacheMap.refresh(OggettiCache.ALIQUOTE)
                            onRefresh()
                        }
                    }
                }
        )
    }

    @Command
    onEliminaTipoAliquota() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        aliquoteService.cancellaTipoAliquota(tipoAliquotaSelezionato)
                        oggettiCacheMap.refresh(OggettiCache.TIPI_ALIQUOTA)
                        oggettiCacheMap.refresh(OggettiCache.ALIQUOTE)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })

    }

    @Command
    onExportXlsTipoAliquote() {

        Map fields = [
                "tipoAliquota": "Tipo Aliquota",
                "descrizione" : "Descrizione"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.TIPO_ALIQUOTA,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaTipiAliquota, fields)
    }

    private void aggiungiTipoAliquota(TipoAliquotaDTO tipoAliquotaDTO, boolean modifica) {

        commonService.creaPopup("/archivio/dizionari/tipoAliquota.zul", self,
                [
                        tipoTributo : tipoTributoSelezionato,
                        tipoAliquota: tipoAliquotaDTO,
                        modifica    : modifica,
                        lettura     : lettura
                ],
                { event ->
                    if (event.data) {
                        if (!event.data.chiudi) {
                            oggettiCacheMap.refresh(OggettiCache.TIPI_ALIQUOTA)
                            onRefresh()
                        }
                    }
                }
        )
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaTipiAliquoteRicerca.zul", self, [filtro: filtro], { event ->
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
