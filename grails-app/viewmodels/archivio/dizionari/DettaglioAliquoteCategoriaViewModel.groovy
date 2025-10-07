package archivio.dizionari

import it.finmatica.tr4.AliquotaCategoria
import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.AliquotaCategoriaDTO
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioAliquoteCategoriaViewModel {


    // Componenti
    Window self

    // Services
    AliquoteService aliquoteService
    CommonService commonService

    // Dati
    def listaCategorieCatasto
    def tipoAliquota
    def anno
    def tipoTributo

    def aliquotaCategoria
    def modifica
    def aliqCatPrecedente
    def lettura
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("tipoAliquota") def ta,
         @ExecutionArgParam("anno") def an,
         @ExecutionArgParam("aliquotaCategoria") def alca,
         @ExecutionArgParam("modifica") def md,
         @ExecutionArgParam("lettura") def lettura) {

        this.self = w
        this.anno = an
        this.tipoAliquota = ta
        this.tipoTributo = tt
        this.modifica = md
        this.lettura = lettura ?: false

        listaCategorieCatasto = aliquoteService.getCategorieCatasto().toDTO()

        aliquotaCategoria = alca ?: new AliquotaCategoriaDTO([
                "anno"            : anno,
                "tipoAliquota"    : tipoAliquota,
                "categoriaCatasto": listaCategorieCatasto[0]
        ])

        // Salvo la categoria catasto precedente per poter eliminare l'entity nel caso di modifica dell'id (cat. catasto)
        if (modifica && alca != null) {
            aliqCatPrecedente = new AliquotaCategoriaDTO()
            InvokerHelper.setProperties(aliqCatPrecedente, alca.properties)
        }

        labels = commonService.getLabelsProperties('dizionario')

    }


    @Command
    onSalva() {

        def errori = controllaParametri()

        if (!errori.empty) {
            Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        if (!modifica &&
                aliquotaCategoria?.categoriaCatasto != null &&
                aliquoteService.existsCategoriaCatasto(tipoTributo, anno, tipoAliquota.tipoAliquota, aliquotaCategoria.categoriaCatasto.categoriaCatasto)) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted, "un'Aliquota per Categoria", 'questa Categoria Catasto')
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }


        def aliq

        if (modifica){
            aliq = aliquoteService.getAliquotaCategoria(aliquotaCategoria.anno, aliquotaCategoria.tipoAliquota.tipoAliquota,
                    aliqCatPrecedente.categoriaCatasto.categoriaCatasto, aliquotaCategoria.tipoAliquota.tipoTributo.tipoTributo)
        }else {
            aliq = new AliquotaCategoria()
        }


        // Nel caso in cui si modifica la categoria catasto, occorre eliminare l'entity precedente alla modifica
        if (modifica && aliqCatPrecedente &&
                aliquotaCategoria?.categoriaCatasto?.categoriaCatasto != aliqCatPrecedente?.categoriaCatasto?.categoriaCatasto) {

            aliquoteService.eliminaAliquotaCategoria(aliq)
        }


        aliq.categoriaCatasto = aliquotaCategoria.categoriaCatasto.toDomain()
        aliq.aliquota = aliquotaCategoria.aliquota
        aliq.aliquotaBase = aliquotaCategoria.aliquotaBase
        aliq.note = aliquotaCategoria.note
        aliq.anno = aliquotaCategoria.anno
        aliq.tipoAliquota = aliquotaCategoria.tipoAliquota.toDomain()

        aliquoteService.salvaAliquotaCategoria(aliq)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        Events.postEvent(Events.ON_CLOSE, self, [ricarica: true])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [ricarica: false])
    }

    private def controllaParametri() {

        def errori = []

        if (aliquotaCategoria?.categoriaCatasto == null) {
            errori << "La Categoria Catasto è obbligatoria\n"
        }

        if (aliquotaCategoria?.aliquota == null) {
            errori << "L'Aliquota è obbligatoria\n"
        }

        return errori
    }

}
