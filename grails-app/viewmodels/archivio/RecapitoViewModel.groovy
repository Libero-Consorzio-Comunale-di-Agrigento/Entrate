package archivio

import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.ArchivioVie
import it.finmatica.tr4.TipoRecapito
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.ArchivioVieDTO
import it.finmatica.tr4.dto.RecapitoSoggettoDTO
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Textbox
import org.zkoss.zul.Window

class RecapitoViewModel {

    Window self

    @Wire('#bandBoxComuneRecapito')
    Textbox bandBoxComuneRecapito

    SoggettiService soggettiService
    DatiGeneraliService datiGeneraliService

    //Modello
    def listaTipiRecapito
    def listaTipiTributo
    Ad4ComuneDTO comuneCliente
    def selectedRecapito = new RecapitoSoggettoDTO()
    boolean modifica
    def verificaProvinciaEnte = false
    def flagProvincia
    def salvaRecapito

    Map filtri = [comuneEvento: [comune: "", denominazione: "", provincia: "", sigla: ""]]

    @NotifyChange([
            "selectedRecapito",
            "filtri",
            "comuneCliente"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("recapito") RecapitoSoggettoDTO recapito,
         @ExecutionArgParam("modifica") boolean modificaRecapito,
         @ExecutionArgParam("duplica") @Default("false") boolean duplicaRecapito,
         @ExecutionArgParam("salva") @Default("true") boolean salvaRecapito) {

        this.self = w
        modifica = modificaRecapito

        if (duplicaRecapito) {
            selectedRecapito = soggettiService.duplicaRecapitoSoggetto(recapito)
        } else {
            this.selectedRecapito = (recapito) ? recapito : new RecapitoSoggettoDTO()
        }
        selectedRecapito.archivioVie = recapito.archivioVie ?: new ArchivioVieDTO()
        selectedRecapito.comuneRecapito = recapito.comuneRecapito ?: new Ad4ComuneTr4DTO(ad4Comune: new Ad4ComuneDTO(denominazione: ""))
        filtri.comuneEvento.denominazione = selectedRecapito.comuneRecapito?.ad4Comune?.denominazione
        listaTipiRecapito = TipoRecapito.list().toDTO().sort { it.id }
        listaTipiTributo = [null, *TipoTributo.list().toDTO()
                .findAll { it.tipoTributo != 'TRASV' }
                .sort { it.tipoTributo }]
        comuneCliente = datiGeneraliService.getComuneCliente()

        if (selectedRecapito.comuneRecapito.provinciaStato > 200) {
            selectedRecapito.zipcode = selectedRecapito.zipcode ?: selectedRecapito?.comuneRecapito?.ad4Comune?.cap
        } else {
            selectedRecapito.cap = selectedRecapito.cap ?: selectedRecapito?.comuneRecapito?.ad4Comune?.cap
        }

        flagProvincia = datiGeneraliService.flagProvinciaAbilitato()
        def isSameComune = comuneCliente.comune == selectedRecapito.comuneRecapito?.ad4Comune?.comune
        verificaProvinciaEnte = flagProvincia && isSameComune

        this.salvaRecapito = salvaRecapito

    }


    @Command
    def onSelectComune(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event.getData()) {
            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            filtri.comuneEvento = filtri.comuneEvento = [
                    comune       : ad4ComuneTr4DTO.ad4Comune.comune,
                    denominazione: ad4ComuneTr4DTO.ad4Comune.denominazione,
                    provincia    : ad4ComuneTr4DTO.ad4Comune?.provincia?.id,
                    sigla        : ad4ComuneTr4DTO.ad4Comune?.provincia?.sigla]
            selectedRecapito.comuneRecapito = ad4ComuneTr4DTO

            if (ad4ComuneTr4DTO.provinciaStato > 200) {
                selectedRecapito.zipcode = ad4ComuneTr4DTO?.ad4Comune?.cap
                selectedRecapito.cap = null
            } else {
                selectedRecapito.cap = ad4ComuneTr4DTO?.ad4Comune?.cap
                selectedRecapito.zipcode = null
            }

            def isSameComune = comuneCliente.comune == selectedRecapito.comuneRecapito?.ad4Comune?.comune
            verificaProvinciaEnte = flagProvincia && isSameComune

        } else {
            filtri.comuneEvento = [comune: "", denominazione: "", provincia: "", sigla: ""]
        }
        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    def onChangeComune(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {
        filtri.comuneEvento = [comune: "", denominazione: "", provincia: "", sigla: ""]

        if (selectedRecapito.comuneRecapito) {
            selectedRecapito.comuneRecapito = null
            selectedRecapito.cap = null
            selectedRecapito.zipcode = null
        }

        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, [recapito: null])
    }

    @Command
    onSalva() {
        if (validaMaschera()) {
            if (selectedRecapito?.tipoRecapito?.id == 1) {
                // Non è stato selezionato un Comune
                if (!selectedRecapito?.comuneRecapito?.ad4Comune?.denominazione?.isEmpty() &&
                        !selectedRecapito?.comuneRecapito?.ad4Comune?.id) {
                    Messagebox.show("Comune non valido.", "Gestione Recapiti", Messagebox.OK, Messagebox.ERROR)
                    return
                }

                // Eliminazione del comune
                if (selectedRecapito?.comuneRecapito?.ad4Comune?.denominazione?.isEmpty()) {
                    selectedRecapito?.comuneRecapito = null
                }

                // L'indirizzo selezionato non è nello stradario
                if (comuneCliente?.id == selectedRecapito?.comuneRecapito?.ad4Comune?.id && !verificaProvinciaEnte) {
                    if (selectedRecapito?.archivioVie?.id == null) {
                        Messagebox.show("Indirizzo non valido.", "Gestione Recapiti", Messagebox.OK, Messagebox.ERROR)
                        return
                    }
                }
            }

            if (selectedRecapito.tipoRecapito.id in [2L, 3L]) {
                selectedRecapito.descrizione = selectedRecapito.descrizione?.trim()
            }

            // Controllo intersezioni date
            def numIntersezioni = soggettiService.checkIntersezioniDateRecapito(selectedRecapito)
            if (numIntersezioni > 0) {
                Clients.showNotification("Esistono altri Periodi intersecanti per Soggetto, tipo tributo e tipo recapito", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return
            }

            // Se estero deve essere valorizzato lo zip
            if (selectedRecapito?.comuneRecapito?.provinciaStato > 200 && selectedRecapito.cap != null) {
                Clients.showNotification("Per gli stati esteri deve essere utilizzato il campo ZIP",
                        Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                return
            }
            if (selectedRecapito?.comuneRecapito?.provinciaStato <= 200 && selectedRecapito.zipcode != null) {
                Clients.showNotification("Per i comuni italiani deve essere utilizzato il campo CAP",
                        Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                return
            }

            if (salvaRecapito) {
                selectedRecapito = soggettiService.salvaRecapitoSoggetto(selectedRecapito)
                Clients.showNotification("Recapito salvato con successo.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            }

            Events.postEvent(Events.ON_CLOSE, self, [recapito: selectedRecapito])
        }
    }

    @Command
    onCheckData() {
        if (selectedRecapito.dal && selectedRecapito.al && selectedRecapito.dal > selectedRecapito.al) {
            selectedRecapito.al = null
            Clients.showNotification("Data Inizio 'Dal' maggiore di Data Fine 'Al'", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            BindUtils.postNotifyChange(null, null, selectedRecapito, "al")
        }
    }

    @Command
    onSelectComuneRecapito(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        selectedRecapito.comuneRecapito = new Ad4ComuneTr4DTO(
                ad4Comune: event.getData(),
                comune: event.getData().comune,
                provinciaStato: event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
        )

        selectedRecapito.cap = event.getData().cap

        if (comuneCliente.id != selectedRecapito?.comuneRecapito?.ad4Comune?.id) {
            selectedRecapito.descrizione = selectedRecapito?.archivioVie?.denomUff ?: selectedRecapito.descrizione
            selectedRecapito.archivioVie = null
        } else {
            selectedRecapito.archivioVie = ArchivioVie.findByDenomUffIlike(selectedRecapito.descrizione)?.toDTO()
        }
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onSelectIndirizzoRecapito(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        selectedRecapito.archivioVie = event.data
        def componente = event.getTarget()
        componente.value = event.data.denomUff ?: ""
        BindUtils.postNotifyChange(null, null, this, "componente")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onErrorVie(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        selectedRecapito.archivioVie?.id = null
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onError(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        selectedRecapito.comuneRecapito.ad4Comune = null
        selectedRecapito.comuneRecapito.comune = null
        selectedRecapito.comuneRecapito.provinciaStato = null
        selectedRecapito.cap = null
        selectedRecapito.zipcode = null
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    private boolean validaMaschera() {
        def errori = []

        if (selectedRecapito.tipoRecapito == null) {
            errori << "Indicare il Tipo Recapito!"
        }

        if (selectedRecapito.dal && selectedRecapito.al && selectedRecapito.dal > selectedRecapito.al) {
            selectedRecapito.al = null
            Clients.showNotification("Data Inizio 'Dal' maggiore di Data Fine 'Al'", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            BindUtils.postNotifyChange(null, null, selectedRecapito, "al")
            return false
        }

        if (!bandBoxComuneRecapito?.getValue()?.isEmpty() && selectedRecapito.comuneRecapito == null) {
            errori << "Selezionare il Comune del Recapito"
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }
}
