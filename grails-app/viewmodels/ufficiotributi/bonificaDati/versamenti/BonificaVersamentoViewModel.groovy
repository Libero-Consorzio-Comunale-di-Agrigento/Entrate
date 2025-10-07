package ufficiotributi.bonificaDati.versamenti

import it.finmatica.tr4.AnciVer
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.WrkVersamenti
import it.finmatica.tr4.bonificaDati.versamenti.BonificaVersamentiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

class BonificaVersamentoViewModel {

    Window self

    BonificaVersamentiService bonificaVersamentiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    SoggettiService soggettiService

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    @Wire('#includeSoggetti #popupFiltriSoggetti')
    Popup popupFiltriSoggetti

    @Wire('#comboSanzRavv')
    Combobox comboSanzRavv

    @Wire('#includeAccLiq #accLiqListBox')
    Listbox accLiqListBox

    @Wire('#tabBoxElenchi')
    Tabbox tabBoxElenchi

    Boolean lettura

    def versamentoAnomaloSelezionato
    def versamentoAnomalo
    def tipoIncasso
    def tipoTributo
    def anci
    def abilitaFlagRavvedimento

    // Tab dei soggetti
    def listaSoggetti
    def soggettoSelezionato
    int activePageSoggetti = 0
    int pageSizeSoggetti = 10
    int totalSizeSoggetti
    def filtriSoggetti
    def sortBySoggetti

    // Tab accertamenti/liquidazioni
    def listaAccLiq
    def accLiqSelezionato
    int activePageAccLiq = 0
    int pageSizeAccLiq = 10
    int totalSizeAccLiq
    def sortByAccLiq
    def modificaDataNotificaPratica = false
    def vecchiaDataNotificaPratica
    def praticaAssociata

    // Tab Ravvedimenti
    def listaRavv
    def ravvSelezionato
    int activePageRavv = 0
    int pageSizeRavv = 10
    int totalSizeRavv
    def sortByRavv

    def tipiVersamento = [
            'A' : 'Acconto',
            'S' : 'Saldo',
            'U' : 'Unico',
            null: ''
    ]

    def tipiRavvedimento = [
            'null': 'Non trattato',
            'N'   : 'Ravv. su Versamento',
            'O'   : 'Ravv. su Omessa Denuncia',
            'I'   : 'Ravv. su Infedele Denuncia'
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("id") def id
         , @ExecutionArgParam("tipoIncasso") def tipoIncasso
         , @ExecutionArgParam("lettura") Boolean lt) {

        this.self = w

        this.lettura = (lt != null) ? lt : true

        this.tipoIncasso = tipoIncasso

        if (tipoIncasso == 'ANCI') {
            versamentoAnomaloSelezionato = AnciVer.findByAnnoFiscaleAndProgrRecord(id.annoFiscale, id.progrRecord).toDTO()
            anci = true
        } else {
            versamentoAnomaloSelezionato = WrkVersamenti.findByProgressivo(new BigDecimal(id)).toDTO(['tipoTributo'])
            anci = false
            abilitaFlagRavvedimento =
                    versamentoAnomaloSelezionato.causale?.causale in ['50000', '50009', '50100', '50109', '50150', '50180', '50190']
        }

        versamentoAnomalo = VersamentoAnomalo.nuovoVersamentoAnomalo().crea(tipoIncasso, versamentoAnomaloSelezionato)

        //--------------------------------------------------------------------------------------------------------------
        // Soggetti
        //--------------------------------------------------------------------------------------------------------------

        // Inizializzazione dei filtri soggetto
        onPulisciFiltriSoggetti()

        // Si imposta il filtro dei soggetti
        filtriSoggetti.codFiscale = versamentoAnomalo.codFiscale

        onCercaSoggetti()

        getInsContribuente()
    }

    @AfterCompose
    void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

