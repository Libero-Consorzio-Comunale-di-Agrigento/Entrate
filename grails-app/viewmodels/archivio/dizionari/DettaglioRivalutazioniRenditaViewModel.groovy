package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.RivalutazioneRenditaDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.rivalutazioniRendita.RivalutazioniRenditaService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioRivalutazioniRenditaViewModel {

    // Services
    RivalutazioniRenditaService rivalutazioniRenditaService
    CommonService commonService

    // Componenti
    Window self

    // Comuni
    def tipoTributo

    // tracciamento dello stato
    boolean isModifica = false
    boolean esistente = false
    boolean isClone = false
    boolean isLettura = false
    def labels

    //tracciamento delle modifiche
    boolean shouldRefresh = false
    //---------------------------
    Collection<TipoOggettoDTO> tipiOggettoList
    int currentIndex

    RivalutazioneRenditaDTO rivalutazioneRendita

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("selezionato") RivalutazioneRenditaDTO selected,
         @ExecutionArgParam("tipiOggettoList") Collection<TipoOggettoDTO> tipiOggettoList,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isClone") boolean isClone,
         @ExecutionArgParam("isLettura") @Default('false') boolean isLettura) {
        this.self = w
        this.tipoTributo = tipoTributo

        this.rivalutazioneRendita = selected ?: new RivalutazioneRenditaDTO(new TipoOggettoDTO())
        this.tipiOggettoList = tipiOggettoList

        this.esistente = (null != selected)
        this.isModifica = isModifica
        this.isClone = isClone
        this.isLettura = isLettura ?: false

        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }

        if (!isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    'una Rivalutazione Rendita',
                    "questo Anno e Tipo Oggetto")

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, ["rivalutazioneRendita": rivalutazioneRendita])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


    /**
     * Per inserire un elemento non devono essercene di già presenti
     */
    private boolean alreadyExist() {
        return rivalutazioniRenditaService.exist([
                tipoTributo: this.tipoTributo,
                anno       : rivalutazioneRendita.anno,
                tipoOggetto: rivalutazioneRendita.tipoOggetto.tipoOggetto
        ])
    }

    private def controllaParametri() {

        def errori = []

        if (null == rivalutazioneRendita.anno) {
            errori << "Il campo Anno è obbligatorio"
        }
        if (StringUtils.isBlank(rivalutazioneRendita.tipoOggetto.descrizione)) {
            errori << "Il campo Tipo Oggetto è obbligatorio"
        }
        if (null == rivalutazioneRendita.aliquota) {
            errori << "Il campo Aliquota è obbligatorio"
        }
        return errori
    }
}
