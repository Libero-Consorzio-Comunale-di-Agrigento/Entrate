package archivio.dizionari

import it.finmatica.tr4.coefficientiNonDomestici.CoefficientiNonDomesticiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CoefficientiNonDomesticiDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCoefficientiNonDomesticiViewModel {

    //  Services
    CoefficientiNonDomesticiService coefficientiNonDomesticiService
    CommonService commonService

    //  Componenti
    Window self
    def labels

    //  Tracciamento dello stato
    boolean isModifica = false
    boolean isLettura = false

    // Modello
    Collection<CategoriaDTO> listaCategorie
    def codiceTributo
    def annoTributo
    CoefficientiNonDomesticiDTO coefficiente

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("listaCategorie") Collection<CategoriaDTO> listaCategorie,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("codiceTributo") def codiceTributo,
         @ExecutionArgParam("selezionato") CoefficientiNonDomesticiDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isLettura") @Default("false") boolean isLettura) {
        this.self = w
        this.listaCategorie = listaCategorie

        this.coefficiente = selected ?: new CoefficientiNonDomesticiDTO(annoTributo, codiceTributo)
        this.annoTributo = annoTributo
        this.codiceTributo = codiceTributo

        this.isModifica = isModifica
        this.isLettura = isLettura
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
        Events.postEvent(Events.ON_CLOSE, self, ["coefficiente": coefficiente])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []

        if (null == coefficiente.categoria) {
            errori << "Il campo Categoria è obbligatorio"
        }
        if (coefficiente.coeffPotenziale == null) {
            errori << "Il campo Coefficiente Potenziale è obbligatorio"
        }
        if (coefficiente.coeffProduzione == null) {
            errori << "Il campo Coefficiente Produzione è obbligatorio"
        }
        if ((0 == errori.size()) && !isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    'un Coefficiente Non Domestico',
                    "questa Categoria")
            errori << message
        }

        return errori
    }

    private boolean alreadyExist() {
        return coefficientiNonDomesticiService.exist([
                "codiceTributo": coefficiente.tributo,
                "annoTributo"  : coefficiente.anno,
                "categoria"    : coefficiente.categoria,
        ])
    }
}
