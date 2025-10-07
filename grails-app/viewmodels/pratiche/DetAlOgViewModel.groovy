package pratiche

import it.finmatica.tr4.Detrazione
import it.finmatica.tr4.MotivoDetrazione
import it.finmatica.tr4.TipoAliquota
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.AliquotaOgcoDTO
import it.finmatica.tr4.dto.DetrazioneOgcoDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.hibernate.criterion.CriteriaSpecification
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DetAlOgViewModel {

    Window self

    def OggettiService oggettiService

    def oggettoContribuente
    def idOggPr
    def codFiscale
    def tipoTributo
    def titolo = ""
    def tt

    List listaTipiAliquota
    List listaAnniDetrazione
    List listaMotiviDetrazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idOggPr") long idOggPr,
         @ExecutionArgParam("codFiscale") String codFiscale) {

        this.self = w

        this.idOggPr = idOggPr
        this.codFiscale = codFiscale

        caricaOgco()
        this.tt = oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo

        creaTitolo()

        caricaDati()
    }

    @Command
    def onChiudiPopup() {
        Events.postEvent("onClose", self, null)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onAggiungiDetrazione() {
        DetrazioneOgcoDTO detOgco = new DetrazioneOgcoDTO()
        oggettoContribuente.addToDetrazioniOgco(detOgco)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onAggiungiAliquota() {
        AliquotaOgcoDTO aliqOgco = new AliquotaOgcoDTO()
        oggettoContribuente.addToAliquoteOgco(aliqOgco)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onEliminaDetrazione(@BindingParam("det") DetrazioneOgcoDTO detOgco) {
        oggettoContribuente.removeFromDetrazioniOgco(detOgco)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onEliminaAliquota(@BindingParam("aliq") AliquotaOgcoDTO aliqOgco) {
        oggettoContribuente.removeFromAliquoteOgco(aliqOgco)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onSalvaOggetto() {

        if (!valida()) {
            return
        }

        oggettoContribuente = oggettiService.salvaOggettoContribuente(oggettoContribuente)

        Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)

        Events.postEvent("onClose", self, [salvato: true])
    }

    private caricaOgco() {
        oggettoContribuente = OggettoContribuente.createCriteria().get {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
            //createAlias("ogpr.tipoOggetto", "tiog", CriteriaSpecification.LEFT_JOIN)
            createAlias("aliquoteOgco", "alog", CriteriaSpecification.LEFT_JOIN)
            createAlias("detrazioniOgco", "deog", CriteriaSpecification.LEFT_JOIN)
            createAlias("deog.motivoDetrazione", "mode", CriteriaSpecification.LEFT_JOIN)
            createAlias("attributiOgco", "atog", CriteriaSpecification.LEFT_JOIN)
            createAlias("atog.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)

            eq("contribuente.codFiscale", codFiscale)
            eq("ogpr.id", idOggPr)
        }.toDTO()
    }


    private creaTitolo() {
        titolo = "Aliquote e Detrazioni $tt"
    }

    private caricaDati() {

        listaTipiAliquota = TipoAliquota.findAllByTipoTributo(TipoTributo.get(tt)).toDTO()

        listaMotiviDetrazione = MotivoDetrazione.findAllByTipoTributo(TipoTributo.get(tt)).toDTO()

        listaAnniDetrazione = Detrazione.createCriteria().list {
            projections { property("anno") }
            eq("tipoTributo.tipoTributo", tt)
            order("anno", "asc")
        }
    }

    private def valida() {
        // Detrazioni

        // Campi obbligatori: anno e motivazione
        def annoAssente = !oggettoContribuente.detrazioniOgco.findAll { it.anno == null }.isEmpty()
        def motivoAssente = !oggettoContribuente.detrazioniOgco.findAll { it.motivoDetrazione == null }.isEmpty()

        // Aliquote

        // Campo obbligatori: tipo, dal, al
        def tipoAssente = !oggettoContribuente.aliquoteOgco.findAll { it.tipoAliquota == null }.isEmpty()
        def dalAssente = !oggettoContribuente.aliquoteOgco.findAll { it.dal == null }.isEmpty()
        def alAssente = !oggettoContribuente.aliquoteOgco.findAll { it.al == null }.isEmpty()

        def msg = ""

        if (annoAssente) {
            msg = "Indicare l'anno per la detrazione."
        }
        if (motivoAssente) {
            msg += "\nIndicare il motivo per la detrazione."
        }
        if (tipoAssente) {
            msg += "\nIndicare il tipo per l'aliquota."
        }
        if (dalAssente) {
            msg += "\nIndicare dal per l'aliquota."
        }
        if (alAssente) {
            msg += "\nIndicare al per l'aliquota."
        }

        if (msg.isEmpty()) {
            return true
        } else {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return false
        }

    }
}
