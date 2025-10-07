package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.imposte.SgraviOrdinamento
import it.finmatica.tr4.imposte.SgraviService
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class SgraviFunzioniViewModel {

    // Componenti
    Window self

    // Services
    def springSecurityService
    SgraviService sgraviService

    // Comuni
    def tipoFunzione
    def titolo
    //Dettaglio elenco / Annulla Elenco
    def elenco
    def elencoSelezionato
    //Numera elenco
    def numeraElencoNumero
    def numeraElencoData
    //Dettaglio sgravio
    def sgravioSelezionato
    def ordinamentoSelezionato
    def ordinamenti = [
            SgraviOrdinamento.ALFABETICO,
            SgraviOrdinamento.CODFISCALE,
            SgraviOrdinamento.NUMERO
    ]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoFunzione") def tf,
         @ExecutionArgParam("sgravioSelezionato") def ss) {

        this.self = w
        this.tipoFunzione = tf

        //Unico zul per tutte le funzioni
        switch (this.tipoFunzione) {
            case "dettaglioElenco":
                this.titolo = "Ricerca Dettaglio Elenco"
                this.elenco = sgraviService.getNumeroElencoFunzioni()
                this.elencoSelezionato = !elenco.empty ? elenco[0] : ""
                break
            case "numeraElenco":
                this.titolo = "Numera Elenco"
                break
            case "annullaElenco":
                this.titolo = "Annulla Sgravi"
                this.elenco = sgraviService.getNumeroElencoFunzioni()
                this.elencoSelezionato = elenco.empty ? elenco[0] : ""
                break
            case "dettaglioSgravio":
                this.titolo = "Dettaglio Sgravio"
                this.sgravioSelezionato = ss
                this.ordinamentoSelezionato = SgraviOrdinamento.ALFABETICO //Ordinamento di default
                break
        }

    }

    //Eventi interfaccia
    @Command
    onOk() {
        switch (tipoFunzione) {
            case "dettaglioElenco":
                dettaglioElenco()
                break
            case "numeraElenco":
                numeraElenco()
                break
            case "annullaElenco":
                annullaElenco()
                break
            case "dettaglioSgravio":
                dettaglioSgravio()
                break
        }
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def dettaglioElenco() {

        def dec = decodificaNumData(elencoSelezionato)

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.DETTAGLIO_ELENCO_SGRAVI,
                [:])

        def reportElenco = sgraviService.generaDettaglioElenco(elencoSelezionato, dec.numero, dec.data)

        if (reportElenco == null) {
            Clients.showNotification("Errore nella generazione della stampa"
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportElenco.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def dettaglioSgravio() {

        def motivoSgravio = sgravioSelezionato.motivoSgravioCat.split(" - ")[0].trim() as Integer

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.DETTAGLIO_SGRAVIO,
                [:])

        def reportSgravio = sgraviService.generaDettaglioSgravio(sgravioSelezionato.dataElenco, motivoSgravio, sgravioSelezionato.numeroElenco, sgravioSelezionato.ruolo, ordinamentoSelezionato)

        if (reportSgravio == null) {
            Clients.showNotification("Errore nella generazione della stampa"
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportSgravio.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def numeraElenco() {

        def result = sgraviService.numeraElencoProcedure(this.numeraElencoNumero, this.numeraElencoData)

        if (result.empty) {
            Clients.showNotification("Elenco numerato con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${result}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    @Command
    def annullaElenco() {

        def dec = decodificaNumData(elencoSelezionato)

        def result = sgraviService.annullaElencoProcedure(dec.numero, dec.data)

        if (result.empty) {
            Clients.showNotification("Elenco annullato con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${result}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }


    //Funzioni d'utilità
    def decodificaNumData(def campo) {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")

        //campo stringa nel formato: ' 1 - 01/01/2000'
        def numero = campo.split(" - ")[0].trim() as Integer
        def data = sdf.parse(campo.split(" - ")[1])

        return ["numero": numero, "data": data]
    }

}
