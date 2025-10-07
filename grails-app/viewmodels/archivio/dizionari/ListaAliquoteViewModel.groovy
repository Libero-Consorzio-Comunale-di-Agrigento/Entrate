package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.AliquotaCategoriaDTO
import it.finmatica.tr4.dto.AliquotaDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

class ListaAliquoteViewModel extends TabListaGenericaTributoViewModel {

    List<AliquotaDTO> listaAliquote
    AliquotaDTO aliquotaSelezionata

    def listaAliquoteCat
    def aliquotaCatSelezionata
    def popupNote

    AliquoteService aliquoteService
    OggettiCacheMap oggettiCacheMap

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    Properties labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {
        super.init(w, tipoTributo, null, tabIndex)

        onRefresh()

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {

        fetchAliquote()
        resetAliquota()
    }

    private boolean filterStringMatchesString(def filterString, def scannedString) {
        String expression = (filterString as String).toLowerCase().replaceAll(/%/, '.*')
        return (scannedString as String).toLowerCase().matches(expression)
    }

    @Command
    onRefreshAliquoteCat() {

        fetchAliquoteCategoria()
        resetAliquotaCategoria()
    }

    @Command
    onAggiungiAliquota() {
        aggiungiAliquota(null, false)
    }

    @Command
    onDuplicaAliquota() {

        AliquotaDTO aliquotaDTO = new AliquotaDTO()
        aliquotaDTO.anno = aliquotaSelezionata.anno
        aliquotaDTO.tipoAliquota = aliquotaSelezionata.tipoAliquota
        aliquotaDTO.flagAbPrincipale = aliquotaSelezionata.flagAbPrincipale
        aliquotaDTO.flagPertinenze = aliquotaSelezionata.flagPertinenze
        aliquotaDTO.aliquota = aliquotaSelezionata.aliquota
        aliquotaDTO.aliquotaErariale = aliquotaSelezionata.aliquotaErariale
        aliquotaDTO.aliquotaStd = aliquotaSelezionata.aliquotaStd
        aliquotaDTO.aliquotaBase = aliquotaSelezionata.aliquotaBase
        aliquotaDTO.percSaldo = aliquotaSelezionata.percSaldo
        aliquotaDTO.percOccupante = aliquotaSelezionata.percOccupante
        aliquotaDTO.flagRiduzione = aliquotaSelezionata.flagRiduzione
        aliquotaDTO.riduzioneImposta = aliquotaSelezionata.riduzioneImposta
        aliquotaDTO.note = aliquotaSelezionata.note
        aliquotaDTO.scadenzaMiniImu = aliquotaSelezionata.scadenzaMiniImu
        aliquotaDTO.flagFabbricatiMerce = aliquotaSelezionata.flagFabbricatiMerce
        aggiungiAliquota(aliquotaDTO, false)
    }

    @Command
    onModificaAliquota() {
        commonService.creaPopup("/archivio/dizionari/aliquota.zul",
                self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        aliquota: commonService.clona(aliquotaSelezionata),
                        modifica   : true,
                        lettura    : lettura
                ],
                { event ->
                    if (!event.data.chiudi) {
                        oggettiCacheMap.refresh(OggettiCache.ALIQUOTE)
                        onRefresh()
                    }
                })
    }

