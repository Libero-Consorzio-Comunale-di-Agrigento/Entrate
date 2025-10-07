package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.tr4.Funzioni
import it.finmatica.tr4.Si4Competenze
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.export.XlsxExporter
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CompetenzeViewModel {

    private static final Logger log = Logger.getLogger(CompetenzeViewModel.class)

    Window self
    CompetenzeService competenzeService
    CommonService commonService
    TributiSession tributiSession

    // TAB UTENTI
    def tipoTributoSelezionato
    List<LinkedHashMap> listaTipiTributoPerUtente
    def selectedEditable

    List<Ad4UtenteDTO> listaUtentiConCompetenze
    def chosenUser

    // TAB TIPI TRIBUTO
    List<Si4Competenze> listaUtentiPerOggetto
    def utenteSelezionato

    TipoTributoDTO tipoTributo
    List<TipoTributoDTO> listaTipiTributo

    // TAB FUNZIONI
    def listaUtentiPerFunzione
    def utenteDiFunzioneSelezionato

    def listaFunzioni
    def funzioneScelta


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        listaTipiTributo = OggettiCache.TIPI_TRIBUTO.valore.sort { it.tipoTributo }
        tipoTributo = listaTipiTributo[0]
        onCambiaTributo()

        listaFunzioni = competenzeService.listaFunzioni().findAll { it.flagVisibile }
        funzioneScelta = !listaFunzioni.empty ? listaFunzioni[0] : null
        onCambiaFunzione()

        listaUtentiConCompetenze = competenzeService.listaUtentiConCompetenze()
        chosenUser = listaUtentiConCompetenze[0]
        onCambioUtente()

    }


    @Command
    def onRefreshAll() {
        onCambioUtente()
        onCambiaTributo()
        onCambiaFunzione()
    }

    // METODI TAB UTENTI

    @Command
    def onRefreshPersone() {
        onCambioUtente()
    }

    @Command
    def onCambioUtente() {

        listaTipiTributoPerUtente = competenzeService.tipoTributiPerUtente(chosenUser.id)

        BindUtils.postNotifyChange(null, null, this, "listaTipiTributoPerUtente")
    }

    @Command
    onSelectUtente() {
        selectedEditable = competenzeService.isCompetenzaEditable(tipoTributoSelezionato)
        BindUtils.postNotifyChange(null, null, this, 'selectedEditable')
    }

    @Command
    def onModificaCompetenzaUtente() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCompetenzaUtente.zul", self,
                [
                        tipoOggetto         : tipoTributoSelezionato.si4Abilitazioni.si4TipiOggetto.id,
                        utente              : chosenUser,
                        competenza: commonService.clona(tipoTributoSelezionato)
                ],
                { event ->
                    if (event?.data?.salvato) {
                        Clients.showNotification("Competenza salvata", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        onRefreshAll()
                    }
                })
    }

    @Command
    def onAggiungiCompetenzaUtente(@BindingParam("tipo") def tipo) {


        def tipoOggetto = tipo == "tributo" ? CompetenzeService.TIPO_OGGETTO : CompetenzeService.TIPO_FUNZIONI

        commonService.creaPopup("/archivio/dizionari/dettaglioCompetenzaUtente.zul", self,
                [
                        tipoOggetto          : tipoOggetto,
                        utente               : chosenUser
                ],
                { event ->
                    if (event?.data?.salvato) {
                        Clients.showNotification("Competenza salvata", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        onRefreshAll()
                    }
                })
    }

    @Command
    def onEliminaCompetenzaUtente() {
        String messaggio = "Eliminare la competenza per l'utente?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            log.debug("Puoi eliminare la competenza ...")
                            Clients.showNotification("Competenza eliminata", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                            competenzeService.eliminaCompetenza(tipoTributoSelezionato)
                            onRefreshAll()
                        }
                    }

                }
        )
    }

    @Command
    def onExportXlsUtenti() {

        Map fields

        if (!listaTipiTributoPerUtente) {
            return
        }

        fields = [
                "descrizioneTributo"                             : "Oggetto",
                "si4Abilitazioni.si4TipiAbilitazione.descrizione": "Tipologia",
                "tipoOggettoDesc"                                : "Tipo Oggetto",
                "dal"                                            : "Dal",
                "al"                                             : "Al"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPETENZE,
                [utente: chosenUser.nominativo])

        XlsxExporter.exportAndDownload(nomeFile, listaTipiTributoPerUtente, fields)
    }


    // METODI TAB TIPI TRIBUTO

    @Command
    def onRefreshTributi() {
        onCambiaTributo()
    }

    @Command
    def onCambiaTributo() {

        listaUtentiPerOggetto = competenzeService.competenzePerOggetto(tipoTributo.tipoTributo, CompetenzeService.TIPO_OGGETTO)

        BindUtils.postNotifyChange(null, null, this, "listaUtentiPerOggetto")
    }

    @Command
    def onDettaglioUtente() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCompetenza.zul",
                self,
                [competenza: commonService.clona(utenteSelezionato), tipoOggetto: CompetenzeService.TIPO_OGGETTO],
                { event ->
                    if (event.data?.salvato) {
                        onCambiaTributo()
                    }
                })
    }

    @Command
    def onInserimentoCompetenzaTributi() {
        inserimentoCompetenza(tipoTributo.tipoTributo, CompetenzeService.TIPO_OGGETTO)
    }

    @Command
    void onEliminaCompetenzaTributo() {
        eliminaCompetenza(CompetenzeService.TIPO_OGGETTO)
    }

    @Command
    def onExportXlsTipiTributo() {

        Map fields

        if (!listaUtentiPerOggetto) {
            return
        }

        fields = [
                "utente.id"                                      : "Nominativo",
                "si4Abilitazioni.si4TipiAbilitazione.descrizione": "Tipologia",
                "dal"                                            : "Dal",
                "al"                                             : "Al"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPETENZE,
                [tipoTributo: tipoTributo.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaUtentiPerOggetto, fields)
    }


    // METODI TAB FUNZIONI

    @Command
    def onRefreshFunzioni() {
        onCambiaFunzione()
    }

    @Command
    def onCambiaFunzione() {

        String funzione = funzioneScelta?.funzione ?: ''
        listaUtentiPerFunzione = competenzeService.competenzePerOggetto(funzione, CompetenzeService.TIPO_FUNZIONI)

        BindUtils.postNotifyChange(null, null, this, "funzioneScelta")
        BindUtils.postNotifyChange(null, null, this, "listaUtentiPerFunzione")
    }

    @Command
    def onDettaglioUtenteDiFunzione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCompetenza.zul",
                self,
                [competenza: commonService.clona(utenteDiFunzioneSelezionato), tipoOggetto: CompetenzeService.TIPO_FUNZIONI],
                { event ->
                    if (event.data?.salvato) {
                        onCambiaFunzione()
                    }
                })
    }

    @Command
    def onInserimentoCompetenzaFunzioni() {
        inserimentoCompetenza(funzioneScelta.funzione, CompetenzeService.TIPO_FUNZIONI)
    }

    @Command
    void onEliminaCompetenzaFunzione() {
        eliminaCompetenza(CompetenzeService.TIPO_FUNZIONI)
    }

    @Command
    def onExportXlsFunzioni() {

        Map fields

        if (!listaUtentiPerFunzione) {
            return
        }

        fields = [
                "utente.id"                                      : "Nominativo",
                "si4Abilitazioni.si4TipiAbilitazione.descrizione": "Tipologia",
                "dal"                                            : "Dal",
                "al"                                             : "Al"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPETENZE,
                [funzione: funzioneScelta.funzione])

        XlsxExporter.exportAndDownload(nomeFile, listaUtentiPerFunzione, fields)
    }

    // PRIVATI

    private void inserimentoCompetenza(String oggettoCompetenza, Long tipoOggetto) {

        commonService.creaPopup("/archivio/dizionari/inserimentoCompetenza.zul",
                self,
                [
                        oggettoCompetenza: oggettoCompetenza,
                        tipoOggetto      : tipoOggetto
                ],
                { event ->
                    if (event.data?.salvato) {
                        log.debug("tipoOggetto : $tipoOggetto")
                        if (tipoOggetto == CompetenzeService.TIPO_OGGETTO) {
                            onCambiaTributo()
                        } else {
                            onCambiaFunzione()
                        }

                    }
                })
    }

    private void eliminaCompetenza(Long tipoOggetto) {

        String messaggio = "Eliminare la competenza per l'utente?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            log.debug("Puoi eliminare la competenza ...")
                            if (tipoOggetto == CompetenzeService.TIPO_OGGETTO) {
                                competenzeService.eliminaCompetenza(utenteSelezionato)
                                onCambiaTributo()
                            } else {
                                competenzeService.eliminaCompetenza(utenteDiFunzioneSelezionato)
                                onCambiaFunzione()
                            }

                        }
                    }

                }
        )
    }
}
