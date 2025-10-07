package ufficiotributi.bonificaDati.docfa

import it.finmatica.tr4.CodiceDiritto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.bonificaDati.docfa.BonificaDocfaService
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

class BonificaDocfaViewModel {
    Window self
    BonificaDocfaService bonificaDocfaService
    OggettiService oggettiService

    @Wire('#tabBoxDocfa')
    Tabbox tabBoxDocfa

    @Wire('#includeOggetti #oggettiListBox')
    Listbox oggettiListBox

    @Wire('#includeModificaOggetto #ricercaOggettiListBox')
    Listbox ricercaOggettiListBox


    @Wire('#includeSoggetti #soggettiListBox')
    Listbox soggettiListBox

    def docfa
    def docCaMu

    def modificaOggetto = false
    def oggettoSelezionato
    def oggettiDaArchivio = []
    def immobileArchivioSelezionato
    List<FiltroRicercaOggetto> listaFiltri
    int oggettiActivePage = 0
    int oggettiPageSize = 5
    int oggettiTotalSize

    def modificaSoggetto = false
    def oggetti
    def listaOggettiPaginazione = [
            max       : 10,
            offset    : 0,
            activePage: 0
    ]

    def soggetti
    def soggettoSelezionato
    def listaSoggettiPaginazione = [
            max       : 10,
            offset    : 0,
            activePage: 0
    ]

    def tipiSoggetto = [
            '0': 'Pers.Fisica',
            '1': 'Pers.Giuridica',
            '2': 'Intestazioni Particolari'
    ]

    def regimi = [
            'S': 'Separazione legale dei beni',
            'C': 'Comunione legale dei beni',
            'B': 'Bene personale'
    ]

    def tipiCaricamento = [
            'D': 'Docfa',
            'M': 'Manuale',
            'B': 'Base Dati'
    ]

    def albi = [
            '1' : 'Architetti',
            '2' : 'Ingegneri',
            '3' : 'Geometri',
            '4' : 'Periti edili',
            '5' : 'Dottori agronomi e forestali',
            '6' : 'Periti agrari',
            '7' : 'Architetto Dipendente Pubblico',
            '8' : 'Ingegnere Dipendente Pubblico',
            '9' : 'Geometra Dipendente Pubblico',
            '10': 'Perito Edile Dipendente Pubblico',
            '11': 'Dottore agronomo o forestale Dipendente Pubblico',
            '12': 'Perito agrario Dipendente Pubblico'
    ]

    def tipiOperazione = [
            'C': 'Costituita',
            'V': 'Variata',
            'S': 'Soppressa'
    ]

    def codiciDiritto