        if (lettura) {
            componenti.each {
                it.disabled = lettura
            }
        }
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCheckFlagRavvedimento() {

        if (versamentoAnomalo.flagRavvedimento &&
                versamentoAnomalo.identificativoOperazione?.substring(0, 3) in ['ACC', 'LIQ']) {

            String messaggio = "Scelta incongruente con Id.Operazione, Si vuole procedere?"
            Messagebox.show(messaggio, "Ricerca soggetto",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onCancellaIdOperazione()
                                gestioneCheckFlagRavvedimento()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                gestioneCheckFlagRavvedimento(true)
                            }
                        }
                    }
            )
        } else {
            gestioneCheckFlagRavvedimento()
        }
    }

    @Command
    def onDettaglioVersato() {

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/versamentoDettaglioPopup.zul",
                self,
                [
                        versamento: versamentoAnomaloSelezionato
                ])

        w.doModal()
    }

    def getInsContribuente() {
        def insContribuente = (Contribuente.findByCodFiscale(versamentoAnomalo.codFiscale) == null)
        if (!insContribuente) {
            versamentoAnomalo.flagContribuente = false
        }
        return insContribuente
    }

    private def gestioneCheckFlagRavvedimento(def annulla = false) {

        if (annulla) {
            versamentoAnomalo.flagRavvedimento = false
        } else {
            if (tabBoxElenchi.selectedIndex == 1) {
                tabBoxElenchi.selectedIndex = 2
                onSelectTab()
            }
            BindUtils.postNotifyChange(null, null, this, "tabBoxElenchi")
        }

        if (!versamentoAnomalo.flagRavvedimento) {
            versamentoAnomalo.sanzioneRavvedimento = null
            BindUtils.postNotifyChange(null, null, this, "versamentoAnomalo")
        } else {
            comboSanzRavv.selectedIndex = 0
        }

    }

    @Command
    @NotifyChange(['versamentoAnomalo', 'insContribuente'])
    onDropCodiceFiscale(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        versamentoAnomalo.codFiscale = event.dragged.label
    }

    @Command
    @NotifyChange(['versamentoAnomalo', 'insContribuente'])
    def onAssociaSoggetto(@BindingParam("tipo") def tipo) {
        associaSoggetto(tipo)
    }

    @Command
    @NotifyChange(['versamentoAnomalo'])
    onDropPratica(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        DropEvent event = (DropEvent) ctx.getTriggerEvent()

        def pratica

        // Acc./Liq.
        if (tabBoxElenchi.selectedIndex == 1) {
            pratica = listaAccLiq.find { it.pratica == event.dragged.label as Integer }
        } else {
            // Ravbv.
            pratica = listaRavv.find { it.pratica == event.dragged.label as Integer }
        }

        pratica.id = pratica.pratica

        associaPratica(event.dragged.label)

        showNotificaRuoloCoattivo(pratica)

        valida(false)
    }

    @Command
    onChangeIdentificativoOperazione() {
        if (!versamentoAnomalo.identificativoOperazione.isEmpty()) {

            def pratica = bonificaVersamentiService.getPratica(
                    versamentoAnomalo.codFiscale,
                    versamentoAnomalo.identificativoOperazione,
                    versamentoAnomalo.dataPagamento,
                    versamentoAnomalo.tipoTributo.tipoTributo)

            showNotificaRuoloCoattivo(pratica)
        }
    }


    @Command
    @NotifyChange(['versamentoAnomalo'])
    onAssociaPratica(@BindingParam("tipo") def tipo) {
        associaPratica(tipo)
    }

    @Command
    @NotifyChange(['tabBoxElenchi'])
    onSelectTab() {
        switch (tabBoxElenchi.selectedTab.id) {
            case 'tabAccLiq':
                caricaAccLiq()
                break
            case 'tabRavv':
                caricaRavv()
                break

        }
    }

    @Command
    onCaricaAccLiq() {
        caricaAccLiq()
    }

    @Command
    def onCaricaOggetti() {
        caricaRavv()
    }

    @Command
    @NotifyChange(['versamentoAnomalo'])
    onCancellaIdOperazione() {
        versamentoAnomalo.identificativoOperazione = null
    }

    @Command
    def onSalva(@BindingParam("aggiornaStato") def aggiornaStato) {

        if (!valida()) {
            return
        }

        if (aggiornaStato) {
            versamentoAnomalo.flagOk = true
        }

        def versamentoModificato = versamentoAnomalo.update().toDomain()
        // Nella tabella ANCI_VER il campo anno fiscale è in chiave, Hibernate non è in grado di effettuare una update.
        if (anci && versamentoModificato.annoFiscale != versamentoAnomalo.anno) {
            versamentoModificato.annoFiscaleModificato = versamentoAnomalo.anno
        }

        try {
            if (!anci) {
                bonificaVersamentiService.aggiornaVersamentoCheck(versamentoModificato)
            }
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }

        bonificaVersamentiService.aggiornaVersamento(versamentoModificato)

        Clients.showNotification("Versamento aggiornato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                null, "middle_center", 3000, true)
    }

    @Command
    @NotifyChange(['versamentoAnomalo', 'praticaAssociata'])
    onChangeRata() {

        if (!valida(true)) {
            return
        }

        /*// Controllo che la rata sia una rata prevista nella pratica di rateazione
        controllaRataPraticaRateazione(true)

        // Nel caso sia stata associata una pratica NON rateizzata e si modifica il campo Rate, si da avviso all'utente

        if (praticaAssociata != null && praticaAssociata?.tipoAtto?.tipoAtto != 90) {
            Clients.showNotification("La pratica trascinata non è rateizzata",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        } else if (checkIdOperazioneDaVersamentoAnomalo()) {
            def idPratica = versamentoAnomalo.identificativoOperazione[-8..-1] as Long
            def prtr = PraticaTributo.get(idPratica)

            if (prtr?.tipoAtto?.tipoAtto != 90) {
                Clients.showNotification("La pratica trascinata non è rateizzata",
                        Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            }

        }*/
    }

    private boolean valida(def aggiornaIdOperazione = false) {
        versamentoAnomalo.identificativoOperazione = versamentoAnomalo.identificativoOperazione?.trim()?.toUpperCase()

        def error = bonificaVersamentiService.verificaDatiIdOperazione(versamentoAnomalo.identificativoOperazione, versamentoAnomalo.anno, versamentoAnomalo.rata)
        if (!(error as String).isEmpty()) {
            Clients.showNotification(error, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 2000, true)
            return false
        }

        // Verifiche dell'id della pratica associato all'id operazione
        def idPratica = null

        if (versamentoAnomalo.identificativoOperazione?.trim()) {
            idPratica = versamentoAnomalo?.identificativoOperazione[-8..-1] as Long
        }

        if (idPratica && idPratica != praticaAssociata?.id) {
            praticaAssociata = PraticaTributo.get(idPratica)
        }

        // Controllo che la rata sia una rata prevista nella pratica di rateazione
        if (!controllaRataPraticaRateazione(aggiornaIdOperazione)) {
            return false
        }

        return true
    }

    private def visualizzaMessaggioRate(def maxRata) {
        def msg = "La rata deve essere minore o uguale di quella prevista nella pratica di rateazione (${maxRata as int})"
        Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
    }

    private def visualizzaMsgUpdateIdOperazione(def idPratica) {
        Messagebox.show("Si desidera aggiornare l'Id Operazione?", "Attenzione", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            associaPratica(idPratica)
                            BindUtils.postNotifyChange(null, null, this, "versamentoAnomalo")
                        }
                    }
                }
        )
    }

    def caricaRavv() {
        def elenco = bonificaVersamentiService.getPraticheRavv([codFiscale: versamentoAnomalo.codFiscale],
                pageSizeRavv, activePageRavv)

        listaRavv = elenco.record
        totalSizeRavv = elenco.numeroRecord
        ravvSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaRavv")
        BindUtils.postNotifyChange(null, null, this, "activePageRavv")
        BindUtils.postNotifyChange(null, null, this, "pageSizeRavv")
        BindUtils.postNotifyChange(null, null, this, "totalSizeRavv")
        BindUtils.postNotifyChange(null, null, this, "ravvSelezionato")

    }

    def caricaAccLiq() {
        def elenco = bonificaVersamentiService.getPratiche([codFiscale: versamentoAnomalo.codFiscale],
                pageSizeAccLiq, activePageAccLiq)

        listaAccLiq = elenco.record
        totalSizeAccLiq = elenco.numeroRecord
        accLiqSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaAccLiq")
        BindUtils.postNotifyChange(null, null, this, "activePageAccLiq")
        BindUtils.postNotifyChange(null, null, this, "pageSizeAccLiq")
        BindUtils.postNotifyChange(null, null, this, "totalSizeAccLiq")
        BindUtils.postNotifyChange(null, null, this, "accLiqSelezionato")

    }

    private def controllaRataPraticaRateazione(def aggiornaIdOperazione = false) {

        if (versamentoAnomalo.rata != null && versamentoAnomalo.identificativoOperazione && praticaAssociata?.tipoAtto?.tipoAtto != 90) {
            Clients.showNotification("L'Id. Operazione è associato ad una pratica non rateizzata",
                    Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }


        if (versamentoAnomalo.identificativoOperazione && praticaAssociata?.tipoAtto?.tipoAtto == 90) {

            // Caso in cui si effettua il trascinamento della pratica rateizzata e successivamente si mmodifica il campo rate

            // Controllo che la rata sia una rata prevista nella pratica di rateazione
            def maxRata = listaAccLiq.find { it.pratica == praticaAssociata.id }?.maxRata

            if (versamentoAnomalo.rata != null && maxRata != null && versamentoAnomalo.rata > (maxRata as int)) {
                visualizzaMessaggioRate(maxRata)
                return false
            }

            if (aggiornaIdOperazione) {
                visualizzaMsgUpdateIdOperazione(praticaAssociata.id)
            }

        } else if (

                checkIdOperazioneDaVersamentoAnomalo()

        ) {

            // Caso in cui all'apertura della maschera è già presente un id operazione e si modifica il campo rate
            def idPratica = versamentoAnomalo.identificativoOperazione[-8..-1] as Long

            def prtr = PraticaTributo.get(idPratica)

            def maxRata = prtr?.rate?.max { it.rata }?.rata

            // Controllo che la pratica sia rateizzata
            if (prtr?.tipoAtto?.tipoAtto == 90) {

                // Controllo che la rata sia una rata prevista nella pratica di rateazione
                if (versamentoAnomalo.rata != null && maxRata != null && versamentoAnomalo.rata > (maxRata as int)) {
                    visualizzaMessaggioRate(maxRata)
                    return false
                }

                if (aggiornaIdOperazione) {
                    visualizzaMsgUpdateIdOperazione(idPratica)
                }
            }

        }

        return true
    }

    private associaPratica(def tipo) {

        def idPratica

        switch (tipo) {
            case 'ACCLIQ':
                idPratica = accLiqSelezionato.pratica
                break
            case 'RAVV':
                idPratica = ravvSelezionato.pratica
                break
            default:
                // Drag & Drop
                idPratica = tipo

        }

        def prtr = PraticaTributo.get(idPratica).toDTO(['tipoEvento'])

        praticaAssociata = prtr

        if (prtr.tipoTributo.tipoTributo != versamentoAnomaloSelezionato.tipoTributo.tipoTributo) {
            Clients.showNotification("Tipi di tributo incompatibili.", Clients.NOTIFICATION_TYPE_ERROR,
                    null, "middle_center", 3000, true)
            return
        }

        versamentoAnomalo.identificativoOperazione =
                CommonService.generaIdentificativoOperazione(prtr, prtr?.tipoAtto?.tipoAtto == 90 ? versamentoAnomalo.rata : null)

        BindUtils.postNotifyChange(null, null, this, "versamentoAnomalo")
        BindUtils.postNotifyChange(null, null, this, "praticaAssociata")

    }

    private associaSoggetto(def tipo) {
        switch (tipo) {
            case 'CF':
                versamentoAnomalo.codFiscale = soggettoSelezionato.contribuente?.codFiscale ?: soggettoSelezionato.codFiscale
                break
            case 'PIVA':
                versamentoAnomalo.codFiscale = soggettoSelezionato.partitaIva
                break
        }
    }

    private showNotificaRuoloCoattivo(def pratica) {
        if (pratica?.id && liquidazioniAccertamentiService.inRuoloCoattivo(pratica)) {
            String msg = 'La pratica selezionata è già stata inserita su ruolo coattivo.'
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_WARNING, null, "before_end", 3000, true)
        }
    }

    private boolean checkIdOperazioneDaVersamentoAnomalo() {
        return (bonificaVersamentiService.verificaIdOperazione(versamentoAnomalo.identificativoOperazione)
                && versamentoAnomalo.identificativoOperazione
                && praticaAssociata == null)
    }

