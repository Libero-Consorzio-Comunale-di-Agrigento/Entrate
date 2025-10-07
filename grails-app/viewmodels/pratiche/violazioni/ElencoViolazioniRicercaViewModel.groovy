package pratiche.violazioni

import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.violazioni.FiltroRicercaViolazioni
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ElencoViolazioniRicercaViewModel {

    // componenti
    Window self

    RateazioneService rateazioneService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService

    def titolo

    def tipoTributo
    def tipoPratica

    // dati
    def lista
    def selected
    Date dataDefault = new Date().clearTime()
    Date aData = dataDefault

    //Stato
    def tipiStato = []

    //Atto
    def tipiAtto = []
    def tipoAttoSelezionato
    boolean isRateizzazioneSelezionata = false

    FiltroRicercaViolazioni mapParametri

    def tipiRata

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    def listaCodicitributo = OggettiCache.CODICI_TRIBUTO.valore.findAll {
        it.tipoTributo?.tipoTributo == 'TARSU'
    }.sort { it.id }

    def listaTitoliOccupazione = [
            0: '',
            1: '1 - Proprietà',
            2: '2 - Usufrutto',
            3: '3 - Locatario',
            4: '4 - Altro diritto reale di godimento'
    ]

    def listaNatureOccupazione = [
            0: '',
            1: '1 - Per singolo',
            2: '2 - Per nucleo familiare',
            3: '3 - Presenza di attività commerciale',
            4: '4 - Altra tipologia di occupante'
    ]

    def listaDestinazioniUso = [
            0: '',
            1: '1 - Per uso abitativo',
            2: '2 - Per immobile tenuto a disposizione',
            3: '3 - Per uso commerciale',
            4: '4 - Per locali adibiti a box',
            5: '5 - Per altri usi'
    ]

    def listaAssenzaEstremiCat = [
            0: '',
            1: '1 - Immobile non accatastato',
            2: '2 - Immobile non accatastabile',
            3: '3 - Dati non disponibili per la comunicazione corrente'
    ]

    def listaTipiNotifica = []

    def disabilitaANumero = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tipoPratica") String tipoPratica,
         @ExecutionArgParam("parRicerca") FiltroRicercaViolazioni parametriRicerca) {

        this.self = w

        tipiStato.add(new TipoStato(tipoStato: null, descrizione: "Nessuno"))
        tipiStato.addAll(OggettiCache.TIPI_STATO.valore.sort {
            (String.format("%5s", (it.numOrdine ?: 99999) as String) + it.tipoStato).replace(' ', '0')
        })

        tipiAtto.add(new TipoAtto(tipoAtto: null, descrizione: "Nessuno"))
        tipiAtto.addAll(OggettiCache.TIPI_ATTO.valore.sort {
            it.descrizione
        })

        tipiRata = rateazioneService.tipiRata
        this.tipoTributo = tipoTributo
        this.tipoPratica = tipoPratica
        mapParametri = parametriRicerca ?: new FiltroRicercaViolazioni()
        mapParametri.tuttiTipiStatoSelezionati = false
        mapParametri.tuttiTipiAttoSelezionati = false

        titolo = "Ricerca Avanzata "
        switch (tipoPratica) {
            case 'A':
                titolo += "Accertamenti"
                break
            case 'L':
                titolo += "Liquidazioni"
                break
            case 'V':
                titolo += "Ravvedimenti Operosi"
                break
            case '*':
                titolo += "Pratiche Rateizzate"
                break
            default:
                titolo += "Pratiche"
        }

        // Rateazione
        if (tipoPratica == '*') {
            tipoAttoSelezionato = tipiAtto.find { it?.tipoAtto == 90 }
            mapParametri.tipiAttoSelezionati = [tipoAttoSelezionato]
            BindUtils.postNotifyChange(null, null, this, "tipoAttoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "mapParametri")
        }

        listaTipiNotifica = [null] + liquidazioniAccertamentiService.getTipiNotifica()

        onSelectTipoAtto()
        onSelectTipoStato()

        onCambiaNumero()
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        mapParametri.indirizzo = event.data
        mapParametri.indirizzoDenomUff = (event.data.denomUff ?: null)
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    def onChangeIndirizzo() {
        if (mapParametri.indirizzoDenomUff.isEmpty()) {
            mapParametri.indirizzo = null
        }
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    onCerca() {
		if(!(mapParametri.filtroAttivoPerTipoPratica(this.tipoPratica))) {
			Clients.showNotification("Nessun parametro di ricerca indicato", Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
			return
		}
        def errori = mapParametri.validate()
        if (!errori.isEmpty()) {
            Clients.showNotification(errori, Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [mapParametri: mapParametri])
    }

    @Command
    def onCheckDaStampare() {
        // Se si seleziona il flag daStampare si annullano le date
        /* TODO: al momento logica disattivata, si permette di filtrare su daStampare e stampati da/a
        if (mapParametri.daStampare) {
            mapParametri.daDataStampa = null
            mapParametri.aDataStampa = null
            BindUtils.postNotifyChange(null, null, this, "mapParametri")
        }
         */
    }

    @Command
    svuotaFiltri() {

        mapParametri = new FiltroRicercaViolazioni()

        // Rateazione
        if (tipoPratica == '*') {
            tipoAttoSelezionato = tipiAtto.find { it?.tipoAtto == 90 }
            mapParametri.tipiAttoSelezionati = [tipoAttoSelezionato]
            BindUtils.postNotifyChange(null, null, this, "tipoAttoSelezionato")
        }

        disabilitaANumero = false

        BindUtils.postNotifyChange(null, null, this, "mapParametri")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiAttoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiStatoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "disabilitaANumero")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onSelectTipoStato() {
        if (mapParametri?.tipiStatoSelezionati && mapParametri?.tipiStatoSelezionati?.size() == tipiStato.size()) {
            mapParametri.tuttiTipiStatoSelezionati = true
        } else {
            mapParametri.tuttiTipiStatoSelezionati = false
        }
        BindUtils.postNotifyChange(null, null, this, "elencoTipiStatoSelezionati")
    }

    String getElencoTipiStatoSelezionati() {

        return mapParametri.tipiStatoSelezionati?.descrizione?.join(", ")
    }

    @Command
    onSelectTipoAtto() {
        if (mapParametri?.tipiAttoSelezionati && mapParametri?.tipiAttoSelezionati?.size() >= tipiAtto.size()) {
            mapParametri.tuttiTipiAttoSelezionati = true
        } else {
            mapParametri.tuttiTipiAttoSelezionati = false
        }

        ArrayList lista = mapParametri?.tipiAttoSelezionati?.collect { t -> t.tipoAtto }
        isRateizzazioneSelezionata = (lista.find { it == 90 }) ? true : false

        BindUtils.postNotifyChange(null, null, this, "tipoAttoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "isRateizzazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiAttoSelezionati")
    }

    @Command
    def onCambiaNumero() {

        def errors = controllaNumero()

        if (errors != null) {
            Clients.showNotification(errors, Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
        }

    }

    String getElencoTipiAttoSelezionati() {

        return mapParametri.tipiAttoSelezionati?.descrizione?.join(", ")
    }

    private def controllaNumero() {

        def daNumero = mapParametri?.daNumeroPratica
        def aNumero = mapParametri?.aNumeroPratica

        def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
        def isANumeroNotEmpty = aNumero != null && aNumero != ""

        if (isDaNumeroNotEmpty && daNumero.contains('%')) {
            disabilitaANumero = true
            mapParametri.aNumeroPratica = null
        } else {
            disabilitaANumero = false
        }

        BindUtils.postNotifyChange(null, null, this, "disabilitaANumero")
        BindUtils.postNotifyChange(null, null, this, "mapParametri")

        if (isANumeroNotEmpty && aNumero.contains('%')) {
            return "Carattere '%' non consentito nel campo Numero A"
        }

        // Nel caso in cui sia dal che al contengono un valore numerico si controlla che dal < al
        if (isANumeroNotEmpty && isDaNumeroNotEmpty && daNumero.isNumber() && aNumero.isNumber()) {
            if ((aNumero as Long) < (daNumero as Long)) {
                return "Numero Dal deve essere minore di Numero Al"
            }
        }

        return null
    }
}
