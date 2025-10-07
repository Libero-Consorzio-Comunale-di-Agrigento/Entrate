package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheBaseService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCodificheBaseViewModel {

    // Componenti
    Window self

    // Services
    CodificheBaseService codificheBaseService
    CommonService commonService

    // Modello
    def tipoCodifica = ""

    def intestazioneTipo = ""
    def intestazioneDescrizione = ""
    def intestazioneOrdine = ""

    def tipoCodificaSelezionata
    def listaCodifiche = []
    def listaCodSoggetto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoCodifica") String tc) {

        this.self = w
        this.tipoCodifica = tc

        decodificaTipoCodifica()
    }


    // Eventi interfaccia

    @Command
    def onModificaCodificaBase() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCodificheBase.zul", self,
                [
                        codificaGenerica       : tipoCodificaSelezionata,
                        tipoCodifica           : tipoCodifica,
                        intestazioneTipo       : intestazioneTipo,
                        intestazioneDescrizione: intestazioneDescrizione,
                        intestazioneOrdine     : intestazioneOrdine,
                        isModifica             : true,
                        isClone                : false,
                        listaCodSoggetto       : listaCodSoggetto
                ]
        ) { event ->
            //Carico la lista di codifiche aggiornata
            onRefresh()
        }
    }

    @Command
    def onAggiungiCodificaBase() {

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioCodificheBase.zul", self,
                [
                        codificaGenerica       : null,
                        tipoCodifica           : tipoCodifica,
                        intestazioneTipo       : intestazioneTipo,
                        intestazioneDescrizione: intestazioneDescrizione,
                        intestazioneOrdine     : intestazioneOrdine,
                        isModifica             : false,
                        isClone                : true,
                        listaCodSoggetto       : listaCodSoggetto
                ]
        )

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            onRefresh()
        }
    }


    @Command
    def onEliminaCodificaBase() {

        String msg = "Si è scelto di eliminare la seguente codifica:\n" +
                this.intestazioneTipo + ": " + this.tipoCodificaSelezionata.tipo + "\n" +
                this.intestazioneDescrizione + ": " + this.tipoCodificaSelezionata.descrizione + ".\n" +
                "La codifica verrà eliminata e non sarà recuperabile.\n" +
                "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Codifica", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {
                    def dto = codificheBaseService.getCodifica(tipoCodificaSelezionata, tipoCodifica, true)
                    def messaggio = codificheBaseService.eliminaCodifica(dto, intestazioneTipo)
                    visualizzaRisultatoEliminazione(messaggio)
                    onRefresh()
                }
            }
        })
    }

    @Command
    onDuplica() {

        def clone = [
                descrizione: tipoCodificaSelezionata.descrizione,
                codSoggetto: tipoCodificaSelezionata.codSoggetto,
                ordine     : tipoCodificaSelezionata.ordine
        ]

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioCodificheBase.zul", self,
                [
                        codificaGenerica       : clone,
                        tipoCodifica           : tipoCodifica,
                        intestazioneTipo       : intestazioneTipo,
                        intestazioneDescrizione: intestazioneDescrizione,
                        intestazioneOrdine     : intestazioneOrdine,
                        isModifica             : false,
                        isClone                : true,
                        listaCodSoggetto       : listaCodSoggetto
                ]
        )

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            onRefresh()
        }
    }

    @Command
    def onExportXls() {

        Map fields

        if (listaCodifiche) {

            fields = [
                    "tipo"       : intestazioneTipo,
                    "descrizione": intestazioneDescrizione
            ]

            if (tipoCodifica == "cariche") {
                fields << ["codSoggetto.descrizione": "Codice Soggetto"]
                fields << ["flagOnline": "Online"]
            }
            if (tipoCodifica == "stati") {
                fields << ["ordine": "Ordine"]
            }

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CODIFICHE,
                    [tipoCodifica: tipoCodifica])

            def converters = [:]
            if (tipoCodifica == "cariche") {
                converters << [flagOnline: Converters.flagBooleanToString]
            }

            XlsxExporter.exportAndDownload(nomeFile, listaCodifiche, fields, converters)
        }
    }

    @Command
    onRefresh() {
        decodificaTipoCodifica()
        BindUtils.postNotifyChange(null, null, this, "listaCodifiche")
    }


    // Funzioni d'utilità


    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo!"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    private def decodificaTipoCodifica() {
        switch (tipoCodifica) {
            case 'oggetti':
                listaCodifiche = codificheBaseService.elencoOggetti()
                intestazioneTipo = "Oggetto"
                intestazioneDescrizione = "Descrizione"
                break
            case 'utilizzi':
                listaCodifiche = codificheBaseService.elencoUtilizzi()
                intestazioneTipo = "Utilizzo"
                intestazioneDescrizione = "Descrizione"
                break
            case 'usi':
                listaCodifiche = codificheBaseService.elencoUsi()
                intestazioneTipo = "Uso"
                intestazioneDescrizione = "Descrizione"
                break
            case 'codiciTributo':

                // Nulla da fare
                // Dati gestiti in apposito tab

                break
            case 'cariche':
                listaCodSoggetto = caricaCodSoggetto()
                listaCodifiche = codificheBaseService.elencoCariche()
                //Sostituisco l'id del codice soggetto con l'oggetto corrispondente (contiene sia id che descrizione da visualizzare lato zul)
                listaCodifiche.each {
                    def cod = it.codSoggetto
                    it.codSoggetto = listaCodSoggetto.find {
                        it.id == cod
                    }
                }
                intestazioneTipo = "Carica"
                intestazioneDescrizione = "Descrizione"
                break
            case 'aree':
                listaCodifiche = codificheBaseService.elencoAree()
                intestazioneTipo = "Area"
                intestazioneDescrizione = "Descrizione"
                break
            case 'contatti':
                listaCodifiche = codificheBaseService.elencoContatti()
                intestazioneTipo = "Contatto"
                intestazioneDescrizione = "Descrizione"
                break
            case 'richiedenti':
                listaCodifiche = codificheBaseService.elencoRichiedenti()
                intestazioneTipo = "Richiedente"
                intestazioneDescrizione = "Descrizione"
                break
            case 'fonti':
                listaCodifiche = codificheBaseService.elencoFonti()
                intestazioneTipo = "Fonte"
                intestazioneDescrizione = "Descrizione"
                break
            case 'tipiTributo':

                // Nulla da fare
                // Dati gestiti in apposito tab

                break
            case 'codiciAttività':
                listaCodifiche = codificheBaseService.elencoCodiciAttivita()
                intestazioneTipo = "Codice"
                intestazioneDescrizione = "Descrizione"
                break
            case 'stati':
                listaCodifiche = codificheBaseService.elencoStati()
                intestazioneTipo = "Stato"
                intestazioneDescrizione = "Descrizione"
                intestazioneOrdine = "Ordine"
                break
            case 'eventi':

                // Nulla da fare
                // Dati gestiti in apposito tab

                break
            case 'atti':
                listaCodifiche = codificheBaseService.elencoAtti()
                intestazioneTipo = "Atto"
                intestazioneDescrizione = "Descrizione"
                break
            case 'recapiti':
                listaCodifiche = codificheBaseService.elencoRecapiti()
                intestazioneTipo = "Recapito"
                intestazioneDescrizione = "Descrizione"
                break

        }
    }

    private def caricaCodSoggetto() {
        def lista = []

        def codCuratoreFallimentare = [:],
            codDefunto = [:],
            codErede = [:],
            codLiquidatore = [:],
            codRappresentante = [:],
            codTutore = [:],
            codCuratoreEredità = [:]

        codCuratoreFallimentare.id = "C"
        codCuratoreFallimentare.descrizione = "Curatore fallimentare"
        codDefunto.id = "D"
        codDefunto.descrizione = "Defunto"
        codErede.id = "E"
        codErede.descrizione = "Erede"
        codLiquidatore.id = "L"
        codLiquidatore.descrizione = "Liquidatore"
        codRappresentante.id = "R"
        codRappresentante.descrizione = "Rappresentante"
        codTutore.id = "T"
        codTutore.descrizione = "Tutore"
        codCuratoreEredità.id = "G"
        codCuratoreEredità.descrizione = "Curatore eredità giacente"

        lista << codCuratoreFallimentare << codDefunto << codErede << codLiquidatore << codRappresentante << codTutore << codCuratoreEredità

        return lista
    }

}
