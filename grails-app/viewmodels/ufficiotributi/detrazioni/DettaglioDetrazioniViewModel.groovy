package ufficiotributi.detrazioni

import document.FileNameGenerator
import it.finmatica.tr4.MotivoDetrazione
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.TipoAliquota
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.AliquotaOgcoDTO
import it.finmatica.tr4.dto.DetrazioneOgcoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.DetrazioniService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.util.Calendar

class DettaglioDetrazioniViewModel {

    private static Log log = LogFactory.getLog(DettaglioDetrazioniViewModel)

    // Services
    DetrazioniService detrazioniService
    CommonService commonService

    // Componenti
    Window self

    @Wire('#detTabBox')
    Tabbox detTabBox

    // Comuni
    def soggetto
    def tipoTributo
    def ultimoStato
    def anno
    def listaOggetti = []
    def lettura
    def oggettoSelezionato

    // Tab
    def tabSelezionata = "aliquote"
    def listaAliquote, listaAliqEliminate = []
    def listaDetrazioni, listaDetEliminate = []
    def aliquotaSelezionata, detrazioneSelezionata
    def aliquoteCaricate = false, detrazioniCaricate = false
    def numAliquote, numDetrazioni
    def oggettoPratica
    def popupNote

    def listaAnni, listaTipiAliquota
    def listaMotiviDetrazione


