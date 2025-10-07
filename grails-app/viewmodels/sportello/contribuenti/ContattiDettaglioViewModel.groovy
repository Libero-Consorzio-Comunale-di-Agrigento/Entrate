package sportello.contribuenti

import it.finmatica.tr4.ContattoContribuente
import it.finmatica.tr4.TipoRichiedente
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ContattiDettaglioViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE
    }

    // Servizi
    ContribuentiService contribuentiService
    CompetenzeService competenzeService
    CommonService commonService

    // Componenti
    def self


    ContattoContribuente contatto
    ContattoContribuente contattoSelezionato
    def listaTipiContatto
    def listaTipiRichiedente
    def listaTipiTributo
    def listaTipiTributoLettura
    def contribuente
    def tipoOperazione
    def compModifica = true

    boolean modifica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoOperazione") def ism,
         @ExecutionArgParam("contribuente") def con,
         @ExecutionArgParam("contattoSelezionato") def cons) {

        this.self = w
        this.contribuente = con
        this.contattoSelezionato = cons
        this.tipoOperazione = ism

        this.modifica = false

        caricaDati()
    }

    @Command
    def onChiudi() {
        Events.postEvent("onClose", self, null)
    }

    @Command
    def onSalva() {

        //Controllo Data obbligatoria
        if (!contatto.data) {
            Clients.showNotification("La Data è obbligatoria!", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        contribuentiService.salvaContatto(contatto)
        onChiudi()
    }

    private def caricaDati() {
        listaTipiContatto = OggettiCache.TIPI_CONTATTO.valore.sort { a, b -> a.tipoContatto <=> b.tipoContatto }.collect { it.toDomain() }
        listaTipiRichiedente = TipoRichiedente.list()

        contatto = new ContattoContribuente()

        listaTipiTributo = competenzeService.tipiTributoUtenzaScrittura().sort { it.tipoTributo }
                .collect { it.toDomain() }

        listaTipiTributoLettura = competenzeService.tipiTributoUtenzaLettura().sort { it.tipoTributo }
                .collect { it.toDomain() }

        if (tipoOperazione == TipoOperazione.MODIFICA || tipoOperazione == TipoOperazione.CLONAZIONE) { //Caso modifica

            if (tipoOperazione == TipoOperazione.CLONAZIONE) {
                contatto.sequenza = contribuentiService.getNuovaSequenzaContatto(contattoSelezionato.contribuente.codFiscale)
            } else {
                contatto.sequenza = contattoSelezionato.sequenza
            }

            if (contattoSelezionato.tipoTributo in listaTipiTributo) {
                compModifica = true
            } else if (contattoSelezionato.tipoTributo in listaTipiTributoLettura) {
                compModifica = false
            }

            contatto.tipoContatto = contattoSelezionato.tipoContatto
            contatto.tipoRichiedente = contattoSelezionato.tipoRichiedente
            contatto.data = contattoSelezionato.data
            contatto.numero = contattoSelezionato.numero
            contatto.anno = contattoSelezionato.anno
            contatto.testo = contattoSelezionato.testo
            contatto.tipoTributo = contattoSelezionato.tipoTributo
            contatto.pratica = contattoSelezionato.pratica
            contatto.contribuente = contattoSelezionato.contribuente
        } else if (tipoOperazione == TipoOperazione.INSERIMENTO) {
            contatto.contribuente = contribuente
        }

        modifica = true

        if (contatto.tipoTributo) {
            if (!(competenzeService.utenteAbilitatoScrittura(contatto.tipoTributo.tipoTributo))) {
                modifica = false
            }
        }
    }
}
