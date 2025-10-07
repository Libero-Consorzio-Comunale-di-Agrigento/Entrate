package ufficiotributi.bonificaDati

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.InstallazioneParametro
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

abstract class AnomalieDatiCatastaliViewModel {

    Window self

    long idOggetto
    long idAnomalia
    OggettoDTO oggettoDTO

    def immobileArchivioSelezionato
    def immobileCatastoSelezionato

    ContribuentiService contribuentiService
    IntegrazioneWEBGISService integrazioneWEBGISService

    def oggettiDaArchivio = []
    def oggettiDaCatasto = []

    boolean disabilitaSostituzione = false
    boolean salva = true
	boolean lettura = false

    OggettiService oggettiService
    CatastoCensuarioService catastoCensuarioService
    GestioneAnomalieService gestioneAnomalieService
    ControlloAnomalieService controlloAnomalieService
    BonificaDatiService bonificaDatiService

    List<FiltroRicercaOggetto> listaFiltri
    List<FiltroRicercaOggetto> listaFiltriCatasto

    boolean categoriaCatastoModificata = false

    short tipoAnomalia

    def proprietarioCatasto

    def abilitaMappe = false

    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true]

    def cbTipiPratica = [
            D  : true    // dichiarazione D
            , A: true    // accertamento A
            , L: true    // liquidazione L
            , I: true    // infrazioni I
            , R: true    // ravvedimenti R
            , V: true]    // versamenti V

    def listaContribuenti
    def listaProprietari

    def contribuenteSelezionato

    def filtri = [indirizzo         : null
                  , tipoOggetto     : null
                  , categoriaCatasto: null
                  , codFiscale      : ""]

    @NotifyChange("oggettoDTO")
    @Command
    onCopiaDatiCatasto(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        def oggDrag = (event.dragged.getAttribute("foo") == null ? event.dragged.getAttribute("catasto") : event.dragged.getAttribute("foo"))

        if (tipoAnomalia != 9 as Short) {
            oggettoDTO.sezione = oggDrag.sezione ?: oggDrag.SEZIONE
            oggettoDTO.foglio = oggDrag.foglio ?: oggDrag.FOGLIO
            oggettoDTO.numero = oggDrag.numero ?: oggDrag.NUMERO
            oggettoDTO.subalterno = oggDrag.subalterno ?: oggDrag.SUBALTERNO
            oggettoDTO.partita = oggDrag.partita ?: oggDrag.PARTITA
        } else {
            categoriaCatastoModificata = oggettoDTO.categoriaCatasto.categoriaCatasto != oggDrag.categoriaCatasto
            oggettoDTO.categoriaCatasto = CategoriaCatasto.get(oggDrag.categoriaCatasto).toDTO()
        }

        disabilitaSostituzione = true
        BindUtils.postNotifyChange(null, null, this, "disabilitaSostituzione")
        BindUtils.postNotifyChange(null, null, this, "copia")
    }


    @NotifyChange("copia")
    @Command
    abilitaSalva() {
        //salva = false
    }

    @Command
    onSostituisci() {
        def immobileSelezionato = [:];

        // Se è selezionato un oggetto da catasto la sostutuzione è permessa solo se non sono presenti
        // oggetti simili in archivio, in questocaso si da un messaggio e si blocca l'operazione.
        if (immobileCatastoSelezionato) {
            List<FiltroRicercaOggetto> listaFiltriCheck =
                    [
                            new FiltroRicercaOggetto(id: 0,
                                    sezione: immobileCatastoSelezionato.sezione,
                                    foglio: immobileCatastoSelezionato.foglio,
                                    numero: immobileCatastoSelezionato.numero,
                                    subalterno: immobileCatastoSelezionato.subalterno,
                                    categoriaCatasto: immobileCatastoSelezionato.categoriaCatasto != null ? CategoriaCatasto.get(immobileCatastoSelezionato.categoriaCatasto).toDTO() : null)
                    ]
            if (!oggettiService.listaOggetti(listaFiltriCheck, 0, 0, null).lista.isEmpty()) {
                Messagebox.show("Operazione non consentita: esistono oggetti in archivio con le stesse caratteristiche dell'oggetto selezionato.",
                        "Bonifica dati", Messagebox.OK, Messagebox.INFORMATION)
                return false
            }

            String fontBonCcValore = InstallazioneParametro.get('FONT_BONCC')?.valore
            if (!fontBonCcValore) {
                Messagebox.show("Fonte non presente in Installazione Parametri, per la sostituzione da Catasto Censuario.",
                        "Bonifica dati", Messagebox.OK, Messagebox.ERROR)
                return false
            }

            FonteDTO fonte = Fonte.get(InstallazioneParametro.get('FONT_BONCC').valore)?.toDTO()
            if (!fonte) {
                Messagebox.show("Fonte non presente in Fonti, per la sostituzione da Catasto Censuario.",
                        "Bonifica dati", Messagebox.OK, Messagebox.ERROR)
                return false
            }

            String indirizzoLocalita = immobileCatastoSelezionato.indirizzo + ", " + immobileCatastoSelezionato.civico
            if (indirizzoLocalita.length() > 36) {
                indirizzoLocalita = indirizzoLocalita.substring(36)
            }

            // Se l'oggetto non è presente in archivio si crea.
            OggettoDTO nuovoOggetto = new OggettoDTO(
                    tipoOggetto: TipoOggetto.get(3).toDTO(),
                    indirizzoLocalita: indirizzoLocalita,
                    sezione: immobileCatastoSelezionato.sezione,
                    foglio: immobileCatastoSelezionato.foglio,
                    numero: immobileCatastoSelezionato.numero,
                    subalterno: immobileCatastoSelezionato.subalterno,
                    zona: immobileCatastoSelezionato.zona,
                    categoriaCatasto: immobileCatastoSelezionato.categoriaCatasto != null ? CategoriaCatasto.get(immobileCatastoSelezionato.categoriaCatasto).toDTO() : null,
                    classeCatasto: immobileCatastoSelezionato.classe,
                    fonte: Fonte.get(InstallazioneParametro.get('FONT_BONCC').valore).toDTO()
            )

            immobileSelezionato.idOggetto = oggettiService.salvaOggetto(nuovoOggetto, null, false).id

        } else {
            immobileSelezionato = immobileArchivioSelezionato
        }

        Map dettaglioOggetto = [tipoTributo   : null
                                , cfContr     : null
                                , idOldOggetto: idOggetto
                                , idNewOggetto: immobileSelezionato.idOggetto]

        Window wSostituzione = Executions.createComponents("/sportello/contribuenti/sostituzioneOggetto.zul", self, [dettaglioOggetto: dettaglioOggetto, sostituisciDaAnomalie: true])

        wSostituzione.onClose { e ->
            if (e.data) {
                // Se la sostituzione è da catasto e si annulla si elimina l'oggetto creato in archivio
                if (e.data?.annulla && immobileCatastoSelezionato) {
                    oggettiService.eliminaOggetto(immobileSelezionato.idOggetto)
                }
                onChiudi()
            }
        }
        wSostituzione.doModal()
    }

    @Command
    onSalvaAnomalia(@BindingParam("aggiornaStato") boolean aggiornaStato) {

        if (categoriaCatastoModificata) {
            Messagebox.show("La categoria catastale è stata modificata. Si vogliono aggiornare anche le denunce relative?",
                    "Bonifica dati", Messagebox.YES | Messagebox.NO,
                    Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
                public void onEvent(Event evt) throws InterruptedException {
                    if (evt.getName().equals("onYes")) {
                        salvaAnomalia(aggiornaStato, true)
                    } else {
                        salvaAnomalia(aggiornaStato)
                    }
                }
            })
        } else {
            salvaAnomalia(aggiornaStato)
        }
    }

    def salvaAnomalia(boolean aggiornaStato, boolean aggiornaDenunce = false) {

        oggettoDTO = gestioneAnomalieService.aggiornaEstremiCatasto(oggettoDTO, aggiornaDenunce)

        if (aggiornaStato) {
            bonificaDatiService.cambiaStatoAnomaliaOggetto(idAnomalia)
            controlloAnomalieService.checkAnomalia(idAnomalia)
        }

        Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true);

        BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCopiaEstremi() {
        //salva = false

        if (immobileArchivioSelezionato) {
            oggettoDTO.sezione = immobileArchivioSelezionato?.sezione
            oggettoDTO.foglio = immobileArchivioSelezionato?.foglio
            oggettoDTO.numero = immobileArchivioSelezionato?.numero
            oggettoDTO.partita = immobileArchivioSelezionato?.partita
            oggettoDTO.subalterno = immobileArchivioSelezionato?.subalterno
        } else {
            oggettoDTO.sezione = immobileCatastoSelezionato?.sezione
            oggettoDTO.foglio = immobileCatastoSelezionato?.foglio
            oggettoDTO.numero = immobileCatastoSelezionato?.numero
            oggettoDTO.partita = immobileCatastoSelezionato?.partita
            oggettoDTO.subalterno = immobileCatastoSelezionato?.subalterno
        }

        BindUtils.postNotifyChange(null, null, this, "salva")
        BindUtils.postNotifyChange(null, null, this, "oggettoDTO")
    }

    @Command
    onSelezionaOggetto(@BindingParam("fonte") String fonte) {

        if (fonte == 'archivio') {
            immobileCatastoSelezionato = null
            listaContribuenti = contribuentiService.getContribuentiOggetto(immobileArchivioSelezionato.idOggetto, null, cbTributi, cbTipiPratica).lista

            BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
        } else {
            immobileArchivioSelezionato = null

            listaProprietari = catastoCensuarioService.getProprietariCatastoCensuario(immobileCatastoSelezionato.IDIMMOBILE, immobileCatastoSelezionato.TIPOOGGETTO)

            BindUtils.postNotifyChange(null, null, this, "listaProprietari")
        }

        BindUtils.postNotifyChange(null, null, this, "immobileArchivioSelezionato")
        BindUtils.postNotifyChange(null, null, this, "immobileCatastoSelezionato")
    }

    @Command
    onCerca() {

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
    onCercaCatasto() {

        Window w = Executions.createComponents("/catasto/listaOggettiCatastoRicerca.zul", self,
                [
                        filtri             : listaFiltriCatasto,
                        ricercaContribuente: true
                ])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    listaFiltriCatasto = event.data.filtri
                    caricaListaCatasto()
                }
            }
        }

        w.doModal()
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtri.indirizzo = (event.data.denomUff ?: null)

        oggettoDTO.archivioVie = event.data
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeTipoTributo() {
        listaContribuenti = contribuentiService.getContribuentiOggetto(immobileArchivioSelezionato.idOggetto, null, cbTributi, cbTipiPratica).lista

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
    }

    @Command
    onChangeTipoPratica() {
        listaContribuenti = contribuentiService.getContribuentiOggetto(immobileArchivioSelezionato.idOggetto, null, cbTributi, cbTipiPratica).lista

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
    }

    private caricaLista() {

        oggettiDaArchivio = []

        def lista = oggettiService.listaOggetti(listaFiltri, 0, 0, null)

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

        BindUtils.postNotifyChange(null, null, this, "oggettiDaArchivio")
    }

    @Command
    void onDenunciaDaCatasto() {
        creaPopup("/pratiche/denunce/denunciaDaCatasto.zul", [codFiscale: proprietarioCatasto.CODFISCALE])
    }

    @Command
    void onInserimentoOggettiRendite() {
        creaPopup("/catasto/inserimentoOggettiRendite.zul", [
                immobile    : immobileCatastoSelezionato.IDIMMOBILE,
                tipoImmobile: immobileCatastoSelezionato.TIPOOGGETTO])
    }

    @Command
    void onVisualizzaMappa(@BindingParam("fonte") String fonte) {

        Window w = Executions.createComponents("/archivio/oggettiWebGis.zul", self
                , [oggetti: fonte == 'A' ? oggettiDaArchivio : oggettiDaCatasto,
                   zul    : fonte == 'A' ? '/archivio/oggettiWebGisArchivio.zul' : '/archivio/oggettiWebGisCatasto.zul'])

        w.doModal()

/**
        integrazioneWEBGISService.openWebGis([[ tipoOggetto : immobileCatastoSelezionato?.tipoOggetto ?: -1,
        										sezione: immobileCatastoSelezionato?.SEZIONE ?: immobileArchivioSelezionato?.sezione ?: '',
        										foglio : immobileCatastoSelezionato?.FOGLIO ?: immobileArchivioSelezionato.foglio,
        										numero : immobileCatastoSelezionato?.NUMERO ?: immobileArchivioSelezionato.numero]])
**/
    }

    @Command
    void onVisualizzaMappaOggetto() {
		
        integrazioneWEBGISService.openWebGis([[	tipoOggetto : oggettoDTO.tipoOggetto,
												sezione: oggettoDTO.sezione ?: '',
												foglio : oggettoDTO.foglio,
												numero : oggettoDTO.numero]])
    }

    protected void creaPopup(String zul, def parametri, def onClose = {}) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }

    private caricaListaCatasto() {
        if (listaFiltriCatasto[0].tipoOggettoCatasto == "F") {
            oggettiDaCatasto = catastoCensuarioService.getImmobiliCatastoUrbano(listaFiltriCatasto)
        } else {
            oggettiDaCatasto = catastoCensuarioService.getTerreniCatastoUrbano(listaFiltriCatasto)
        }
        BindUtils.postNotifyChange(null, null, this, "oggettiDaCatasto")
    }
}
