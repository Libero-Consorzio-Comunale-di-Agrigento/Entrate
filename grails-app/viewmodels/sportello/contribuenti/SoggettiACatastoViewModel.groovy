package sportello.contribuenti

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.SoggettoDTO
import org.apache.log4j.Logger
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listbox
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class SoggettiACatastoViewModel {

	private static final Logger log = Logger.getLogger(SoggettiACatastoViewModel.class)

    // services
    SpringSecurityService springSecurityService
    ContribuentiService contribuentiService

    CatastoCensuarioService catastoCensuarioService

    ServletContext servletContext

    // componenti
    Window self
    // dati
    SoggettoDTO soggetto
    def ultimoStato = ""
    def numSoggetti = 0

    String tabSelezionata = "soggetti"

    def modificaInline = false
    def listaProprietari

    def proprietarioSelezionato
    def proprietarioSelezionatoPrecedente = [:]
    def proprietarioSelezionatoPrecedenteId

    def isDirty = false

    // paginazione
    def pagingDetails = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    def forzaCaricamentoTab = [
            'soggetti': false
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("idSoggetto") long idSoggetto) {

        this.self = w

        if (idSoggetto > 0) {
            soggetto = Soggetto.get(idSoggetto).toDTO([
                    "contribuenti",
                    "comuneResidenza",
                    "comuneResidenza.ad4Comune",
                    "archivioVie",
                    "stato"
            ])

            if (soggetto.stato) {
                ultimoStato = soggetto.stato.descrizione
                if (soggetto.dataUltEve) {
                    ultimoStato += " il " + soggetto.dataUltEve.format('dd/MM/yyyy')
                }
            }

            onRefresh()
        } else {
            // soggetto = new SoggettoDTO(id: idSoggetto)
            // TODO gestione errore...
            ultimoStato = ""
        }
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        tabSelezionata = tabId

        switch (tabId) {
            case 'soggetti':
                try {
                    (self.getFellow("includeSoggetti").getFellow("gridSitContrSoggetti")
                            as Listbox)
                            .invalidate()
                } catch (Exception e) {
                    log.info "gridSitContrSoggetti non caricata."
                }
                break
        }

        if (forzaCaricamentoTab[tabSelezionata]) {

            onRefresh()
            forzaCaricamentoTab[tabSelezionata] = false
        }
    }

    @Command
    onChiudiPopup() {

        Events.postEvent(Events.ON_CLOSE, self, [isDirty: isDirty])
    }

    @Command
    onAggiungiProprietario() {

        String cfSoggetto = soggetto?.contribuente?.codFiscale ?: 'ZZZ'

        Window w = Executions.createComponents("/sportello/contribuenti/soggettiACatastoRicerca.zul", self, [cfSoggetto: cfSoggetto])
        w.onClose { event ->
            if (event.data) {

                def idSoggetti = event.data.idSoggetti

                idSoggetti.each() { sogg ->

                    Long counter = 0
                    listaProprietari.each() { s ->
                        if (s.IDSOGGETTO == sogg.id) {
                            counter++
                        }
                    }

                    if (counter == 0) {
                        catastoCensuarioService.creaAssegnazioniSoggettoCatasto(cfSoggetto, sogg.id)
                    }
                }

                isDirty = true

                onRefresh()
            }
        }
        w.doModal()
    }

    @Command
    onSelezionaProprietario() {

        if (modificaInline) {

            proprietarioSelezionato = listaProprietari.find { it.IDSEQUENZA == proprietarioSelezionatoPrecedenteId }
            BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")

            Messagebox.show("Modifica in corso, impossibile selezionare un altro soggetto.", "Attenzione", Messagebox.OK, Messagebox.INFORMATION)
            return
        }

        proprietarioSelezionatoPrecedenteId = proprietarioSelezionato.IDSEQUENZA
        InvokerHelper.setProperties(proprietarioSelezionatoPrecedente, proprietarioSelezionato)
    }

    @Command
    @NotifyChange(['modificaInline'])
    def onModificaInline() {

        modificaInline = !modificaInline
    }

    @Command
    @NotifyChange(['modificaInline'])
    def onAnnullaModificaInline() {

        modificaInline = false

        listaProprietari.each {
            if (it.IDSEQUENZA == proprietarioSelezionato.IDSEQUENZA) {
                InvokerHelper.setProperties(it, proprietarioSelezionatoPrecedente)
                BindUtils.postNotifyChange(null, null, this, "listaProprietari")
            }
        }
    }

    @Command
    @NotifyChange(['modificaInline'])
    def onAccettaModificaInline() {

        modificaInline = false

        Long idSequenza = proprietarioSelezionato.IDSEQUENZA
        String note = proprietarioSelezionato.NOTE_SEQUENZA

        catastoCensuarioService.modificaAssegnazioniSoggettoCatasto(idSequenza, note)

        proprietarioSelezionatoPrecedente.NOTE_SEQUENZA = note

        isDirty = true
    }

    @Command
    def onVisualizzaSoggetto() {
        def ni = soggetto.id

        if (!ni) {
            Clients.showNotification("Soggetto non trovato.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=SOGGETTO&idSoggetto=${ni}','_blank');")
    }

    @Command
    onEliminaProprietario() {

        String title = "Conferma operazione"
        String message = "Sicuri di voler eliminare il soggetto dall'elenco ?"

        Long idSequenza = proprietarioSelezionato.IDSEQUENZA

        Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaSequenza(idSequenza)
                            isDirty = true
                            onRefresh()
                        }
                    }
                }
        )
    }

    @Command
    onRefresh() {

        switch (tabSelezionata) {
            case "soggetti":
                caricalListaProprietari(true)
                proprietarioSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
                break
        }
    }

    @Command
    onPaging() {

        switch (tabSelezionata) {
            case "soggetti":
                caricalListaProprietari()
                proprietarioSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
                break
        }
    }

    private caricalListaProprietari(Boolean resetLista = false) {

        String tipoOrdinamentoProprietari = "alfabetico"

        if (resetLista) {
            pagingDetails.activePage = 0
        }

        String cfSoggetto = soggetto?.contribuente?.codFiscale ?: 'ZZZ'

        def filtroProprietari = [
                codiceFiscaleContribuente: cfSoggetto
        ]

        def elencoProprietari = catastoCensuarioService.getProprietariDaCFContribuente(filtroProprietari, pagingDetails, tipoOrdinamentoProprietari)
        pagingDetails.totalSize = elencoProprietari.totalCount
        listaProprietari = elencoProprietari.data

        BindUtils.postNotifyChange(null, null, this, "listaProprietari")
        BindUtils.postNotifyChange(null, null, this, "pagingDetails")

        numSoggetti = pagingDetails.totalSize
        BindUtils.postNotifyChange(null, null, this, "numSoggetti")

        modificaInline = false
        BindUtils.postNotifyChange(null, null, this, "modificaInline")
    }

    private eliminaSequenza(Long idSequenza) {

        catastoCensuarioService.eliminaAssegnazioniSoggettoCatasto(idSequenza)
    }

}
