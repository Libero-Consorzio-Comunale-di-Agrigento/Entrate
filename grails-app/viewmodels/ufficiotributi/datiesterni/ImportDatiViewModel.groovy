package ufficiotributi.datiesterni

import document.FileNameGenerator
import groovy.xml.XmlUtil
import it.finmatica.datiesterni.beans.ImportNotifiche
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.datiesterni.ImportDatiEsterniService
import it.finmatica.tr4.datiesterni.ParametroImport
import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.jobs.ImportaDatiEsterniJob
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.w3c.dom.Document
import org.xml.sax.InputSource
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zhtml.Filedownload
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zul.Include
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.xml.parsers.DocumentBuilder
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.Transformer
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource
import java.text.SimpleDateFormat

class ImportDatiViewModel {

    private static Log log = LogFactory.getLog(ImportDatiViewModel)

    Window self

    // Service
    def springSecurityService
    def grailsApplication
    CommonService commonService
    CompetenzeService competenzeService

    ImportNotifiche importNotifiche

    String selectedSezione
    String urlSezione

    boolean hideExport = false

    @Deprecated
    def pagingList = [
            activePage: 0,
            pageSize  : 30,
            totalSize : 0
    ]

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    // Filtri
    def filtro
    def filtroAttivo

    def listaDocumentiCaricati = []
    def documentoSelezionato

    def listaAnomalie
    def anomaliaSelezionata

    TitoloDocumento tipologia
    def listaParametri = [:]

    List<FonteDTO> listaFonti
    FonteDTO fonteSelezionata
    boolean sezione
    boolean ctrDenuncia
    String spese

    boolean visibleFonte
    boolean visibleCtrDenuncia
    boolean visibleSezione
    boolean visibleSpese

    boolean visualizzaDocumentiCaricati
    boolean visualizzaJob


    ImportDatiEsterniService importDatiEsterniService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaFonti = Fonte.list().sort { it.fonte }.toDTO()
        sezione = false
        ctrDenuncia = false

        visualizzaDocumentiCaricati = true
        visualizzaJob = false
        filtroAttivo = false

        hideExport = competenzeService.tipoAbilitazioneNoCmpetenze(CompetenzeService.FUNZIONI.GESTIONE_TEFA) != null