    boolean modifica = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("docfa") def docfa,
         @ExecutionArgParam("modifica") def md) {

        this.self = w

        this.docfa = docfa
        this.modifica = md

        docCaMu = bonificaDocfaService.getDocumentoMulti(docfa)

        caricaSoggettiDocfa()

        codiciDiritto = CodiceDiritto.findAll().sort { it.codDiritto }
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onScaricaDocumento() {
        if (!docCaMu?.contenuto2) {
            Clients.showNotification("Nessun documento disponibile.", Clients.NOTIFICATION_TYPE_INFO,
                    null, "middle_center", 3000, true)
            return
        }

        AMedia amedia = new AMedia(docCaMu.nomeDocumento2, "pdf", "application/pdf", docCaMu.contenuto2)
        Filedownload.save(amedia)
    }

    @Command
    def onMostraNota(@BindingParam("nota") def nota,
                     @BindingParam("titolo") def titolo) {

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/docfa/docfaNota.zul",
                self,
                [
                        titolo: titolo,
                        nota  : nota
                ])
        w.doModal()

    }

    @NotifyChange(['tabBoxDocfa', 'modificaOggetto', 'modificaSoggetto'])
    @Command
    def onSelectTab() {
        switch (tabBoxDocfa.selectedTab.id) {
            case 'tabOggetti':
                getOggettiDocfa()
                modificaSoggetto = false
                break;
            case 'tabSoggetti':
                getSoggettiDocfa()
                modificaOggetto = false
                break;
            default:
                modificaOggetto = false
                modificaSoggetto = false
        }

    }

    @Command
    def onCaricaOggetti() {
        getOggettiDocfa()
    }

    @Command
    def onCaricaListaSoggetti() {
        getSoggettiDocfa()
    }

    @NotifyChange(['modificaOggetto', 'oggettoSelezionato'])
    @Command
    def onModificaOggetto(@BindingParam("oggetto") def oggetto) {
        modificaOggetto = true
        oggettoSelezionato = oggetto
    }

    @NotifyChange(['modificaSoggetto', 'soggettoSelezionato'])
    @Command
    def onModificaSoggetto(@BindingParam("soggetto") def soggetto) {
        modificaSoggetto = true
        soggettoSelezionato = soggetto
    }

    @NotifyChange(['modificaOggetto'])
    @Command
    def onAnnullaModificaOggetto() {
        modificaOggetto = false
    }

    @NotifyChange(['modificaSoggetto'])
    @Command
    def onAnnullaModificaSoggetto() {
        modificaSoggetto = false
    }

    @NotifyChange(['modificaOggetto'])
    @Command
    def onAccettaModificaOggetto() {
        oggettoSelezionato.save(flush: true, failOnError: true)
        caricaSoggettiDocfa()
        getOggettiDocfa(true)
        modificaOggetto = false
    }

    @NotifyChange(['modificaSoggetto'])
    @Command
    def onAccettaModificaSoggetto() {
        soggettoSelezionato.save(flush: true, failOnError: true)
        modificaSoggetto = false
        getSoggettiDocfa()
    }

    @Command
    def onCercaOggettiArchivio() {

        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self, [filtri: listaFiltri, listaVisibile: false, inPratica: false, ricercaContribuente: true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    listaFiltri = event.data.filtri
                    caricaLista()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onPaging() {
        caricaLista()
    }

    @NotifyChange(['oggettoSelezionato'])
    @Command
    def onDropOggetto(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        oggettoSelezionato.tr4Oggetto = (event.dragged.label as Integer)
    }

    @NotifyChange(['oggettoSelezionato'])
    @Command
    def onAssociaOggetto() {
        oggettoSelezionato.tr4Oggetto = immobileArchivioSelezionato.idOggetto
    }

    @Command
    def onCarica() {
        def messaggi = bonificaDocfaService.convalidaDocfa(docfa)

        if (!messaggi.isEmpty()) {
            Clients.showNotification(messaggi, Clients.NOTIFICATION_TYPE_WARNING,
                    null, "middle_center", 3000, true)
        } else {
            onClose()
        }
    }

    @Command
    def onSalva() {
        docfa.toDomain().save(failOnError: true, flush: true)
        Clients.showNotification("Docfa salvato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                null, "middle_center", 3000, true)
    }

    @Command
    def onEliminaSoggetto(@BindingParam("soggettoSelezionato") def sogg) {
        String messaggio = "Eliminazione della registrazione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.CANCEL | Messagebox.YES, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    public void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            sogg.delete(failOnError: true, flush: true)
                            getSoggettiDocfa()
                            Clients.showNotification("Soggetto eliminato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                                    null, "middle_center", 3000, true)
                        }
                    }
                })
    }

    @Command
    def onSelectOggetto() {
        listaSoggettiPaginazione = [
                max       : 10,
                offset    : 0,
                activePage: 0
        ]
    }

    def formattaDenominazione(def denominazione) {
        return denominazione.replace('/', ' ')
    }

    private caricaSoggettiDocfa() {
        def messaggi = bonificaDocfaService.caricaSoggettiDocfa(docfa)

        if (!messaggi.isEmpty()) {
            Clients.showNotification(messaggi, Clients.NOTIFICATION_TYPE_WARNING,
                    null, "middle_center", 3000, true)
        }
    }

    private void getOggettiDocfa(def refresh = false) {

        if (!oggetti || refresh) {
            oggetti = bonificaDocfaService.getOggetti(docfa, listaOggettiPaginazione)
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggettiPaginazione")
        BindUtils.postNotifyChange(null, null, this, "oggetti")
    }

    private void getSoggettiDocfa() {
        soggetti = bonificaDocfaService.getSoggetti(oggettoSelezionato, listaSoggettiPaginazione)
        soggettiListBox.invalidate()

        BindUtils.postNotifyChange(null, null, this, "listaSoggettiPaginazione")
        BindUtils.postNotifyChange(null, null, this, "soggetti")
    }

    private caricaLista() {

        oggettiDaArchivio = []

        def lista = oggettiService.listaOggetti(listaFiltri, oggettiPageSize, oggettiActivePage, null)
        oggettiTotalSize = lista.totale

        lista.lista.each {

            def oggetto = [
                    idOggetto         : it.id,
                    tipoOggetto       : it.tipoOggetto?.tipoOggetto,
                    categoriaCatasto  : it.categoriaCatasto?.categoriaCatasto,
                    sezione           : it.sezione,
                    foglio            : it.foglio,
                    numero            : it.numero,
                    subalterno        : it.subalterno,
                    partita           : it.partita,
                    zona              : it.zona,
                    protocolloCatasto : it.protocolloCatasto,
                    annoCatasto       : it.annoCatasto,
                    calsse            : it.classeCatasto,
                    indirizzoCompleto : it.indirizzo,
                    estremiCatastoSort: it.estremiCatastoSort
            ]

            oggettiDaArchivio << oggetto
        }

        oggettiDaArchivio.sort { it.estremiCatastoSort }

        ricercaOggettiListBox.invalidate()

        BindUtils.postNotifyChange(null, null, this, "oggettiDaArchivio")
        BindUtils.postNotifyChange(null, null, this, "oggettiActivePage")
        BindUtils.postNotifyChange(null, null, this, "oggettiTotalSize")
    }
}