    @Command
    onEliminaAliquota() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        aliquoteService.cancellaAliquota(aliquotaSelezionata)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        oggettiCacheMap.refresh(OggettiCache.ALIQUOTE)
                        onRefresh()
                    }
                })
    }

    @Command
    onExportXlsAliquote() {
        Map fields = [anno                      : labels.get('dizionario.aliquota.label.estesa.anno'),
                      tipoAliquota              : labels.get('dizionario.aliquota.label.estesa.tipoAliquota'),
                      aliquota                  : labels.get('dizionario.aliquota.label.estesa.aliquota'),
                      aliquotaBase              : labels.get('dizionario.aliquota.label.estesa.aliquotaBase'),
                      aliquotaErariale          : labels.get('dizionario.aliquota.label.estesa.aliquotaErariale'),
                      aliquotePerCategoriaExport: labels.get('dizionario.aliquota.label.estesa.countAlca'),
                      flagAbPrincipale          : labels.get('dizionario.aliquota.label.estesa.flagAbPrincipale'),
                      flagPertinenze            : labels.get('dizionario.aliquota.label.estesa.flagPertinenze')]
        if (tipoTributoSelezionato.tipoTributo == 'ICI') {
            fields = [*                  : fields,
                      flagFabbricatiMerce: labels.get('dizionario.aliquota.label.estesa.flagFabbricatiMerce'),
                      aliquotaStd        : labels.get('dizionario.aliquota.label.estesa.aliquotaStd'),
                      percSaldo          : labels.get('dizionario.aliquota.label.estesa.percSaldo'),
                      scadenzaMiniImu    : labels.get('dizionario.aliquota.label.estesa.scadenzaMiniImu'),
                      flagRiduzione      : labels.get('dizionario.aliquota.label.estesa.flagRiduzione')]
        } else {
            fields = [*            : fields,
                      percOccupante: labels.get('dizionario.aliquota.label.estesa.percOccupante')]
        }
        fields = [*               : fields,
                  flagRiduzione   : labels.get('dizionario.aliquota.label.estesa.flagRiduzione'),
                  riduzioneImposta: labels.get('dizionario.aliquota.label.estesa.riduzioneImposta'),
                  note            : labels.get('dizionario.aliquota.label.estesa.note')]


        def formatters = [
                tipoAliquota                : { ta -> "${ta.tipoAliquota} - ${ta.descrizione}" },
                "flagAbPrincipale"          : Converters.flagString,
                "flagPertinenze"            : Converters.flagString,
                "flagFabbricatiMerce"       : Converters.flagString,
                "aliquotePerCategoriaExport": { o -> fCountAlca(o) ? 'S' : 'N' }]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ALIQUOTE,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaAliquote, fields, formatters)
    }

    @Command
    onExportXlsAliquoteCat() {

        Map fields = [
                "categoriaCatasto": "Categoria Catasto",
                "aliquota"        : "Aliquota",
                "aliquotaBase"    : "Aliquota Base",
                "note"            : "Note"
        ]


        def formatters = [
                tipoAliquota    : { ta -> "${aliquotaSelezionata.tipoAliquota.tipoAliquota} - ${aliquotaSelezionata.tipoAliquota.descrizione}" },
                categoriaCatasto: { cc -> "${cc.categoriaCatasto} - ${cc.descrizione}" },
                anno            : { anno -> aliquotaSelezionata.anno }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ALIQUOTE_ALIQUOTE_PER_CATEGORIA,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaAliquoteCat, fields, formatters)
    }

    @Command
    def onSelectAliquota() {
        onRefreshAliquoteCat()
    }

    @Command
    def onAggiungiAliquotaCat() {

        commonService.creaPopup("/archivio/dizionari/dettaglioAliquoteCategoria.zul", self,
                [
                        tipoTributo      : tipoTributoSelezionato.tipoTributo,
                        tipoAliquota     : aliquotaSelezionata.tipoAliquota,
                        anno             : aliquotaSelezionata.anno,
                        aliquotaCategoria: null,
                        modifica         : false
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.ricarica) {
                            refreshSenzaResetAliquota()
                        }
                    }
                })

    }

    @Command
    def onModificaAliquotaCat() {

        commonService.creaPopup("/archivio/dizionari/dettaglioAliquoteCategoria.zul", self,
                [
                        tipoTributo      : tipoTributoSelezionato.tipoTributo,
                        tipoAliquota     : aliquotaSelezionata.tipoAliquota,
                        anno             : aliquotaSelezionata.anno,
                        modifica         : true,
                        aliquotaCategoria: aliquotaCatSelezionata,
                        lettura          : lettura
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.ricarica) {
                            onRefreshAliquoteCat()
                        }
                    }
                })
    }

    @Command
    def onDuplicaAliquotaCat() {

        def nuovaAliquotaCat = new AliquotaCategoriaDTO()
        InvokerHelper.setProperties(nuovaAliquotaCat, aliquotaCatSelezionata.properties)

        commonService.creaPopup("/archivio/dizionari/dettaglioAliquoteCategoria.zul", self,
                [
                        tipoTributo      : tipoTributoSelezionato.tipoTributo,
                        tipoAliquota     : aliquotaSelezionata.tipoAliquota,
                        anno             : aliquotaSelezionata.anno,
                        aliquotaCategoria: nuovaAliquotaCat,
                        modifica         : false
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.ricarica) {
                            refreshSenzaResetAliquota()
                        }
                    }
                })

    }

    @Command
    def onEliminaAliquotaCat() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def aliq = aliquoteService.getAliquotaCategoria(aliquotaCatSelezionata.anno, aliquotaCatSelezionata.tipoAliquota.tipoAliquota,
                                aliquotaCatSelezionata.categoriaCatasto.categoriaCatasto, aliquotaCatSelezionata.tipoAliquota.tipoTributo.tipoTributo)
                        aliquoteService.eliminaAliquotaCategoria(aliq)
                        refreshSenzaResetAliquota()
                    }
                })
    }

    @Command
    def onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()
    }

    @Command
    def onChangeValue(@BindingParam("val") def value) {
        def aliqCat = aliquoteService.getAliquotaCategoria(
                value.anno,
                value.tipoAliquota.tipoAliquota,
                value.categoriaCatasto.categoriaCatasto,
                value.tipoAliquota.tipoTributo.tipoTributo
        )
        aliqCat.note = value.note
        aliquoteService.salvaAliquotaCategoria(aliqCat)
    }


    private void aggiungiAliquota(AliquotaDTO al, boolean modifica) {

        commonService.creaPopup("/archivio/dizionari/aliquota.zul",
                self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        aliquota   : al,
                        modifica   : modifica,
                        lettura    : lettura
                ],
                { event ->
                    if (event.data) {
                        if (!event.data.chiudi) {
                            oggettiCacheMap.refresh(OggettiCache.ALIQUOTE)
                            onRefresh()
                        }
                    }
                }
        )
    }

    def fCountAlca(def al) {

        return aliquoteService.fCountAlca(al.anno, al.tipoAliquota.tipoAliquota, tipoTributoSelezionato.tipoTributo) > 0
    }

    private def refreshSenzaResetAliquota() {
        fetchAliquote()
        fetchAliquoteCategoria()

        resetAliquotaCategoria()
    }

    private void fetchAliquote() {
        listaAliquote = OggettiCache.ALIQUOTE.valore
                .findAll {
                    (it.tipoAliquota.tipoTributo.tipoTributo == tipoTributoSelezionato.tipoTributo &&
                            (filtro.daAliquota ? it.aliquota >= filtro.daAliquota : true) &&
                            (filtro.aAliquota ? it.aliquota <= filtro.aAliquota : true) &&
                            (filtro.daAliquotaBase ? it.aliquotaBase >= filtro.daAliquotaBase : true) &&
                            (filtro.aAliquotaBase ? it.aliquotaBase <= filtro.aAliquotaBase : true) &&
                            (filtro.daAliquotaErariale ? it.aliquotaErariale >= filtro.daAliquotaErariale : true) &&
                            (filtro.aAliquotaErariale ? it.aliquotaErariale <= filtro.aAliquotaErariale : true) &&
                            (filtro.daAliquotaStandard ? it.aliquotaStd >= filtro.daAliquotaStandard : true) &&
                            (filtro.aAliquotaStandard ? it.aliquotaStd <= filtro.aAliquotaStandard : true) &&
                            (filtro.daPercentualeOccupante ? it.percOccupante >= filtro.daPercentualeOccupante : true) &&
                            (filtro.aPercentualeOccupante ? it.percOccupante <= filtro.aPercentualeOccupante : true) &&
                            (filtro.daPercentualeSaldo ? it.percSaldo >= filtro.daPercentualeSaldo : true) &&
                            (filtro.daPercentualeSaldo ? it.percSaldo <= filtro.daPercentualeSaldo : true) &&
                            (filtro.daTipoAliquota ? it.tipoAliquota.tipoAliquota >= filtro.daTipoAliquota : true) &&
                            (filtro.aTipoAliquota ? it.tipoAliquota.tipoAliquota <= filtro.aTipoAliquota : true) &&
                            (filtro.descrizione ? filterStringMatchesString(filtro.descrizione, it.tipoAliquota.descrizione) : true) &&
                            (filtro.countAlca == 'Con' ? fCountAlca(it) : true) &&
                            (filtro.countAlca == 'Senza' ? !fCountAlca(it) : true) &&
                            (filtro.abPrincipale == 'Con' ? it.flagAbPrincipale == 'S' : true) &&
                            (filtro.abPrincipale == 'Senza' ? it.flagAbPrincipale != 'S' : true) &&
                            (filtro.pertinenze == 'Con' ? it.flagPertinenze == 'S' : true) &&
                            (filtro.pertinenze == 'Senza' ? it.flagPertinenze != 'S' : true) &&
                            (filtro.daAnno ? it.anno >= filtro.daAnno : true) &&
                            (filtro.aAnno ? it.anno <= filtro.aAnno : true) &&
                            (filtro.riduzione == 'Con' ? it.flagRiduzione == 'S' : true) &&
                            (filtro.riduzione == 'Senza' ? it.flagRiduzione != 'S' : true) &&
                            (filtro.daRiduzioneImposta ? it.riduzioneImposta >= filtro.daRiduzioneImposta : true) &&
                            (filtro.aRiduzioneImposta ? it.riduzioneImposta <= filtro.aRiduzioneImposta : true) &&
                            (filtro.note ? filterStringMatchesString(filtro.note, it.note) : true) &&
                            (filtro.daScadenzaMiniImu ? it.scadenzaMiniImu <= filtro.daScadenzaMiniImu : true) &&
                            (filtro.aScadenzaMiniImu ? it.scadenzaMiniImu >= filtro.aScadenzaMiniImu : true) &&
                            (filtro.fabbricatiMerce == 'Con' ? it.flagFabbricatiMerce == 'S' : true) &&
                            (filtro.fabbricatiMerce == 'Senza' ? it.flagFabbricatiMerce != 'S' : true)
                    )
                }.sort { a, b -> (b.anno <=> a.anno) ?: (a.tipoAliquota.tipoAliquota <=> b.tipoAliquota.tipoAliquota) }
        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
    }

    private void resetAliquota() {
        aliquotaSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "aliquotaCatSelezionata")
        listaAliquoteCat = null
        BindUtils.postNotifyChange(null, null, this, "listaAliquoteCat")
        aliquotaCatSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
    }

    private void fetchAliquoteCategoria() {
        listaAliquoteCat = aliquoteService.getListaAliquoteCategoria(tipoTributoSelezionato.tipoTributo,
                aliquotaSelezionata.anno, aliquotaSelezionata.tipoAliquota.tipoAliquota).toDTO(['tipoAliquota', 'categoriaCatasto'])
        BindUtils.postNotifyChange(null, null, this, "listaAliquoteCat")
    }

    private void resetAliquotaCategoria() {
        aliquotaCatSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "aliquotaCatSelezionata")
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaAliquoteRicerca.zul", self, [filtro: filtro, tipoTributo: tipoTributoSelezionato.tipoTributo], { event ->
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
