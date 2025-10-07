package pratiche.denunce


import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.criterion.CriteriaSpecification
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ListaOggettiAnniPrecedentiViewModel {
    // Componenti
    Window self

    // Service
    OggettiService oggettiService

    // Modello
    def listaOggetti = []
    def listaAnni = []
    def oggettoSelezionato
    def annoSelezionato
    def codFiscale
    def tipoTributo
    def tipoRapportoSelezionato
    def abilitaCerca = false
    def listaRapporti = [[valore       : "D"
                          , descrizione: "Proprietario"]
                         , [valore       : "A"
                            , descrizione: "Occupante"]
                         , [valore       : "E"
                            , descrizione: "Entrambi"]]

    def oggettiSelezionati = [:]
    def selezionePresente = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anno") Short anno
         , @ExecutionArgParam("tipoTributo") String tipoTributo
         , @ExecutionArgParam("contribuente") String codFiscale
         , @ExecutionArgParam("tipoRapporto") String tipoRapporto) {
        self = w
        this.tipoRapportoSelezionato = [valore: tipoRapporto, descrizione: (tipoRapporto.equals("D")) ? "Proprietario" : "Occupante"]
        abilitaCerca = annoSelezionato && tipoRapportoSelezionato?.valore
        this.tipoTributo = tipoTributo
        this.codFiscale = codFiscale
        caricaListaAnni(anno)
        annoSelezionato = listaAnni.max()
        caricaLista()
        BindUtils.postNotifyChange(null, null, this, "annoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaAnni")
        BindUtils.postNotifyChange(null, null, this, "abilitaCerca")
    }

    @Command
    onCerca() {
        caricaLista()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCheckOggetto(@BindingParam("oggetto") def oggetto) {
        selezionePresente()
    }

    @Command
    def onCheckOggetti() {
        selezionePresente()

        oggettiSelezionati = [:]

        // Se non era selezionata almeno una pratica allora si vogliono selezionare tutte
        if (!selezionePresente) {

            listaOggetti.each {
                oggettiSelezionati << [(it): true]
            }
        }

        // Si aggiorna la presenza di selezione
        selezionePresente()

        BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
    }

    @Command
    onScegliOggetto() {
        if (selezionePresente) {
            def lista = []
            oggettiSelezionati.each() {
                if (it.value) {
                    lista << it.key
                }
            }
            Events.postEvent(Events.ON_CLOSE, self, [status: "Oggetto", listaOggettoContribuente: lista])
        } else
            Clients.showNotification("Occorre selezionare l'oggetto", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
    }

    @Command
    onSelectAnno() {
        abilitaCerca = annoSelezionato && tipoRapportoSelezionato?.valore
        caricaLista()
        BindUtils.postNotifyChange(null, null, this, "abilitaCerca")
    }

    @Command
    onSelectTipoRapporto() {
        abilitaCerca = annoSelezionato && tipoRapportoSelezionato?.valore
        caricaLista()
        BindUtils.postNotifyChange(null, null, this, "abilitaCerca")
    }

    private void selezionePresente() {
        selezionePresente = (oggettiSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private caricaListaAnni(def anno) {
        listaAnni = PraticaTributo.createCriteria().list {
            createAlias("rapportiTributo", "rappTrib", CriteriaSpecification.INNER_JOIN)

            projections {
                distinct("anno")
            }
            eq("tipoTributo.tipoTributo", tipoTributo)
            lt("anno", anno)
            eq("rappTrib.contribuente.codFiscale", codFiscale)
            or {
                eq("tipoPratica", "D")
                and {
                    eq("tipoPratica", "A")
                    eq("flagDenuncia", true)
                }
            }
            order("anno", "desc")
        }
    }

    private caricaLista() {
        if (annoSelezionato) {
            listaOggetti = oggettiService.listaOggettiAnniPrecedenti(annoSelezionato, codFiscale, tipoRapportoSelezionato.valore, tipoTributo)
            BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        }
    }
}
