package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.TariffaNonDomesticaDTO
import it.finmatica.tr4.tariffeNonDomestiche.TariffeNonDomesticheService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioTariffaNonDomesticaViewModel {

    //  Services
    TariffeNonDomesticheService tariffeNonDomesticheService
    CommonService commonService

    //  Componenti
    Window self

    def labels

    //  Tracciamento dello stato
    boolean isModifica = false
    boolean isLettura = false

    // Modello
    Collection<CategoriaDTO> listaCategorie
    def annoTributo
    def codiceTributo
    TariffaNonDomesticaDTO tariffa

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("listaCategorie") Collection<CategoriaDTO> listaCategorie,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("codiceTributo") def codiceTributo,
         @ExecutionArgParam("selezionato") TariffaNonDomesticaDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isLettura") @Default("false") boolean isLettura) {

        this.self = w

        this.listaCategorie = listaCategorie

        this.tariffa = selected ?: new TariffaNonDomesticaDTO(annoTributo, codiceTributo)
        this.isModifica = isModifica
        this.isLettura = isLettura ?: false
        this.labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, ["tariffa": tariffa])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def controllaParametri() {

        def errori = []

        if (tariffa.categoria == null) {
            errori << "Il campo Categoria è obbligatorio"
        }
        if (tariffa.tariffaQuotaFissa == null) {
            errori << "Il campo Tariffa Quota Fissa è obbligatorio"
        }
        if (tariffa.tariffaQuotaVariabile == null) {
            errori << "Il campo Tariffa Quota Variabile è obbligatorio"
        }
        if ((errori.size() == 0) && !isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    'una Tariffa Non Domestica',
                    "questa Categoria")
            errori << message
        }

        return errori
    }

    private boolean alreadyExist() {
        return tariffeNonDomesticheService.exist([
                "codiceTributo": tariffa.tributo,
                "annoTributo"  : tariffa.anno,
                "categoria"    : tariffa.categoria,
        ])
    }
}