// -----------------------------------------------------------------------------------------------------------------
// COMANDI TAB SOGGETTI
// -----------------------------------------------------------------------------------------------------------------

    @Command
    @NotifyChange(['listaSoggetti', 'activePageSoggetti', 'pageSizeSoggetti', 'totalSizeSoggetti'])
    def onCercaSoggetti() {

        // Si deve specificare almeno un archivio
        if (!(filtriSoggetti.soggetti || filtriSoggetti.contribuenti)) {
            Clients.showNotification("Selezionare almeno un archivio.", Clients.NOTIFICATION_TYPE_ERROR,
                    null, "middle_center", 3000, true)

            return
        }

        // Deve essere presente il codice fiscale o la partita iva
        if (!filtriSoggetti.codFiscale && !filtriSoggetti.cognome && !filtriSoggetti.nome) {
            return
        }

        // Filtro da passare al servizio
        def filtro = [:]

        // Codice fiscale
        if (filtriSoggetti.codFiscale) {
            filtro.codFiscale = filtriSoggetti.codFiscale + '%'
        }

        // Cognome
        if (filtriSoggetti.cognome) {
            filtro.cognome = filtriSoggetti.cognome
        }

        // Nome
        if (filtriSoggetti.nome) {
            filtro.nome = filtriSoggetti.nome
        }

        if (filtriSoggetti.soggetti && filtriSoggetti.contribuenti) {
            filtro.contribuente = 'e'
        } else if (filtriSoggetti.contribuenti) {
            filtro.contribuente = 'c'
        } else {
            filtro.contribuente = 's'
        }

        def elenco = soggettiService.listaSoggettiContribuenti(filtro, pageSizeSoggetti, activePageSoggetti,
                ['contribuenti'], sortBySoggetti)
        listaSoggetti = elenco.lista
        totalSizeSoggetti = elenco.totale

        popupFiltriSoggetti?.close()
    }

    @Command
    @NotifyChange(['filtriSoggetti'])
    def onPulisciFiltriSoggetti() {
        filtriSoggetti = [
                cognome     : null,
                nome        : null,
                codFiscale  : null,
                soggetti    : true,
                contribuenti: true
        ]
    }

    @Command
    def onCloseFiltriSoggetti() {
        popupFiltriSoggetti.close()
    }

    @Command
    @NotifyChange(['listaSoggetti', 'activePageSoggetti', 'pageSizeSoggetti', 'totalSizeSoggetti'])
    def onPagingSoggetti() {
        onCercaSoggetti()
    }

    @NotifyChange([
            'listaDettaglioAnomalie',
            'listaDettaglioAnomaliePaginazione'
    ])
    @Command
    def onSortSoggettiSort(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("property") String property) {
        sortBySoggetti = [property: property, direction: event.ascending ? 'asc' : 'desc']
        onCercaSoggetti()
    }

    @Command
    def onSelezionaSoggetto() {

    }

