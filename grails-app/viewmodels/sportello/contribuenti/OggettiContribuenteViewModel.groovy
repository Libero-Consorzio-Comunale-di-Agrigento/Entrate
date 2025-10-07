package sportello.contribuenti


import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class OggettiContribuenteViewModel {

    CompetenzeService competenzeService
    ContribuentiService contribuentiService

    def azione

    def self

    def cbTributi = [
            ICI  : true,
            TASI : true,
            TARSU: false,
            ICP  : false,
            TOSAP: false
    ]
    def cbTributiScrittura = [
            ICI  : false,
            TASI : false,
            TARSU: false,
            ICP  : false,
            TOSAP: false
    ]
    def cbTipiPratica

    def tipoTributoSelezionato = 'E'
    def tipoPratica = 'D'

    def oggettiSelezionati
    def listaOggetti
    def listaOggettiOrig

    def annoChiusura
    def mesiPossessoChiusura
    def meseInizioPossesso = 1

    def zul
    def vflexOggCat = ''

    def codFiscale
    def annoFiltro = null
    def tipoTributo

    // Proprietà per il riutilizzo della include degli oggetti in catasto
    def oggettiDaCatasto
    def immobileCatastoSelezionato
    def immobiliNonAssociati
    def modificaAnno = true

    // Utilizzato per compatibilità
    def immobiliNonAssociatiCatasto = [:]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("azione") def azione,
         @ExecutionArgParam("dati") def dati,
         @ExecutionArgParam("zul") def zul,
         @ExecutionArgParam("tipiTributo") def tt,
         @ExecutionArgParam("tipiPratica") def tp,
         @ExecutionArgParam("annoFiltro") def annoFiltro
    ) {

        if (!(azione in ['CHIUDI', 'INSERISCI'])) {
            throw new RuntimeException("Azione $azione non supportata.")
        }

        this.self = w

        this.annoFiltro = annoFiltro
        this.annoChiusura = (annoFiltro as Integer)
        this.azione = azione

        this.cbTributi = tt ?: [
                'ICI'  : true,
                'TASI' : true,
                'TARSU': false,
                'ICP'  : false,
                'TOSAP': false
        ]

        // Al momento si gestiscono solo IMU e TASI
        this.cbTributiScrittura = [
                'ICI'  : competenzeService.utenteAbilitatoScrittura('ICI'),
                'TASI' : competenzeService.utenteAbilitatoScrittura('TASI'),
                'TARSU': false,
                'ICP'  : false,
                'TOSAP': false
        ]

        // Disabilita tributi non in scrittura
        if (!this.cbTributiScrittura.ICI) {
            this.cbTributi.ICI = false
        }
        if (!this.cbTributiScrittura.TASI) {
            this.cbTributi.TASI = false
        }
        if (!this.cbTributiScrittura.TARSU) {
            this.cbTributi.TARSU = false
        }
        if (!this.cbTributiScrittura.ICP) {
            this.cbTributi.ICP = false
        }
        if (!this.cbTributiScrittura.TOSAP) {
            this.cbTributi.TOSAP = false
        }

        listaOggettiOrig = dati.oggetti
        oggettiDaCatasto = dati.oggetti

        if (azione == 'CHIUDI') {
            filtraOggetti()
        } else if (azione == 'INSERISCI') {
            this.modificaAnno = false
            this.tipoTributoSelezionato = 'ICI'
        }

        this.zul = zul
        this.codFiscale = dati.codFiscale

    }

    @Command
    def onChiudiOggetti() {
        def msg = controlliChiusura()
        if (msg) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            return
        }

        def aggiuntaAp = false
        def aggiuntePrtinenze = false

        oggettiSelezionati.each { ogg ->

            // Se pertinenza, deve essere selezionata l'ap e se esitono le altre pertinenze
            if (ogg.oggettoPraticaRifAp) {
                def ap = listaOggetti.findAll { it.oggettoPratica == ogg.oggettoPraticaRifAp }[0]
                def pertinenze = listaOggetti.findAll { it.oggettoPraticaRifAp == ogg.oggettoPratica }

                if (ap && !(ap in oggettiSelezionati)) {
                    oggettiSelezionati << ap
                    aggiuntaAp = true
                }

                pertinenze.each {
                    if (!(it in oggettiSelezionati)) {
                        oggettiSelezionati << it
                        aggiuntePrtinenze = true
                    }
                }

            }

            def pertinenze = listaOggetti.findAll { it.oggettoPraticaRifAp == ogg.oggettoPratica }
            pertinenze.each {
                if (!(it in oggettiSelezionati)) {
                    oggettiSelezionati << it
                    aggiuntePrtinenze = true
                }
            }
        }
        BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")

        String messaggio = ""
        if (aggiuntaAp) {
            messaggio += "All'elenco sono state aggiunte una o più abitazioni pricipali.\n"
        }
        if (aggiuntePrtinenze) {
            messaggio += "All'elenco sono state aggiunte una o più pertinenze.\n"
        }

        messaggio += "Procedere con la chiusura?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            contribuentiService.chiudiOggetti(codFiscale, annoChiusura, annoFiltro, mesiPossessoChiusura, meseInizioPossesso, oggettiSelezionati.collect {
                                [oggetto: it.oggetto, tipoTributo: it.tipoTributo, tipoRapporto: it.tipoRapporto == 'E' ? it.tipoRapportoOgim : it.tipoRapporto]
                            })

                            Events.postEvent(Events.ON_CLOSE, self, [oggettiChiusi: true])
                        }
                    }
                }
        )
    }

    @Command
    def onInserisciOggetti() {

        def msg = controlliInserimento()
        if (msg) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            return
        }

        def tipiTributo = [:]
        if (tipoTributoSelezionato == 'E' || tipoTributoSelezionato == 'ICI') {
            tipiTributo << ['ICI': true]
        }

        def result = contribuentiService.inserisciOggetti(
                codFiscale,
                annoChiusura as short,
                annoFiltro as short,
                tipiTributo,
                mesiPossessoChiusura,
                oggettiSelezionati,
                tipoPratica
        )
        if (!result?.messaggi?.isEmpty()) {
            Clients.showNotification(messaggi, Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        }

        Events.postEvent(Events.ON_CLOSE, self, [oggettiChiusi: true, pratica : result.pratica])
    }


    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onChangeTipoTributo() {
        if (azione == 'CHIUDI') {
            filtraOggetti()
        }
    }

    @NotifyChange(["mesiPossessoChiusura", "meseInizioPossesso"])
    @Command
    def onChangeMesiPossessoChiusura() {
        if (mesiPossessoChiusura == null || mesiPossessoChiusura > 0) {
            meseInizioPossesso = 1
        }

        if (mesiPossessoChiusura == 0) {
            meseInizioPossesso = null
        }
    }

    @NotifyChange(["meseInizioPossesso"])
    @Command
    def onSelezionaRiga() {
        gestisciMesiInizioPossesso()
    }

    @NotifyChange(["meseInizioPossesso"])
    @Command
    def onCambiaAnno() {
        gestisciMesiInizioPossesso()
    }

    // Per compatibilità
    @Command
    def onSelezionaOggettoCatasto() {}

    private def controlliChiusura() {

        def mesiIncongruenti = ""
        oggettiSelezionati.each {
            if (it.anno == annoChiusura && it.mesiPossesso < mesiPossessoChiusura) {
                mesiIncongruenti = "Mesi di cessazione maggiori dei mesi di possesso per l'oggetto: [$it.oggetto - $it.tributoDescrizione - $it.anno]\n"
            }
        }

        def errori = controlli()
        if (meseInizioPossesso != null && !(meseInizioPossesso in (0..12))) {
            errori += "Valore non valido per mese inizio possesso.\n"
        }
        if (!(mesiPossessoChiusura in (0..12))) {
            errori += "Valore non valido per mesi possesso.\n"
        }
        if (!mesiIncongruenti.isEmpty()) {
            errori += mesiIncongruenti
        }

        return errori.empty ? null : errori
    }

    private def controlliInserimento() {
        def errori = controlli()
        if (tipoTributoSelezionato == 'TASI' && annoChiusura < 2014) {
            errori += "Impossibile inserire pratiche TASI per annualità precedenti al 2014.\n"
        }

        return errori.empty ? null : errori
    }

    private controlli() {
        def errori = ""
        if (!annoChiusura) {
            errori += "Indicare l'anno.\n"
        }
        if (annoChiusura && (annoChiusura as String).length() < 4) {
            errori += "Valore non valido per anno.\n"
        }
        if (!oggettiSelezionati || oggettiSelezionati.isEmpty()) {
            errori += "Selezionare almeno un oggetto dalla lista.\n"
        }
        if (azione == 'CHIUDI' && cbTributi.findAll { k, v -> v }.isEmpty()) {
            errori += "Indicare almeno un tributo.\n"
        }
        return errori
    }

    private filtraOggetti() {
        if (azione != 'CHIUDI') {
            throw new IllegalStateException("Impossibile filtrare gli oggetti se aperta maschera in modalità $azione")
        }
        listaOggetti = listaOggettiOrig.findAll {
            cbTributi[it.tipoTributo]
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    private gestisciMesiInizioPossesso() {
        if (annoChiusura) {
            if ((!oggettiSelezionati || oggettiSelezionati.isEmpty()) && meseInizioPossesso == null) {
                meseInizioPossesso = 1
            } else {
                def annoUguale = false
                oggettiSelezionati.each {
                    if (it.anno == annoChiusura) {
                        annoUguale = true
                    }
                }
                if (annoUguale) {
                    meseInizioPossesso = null
                } else if (meseInizioPossesso == null) {
                    meseInizioPossesso = 1
                }
            }
        }
    }
}