    def isDirtyAliquote
    def isDirtyDetrazioni
    def inizializzazioneAliquote = true
    def inizializzazioneDetrazioni = true
    EventListener<Event> eventIsDirty = null


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ni") def ni,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("anno") String an,
         @ExecutionArgParam("oggettoPratica") def ogpr,
         @ExecutionArgParam("lettura") def lt) {

        this.self = w
        this.tipoTributo = tt
        this.anno = an
        this.oggettoPratica = ogpr
        this.lettura = lt

        this.soggetto = Soggetto.get(ni).toDTO([
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

        listaOggetti = detrazioniService.getListaOggetti(tipoTributo.tipoTributo, soggetto.codFiscale, anno)

        listaAnni = detrazioniService.getAnniDetrazione(tipoTributo.tipoTributo).sort { it }

        listaTipiAliquota = TipoAliquota.list().toDTO()
                .findAll { it.tipoTributo.tipoTributo == tipoTributo.tipoTributo }

        listaMotiviDetrazione = MotivoDetrazione.list().toDTO()
                .findAll { it.tipoTributo.tipoTributo == tipoTributo.tipoTributo }
                .sort { it.motivoDetrazione }

    }

    @AfterCompose
    def afterInit() {

        isDirtyAliquote = false
        isDirtyDetrazioni = false
        def props = ['listaAliquote', 'listaDetrazioni']
        def classes = [AliquotaOgcoDTO, DetrazioneOgcoDTO]

        eventIsDirty = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {

                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    def prop = ((PropertyChangeEvent) event).property

                    if (!(pe.base.class in classes) &&
                            !(prop in props)) {
                        return
                    }

                    // Aliquote: se si modifica un elemento della lista (aggiunta/modifica/clonazione/eliminazione)
                    if (pe.base instanceof AliquotaOgcoDTO || prop == "listaAliquote") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtyAliquote && !inizializzazioneAliquote) {
                            log.info "[Aliquote] Modificata proprietà [$prop]"
                            isDirtyAliquote = true
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (prop == "listaAliquote" && inizializzazioneAliquote) {
                            inizializzazioneAliquote = false
                        }

                        return
                    }

                    // Detrazioni: se si modifica un elemento della lista (aggiunta/modifica/clonazione/eliminazione)
                    if (pe.base instanceof DetrazioneOgcoDTO || prop == "listaDetrazioni") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtyDetrazioni && !inizializzazioneDetrazioni) {
                            log.info "[Detrazioni] Modificata proprietà [$prop]"
                            isDirtyDetrazioni = true
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (prop == "listaDetrazioni" && inizializzazioneDetrazioni) {
                            inizializzazioneDetrazioni = false
                        }

                        return
                    }

                }
            }
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(eventIsDirty)
    }


    @Command
    def onSalva() {

        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
            return
        }

        String messaggio = "Si desidera procedere con il salvataggio delle modifiche?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.CANCEL | Messagebox.YES, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            salva()
                            resettaFiltroDirty()
                        }
                    }
                })
    }

    @Command
    def onChiudi() {


        if (modificheIncorso()) {
            String messaggio = "Esistono delle modifiche in sospeso, si desidera salvarle?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {

                                def errori = controllaParametri()

                                if (errori.size() > 0) {
                                    Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
                                    return
                                }
                                salva()
                                chiudi()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                chiudi()
                            }
                        }
                    }
            )
        } else {
            chiudi()
        }
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        if (oggettoSelezionato == null) {
            return
        }

        // Se si è in modifica in una delle tab, non si permette il cambio tab
        if (modificheIncorso()) {
            Clients.showNotification("Salvare prima le modifiche in corso.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 2000, true)

            detTabBox.selectedTab = detTabBox.tabs.children.find { it.id == tabSelezionata }

            return
        }


        tabSelezionata = tabId

        detrazioneSelezionata = null
        aliquotaSelezionata = null


        BindUtils.postNotifyChange(null, null, this, "tabSelezionata")
        BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
    }

    @Command
    def onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()
    }

    @Command
    def setAliquotaSelezionata(@BindingParam("aliq") def aliq) {
        aliquotaSelezionata = aliq
        BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
    }

    @Command
    def setDetrazioneSelezionata(@BindingParam("det") def det) {
        detrazioneSelezionata = det
        BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
    }

    @Command
    def onRefreshAliquote() {

        if (modificheIncorso()) {
            String messaggio = "Esistono delle modifiche in sospeso, si desidera salvarle?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {

                                def errori = controllaParametri()

                                if (errori.size() > 0) {
                                    Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
                                    return
                                }
                                salva()
                                caricaAliquote(true)
                                resettaFiltroDirty()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                caricaAliquote(true)
                                resettaFiltroDirty()
                            }
                        }
                    }
            )
        } else {
            caricaAliquote(true)
            resettaFiltroDirty()
        }

    }

    @Command
    def onRefreshDetrazioni() {

        if (modificheIncorso()) {
            String messaggio = "Esistono delle modifiche in sospeso, si desidera salvarle?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {

                                def errori = controllaParametri()

                                if (errori.size() > 0) {
                                    Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
                                    return
                                }
                                salva()
                                caricaDetrazioni(true)
                                resettaFiltroDirty()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                caricaDetrazioni(true)
                                resettaFiltroDirty()
                            }
                        }
                    }
            )
        } else {
            caricaDetrazioni(true)
            resettaFiltroDirty()
        }

    }

    @Command
    def onAggiungiAliquota() {

        def oggContribuenteDTO = detrazioniService.getOggettoContribuente(soggetto.codFiscale, oggettoSelezionato.oggettoPratica)

        listaAliquote.add(
                new AliquotaOgcoDTO([
                        "tipoAliquota"       : null,
                        "dal"                : null,
                        "al"                 : null,
                        "note"               : null,
                        "nuovo"              : true,
                        "oggettoContribuente": oggContribuenteDTO
                ])
        )

        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
    }

    @Command
    def onDuplicaAliquota() {

        def nuovaAliquota = new AliquotaOgcoDTO()
        InvokerHelper.setProperties(nuovaAliquota, aliquotaSelezionata.properties)
        nuovaAliquota.uuid = UUID.randomUUID().toString().replace('-', '')
        nuovaAliquota.nuovo = true

        listaAliquote.add(nuovaAliquota)
        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
    }

    @Command
    def onEliminaAliquota() {

        String messaggio = "Eliminare l'aliquota?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def aliq = listaAliquote.find { it.uuid == aliquotaSelezionata.uuid }
                            aliq.esistente = false
                            aliquotaSelezionata = null
                            caricaAliquote()
                            BindUtils.postNotifyChange(null, null, this, "listaAliquote")
                            BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
                        }
                    }
                }
        )
    }

    @Command
    def onExportXlsAliquote() {

        def fields

        fields = [
                "contrContribuente"   : "Contribuente",
                "contrCodFiscale"     : "Cod Fiscale",
                "contrIndirizzo"      : "Indirizzo",
                "oggOggetto"          : "Oggetto",
                "oggIndirizzoLocalita": "Indirizzo Ogg.",
                "oggSezione"          : "Sezione",
                "oggFoglio"           : "Foglio",
                "oggNumero"           : "Numero",
                "oggSubalterno"       : "Subalterno",
                "oggZona"             : "Zona",
                "oggPartita"          : "Partita",
                "oggCategoriaCatasto" : "Categoria Catasto",
                "oggClasseCatasto"    : "Classe Catasto",
                "oggPotocolloCatasto" : "Protocollo",
                "oggAnno"             : "Anno",
                "oggPercPossesso"     : "%Poss.",
                "oggMesiPossesso"     : "MP",
                "oggMesiEsclusione"   : "ME",
                "oggMesiRiduzione"    : "MR",
                "oggMesiPossesso1sem" : "1S",
                "oggFlagPossesso"     : "P",
                "oggFlagEsclusione"   : "E",
                "oggFlagRiduzione"    : "R",
                "oggFlagAbPrincipale" : "A",
                "oggDet"              : "Detrazioni Oggetto Contribuente",
                "oggAli"              : "Aliquote Oggetto Contribuente",
                "oggDetrazione"       : "Detrazione",
                "tipoAliquota"        : "Tipo Aliquota",
                "dal"                 : "Dal",
                "al"                  : "Al",
                "note"                : "Note"
        ]

        def formatters = [
                contrContribuente   : { con -> soggetto.cognome + " " + soggetto.nome },
                contrCodFiscale     : { con -> soggetto.codFiscale },
                oggOggetto          : { con -> oggettoSelezionato.oggetto as Integer },
                oggIndirizzoLocalita: { con -> oggettoSelezionato.indirizzoLocalita },
                oggSezione          : { con -> oggettoSelezionato.sezione as Integer },
                oggFoglio           : { con -> oggettoSelezionato.foglio as Integer },
                oggNumero           : { con -> oggettoSelezionato.numero as Integer },
                oggSubalterno       : { con -> oggettoSelezionato.subalterno as Integer },
                oggZona             : { con -> oggettoSelezionato.zona },
                oggPartita          : { con -> oggettoSelezionato.partita },
                oggCategoriaCatasto : { con -> oggettoSelezionato.categoriaCatasto },
                oggClasseCatasto    : { con -> oggettoSelezionato.classeCatasto },
                oggPotocolloCatasto : { con -> oggettoSelezionato.protocolloCatasto },
                oggAnno             : { con -> oggettoSelezionato.anno as short },
                oggPercPossesso     : { con -> oggettoSelezionato.percPossesso as Integer },
                oggMesiPossesso     : { con -> oggettoSelezionato.mesiPossesso as Integer },
                oggMesiEsclusione   : { con -> oggettoSelezionato.mesiEsclusione as Integer },
                oggMesiRiduzione    : { con -> oggettoSelezionato.mesiRiduzione as Integer },
                oggMesiPossesso1sem : { con -> oggettoSelezionato.mesiPossesso1sem as Integer },
                oggFlagPossesso     : { con -> oggettoSelezionato.flagPossesso },
                oggFlagEsclusione   : { con -> oggettoSelezionato.flagEsclusione },
                oggFlagRiduzione    : { con -> oggettoSelezionato.flagRiduzione },
                oggFlagAbPrincipale : { con -> oggettoSelezionato.flagAbPrincipale },
                oggDet              : { con -> oggettoSelezionato.det == null ? 'N' : 'S' },
                oggAli              : { con -> oggettoSelezionato.ali == null ? 'N' : 'S' },
                oggDetrazione       : { con -> oggettoSelezionato.detrazione },
                tipoAliquota        : { tAliq -> tAliq.tipoAliquota + " - " + tAliq.descrizione }

        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ALIQUOTE,
                [tipoTributo: tipoTributo.tipoTributoAttuale,
                 codFiscale : soggetto.codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, listaAliquote, fields, formatters)
    }

    @Command
    def onExportXlsDetrazioni() {

        def fields

        fields = [
                "contrContribuente"   : "Contribuente",
                "contrCodFiscale"     : "Cod Fiscale",
                "contrIndirizzo"      : "Indirizzo",
                "oggOggetto"          : "Oggetto",
                "oggIndirizzoLocalita": "Indirizzo Ogg.",
                "oggSezione"          : "Sezione",
                "oggFoglio"           : "Foglio",
                "oggNumero"           : "Numero",
                "oggSubalterno"       : "Subalterno",
                "oggZona"             : "Zona",
                "oggPartita"          : "Partita",
                "oggCategoriaCatasto" : "Categoria Catasto",
                "oggClasseCatasto"    : "Classe Catasto",
                "oggPotocolloCatasto" : "Protocollo",
                "oggAnno"             : "Anno",
                "oggPercPossesso"     : "%Poss.",
                "oggMesiPossesso"     : "MP",
                "oggMesiEsclusione"   : "ME",
                "oggMesiRiduzione"    : "MR",
                "oggMesiPossesso1sem" : "1S",
                "oggFlagPossesso"     : "P",
                "oggFlagEsclusione"   : "E",
                "oggFlagRiduzione"    : "R",
                "oggFlagAbPrincipale" : "A",
                "oggDet"              : "Detrazioni Oggetto Contribuente",
                "oggAli"              : "Aliquote Oggetto Contribuente",
                "oggDetrazione"       : "Detrazione",
                "anno"                : "Anno",
                "motivoDetrazione"    : "Motivo Detrazione",
                "detrazione"          : "Detrazione",
                "detrazioneAcconto"   : "Detrazione Acconto",
                "note"                : "Note"
        ]

        def formatters = [
                contrContribuente   : { con -> soggetto.cognome + " " + soggetto.nome },
                contrCodFiscale     : { con -> soggetto.codFiscale },
                oggOggetto          : { con -> oggettoSelezionato.oggetto as Integer },
                oggIndirizzoLocalita: { con -> oggettoSelezionato.indirizzoLocalita },
                oggSezione          : { con -> oggettoSelezionato.sezione as Integer },
                oggFoglio           : { con -> oggettoSelezionato.foglio as Integer },
                oggNumero           : { con -> oggettoSelezionato.numero as Integer },
                oggSubalterno       : { con -> oggettoSelezionato.subalterno as Integer },
                oggZona             : { con -> oggettoSelezionato.zona },
                oggPartita          : { con -> oggettoSelezionato.partita },
                oggCategoriaCatasto : { con -> oggettoSelezionato.categoriaCatasto },
                oggClasseCatasto    : { con -> oggettoSelezionato.classeCatasto },
                oggPotocolloCatasto : { con -> oggettoSelezionato.protocolloCatasto },
                oggAnno             : { con -> oggettoSelezionato.anno as short },
                oggPercPossesso     : { con -> oggettoSelezionato.percPossesso as Integer },
                oggMesiPossesso     : { con -> oggettoSelezionato.mesiPossesso as Integer },
                oggMesiEsclusione   : { con -> oggettoSelezionato.mesiEsclusione as Integer },
                oggMesiRiduzione    : { con -> oggettoSelezionato.mesiRiduzione as Integer },
                oggMesiPossesso1sem : { con -> oggettoSelezionato.mesiPossesso1sem as Integer },
                oggFlagPossesso     : { con -> oggettoSelezionato.flagPossesso },
                oggFlagEsclusione   : { con -> oggettoSelezionato.flagEsclusione },
                oggFlagRiduzione    : { con -> oggettoSelezionato.flagRiduzione },
                oggFlagAbPrincipale : { con -> oggettoSelezionato.flagAbPrincipale },
                oggDet              : { con -> oggettoSelezionato.det == null ? 'N' : 'S' },
                oggAli              : { con -> oggettoSelezionato.ali == null ? 'N' : 'S' },
                oggDetrazione       : { con -> oggettoSelezionato.detrazione },
                anno                : Converters.decimalToInteger,
                motivoDetrazione    : { mDetr -> mDetr.motivoDetrazione + " - " + mDetr.descrizione },

        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DETRAZIONI,
                [tipoTributo: tipoTributo.tipoTributoAttuale,
                 codFiscale : soggetto.codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, listaDetrazioni, fields, formatters)
    }

    @Command
    def onAggiungiDetrazione() {

        def oggContribuenteDTO = detrazioniService.getOggettoContribuente(soggetto.codFiscale, oggettoSelezionato.oggettoPratica)

        listaDetrazioni.add(
                new DetrazioneOgcoDTO([
                        "anno"               : null,
                        "motivoDetrazione"   : null,
                        "detrazione"         : null,
                        "detrazioneAcconto"  : null,
                        "tipoTributo"        : tipoTributo,
                        "note"               : null,
                        "nuovo"              : true,
                        "oggettoContribuente": oggContribuenteDTO
                ])
        )

        BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
    }

    @Command
    def onDuplicaDetrazione() {

        def nuovaDetrazione = new DetrazioneOgcoDTO()
        InvokerHelper.setProperties(nuovaDetrazione, detrazioneSelezionata.properties)
        nuovaDetrazione.uuid = UUID.randomUUID().toString().replace('-', '')
        nuovaDetrazione.anno = null
        nuovaDetrazione.nuovo = true

        listaDetrazioni.add(nuovaDetrazione)
        BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
    }

    @Command
    def onEliminaDetrazione() {
        String messaggio = "Eliminare la detrazione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            listaDetrazioni.find { it.uuid == detrazioneSelezionata.uuid }.esistente = false
                            detrazioneSelezionata = null
                            caricaDetrazioni()
                            BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
                            BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
                        }
                    }
                }
        )
    }

    @Command
    def onChangeOggetto() {

        if (modificheIncorso()) {
            String messaggio = "Esistono delle modifiche in sospeso, si desidera salvarle?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                def errori = controllaParametri()

                                if (errori.size() > 0) {
                                    Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
                                    return
                                }
                                salva()
                                changeOggetto()
                            } else {
                                changeOggetto()
                            }
                        }
                    }
            )
        } else {
            changeOggetto()
        }
    }

    @Command
    def onChangeValue(@BindingParam("val") def value) {

        if (tabSelezionata == "aliquote") {
            listaAliquote.find { it.uuid == value.uuid }.modificato = true
            BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        } else if (tabSelezionata == "detrazioni") {
            listaDetrazioni.find { it.uuid == value.uuid }.modificato = true
            BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
        }
    }

    @Command
    def onChangeAnno(@BindingParam("val") def value) {

        value.modificato = true

        // L'anno è cambiato se la entry è stata modificata e non è nuova (esclude aggiunta e duplica)
        // e se l'anno non è già cambiato precedentemente (se si cambia anno più volte serve il primissimo anno)
        value.annoCambiato = value.modificato && !value.nuovo && !value.annoCambiato

        def listaDetrTemp = listaDetrazioni.findAll { it.oggettoContribuente != null }
        listaDetrTemp.remove(listaDetrazioni.find { it.uuid == value.uuid })


        if (value.anno in listaDetrTemp.collect { it.anno }) {
            Clients.showNotification("E' già presente una Detrazione con lo stesso Anno per l'oggetto selezionato"
                    , Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        }
    }

    @Command
    def onChangeDataAliquota(@BindingParam("aliq") def aliquota, @BindingParam("tipo") def tipo) {


        listaAliquote.find { it.uuid == aliquota.uuid }.modificato = true


        if (tipo == "dal") {
            // L'anno è cambiato se la entry è stata modificata e non è nuova (esclude aggiunta e duplica)
            // e se la data non è già cambiata precedentemente
            aliquota.dataDalCambiata = aliquota.modificato && !aliquota.nuovo && !aliquota.dataDalCambiata
        }


        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join()
                    , Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        }
    }


    @Command
    def onOpenSituazioneContribuente() {
        def ni = soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    private def changeOggetto() {
        caricaTutto()
        resettaFiltroDirty()
    }

    private def caricaAliquote(def forzaRicarica = false) {

        if (!aliquoteCaricate || forzaRicarica) {
            listaAliquote = detrazioniService.getAliquoteDettaglio(tipoTributo.tipoTributo, soggetto.codFiscale, oggettoSelezionato.oggettoPratica).toDTO(["tipoAliquota"])
            listaAliquote.each { it.dataDalPrecedente = it.dal }
            aliquoteCaricate = true
        }

        listaAliqEliminate = listaAliqEliminate + listaAliquote.findAll { !it.esistente }
        listaAliquote = listaAliquote.findAll { it.esistente }

        numAliquote = listaAliquote.size()

        aliquotaSelezionata = null


        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        BindUtils.postNotifyChange(null, null, this, "numAliquote")
        BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "aliquoteCaricate")
        BindUtils.postNotifyChange(null, null, this, "listaAliqEliminate")
    }

    private def caricaDetrazioni(def forzaRicarica = false) {

        if (!detrazioniCaricate || forzaRicarica) {
            listaDetrazioni = detrazioniService.getDetrazioniDettaglio(tipoTributo.tipoTributo, soggetto.codFiscale, oggettoSelezionato.oggettoPratica).toDTO(["motivoDetrazione", "tipoTributo"])
            listaDetrazioni.each { it.annoPrecedente = it.anno }
            detrazioniCaricate = true
        }

        listaDetEliminate = listaDetEliminate + listaDetrazioni.findAll { !it.esistente }
        listaDetrazioni = listaDetrazioni.findAll { it.esistente }

        numDetrazioni = listaDetrazioni.size()

        detrazioneSelezionata = null


        BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
        BindUtils.postNotifyChange(null, null, this, "numDetrazioni")
        BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "detrazioniCaricate")
        BindUtils.postNotifyChange(null, null, this, "listaDetEliminate")
    }

    private def chiudi() {
        if (eventIsDirty) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(eventIsDirty)
            eventIsDirty = null
        }

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def salva() {

        if (tabSelezionata == "aliquote") {
            detrazioniService.salvaDettagli(listaAliquote, listaAliqEliminate, tabSelezionata)
            caricaAliquote(true)
        } else if (tabSelezionata == "detrazioni") {
            detrazioniService.salvaDettagli(listaDetrazioni, listaDetEliminate, tabSelezionata)
            caricaDetrazioni(true)
        }

        Clients.showNotification("Modifiche salvate"
                , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

    }

    private def caricaTutto() {
        caricaAliquote(true)
        caricaDetrazioni(true)
    }

    private def modificheIncorso() {
        // Si leggono le proprietà isDirty
        def dirtyProps = [:]

        for (def property in this.properties) {
            if (property.key.startsWith('isDirty')) {
                dirtyProps << property
            }
        }

        dirtyProps.each { k, v -> log.info "${k} = ${v}" }

        return dirtyProps
                .inject(false) { a, b -> a || b.value }
    }

    private def resettaFiltroDirty() {
        isDirtyDetrazioni = false
        isDirtyAliquote = false
        inizializzazioneDetrazioni = true
        inizializzazioneAliquote = true
    }


    private invalidaGridAliquote() {
        try {
            ((self.getFellow("detTabBox")
                    .getFellow("tabPanelDetr")
                    .getFellow("includeAliquote")
                    .getFellow("gridAliquote")) as Grid)
                    .invalidate()
        } catch (Exception e) {
            log.info("detTabBox.folderAliquote non caricato.")
        }
    }

    private def getUltimoGiornoDelMese(def date) {
        Calendar cal = Calendar.getInstance()
        cal.setTime(date)
        return cal.getActualMaximum(java.util.Calendar.DATE)
    }

    private def getPrimoGiornoDelMese(def date) {
        Calendar cal = Calendar.getInstance()
        cal.setTime(date)
        return cal.getActualMinimum(java.util.Calendar.DATE)
    }

    private def getGiornoDelMese(def date) {
        Calendar cal = Calendar.getInstance()
        cal.setTime(date)
        return cal.get(Calendar.DAY_OF_MONTH)
    }

    private def controllaParametri() {

        // I controlli vengono effettuati per ogni entry rispetto quelle restanti, rimuovendo ogni volta la entry appena controllata

        def errori = []

        if (tabSelezionata == "aliquote") {

            def listaAliqTemp = listaAliquote.findAll { it.oggettoContribuente != null }

            for (aliqSelezionata in listaAliquote) {

                // Rimuovo la entry dalla lista dei confronti
                listaAliqTemp.remove(aliqSelezionata)

                // Controllo le condizioni singole dei parametri (tipo aliquota, da, al)
                def erroriSingoli = controllaParametriSingoli(aliqSelezionata)

                // Se sono presenti errori sui parametri ci si ferma e si segnala
                if (erroriSingoli.size() > 0) {
                    errori << erroriSingoli.join()
                    break
                }

                // Controlli sulla singola entry rispetto tutte le altre
                def erroriMultipli = controllaParametriMultipli(aliqSelezionata, listaAliqTemp)

                // Se sono presenti errori tra la entry e le altre ci si ferma e si segnala
                if (erroriMultipli.size() > 0) {
                    errori << erroriMultipli.join()
                    break
                }
            }

        } else if (tabSelezionata == "detrazioni") {
            def listaDetrTemp = listaDetrazioni.findAll { it.oggettoContribuente != null }

            for (detrSelezionata in listaDetrazioni) {

                // Rimuovo la entry dalla lista dei confronti
                listaDetrTemp.remove(detrSelezionata)

                // Controllo le condizioni singole dei parametri (motivo, detr, detr.acconto)
                def erroriSingoli = controllaParametriSingoli(detrSelezionata)

                // Se sono presenti errori sui parametri ci si ferma e si segnala
                if (erroriSingoli.size() > 0) {
                    errori << erroriSingoli.join()
                    break
                }

                // Controlli sulla singola entry rispetto tutte le altre
                def erroriMultipli = controllaParametriMultipli(detrSelezionata, listaDetrTemp)

                // Se sono presenti errori tra la entry e le altre ci si ferma e si segnala
                if (erroriMultipli.size() > 0) {
                    errori << erroriMultipli.join()
                    break
                }
            }
        }

        return errori
    }

    private def controllaParametriMultipli(def selezione, def listaConfronto) {

        def errori = []

        if (tabSelezionata == "aliquote") {

            // Controllo sovrapposizioni date
            if (listaConfronto != null && listaConfronto.size() > 0) {

                for (def aliq in listaConfronto) {
                    if (selezione.dal && selezione.al && aliq.dal && aliq.al &&
                            commonService.isOverlapping(selezione.dal, selezione.al, aliq.dal, aliq.al)) {
                        errori << "E' presente un'intersezione tra date\n"
                        break
                    }
                }
            }
        } else if (tabSelezionata == "detrazioni") {

            // Controllo che non eista già una detrazione con lo stesso anno
            if (selezione.anno in listaConfronto.collect { it.anno }) {
                errori << "E' già presente una Detrazione con lo stesso Anno per l'oggetto selezionato\n"
            }
        }

        return errori
    }

    private def controllaParametriSingoli(def selezione) {

        def errori = []

        if (tabSelezionata == "aliquote") {

            if (selezione.tipoAliquota == null) {
                errori << "Il valore 'Tipo Aliquota' è obbligatorio\n"
            }

            if (selezione.dal == null) {
                errori << "Il valore 'Dal' è obbligatorio\n"
            } else if (getGiornoDelMese(selezione.dal) != getPrimoGiornoDelMese(selezione.dal)) {
                errori << "Il giorno del campo 'Dal' deve essere il primo del mese (${getPrimoGiornoDelMese(selezione.dal)})\n"
            }

            if (selezione.al == null) {
                errori << "Il valore 'Al' è obbligatorio\n"
            } else if (getGiornoDelMese(selezione.al) != getUltimoGiornoDelMese(selezione.al)) {
                errori << "Il giorno del campo 'Al' deve essere l'ultimo del mese (${getUltimoGiornoDelMese(selezione.al)})\n"
            }

            if (selezione.dal && selezione.al && selezione.dal > selezione.al) {
                errori << "'Dal' non può essere maggiore di 'Al'\n"
            }

        } else if (tabSelezionata == "detrazioni") {

            if (selezione.anno == null) {
                errori << "Il valore 'Anno' è obbligatorio\n"
            }
            if (selezione.motivoDetrazione == null) {
                errori << "Il valore 'Motivo Detrazione' è obbligatorio\n"
            }
        }

        return errori
    }

    private def controllaEsistenzaDetrazione(def detrazione) {
        return detrazioniService.existsDetrazione(detrazione.oggettoContribuente.contribuente.codFiscale,
                detrazione.oggettoContribuente.oggettoPratica.id,
                detrazione.anno,
                detrazione.tipoTributo.tipoTributo
        )
    }


}