// -----------------------------------------------------------------------------------------------------------------
// COMANDI ACCERTAMENTI/LIQUIDAZIONI
// -----------------------------------------------------------------------------------------------------------------

    @Command
    @NotifyChange(['modificaDataNotificaPratica'])
    def onModificaDataNotificaPratica(@BindingParam("pratica") def praticaSelezionata) {
        if (praticaSelezionata.dataNotifica == null || versamentoAnomalo.dataPagamento < praticaSelezionata.dataNotifica) {

            // Si salva il valore della data di notifica per un eventuale ripristino
            vecchiaDataNotificaPratica = praticaSelezionata.dataNotifica
            modificaDataNotificaPratica = !modificaDataNotificaPratica
            accLiqSelezionato = praticaSelezionata
        } else {
            Clients.showNotification("Operazione non consentita.\nLa data di notifica non deve essere valorizzata o deve essere successiva alla data di pagamento.", Clients.NOTIFICATION_TYPE_INFO,
                    null, "middle_center", 5000, true)
        }

        accLiqListBox.invalidate()
    }

    @Command
    @NotifyChange(['modificaDataNotificaPratica', 'listaAccLiq'])
    def onAnnullaModificaDataNotificaPratica(@BindingParam("pratica") def praticaSelezionata) {
        modificaDataNotificaPratica = false
        praticaSelezionata.dataNotifica = vecchiaDataNotificaPratica
        accLiqSelezionato = null
        accLiqListBox.invalidate()
    }

    @Command
    @NotifyChange(['modificaDataNotificaPratica', 'listaAccLiq'])
    def onAccettaModificaDataNotificaPratica(@BindingParam("pratica") def praticaSelezionata) {

        // Salvataggio della nuova data di notifica
        def prtr = PraticaTributo.get(praticaSelezionata.pratica)
        prtr.dataNotifica = praticaSelezionata.dataNotifica

        def esito = bonificaVersamentiService.aggiornaDataNotificaCheck(prtr)

        if (esito.isEmpty()) {
            bonificaVersamentiService.aggiornaDataNotifica(prtr)
            modificaDataNotificaPratica = false
            accLiqSelezionato = null
            accLiqListBox.invalidate()
            Clients.showNotification("Data di notifica aggiornata correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                    null, "middle_center", 3000, true)
        } else {
            Clients.showNotification(esito, Clients.NOTIFICATION_TYPE_ERROR,
                    null, "middle_center", 3000, true)
        }

    }

// -----------------------------------------------------------------------------------------------------------------
// COMANDI RAVVEDIMENTI
// -----------------------------------------------------------------------------------------------------------------

    @Command
    def onNumeraRavvedimento(@BindingParam("pratica") def ravvedimentoSelezionato) {

        bonificaVersamentiService.numeraPratiche(
                ravvedimentoSelezionato.tipoTributo.tipoTributo, 'V',
                Contribuente.findByCodFiscale(versamentoAnomalo.codFiscale).soggetto.id, versamentoAnomalo.codFiscale,
                ravvedimentoSelezionato.anno, ravvedimentoSelezionato.anno,
                ravvedimentoSelezionato.data, ravvedimentoSelezionato.data
        )

        ravvedimentoSelezionato.numero = PraticaTributo.get(ravvedimentoSelezionato.pratica).numero

        BindUtils.postNotifyChange(null, null, ravvedimentoSelezionato, "numero")

        Clients.showNotification("Pratica numerata correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                null, "middle_center", 3000, true)
    }

}