        onRefresh()
    }

    @Command
    def onCambioPagina() {
        caricaListaDocumenti()
    }

    @Command
    onOpenFinestraCaricamento() {

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/loadFile.zul", null, null)
        w.doModal()
        w.onClose() {
            onRefresh()
            BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")
        }
    }

    @Command
    onVisualizzaStato(@BindingParam("popup") Component popupNoteCaricamento) {

        popupNoteCaricamento.open(self, "after_pointer")
    }

    @Command
    onAggiornaStato() {
        Map params = new HashMap()
        params.put("width", "300")
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]

        Messagebox.show("Portare lo stato in 'Da caricare'?",
                "Attenzione",
                buttons,
                null,
                Messagebox.QUESTION,
                null,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            aggiornaStato()
                        }
                    }
                },
                params
        )
    }

    @Command
    def onScaricaLogErrori() {

        def fis = new FileInputStream(importNotifiche.logFile(documentoSelezionato.id))
        AMedia amedia =
                new AMedia("${documentoSelezionato.id}_log.txt",
                        "txt", "text/plain", fis)
        org.zkoss.zul.Filedownload.save(amedia)
    }

    private aggiornaStato() {
        if (documentoSelezionato) {
            importDatiEsterniService.cambiaStato(documentoSelezionato.id, (short) 1)
            caricaListaDocumenti()
        }
        BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")
    }

    @Command
    onRefresh() {
        caricaListaDocumenti(true)
    }

    @Command
    onCaricaListaJob(@BindingParam("lista") Include listaJob) {
        listaJob?.invalidate()
    }

    @NotifyChange(["visibleFonte", "visibleCtrDenuncia", "visibleSezione", "visibleSpese", "fonteSelezionata", "sezione", "ctrDenuncia", "spese"])
    @Command
    onEseguiJob(@BindingParam("popup") Component popupDatiImport) {

        // Il MUI che si vuole caricare è precedente all'ultimo caricato. Si impedisce il caricamento.
        if (importDatiEsterniService.verificaCaricamento(documentoSelezionato.id) == '2') {
            Messagebox.show("MUI precedente all'ultimo MUI caricato.", "Impossibile caricare il documento", Messagebox.OK, Messagebox.ERROR)
            return
        }

        tipologia = TitoloDocumento.get(documentoSelezionato.titolo)
        listaParametri = ParametroImport.findAllByTitoloDocumentoAndComponenteIsNotNull(tipologia).groupBy { it.nomeParametro }.collectEntries { key, value -> [key, null] }

        if (listaParametri) {
            fonteSelezionata = null
            sezione = false
            ctrDenuncia = false
            spese = null

            popupDatiImport?.open(self, "middle_center")
            visibleFonte = listaParametri.containsKey("fonte")
            visibleCtrDenuncia = listaParametri.containsKey("ctrDenuncia")
            visibleSezione = listaParametri.containsKey("sezioneUnica")
            visibleSpese = listaParametri.containsKey("spese")

        } else {
            SimpleDateFormat sdf = new SimpleDateFormat("yyMMdd_hhmm")
            String data = sdf.format(new Date())

            listaParametri.put("idDocumento", documentoSelezionato.id)
            listaParametri.put("ente", springSecurityService.principal.amministrazione.toDTO())
            listaParametri.put("utente", springSecurityService.currentUser.toDTO())
            listaParametri.put("nomeSupporto", "A_TAR" + data + ".txt")

            log.info "Lancio il job senza parametri"

            documentoSelezionato.stato = 15
            documentoSelezionato.descrizioneStato = importDatiEsterniService.getStato((short) documentoSelezionato.stato)
            BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")

            // Obbligatorio indicare codiceUtenteBatch se si vuole associare il job all'utente loggato;
            // se codiceUtenteBatch non viene indicato il job verrà associato all'utente indicato nel paremetro di configurazione utenteBatch
            // Obbligatorio indicare codiciEntiBatch altrimenti il processo non viene associato ad alcun ente
            ImportaDatiEsterniJob.triggerNow([codiceUtenteBatch     : springSecurityService.currentUser.id
                                              , codiciEntiBatch     : springSecurityService.principal.amministrazione.codice
                                              , customDescrizioneJob: "${documentoSelezionato.descrizione} - ${documentoSelezionato.nomeDocumento}"
                                              , service             : tipologia.nomeBean
                                              , metodo              : tipologia.nomeMetodo
                                              , parametri           : listaParametri])


        }

    }

    @Command
    onEseguiImport(@BindingParam("popup") Component popupDatiImport) {

        if (importDatiEsterniService.verificaCaricamento(documentoSelezionato.id) == '1') {

            // Il MUI che si vuole caricare non è immediatamente successivo all'ultimo caricato. Si chiede conferma.
            Messagebox.show("Il MUI non è immediatamete successivo all'ultimo caricato. Continuare?", "Fiscalità locale", Messagebox.OK | Messagebox.CANCEL,
                    Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
                void onEvent(Event evt) throws InterruptedException {
                    if (evt.getName().equals("onOK")) {
                        eseguiImport()
                        popupDatiImport.close()
                    }
                }
            }
            )
        } else {
            eseguiImport()
            popupDatiImport.close()
        }
    }

    def eseguiImport() {
        listaParametri.ctrDenuncia = ctrDenuncia ? "S" : "N"
        listaParametri.sezioneUnica = sezione ? "S" : "N"
        listaParametri.fonte = fonteSelezionata?.fonte
        listaParametri.put("idDocumento", documentoSelezionato.id)
        listaParametri.put("ente", springSecurityService.principal.amministrazione.toDTO())
        listaParametri.put("utente", springSecurityService.currentUser.toDTO())

        log.info "Lancio il job con i parametri"

        documentoSelezionato.stato = 15
        documentoSelezionato.descrizioneStato = importDatiEsterniService.getStato((short) documentoSelezionato.stato)
        BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")


        ImportaDatiEsterniJob.triggerNow([codiceUtenteBatch     : springSecurityService.currentUser.id
                                          , codiciEntiBatch     : springSecurityService.principal.amministrazione.codice
                                          , customDescrizioneJob: "${documentoSelezionato.descrizione} - ${documentoSelezionato.nomeDocumento}"
                                          , service             : tipologia.nomeBean
                                          , metodo              : tipologia.nomeMetodo
                                          , parametri           : listaParametri])


        documentoSelezionato = null

    }

    @NotifyChange(["documentoSelezionato"])
    @Command
    onChiudiPopup(@BindingParam("popup") Component popupDatiImport) {
        documentoSelezionato = null
        popupDatiImport.close()
    }

    @Command
    onChiudiRiepilogoJob(@BindingParam("popup") Component popupStatoJob) {

        popupStatoJob.close()
    }

    @Command
    onVisualizzaDocumento() {

        // Recupero del contenuto del file
        def contenuto = new String(importDatiEsterniService.loadContenuto(documentoSelezionato.id), "UTF-8")

        // In caso di MUI si effettua la trasformazione XSL
        if (documentoSelezionato.titolo == 1) {

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance()
            DocumentBuilder builder = factory.newDocumentBuilder()
            InputSource is = new InputSource(new StringReader(contenuto))
            Document xmlDocument = builder.parse(is)

            // Use a Transformer for output
            TransformerFactory tFactory = TransformerFactory.newInstance()
            def xsltFile = grailsApplication.mainContext.getResource("xslt/notai.xslt").file
            StreamSource stylesource = new StreamSource(xsltFile)
            Transformer transformer = tFactory.newTransformer(stylesource)

            DOMSource source = new DOMSource(xmlDocument)
            StringWriter writer = new StringWriter()
            StreamResult result = new StreamResult(writer)
            transformer.transform(source, result)

            AMedia amedia = new AMedia(documentoSelezionato.nomeDocumento + ".html", "html", "text/html", writer.toString())
            Filedownload.save(amedia)
        } else {
            AMedia amedia = new AMedia(documentoSelezionato.nomeDocumento, "html", "text/plain", contenuto.toString())
            Filedownload.save(amedia)
        }

    }

    @Command
    onVisualizzaRettifica() {
        def note = anomaliaSelezionata?.note

        // Recupero del contenuto del file
        def contenuto = new String(importDatiEsterniService.loadContenuto(documentoSelezionato.id), "UTF-8")


        // Se la nota non è nulla ed inizia con 'N. Nota: ' allora effettuare la trasformazione XSL e visualizzare il documento
        if (note && note.indexOf("N. Nota: ") != -1) {

            def numeroNotaRettifca = note.substring("N. Nota: ".length(), note.indexOf(';'))

            // Recupero del contenuto del file
            //def contenuto = new String(importDatiEsterniService.loadContenuto(documentoSelezionato.id), "UTF-8")

            def response = new XmlSlurper(false, false).parseText(contenuto)

            // Recupero del numero ella nota rettificata
            def variazioneRettifica = response.DatiPresenti.Variazioni.Variazione.find { variazione ->
                variazione.Trascrizione.Nota.NumeroNota == numeroNotaRettifca
            }

            def numeroNotaRettificata = variazioneRettifica.Trascrizione.NotaRettificata.NumeroNota

            // Recupero dei documenti in cui cercare la nota rettificata
            def filtriDaCaricare = [stato: (short) 1, titoloDocumento: 1L]
            def filtriCaricati = [stato: (short) 2, titoloDocumento: 1L]

            // Integer.MAX_VALUE non effettua la paginazione
            def listaDaCaricare = importDatiEsterniService.caricaListaDocumenti(filtriDaCaricare, Integer.MAX_VALUE, 0).lista
            def listaCaricati = importDatiEsterniService.caricaListaDocumenti(filtriCaricati, Integer.MAX_VALUE, 0).lista

            // Lista documenti complessiva
            def listaDocumenti = listaDaCaricare + listaCaricati

            // Si cerca la nota rettificata ed eventuali altre rettifiche della stessa nota
            def variazioneRettificata
            def rettifiche = []
            def documentoMui

            listaDocumenti.each { documento ->
                // Si carica il contenuto del documento
                documentoMui = importDatiEsterniService.loadContenuto(documento.id)
                // Si procede solo se il il file non è vuoto
                if (documentoMui != null) {
                    contenuto = new String(documentoMui, "UTF-8")


                    // Si cerca la nota rettificata
                    try {
                        response = new XmlSlurper(false, false).parseText(contenuto)
                    } catch (Exception e) {
                        log.info "Contenuto del documento non valido. Documento id [${documento.id}]"
                        return
                    }
                    if (variazioneRettificata != null) {
                        variazioneRettificata = response.'**'.Variazioni.Variazione.find { variazione ->
                            variazione.Trascrizione.Nota.NumeroNota == numeroNotaRettificata
                        }
                    }

                    // Si cercano altre rettifiche per la stessa nota
                    rettifiche << response.DatiPresenti.Variazioni.Variazione.findAll { variazione ->
                        variazione.Trascrizione.NotaRettificata.NumeroNota == numeroNotaRettificata &&
                                variazione.Trascrizione.Nota.NumeroNota != numeroNotaRettifca
                    }
                }
            }

            // Si crea il nuovo XML:
            // 1. Nota rettifica
            // 2. Nota rettificata
            // 3. Eventuali altre rettifiche della nota al punto 2 ordinate per numero di nota
            contenuto = new String(importDatiEsterniService.loadContenuto(documentoSelezionato.id), "UTF-8")
            response = new XmlSlurper(false, false).parseText(contenuto)
            response.DatiPresenti.Variazioni.Variazione.each { variazione ->
                variazione.replaceNode {}
            }

            // Aggiunta della nota rettifica
            response.DatiPresenti.Variazioni.appendNode(variazioneRettifica)

            // Aggiunta della nota rettificata
            response.DatiPresenti.Variazioni.appendNode(variazioneRettificata)

            // Aggiunte delle altre eventuali rettifiche
            rettifiche.each { node ->
                response.DatiPresenti.Variazioni.appendNode(node)
            }

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance()
            DocumentBuilder builder = factory.newDocumentBuilder()
            InputSource is = new InputSource(new StringReader(XmlUtil.serialize(response)))
            Document xmlDocument = builder.parse(is)

            // Use a Transformer for output
            TransformerFactory tFactory = TransformerFactory.newInstance()
            def xsltFile = grailsApplication.mainContext.getResource("xslt/notai.xslt").file
            StreamSource stylesource = new StreamSource(xsltFile)
            Transformer transformer = tFactory.newTransformer(stylesource)

            DOMSource source = new DOMSource(xmlDocument)
            StringWriter writer = new StringWriter()
            StreamResult result = new StreamResult(writer)
            transformer.transform(source, result)
            String nomeRettifica = documentoSelezionato.nomeDocumento
            nomeRettifica = nomeRettifica.substring(0, nomeRettifica.indexOf(".")) + ".html"

            AMedia amedia = new AMedia(nomeRettifica, "html", "text/html", writer.toString())
            Filedownload.save(amedia)

        } else {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance()
            DocumentBuilder builder = factory.newDocumentBuilder()
            InputSource is = new InputSource(new StringReader(contenuto))
            Document xmlDocument = builder.parse(is)

            // Use a Transformer for output
            TransformerFactory tFactory = TransformerFactory.newInstance()
            def xsltFile = grailsApplication.mainContext.getResource("xslt/notai.xslt").file
            StreamSource stylesource = new StreamSource(xsltFile)
            Transformer transformer = tFactory.newTransformer(stylesource)

            DOMSource source = new DOMSource(xmlDocument)
            StringWriter writer = new StringWriter()
            StreamResult result = new StreamResult(writer)
            transformer.transform(source, result)

            AMedia amedia = new AMedia(documentoSelezionato.nomeDocumento + ".html", "html", "text/html", writer.toString())
            Filedownload.save(amedia)
        }
    }

    @Command
    onAnnullaDocumento() {

        Messagebox.show("Vuoi annullare il documento caricato?", "Fiscalità locale", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
            void onEvent(Event evt) throws InterruptedException {
                if (evt.getName().equals("onOK")) {
                    annullaDocumento()
                }
            }
        }
        )
    }

    def annullaDocumento() {
        importDatiEsterniService.annullaDocumento(documentoSelezionato.id)

        documentoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")

        caricaListaDocumenti(true)
    }

    @NotifyChange(["listaAnomalie"])
    @Command
    onVisualizzaAnomalie(@BindingParam("popup") Component popupAnomalie) {
        listaAnomalie = importDatiEsterniService.caricaAnomalie(documentoSelezionato.id)
        popupAnomalie.open(self, "overlap")
    }

    @Command
    openCloseFiltri() {

        commonService.creaPopup("/ufficiotributi/datiesterni/importDatiRicerca.zul", self,
                [
                        filtro: filtro
                ],
                { event ->
                    if (event.data) {
                        filtro = event.data.filtro
                    }

                    filtroAttivo = filtro ? filtro.isAttivo() : false

                    BindUtils.postNotifyChange(null, null, this, "filtro")
                    BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                    onRefresh()
                }
        )
    }

    @Command
    def onExportDati() {
        commonService.creaPopup("/ufficiotributi/datiesterni/exportDati.zul", self, [:], {})
    }

    @Command
    def onExportXlsDati() {

        Map fields = [
                "id"              : "Id Documento",
                "descrizione"     : "Tipo documento",
                "nomeDocumento"   : "Nome file",
                "descrizioneStato": "Stato",
                "lastUpdated"     : "Data variazione",
                "note"            : "Note"
        ]

        def formatters = [
                "id": Converters.decimalToInteger
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.IMPORT_EXPORT,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, importDatiEsterniService.caricaListaDocumenti(filtro, Integer.MAX_VALUE, 0), fields, formatters)
    }

    private def caricaListaDocumenti(boolean resetPaginazione = false) {

        if (resetPaginazione) {
            activePage = 0
            pageSize = 30
            totalSize
        }


        def documenti = importDatiEsterniService.getListaDocumenti(filtro, pageSize, activePage)
        listaDocumentiCaricati = documenti.listaDocumenti
        totalSize = documenti.totale
        documentoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }
}
