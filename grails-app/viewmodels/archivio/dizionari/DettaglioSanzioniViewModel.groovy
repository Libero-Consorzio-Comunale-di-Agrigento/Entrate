package archivio.dizionari

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.SanzioneDTO
import it.finmatica.tr4.sanzioni.SanzioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioSanzioniViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    // Servizi
    SanzioniService sanzioniService
    CommonService commonService

    // Componenti
    Window self

    def tipoOperazione
    def labels

    // Comuni
    def tipoTributo
    SanzioneDTO sanzioneSelezionata
    SanzioneDTO sanzione
    def listaCodiciTributo
    def listaGruppiSanzione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("sanzioneSelezionata") SanzioneDTO ss,
         @ExecutionArgParam("tipoOperazione") def to) {

        this.self = w

        this.labels = commonService.getLabelsProperties('dizionario')

        this.tipoTributo = tt
        this.tipoOperazione = to

        sanzioneSelezionata = ss

        initSanzione()

        listaCodiciTributo = OggettiCache.CODICI_TRIBUTO.valore.findAll { it?.tipoTributo?.tipoTributo == this.tipoTributo }
        listaGruppiSanzione = [null]
        listaGruppiSanzione.addAll(sanzioniService.getListaGruppiSanzione())
    }

    @Command
    onSalva() {

        if (!valida()) {
            return
        }

        sanzione.descrizione = sanzione.descrizione.toUpperCase()

        if (tipoOperazione == TipoOperazione.INSERIMENTO || tipoOperazione == TipoOperazione.CLONAZIONE) {
            sanzioniService.creaSanzione(sanzione.toDomain())
        } else {
            sanzioniService.salvaSanzione(sanzione.toDomain())
        }
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onChiudi()
    }

    private def valida() {
        def errors = []
        if (!sanzione.codSanzione ||
                (tipoOperazione in [TipoOperazione.INSERIMENTO, TipoOperazione.CLONAZIONE] && !((sanzione.codSanzione as Integer) in (1000..8999)))
        ) {
            errors << 'Codice deve essere compreso tra 1000 e 8999'
        }
        if (!sanzione.descrizione) {
            errors << 'Descrizione è obbligatorio'
        }

        if (!sanzione.dataInizio) {
            errors << 'Data Inizio è obbligatoria'
        }

        if (!sanzione.dataFine) {
            errors << 'Data Fine è obbligatoria'
        }

        if (sanzione.dataInizio > sanzione.dataFine) {
            errors << 'Data Inizio deve essere inferiore alla Data Fine'
        }

        if ((tipoOperazione == TipoOperazione.INSERIMENTO || tipoOperazione == TipoOperazione.CLONAZIONE) &&
                sanzioniService.existsSanzione(sanzione)) {
            errors << "Esiste già una Sanzione per la coppia Codice/Sequenza"

        }

        if (sanzioniService.presenzaDiSovrapposizioni(sanzione)) {
            errors << "Esistono periodi intersecanti per questa Sanzione"
        }

        if (errors.empty) {
            return true
        }
        Clients.showNotification(errors.join('\n'), Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true
        )
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCheckboxCheck(@BindingParam("flagCheckbox") def flagCheckbox) {

        // Inverte il flag del checkbox relativo tra null o 'S'
        this.sanzione."${flagCheckbox}" = this.sanzione."${flagCheckbox}" == null ? "S" : null
    }

    private def initSanzione() {

        if (tipoOperazione == TipoOperazione.INSERIMENTO) {

            this.sanzione = new SanzioneDTO()
            sanzione.dataFine = Date.parse('dd/MM/yyyy', '31/12/9999')

            this.sanzione.tipoTributo = TipoTributo.findByTipoTributo(this.tipoTributo).toDTO()

        } else if (tipoOperazione == TipoOperazione.CLONAZIONE) {
            this.sanzione = new SanzioneDTO()

            this.sanzione.codSanzione = sanzioneSelezionata.codSanzione
            this.sanzione.descrizione = sanzioneSelezionata.descrizione
            this.sanzione.flagCalcoloInteressi = sanzioneSelezionata.flagCalcoloInteressi
            this.sanzione.flagImposta = sanzioneSelezionata.flagImposta
            this.sanzione.flagInteressi = sanzioneSelezionata.flagInteressi
            this.sanzione.flagPenaPecuniaria = sanzioneSelezionata.flagPenaPecuniaria
            this.sanzione.gruppoSanzione = sanzioneSelezionata.gruppoSanzione
            this.sanzione.percentuale = sanzioneSelezionata.percentuale
            this.sanzione.riduzione = sanzioneSelezionata.riduzione
            this.sanzione.riduzione2 = sanzioneSelezionata.riduzione2
            this.sanzione.sanzione = sanzioneSelezionata.sanzione
            this.sanzione.sanzioneMinima = sanzioneSelezionata.sanzioneMinima
            this.sanzione.tipoTributo = sanzioneSelezionata.tipoTributo
            this.sanzione.tributo = sanzioneSelezionata.tributo
            this.sanzione.codTributoF24 = sanzioneSelezionata.codTributoF24
            this.sanzione.flagMaggTares = sanzioneSelezionata.flagMaggTares
            this.sanzione.rata = sanzioneSelezionata.rata
            this.sanzione.tipologiaRuolo = sanzioneSelezionata.tipologiaRuolo
            this.sanzione.tipoCausale = sanzioneSelezionata.tipoCausale
            this.sanzione.flagCalcoloInteressi = sanzioneSelezionata.flagCalcoloInteressi
            sanzione.dataFine = Date.parse('dd/MM/yyyy', '31/12/9999')
        } else {
            this.sanzione = sanzioneSelezionata
        }

    }

}
