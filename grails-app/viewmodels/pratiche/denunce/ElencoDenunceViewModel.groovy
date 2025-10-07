package pratiche.denunce

import document.FileNameGenerator
import it.finmatica.tr4.Si4Competenze
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.denunce.CampiOrdinamento
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.denunce.FiltroRicercaDenunce
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import it.finmatica.tr4.portale.IntegrazionePortaleService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ElencoDenunceViewModel {

    // componenti
    Window self

    // services
    def springSecurityService
    DenunceService denunceService
    TributiSession tributiSession
    CompetenzeService competenzeService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    CommonService commonService
    IntegrazionePortaleService integrazionePortaleService

    // dati
    def lista
    def selected

    def denunceSelezionate = [:]

    // ricerca
    boolean nonDeceduti = false
    boolean deceduti = false
    boolean ricercaAnnullata = false
    def ordinamento = [tipo: CampiOrdinamento.ALFA, ascendente: true]
    FiltroRicercaDenunce parRicerca

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    boolean creaDenunciaVisible = true
    boolean esportaDenunciaVisible = false
    boolean stampaDenunciaVisible = false
    boolean filtroAttivo = false

    String tipoTributo
    def tipoTributoAttuale

    def tipoAbilitazione = "A"
    def descrizioneAbilitazione = "Modifica"
    Boolean lettura = true

    def praticheDaImportare = ""

    def integrazionePortaleAttiva

    //Definiamo i vari pannell con competenza di lettura default a true
    Map caricaPannello = [ICI  : [zul: "/pratiche/denunce/denunciaImu.zul", lettura: true, daBonifiche: false],
                          TARSU: [zul: "/pratiche/denunce/denunciaTari.zul", lettura: true, daBonifiche: false],
                          TASI : [zul: "/pratiche/denunce/denunciaTasi.zul", lettura: true, daBonifiche: false],
                          CUNI : [zul: "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul", lettura: true, daBonifiche: false]]

    @NotifyChange(["creaDenunciaVisible", "esportaDenunciaVisible"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("tipoTributo") String tt) {

        this.self = w

        tipoTributo = tt
        tipoTributoAttuale = TipoTributo.findByTipoTributo(tipoTributo)?.tipoTributoAttuale

        //Controllo competenze
        def competenze = Si4Competenze.findByUtenteAndOggetto(springSecurityService.currentUser, tipoTributo)
        if (competenze) {
            tipoAbilitazione = competenze.si4Abilitazioni.si4TipiAbilitazione.tipoAbilitazione
            descrizioneAbilitazione = competenze.si4Abilitazioni.si4TipiAbilitazione.descrizione
            //Settimao la competenza di Lettura/Scrittura in funzione alle competenze
            caricaPannello."${tipoTributo}".lettura = (tipoAbilitazione == 'L')
        }
        tipoAbilitazione = competenzeService.tipoAbilitazioneUtente(tipoTributo)
        lettura = tipoAbilitazione != 'A'
        //Settimao la competenza di Lettura/Scrittura in funzione alle competenze
        caricaPannello[tipoTributo]["lettura"] = (tipoAbilitazione == 'L')

        creaDenunciaVisible = tipoTributo in ['ICI', 'TASI', 'TARSU', 'CUNI']
        esportaDenunciaVisible = tipoTributo in ['ICI', 'TASI', 'TARSU', 'CUNI']
        parRicerca = tributiSession.filtroRicercaDenunce ?: new FiltroRicercaDenunce()
        if (parRicerca.filtriAggiunti == null) {
            parRicerca.filtriAggiunti = new FiltroRicercaCanoni()
        }
        filtroAttivo = verificaCampiFiltranti()

        if (filtroAttivo) {
            caricaLista()
        } else {
            openCloseFiltri()
        }

        aggiornaPraticheDaImportare()
        integrazionePortaleAttiva = integrazionePortaleService.integrazionePortaleAttiva()
    }

    @NotifyChange(["selected"])
    @Command
    onRefresh() {
        caricaLista()
        selected = null
        denunceSelezionate = [:]

        BindUtils.postNotifyChange(null, null, this, "denunceSelezionate")
    }

    @NotifyChange(["activePage"])
    @Command
    onCerca() {
        activePage = 0
        denunceSelezionate = [:]

        caricaLista()
        selected = null

        BindUtils.postNotifyChange(null, null, this, "denunceSelezionate")
    }

    @Command
    onNuovo() {
        if (tipoTributo == 'CUNI') {
            /// La Denuncia CUNI non gestisce la selezione in maschera del soggetto/contribuente
            selezionaSoggetto()
        } else {
            nuovaDenuncia(selected)
        }
    }

    @Command
    onModifica() {
        String zul = caricaPannello."${tipoTributo}".zul
        boolean lettura = caricaPannello."${tipoTributo}".lettura
        creaPopup(zul, [pratica     : selected.id,
                        tipoRapporto: selected.tipoRapporto,
                        lettura     : lettura,
                        daBonifiche : caricaPannello."${tipoTributo}".daBonifiche])
    }

    @Command
    onChangeStato(@BindingParam("valore") String valore) {
        deceduti = (valore == "Deceduti")
        nonDeceduti = (valore == "Non deceduti")
        activePage = 0
        caricaLista()
    }

    @Command
    openCloseFiltri() {

        Window w = Executions.createComponents("/pratiche/denunce/elencoDenunceRicerca.zul", self, [parRicerca: parRicerca, tipoTributo: tipoTributo])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicerca = event.data.parRicerca
                    tributiSession.filtroRicercaDenunce = parRicerca
                    ricercaAnnullata = false
                    onCerca()
                }
                if (event.data.status == "Chiudi") {
                    ricercaAnnullata = true
                }
            }
            filtroAttivo = verificaCampiFiltranti()
            BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        }
        w.doModal()
    }

    @Command
    onChangeOrdinamento(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
        ordinamento.tipo = CampiOrdinamento.getAt(valore)
        ordinamento.ascendente = event.isAscending()
        caricaLista()
    }

    @Command
    def onCheckAll() {
        if (denunceSelezionate.any { k, v -> v }) {
            denunceSelezionate = [:]
        } else {
            denunceSelezionate = denunceService.listaDenunce(deceduti, nonDeceduti, ordinamento, parRicerca, tipoTributo,
                    parRicerca.tipoPratica, Integer.MAX_VALUE, 0).result.collect {
                [(it.id): true]
            }.collectEntries()
        }

        BindUtils.postNotifyChange(null, null, this, "denunceSelezionate")
    }

    @Command
    def onCheckPratica(@BindingParam("prtr") def pratica) {

        denunceSelezionate = denunceSelezionate.findAll { k, v -> v }

        BindUtils.postNotifyChange(null, null, this, "denunceSelezionate")
    }

    @Command
    def onValidaDenunceOnline() {

        if (!PraticaTributo.findAllByIdInListAndFlagAnnullamento(denunceSelezionate.keySet(), true).empty) {
            Clients.showNotification("Nell'elenco sono presenti pratiche annullate", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        def msg = integrazionePortaleService.validaPratiche(denunceSelezionate.keySet())
        Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        onCerca()
    }

    @Command
    onExportXls() {

        Map fields
        def denunce

        if (tipoTributo in ['ICI', 'TASI']) {

            fields = ["id"                    : "Pratica",
                      "tipoPratica"  : "Tipo Pratica",
                      "flagAnnullata": "Annullata",
                      "cognomeNome"           : "Contribuente",
                      "codFiscale"            : "Cod.Fiscale",
                      "anno"                  : "Anno",
                      "data"                  : "Data",
                      "numero"                : "Numero",
                      "tipoTributoAttuale"    : "Tipo Tributo",
                      "tipoRapporto"          : "Tipo Rapporto",
                      "indirizzo"             : "Indirizzo",
                      "comune.denominazione"  : "Comune",
                      "comune.provincia.sigla": "Provincia",
                      "denunciante"           : "Denunciante",
                      "codFiscaleDen"         : "Cod.Fiscale Den.",
                      "tipoCarica"            : "Tipo Carica",
                      "indirizzoDen"          : "Indirizzo Den.",
                      "comuneDen"             : "Comune Den.",
                      "provinciaDen"          : "Provincia Den.",]

        } else if (tipoTributo in ['TARSU', 'CUNI']) {

            Map commonFields = ["cognomeNome"           : "Contribuente",
                                "codFiscale"            : "Cod.Fiscale",
                                "anno"                  : "Anno",
                                "data"                  : "Data",
                                "numero"                : "Numero",
                                "tipoTributoAttuale"    : "Tipo Tributo",
                                "tipoEvento"            : "Tipo Evento",
                                "tipoRapporto"          : "Tipo Rapporto",
                                "indirizzo"             : "Indirizzo",
                                "comune.denominazione"  : "Comune",
                                "comune.provincia.sigla": "Provincia",
                                "denunciante"           : "Denunciante",
                                "codFiscaleDen"         : "Cod.Fiscale Den.",
                                "tipoCarica"            : "Tipo Carica",
                                "indirizzoDen"          : "Indirizzo Den.",
                                "comuneDen"             : "Comune Den.",
                                "provinciaDen"          : "Provincia Den.",]

            if (tipoTributo == "TARSU") {
                fields = ["id"               : "Pratica",
                          "tipoPratica"      : "Tipo Pratica",
                          "flagAnnullata": "Annullata",
                          "eventoSuccessivo" : "Evento Successivo",
                          "praticaSuccessiva": "Pratica Successiva"]

                fields.putAll(commonFields)

            } else {
                fields = ["id": "Pratica"]

                fields.putAll(commonFields)
            }


        }

        def documenti =
                denunceService.listaDenunce(deceduti, nonDeceduti, ordinamento, parRicerca, tipoTributo,
                        parRicerca.tipoPratica, Integer.MAX_VALUE, 0)
        denunce = documenti.result

        def nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DENUNCE,
                [tipoTributo: TipoTributo.get(tipoTributo).toDTO().tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, denunce, fields, [flagAnnullata: Converters.flagBooleanToString])

    }

    @Command
    def onComponentiConsistenza() {
        commonService.creaPopup("/pratiche/denunce/componentiConsistenza.zul", self, [:],
                { event ->

                })
    }

    @Command
    def onVariazioneAutomatiche() {

        commonService.creaPopup("/pratiche/denunce/variazioneAutomatiche.zul", self, [tipoTributo: tipoTributo],
                { event ->
                    if (event.data) {
                        if (event.data?.aggiornaStato != false) {
                            onRefresh()
                        }
                    }
                })
    }

    private void caricaLista() {
        def documenti = denunceService.listaDenunce(deceduti,
                nonDeceduti,
                ordinamento,
                parRicerca,
                tipoTributo,
                parRicerca.tipoPratica,
                pageSize,
                activePage)

        lista = documenti.result
        totalSize = documenti.total
        BindUtils.postNotifyChange(null, null, this, "lista")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    private def selezionaSoggetto(def ricerca = false) {

        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true, eseguiRicerca: ricerca])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    if (!event.data.Soggetto.codFiscale) {
                        if (!event.data.Soggetto.partitaIva) {
                            Clients.showNotification("Soggetto con codice fiscale non valorizzato. Impossibile creare la denuncia.", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
                            selezionaSoggetto(event.data.filtri)
                            return
                        }
                    }
                    nuovaDenuncia(event.data.Soggetto)
                }
            }
        }
        w.doModal()
    }

    def nuovaDenuncia(def soggetto) {

        creaPopup(caricaPannello."${tipoTributo}".zul,
                [pratica    : -1, tipoRapporto: "D", lettura: caricaPannello."${tipoTributo}".lettura,
                 daBonifiche: caricaPannello."${tipoTributo}".daBonifiche,
                 selected   : soggetto])
    }

    // FIXME: Usare {@link it.finmatica.tr4.commons.ComonService#creaPopup}
    @Deprecated
    private void creaPopup(String zul, def parametri) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.doModal()
        w.onClose {
            if (ricercaAnnullata || it.data?.salvato) {
                caricaLista()
            }
        }
    }

    boolean verificaCampiFiltranti() {

        boolean attivi = parRicerca ? (
                (parRicerca?.cognome ?: '') != "" ||
                        (parRicerca?.nome ?: '') != "" ||
                        (parRicerca?.cf ?: '') != "" ||
                        parRicerca?.numeroIndividuale != null ||
                        parRicerca?.codContribuente != null ||
                        parRicerca?.daNumero != null ||
                        parRicerca?.aNumero != null ||
                        parRicerca?.daAnno != null ||
                        parRicerca?.aAnno != null ||
                        parRicerca?.daNumeroPratica != null ||
                        parRicerca?.aNumeroPratica != null ||
                        parRicerca?.daData != null ||
                        !parRicerca?.aData?.equals(new Date().clearTime()) ||
                        parRicerca?.fonte != null ||
                        parRicerca?.dichiaranti ||
                        parRicerca?.frontespizio ||
                        parRicerca?.flagEsclusione ||
                        parRicerca?.doppie ||
                        parRicerca?.flagAbitazionePrincipale ||
                        (DenunceService.VISUALIZZA_DOC_ID[tipoTributo] && parRicerca?.document) ||
                        ((parRicerca.codiciTributo ?: []).size() > 0) ||
                        ((parRicerca.tipiTariffa ?: []).size() > 0) ||
                        (parRicerca.tipoPratica && parRicerca.tipoPratica != '*')
        ) : false

        /// Al momento la maschera di ricerca visualizza questi filtri solo per CUNI
        if (tipoTributoAttuale in ['CUNI']) {
            if (parRicerca.filtriAggiunti?.isDirty() ?: false) {
                attivi = true
            }
        }

        return attivi
    }

    @Command
    void onGestionePraticheOnline() {
        commonService.creaPopup("/portale/elencoPratichePortale.zul",
                self,
                [tipoTributo: tipoTributo],) {

            caricaLista()
            aggiornaPraticheDaImportare()
            selected = null
        }
    }

    private aggiornaPraticheDaImportare() {
        praticheDaImportare = integrazionePortaleService.praticheDaImportare(tipoTributo)
        BindUtils.postNotifyChange(null, null, this, "praticheDaImportare")
    }
}
