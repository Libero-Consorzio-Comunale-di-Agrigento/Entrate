package archivio

import document.FileNameGenerator
import it.finmatica.tr4.CaricoTarsu
import it.finmatica.tr4.dto.CaricoTarsuDTO
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

import java.awt.*

class CalcoloFamiliariViewModel {

    // Componenti
    Window self

    @Wire('#labelData')
    Label labelData

    // Service
    SoggettiService soggettiService

    // Modello
    def idSoggetto
    def titoloPagina
    def labelContribuente
    def anno
    def dataDalAl
    def cbScadenzeParziali
    def modalitaSelezionata
    CaricoTarsuDTO carichiTarsu

    def listaModalita = [null] +
            [codice: 1, descrizione: 'Data Evento'] +
            [codice: 2, descrizione: 'Mese successivo all\'Evento'] +
            [codice: 3, descrizione: 'Bimestre solare'] +
            [codice: 4, descrizione: 'Semestre solare'] +
            [codice: 5, descrizione: 'Mese sulla base del giorno 15']

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idSoggetto") long id,
         @ExecutionArgParam("titolo") String titolo,
         @ExecutionArgParam("contribuenteDescr") String contribuenteDescr) {
        this.self = w
        dataDalAl = new Date(0, 00, 01)
        idSoggetto = (id > 0) ? id : null
        titoloPagina = titolo
        labelContribuente = contribuenteDescr
        BindUtils.postNotifyChange(null, null, this, "dataDalAl")
    }

    @Command
    onCalcolaNumeroFamiliari() {
        if (validaMaschera()) {
            setModalita()
            calcolaNumeroFamiliari()
        }
    }

    @Command
    def onChangeAnno() {
        //Sistemazione Data
        Integer giorno = dataDalAl.getAt(Calendar.DAY_OF_MONTH)
        Integer mese = dataDalAl.month
        Integer anno = anno - 1900
        dataDalAl = new Date(anno, mese, giorno)
        BindUtils.postNotifyChange(null, null, this, "dataDalAl")
        getModalita()
    }

    @Command
    def getModalita() {
        //Seleziono la modalità in funzione all'anno
        carichiTarsu = CaricoTarsu.findByAnno(this.anno)?.toDTO()
        if (carichiTarsu) {
            modalitaSelezionata = listaModalita.subList(1, listaModalita.size()).find { c -> c.codice == carichiTarsu?.modalitaFamiliari }
        } else {
            modalitaSelezionata = null
        }

        BindUtils.postNotifyChange(null, null, this, "modalitaSelezionata")
    }

    private setModalita() {
        if (modalitaSelezionata) {
            soggettiService.salvaCaricoTarsu(carichiTarsu, modalitaSelezionata.codice)
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    def generaReport(String messaggio) {
        String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.JASPER,
				FileNameGenerator.GENERATORS_TITLES.INSERIMENTO_FAMILIARI_SOGGETTI_NON_TRATTATI,
				[:])
        def report = soggettiService.generaReportCalcoloNumeroFamiliari(messaggio)

        if (report == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {
            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
            onChiudi()
        }
    }

    private boolean validaMaschera() {
        def errori = []

        if (anno == null) {
            errori << "Valore obbligatorio sul campo Anno"
        }

        if (dataDalAl == null || dataDalAl < new Date(0, 0, 1)) {
            errori << "La Data di riferimento deve essere maggiore di 01/01/1900"
            if (anno) {
                onChangeAnno()
            } else {
                dataDalAl = new Date(0, 00, 01)
            }
            BindUtils.postNotifyChange(null, null, this, "dataDalAl")
        }

        if (cbScadenzeParziali && modalitaSelezionata == null) {
            errori << "Occorre definire la modalita"
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    private calcolaNumeroFamiliari() {

        Long result
        String messaggio

        def applyResult = soggettiService.calcolaNumeroFamiliari(idSoggetto, anno, dataDalAl, (cbScadenzeParziali) ? "S" : "N", (cbScadenzeParziali) ? "S" : "N", modalitaSelezionata?.codice)
        result = applyResult.result
        messaggio = applyResult.messaggio

        String title = ""
        String message = ""
        int buttons = Messagebox.OK
        def icon = Messagebox.INFORMATION

        switch (result) {
            case 0:
                title = "Informazione"
                message = "Inserimento effettuato con successo"
                icon = Messagebox.INFORMATION
                buttons = Messagebox.OK
                break
            case 1:
                title = "Informazione"
                message = "Nessun soggetto elaborato"
                icon = Messagebox.INFORMATION
                buttons = Messagebox.OK
                break
            case 2:
                title = "Attenzione"
                message = "Inserimento Effettuato: Esistono Soggetti Non Trattati.\n Stampa Soggetti Non Trattati?"
                icon = Messagebox.EXCLAMATION
                buttons = Messagebox.YES | Messagebox.NO
                break
            case 3:
                title = "Errore"
                message = messaggio
                icon = Messagebox.ERROR
                buttons = Messagebox.OK
                break
        }
        Messagebox.show(message, title, buttons, icon,
                new org.zkoss.zk.ui.event.EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            generaReport(messaggio)
                        }
                    }
                }
        )
    }

}
