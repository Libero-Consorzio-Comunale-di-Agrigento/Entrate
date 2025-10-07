package archivio.dizionari

import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.dto.comunicazioni.DettaglioComunicazioneDTO
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.smartpnd.SmartPndService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioComunicazioneViewModel {

    // Componenti
    Window self
    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    ComunicazioniService comunicazioniService
    ComunicazioniTestiService comunicazioniTestiService
    SmartPndService smartPndService

    def dettaglioComunicazione

    def listaComunicazioneParametri

    def listaTipiCanale

    def allListaTipoComunicazioneSmartPnd
    def listaTipoComunicazioneSmartPnd

    def lettura = false
    def smartPndAbilitato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("dettaglioComunicazione") DettaglioComunicazioneDTO dettaglioComunicazione,
         @ExecutionArgParam("lettura") def lettura
    ) {

        if (dettaglioComunicazione == null) {
            throw new RuntimeException("dettaglioComunicazione non specificato")
        }

        if (dettaglioComunicazione.tipoTributo == null) {
            throw new RuntimeException("tipoTributo non specificato")
        }

        if (dettaglioComunicazione.tipoComunicazione == null) {
            throw new RuntimeException("tipoComunicazione non specificato")
        }

        this.self = w

        this.lettura = lettura ?: false

        // Un dettaglio utilizzato in una massiva non può essere modificato
        if (!this.lettura) {
            this.lettura = AttivitaElaborazione.countByDettaglioComunicazione(dettaglioComunicazione.toDomain()) > 0
        }

        this.smartPndAbilitato = smartPndService.smartPNDAbilitato()

        // Modifica di un dettaglio
        if (dettaglioComunicazione.sequenza != null) {
            this.dettaglioComunicazione = new DettaglioComunicazioneDTO()
            InvokerHelper.setProperties(this.dettaglioComunicazione, dettaglioComunicazione.properties)
        } else {
            this.dettaglioComunicazione = dettaglioComunicazione
            dettaglioComunicazione.sequenza =
                    comunicazioniService.generaSequenza(dettaglioComunicazione.tipoTributo.toDomain(),
                            dettaglioComunicazione.tipoComunicazione)

        }

        this.listaComunicazioneParametri = comunicazioniService.getListaComunicazioneParametri([
                tipoTributo: dettaglioComunicazione?.tipoTributo?.tipoTributo
        ])

        this.listaTipiCanale = [null, *comunicazioniTestiService.getListaTipiCanale()]

        this.dettaglioComunicazione.tag = smartPndAbilitato ? null : this.dettaglioComunicazione.tag
        this.dettaglioComunicazione.tipoComunicazionePnd = smartPndAbilitato ? this.dettaglioComunicazione.tipoComunicazionePnd : null

        if (smartPndAbilitato) {
            allListaTipoComunicazioneSmartPnd = smartPndService.listaTipologieComunicazione()
            fetchTipiComunicazioneSmartPnd()
        }
    }

    @AfterCompose
    void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

        if (lettura) {
            componenti.each {
                it.disabled = true
            }
        }
    }

    @Command
    onSalva() {

        def errori = controllaParametri()

        if (!errori.empty) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, ["dettaglioComunicazione": dettaglioComunicazione])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    @Command
    void onChangeTipoCanale() {
        if (smartPndAbilitato) {
            fetchTipiComunicazioneSmartPnd()
            dettaglioComunicazione.tipoComunicazionePnd = null

        }
        BindUtils.postNotifyChange(null, null, dettaglioComunicazione, 'tipoComunicazionePnd')
        BindUtils.postNotifyChange(null, null, this, "listaTipoComunicazioneSmartPnd")
    }

    private void fetchTipiComunicazioneSmartPnd() {
        switch (dettaglioComunicazione?.tipoCanale?.id) {
            case TipiCanaleDTO.APPIO:
                fetchTipiComunicazioneSmartPndAPPIO()
                break
            case TipiCanaleDTO.PND:
                fetchTipiComunicazioneSmartPndPND()
                break
            case [TipiCanaleDTO.EMAIL, TipiCanaleDTO.PEC]:
                fetchTipiComunicazioneSmartPndEMAIL()
                break
            default:
                fetchTipiComunicazioneSmartPndEmpty()
                break
        }
    }

    private void fetchTipiComunicazioneSmartPndAPPIO() {
        this.listaTipoComunicazioneSmartPnd = allListaTipoComunicazioneSmartPnd.findAll {
            it.tagAppio != null
        }
    }

    private void fetchTipiComunicazioneSmartPndPND() {
        this.listaTipoComunicazioneSmartPnd = allListaTipoComunicazioneSmartPnd.findAll {
            it.tagPnd != null
        }
    }

    private void fetchTipiComunicazioneSmartPndEMAIL() {
        this.listaTipoComunicazioneSmartPnd = allListaTipoComunicazioneSmartPnd.findAll {
            it.tagMail != null
        }
    }

    private void fetchTipiComunicazioneSmartPndEmpty() {
        this.listaTipoComunicazioneSmartPnd = []
    }

    private def controllaParametri() {

        def errori = []

        if (dettaglioComunicazione.tipoComunicazione == null) {
            errori << "Il campo Tipo Comunicazione è obbligatorio"
        }

        if (dettaglioComunicazione.descrizione == null) {
            errori << "Il campo Descrizione è obbligatorio"
        }

        if ((dettaglioComunicazione.tipoComunicazionePnd?.trim()
                || dettaglioComunicazione.tipoComunicazionePnd?.trim()) && dettaglioComunicazione.tipoCanale == null) {
            errori << "Selezionare il Tipo Canale"
        }

        if (smartPndAbilitato && comunicazioniTestiService.esisteDettaglioComunicazione(
                dettaglioComunicazione.tipoTributo.toDomain(),
                dettaglioComunicazione.tipoComunicazione,
                dettaglioComunicazione.tipoCanale.toDomain(),
                dettaglioComunicazione.tipoComunicazionePnd,
                dettaglioComunicazione.sequenza)) {
            errori << "Esiste già un dettaglio comunicazione per (${dettaglioComunicazione.tipoTributo.getTipoTributoAttuale()}, ${dettaglioComunicazione.tipoCanale.descrizione}, ${dettaglioComunicazione.tipoComunicazionePnd})"
        }

        return errori
    }

}
