package ufficiotributi.imposte

import it.finmatica.tr4.CaricoTarsu
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.SpecieRuolo
import it.finmatica.tr4.commons.TipoRuolo
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioListaDiCaricoViewModel {

    // Services
    def springSecurityService
    CommonService commonService

    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    IntegrazioneDePagService integrazioneDePagService

    // Componenti
    Window self

    // Generali
    boolean aggiornaStato = false

    TributiSession tributiSession

    TipoTributoDTO tipoTributo
    String tipoTributoDescr

    boolean modificabile = false
    boolean esistente = false

    boolean dePagAbilitato = false
    boolean flagEliminaDepag = false

    // Dati
    RuoloDTO ruolo
    Boolean flagInviato
    Boolean flagLordo
    Boolean flagTarPrecalcolata
    Boolean flagTarBase
    Boolean flagDePag
    Short numeroRate
    def invioConsorzioOriginale
    def flagIscrittiAltroRuolo = true

    def tipiRuolo = [
            [codice: null, descrizione: ''],
            [codice: TipoRuolo.PRINCIPALE.tipoRuolo, descrizione: 'P - Principale'],
            [codice: TipoRuolo.SUPPLETTIVO.tipoRuolo, descrizione: 'S - Suppletivo']
    ]
    def tipoRuoloSelected = null

    def specieRuolo = [
            [codice: null, descrizione: ''],
            [codice: 0, descrizione: '0 - Ordinario'],
            [codice: 1, descrizione: '1 - Coattivo']
    ]
    def specieRuoloSelected = null

    def tipiCalcolo = [
            [codice: null, descrizione: ''],
            [codice: 'T', descrizione: 'Tradizionale'],
            [codice: 'N', descrizione: 'Normalizzato']
    ]
    def tipoCalcoloSelected = null

    def tipiEmissione = [
            [codice: null, descrizione: ''],
            [codice: 'A', descrizione: 'Acconto'],
            [codice: 'S', descrizione: 'Saldo'],
            [codice: 'T', descrizione: 'Totale']
    ]
    def tipoEmissioneSelected = null

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") Long rr,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("modifica") boolean md) {

        this.self = w

        modificabile = md

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        tipoTributo = TipoTributo.get(tt).toDTO()
        tipoTributoDescr = tipoTributo.getTipoTributoAttuale()

        if (rr != null) {
            ruolo = Ruolo.get(rr).toDTO()
            esistente = true
        } else {
            Short annoAttuale = Calendar.getInstance().get(Calendar.YEAR)
            ruolo = new RuoloDTO()
            ruolo.annoRuolo = annoAttuale
            ruolo.annoEmissione = annoAttuale
            ruolo.tipoTributo = tipoTributo
            ruolo.tipoRuolo = TipoRuolo.PRINCIPALE.tipoRuolo
            ruolo.specieRuolo = SpecieRuolo.ORDINARIO.specieRuolo
            ruolo.dataEmissione = new Date()
            ruolo.rate = 1
            ruolo.flagIscrittiAltroRuolo = 'S'
            esistente = false
        }

        if (!dePagAbilitato) {
            ruolo.flagDePag = null
            ruolo.flagEliminaDepag = null
        }

        impostaRuolo()
    }

    // Eventi interfaccia

    @Command
    def onChangeTipoRuolo() {

    }

    @Command
    def onChangeSpecieRuolo() {

    }

    @Command
    def onChangeTipoCalcolo() {

        String tipoCalcolo = tipoCalcoloSelected?.codice

        if (tipoCalcolo != 'N') {
            if (flagTarPrecalcolata) {
                flagTarPrecalcolata = false
                BindUtils.postNotifyChange(null, null, this, "flagTarPrecalcolata")
            }
        } else {
            flagTarPrecalcolata = CaricoTarsu.findByAnno(ruolo.annoEmissione)?.flagTariffeRuolo == 'S'
            flagTarBase = flagTarPrecalcolata
            BindUtils.postNotifyChange(null, null, this, "flagTarPrecalcolata")
            BindUtils.postNotifyChange(null, null, this, "flagTarBase")
        }
    }

    @Command
    def onChangeTipoEmissione() {

        String tipoEmissione = tipoEmissioneSelected?.codice

        if (tipoEmissione != 'A') {
            if (ruolo.percAcconto) {
                ruolo.percAcconto = null
                BindUtils.postNotifyChange(null, null, this, "ruolo")
            }
        }
    }

    @Command
    def onChangePercAcconto() {

        Boolean changed = false

        if (ruolo.percAcconto) {
            if (ruolo.percAcconto > 100.0) {
                ruolo.percAcconto = 100.0; changed = true
            }
            if (ruolo.percAcconto < 0.01) {
                ruolo.percAcconto = 0.01; changed = true
            }
        }
        if (changed) {
            BindUtils.postNotifyChange(null, null, this, "ruolo")
        }
    }

    @Command
    def onCheckLordo() {

    }

    @Command
    def onCheckTarPrecalcolata() {

        if (flagTarPrecalcolata) {
            flagTarBase = true
            BindUtils.postNotifyChange(null, null, this, "flagTarBase")
        }
    }

    @Command
    def onCheckTarBase() {

    }

    @Command
    def onChangeInvioConsorzio() {

        if (ruolo.invioConsorzio != invioConsorzioOriginale) {

            if (checkCoerenzaInvioConsorzio() == false) {
                ruolo.invioConsorzio = invioConsorzioOriginale
                BindUtils.postNotifyChange(null, null, this, "ruolo")
            }
        }

        flagInviato = (ruolo.invioConsorzio != null)
        BindUtils.postNotifyChange(null, null, this, "flagInviato")
    }

    @Command
    def onChangeNumeroRate() {

        Boolean changed = false

        if (ruolo.rate < 1) {
            ruolo.rate = 1
            changed = true
        }
        if (ruolo.rate > 4) {
            ruolo.rate = 4
            changed = true
        }

        if (ruolo.rate < 2) {
            if (ruolo.scadenzaRata2) {
                ruolo.scadenzaRata2 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso2) {
                ruolo.scadenzaAvviso2 = null
                changed = true
            }
        }
        if (ruolo.rate < 3) {
            if (ruolo.scadenzaRata3) {
                ruolo.scadenzaRata3 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso3) {
                ruolo.scadenzaAvviso3 = null
                changed = true
            }
        }
        if (ruolo.rate < 4) {
            if (ruolo.scadenzaRata4) {
                ruolo.scadenzaRata4 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso4) {
                ruolo.scadenzaAvviso4 = null
                changed = true
            }
        }
        if (changed) {
            BindUtils.postNotifyChange(null, null, this, "ruolo")
        }

        if (numeroRate != ruolo.rate) {
            numeroRate = ruolo.rate
            BindUtils.postNotifyChange(null, null, this, "numeroRate")
        }
    }

    @Command
    def onCheckFlagDePag() {

        Boolean changed = false

        if (!flagDePag) {

            if (ruolo.scadenzaAvviso1) {
                ruolo.scadenzaAvviso1 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso2) {
                ruolo.scadenzaAvviso2 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso3) {
                ruolo.scadenzaAvviso3 = null
                changed = true
            }
            if (ruolo.scadenzaAvviso4) {
                ruolo.scadenzaAvviso4 = null
                changed = true
            }
            if (ruolo.scadenzaAvvisoUnico) {
                ruolo.scadenzaAvvisoUnico = null
                changed = true
            }
            if(flagEliminaDepag) {
                flagEliminaDepag = false
                changed = true
            }
        }

        if (changed) {
            BindUtils.postNotifyChange(null, null, this, "ruolo")
            BindUtils.postNotifyChange(null, null, this, "flagEliminaDepag")
        }
    }

    @Command
    def onEmissioneRuolo() {

        def datiEmissione = [:]

        datiEmissione.ruolo = ruolo.id as Long
        datiEmissione.codFiscale = '%'

        commonService.creaPopup("/sportello/contribuenti/emissioneRuolo.zul", self,
                [ruolo: datiEmissione, lettura: false],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            ruolo = Ruolo.get(ruolo.id).toDTO()
                            impostaRuolo()
                            aggiornaStato = true
                            if (RuoloContribuente.countByRuolo(Ruolo.get(ruolo.id)) > 0) {
                                Clients.showNotification("Contribuenti inseriti in ruolo [${ruolo.id}]", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                            } else {
                                Clients.showNotification("Contribuenti non inseriti in ruolo [${ruolo.id}]", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                            }
                        }
                    }
                })
    }

    @Command
    def onSalva() {

        if (!completaRuolo()) {
            return
        }
        if (!verificaRuolo()) {
            return
        }

        if (ruolo.id) {

            def report = listeDiCaricoRuoliService.checkCalcoloRuolo(ruolo)
            if (report.result != 0) {

                String message = "${report.message}\n\nPer la correttezza dei dati verra' eliminato e riemesso il ruolo.\n\nSi vuole procedere?"

                Messagebox.show(message, "Attenzione",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    salvaRuolo(true)
                                }
                            }
                        }
                )
            } else {
                salvaRuolo(false)
            }
        } else {
            salvaRuolo(false)
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, ruolo: ruolo])
    }

    @Command
    def onSelectTipoRuolo() {
        flagIscrittiAltroRuolo = (tipoRuoloSelected.codice == 1)
        BindUtils.postNotifyChange(null, null, this, "flagIscrittiAltroRuolo")
    }

    // Funzioni interne

    // Attiva ruolo impostata
    def impostaRuolo() {

        tipoRuoloSelected = tipiRuolo.find { it.codice == ruolo.tipoRuolo }
        def codSpecieRuolo = ruolo.specieRuolo ? 1 : 0
        specieRuoloSelected = specieRuolo.find { it.codice == codSpecieRuolo }
        tipoCalcoloSelected = tipiCalcolo.find { it.codice == ruolo.tipoCalcolo }
        tipoEmissioneSelected = tipiEmissione.find { it.codice == ruolo.tipoEmissione }

        flagLordo = ruolo.importoLordo
        flagTarPrecalcolata = (ruolo.flagTariffeRuolo == 'S')
        flagTarBase = (ruolo.flagCalcoloTariffaBase == 'S')
        flagDePag = (ruolo.flagDePag == 'S')
        flagEliminaDepag = (ruolo.flagEliminaDepag == 'S')
        numeroRate = ruolo.rate
        flagIscrittiAltroRuolo = ruolo.flagIscrittiAltroRuolo == 'S'

        invioConsorzioOriginale = ruolo.invioConsorzio

        onChangeInvioConsorzio()
        onCheckTarPrecalcolata()
        onChangePercAcconto()

        onCheckFlagDePag()
        onChangeNumeroRate()

        BindUtils.postNotifyChange(null, null, this, "ruolo")

        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "esistente")
    }

    // Completa prima di verifica e salvataggio
    private def completaRuolo() {

        String message = ""
        boolean result = true

        ruolo.tipoRuolo = tipoRuoloSelected?.codice ?: -1
        ruolo.tipoCalcolo = tipoCalcoloSelected?.codice
        ruolo.tipoEmissione = tipoEmissioneSelected?.codice
        ruolo.flagIscrittiAltroRuolo = flagIscrittiAltroRuolo ? 'S' : null

        if (ruolo.tipoEmissione != 'A') {
            ruolo.percAcconto = null
        }

        ruolo.importoLordo = flagLordo
        ruolo.flagTariffeRuolo = flagTarPrecalcolata ? 'S' : null
        ruolo.flagCalcoloTariffaBase = flagTarBase ? 'S' : null

        ruolo.flagDePag = flagDePag ? 'S' : null
        ruolo.flagEliminaDepag = flagEliminaDepag ? 'S' : null

        if (ruolo.invioConsorzio == null) {
            ruolo.progrInvio = null
        }

        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            result = false
        }

        return result
    }

    // Controlla coerenza Invio -> true se tutto ok, false se anomalia di emissione
    private Boolean checkCoerenzaInvioConsorzio() {

        Boolean result = true

        completaRuolo()

        def report = listeDiCaricoRuoliService.checkCoerenzaInvioConsorzio(ruolo)

        visualizzaReport(report, '')

        if (report.result != 0) {
            result = false
        }

        return result
    }

    // Verifica coerenza dati
    private def verificaRuolo() {

        boolean result = true

        def report = listeDiCaricoRuoliService.verificaListaDiCarico(ruolo)

        if (report.result != 0) {
            report.message = "Attenzione :\n\n${report.message}"
        }

        visualizzaReport(report, '')

        if (report.result > 1) {
            result = false
        }

        return result
    }

    // Salva il ruolo, eventualmente elimina il calcolo precedente
    def salvaRuolo(Boolean eliminaCalcoloPrecedente) {

        def report = listeDiCaricoRuoliService.salvaListaDiCarico(ruolo, eliminaCalcoloPrecedente)
        if (report.result < 2) {
            ruolo = report.ruolo
            impostaRuolo()
        }

        visualizzaReport(report, "Salvataggio eseguito con successo")

        if (report.result == 0) {
            aggiornaStato = true
        }

        if (report.result == 0) {
            if (ruolo.getDomainObject() == null) {
                onChiudi()
            }
        }

        if (report.result == 0 && (!esistente || eliminaCalcoloPrecedente)) {

            if (eliminaCalcoloPrecedente) {
                onEmissioneRuolo()
            } else {
                String messaggio = "Procedere con Emissione Ruolo?"
                Messagebox.show(messaggio, "Attenzione",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    onEmissioneRuolo()
                                }
                            }
                        }
                )
            }
        }
    }

    // Visualizza report
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if (!(messageOnSuccess ?: '').empty) {
                    Clients.showNotification(messageOnSuccess, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 5000, true)
                }
                break
            case 1:
                Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 8000, true)
                break
            case 2:
                Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }
    }
}
