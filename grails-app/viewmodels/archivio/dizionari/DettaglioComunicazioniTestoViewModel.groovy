package archivio.dizionari


import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.dto.DocumentoContribuenteDTO
import it.finmatica.tr4.dto.comunicazioni.testi.ComunicazioneTestiDTO
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Textbox
import org.zkoss.zul.Window

class DettaglioComunicazioniTestoViewModel {
    public static final String UPL_EMAIL = 'UPL_EMAIL'
    private final static def MAX_WIDTH = "98%"
    private final static def MIN_WIDTH = "50%"

    final def TITOLO_LENGTH = DocumentoContribuenteDTO.TITOLO_LENGTH

    // Componenti
    Window self

    @Wire("#comunicazioneTesto")
    private Textbox comunicazioneTestoTxtBox
    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    def lettura

    def campiUnioneGroupModels

    ComunicazioniTestiService comunicazioniTestiService
    def comunicazioniService
    CommonService commonService

    def campiUnione
    def selectedCampoUnione
    ComunicazioneTestiDTO testo

    def listaComunicazioneParametri
    def listaTipiCanale

    def filtroCampiUnione = ""

    def selectedTab = 0
    def uploadInfo
    def gestioneAllegati = false
    def listaAllegati = []
    def allegatiSize = [:]
    def allegatiTotalSize = 0
    def allegatoSelezionato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("comunicazioneTesto") def comunicazioneTesto,
         @ExecutionArgParam("lettura") def lettura) {

        if (comunicazioneTesto == null) {
            throw new RuntimeException("dettaglioComunicazioneTesto non specificato")
        }
        if (comunicazioneTesto.tipoTributo == null) {
            throw new RuntimeException("tipoTributo non specificato")
        }

        this.self = w
        this.lettura = lettura ?: false

        // Modifica di un testo esistente
        if (comunicazioneTesto.id == null) {
            this.testo = new ComunicazioneTestiDTO()
            InvokerHelper.setProperties(this.testo, comunicazioneTesto.properties)
        } else {
            this.testo = comunicazioneTesto
        }

        this.listaComunicazioneParametri = comunicazioniService.getListaComunicazioneParametri([
                tipoTributo: testo?.tipoTributo
        ])

        this.listaTipiCanale = [null, *comunicazioniTestiService.getListaTipiCanale()]


        if (testo.tipoCanale) {
            caricaListaCampiUnione()
        }

        onChangeTipoCanale()

        caricaUploadInfo()
        gestioneAllegatiAttiva()
        visualizzaAllegati()
    }

    private caricaUploadInfo() {
        def uploadInfoString = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == UPL_EMAIL }?.valore
        uploadInfo = commonService.getUploadInfoByString(uploadInfoString)
    }

    private gestioneAllegatiAttiva() {
        gestioneAllegati = testo?.tipoCanale?.id in ComunicazioniTestiService.TIPI_CANALE_GESTIONE_ALLEGATI
        BindUtils.postNotifyChange(null, null, this, "gestioneAllegati")
    }

    private visualizzaAllegati() {
        if (!gestioneAllegati) {
            return
        }

        listaAllegati = testo.allegatiTesto?.sort { it.sequenza } ?: []

        allegatoSelezionato = null

        calcolaDimensioneAllegati()
        calcolaDimensioneTotaleAllegati()

        BindUtils.postNotifyChange(null, null, this, 'listaAllegati')
        BindUtils.postNotifyChange(null, null, this, 'allegatoSelezionato')
    }

    private calcolaDimensioneAllegati() {
        allegatiSize = listaAllegati.collectEntries { allegato ->
            [(allegato.nomeFile): commonService.humanReadableSize(allegato.documento.size())]
        }
        BindUtils.postNotifyChange(null, null, this, 'allegatiSize')
    }

    private calcolaDimensioneTotaleAllegati() {
        def dimensione = listaAllegati.sum { it.documento.size() } ?: 0 as Long
        allegatiTotalSize = commonService.humanReadableSize(dimensione)
        BindUtils.postNotifyChange(null, null, this, "allegatiTotalSize")
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
    def onAggiungiAllegato() {
        commonService.creaPopup("/archivio/dizionari/allegatoTesto.zul",
                self,
                [tipoOperazione    : AllegatoTestoViewModel.TipoOperazione.INSERIMENTO,
                 comunicazioneTesto: this.testo],
                { event ->
                    def newAllegatoTesto = event.data?.allegatoTesto
                    if (newAllegatoTesto) {
                        testo.addToAllegatiTesto(newAllegatoTesto)
                    }
                    visualizzaAllegati()
                })
    }

    @Command
    def onApriAllegato() {

        commonService.creaPopup("/archivio/dizionari/allegatoTesto.zul",
                self,
                [tipoOperazione    : lettura ? AllegatoTestoViewModel.TipoOperazione.VISUALIZZAZIONE : AllegatoTestoViewModel.TipoOperazione.MODIFICA,
                 allegatoTesto     : allegatoSelezionato,
                 comunicazioneTesto: this.testo],
                { event ->
                    visualizzaAllegati()
                })
    }

    @Command
    def onRimuoviAllegato(@BindingParam('allegato') def allegato) {
        testo.removeFromAllegatiTesto(allegato)

        visualizzaAllegati()
    }

    @Command
    onSalva() {
        testo.testo = comunicazioneTestoTxtBox.value
        def errori = valida()

        if (!errori.empty) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, ["testo": testo])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    @Command
    onFiltraCampiUnione() {
        caricaListaCampiUnione(filtroCampiUnione)
    }

    @Command
    void onChangeTipoCanale() {

        // PND non consente testo, non carichiamo i campi unione
        if (testo?.tipoCanale?.id != 4) {
            caricaListaCampiUnione()
        }

        // In caso di PND
        if (testo?.tipoCanale?.id == 4) {
            self.width = MIN_WIDTH
            testo?.testo = null
        } else {
            self.width = MAX_WIDTH
        }

        self.invalidate()

        BindUtils.postNotifyChange(null, null, this, "testo")

        gestioneAllegatiAttiva()
        visualizzaAllegati()
    }

    private caricaListaCampiUnione(def filtro = "") {

        selectedCampoUnione = null

        campiUnione = campiUnione ?: comunicazioniTestiService.generaCampiUnioneRaggruppati(
                testo.tipoTributo, testo.tipoComunicazione
        )

        if (campiUnione.empty) {
            campiUnione = comunicazioniTestiService.generaCampiUnioneDefault().sort { it.key }
        }

        if (!filtroCampiUnione.empty) {
            campiUnione = campiUnione.findAll { it.codice.contains(filtroCampiUnione.toUpperCase()) }
        }

        campiUnioneGroupModels = new CampiUnioneGroupModels(campiUnione as Object[],
                { a, b -> a.pos <=> b.pos ?: a.label <=> b.label }
        )

        BindUtils.postNotifyChange(null, null, this, "campiUnioneGroupModels")
    }

    @Command
    def onSelezionaCampoUnione() {

        String campoUnione = selectedCampoUnione.codice

        Clients.evalJavaScript("insertAtCursor(document.getElementById('" + comunicazioneTestoTxtBox.getUuid() + "'), '<${campoUnione}>')")
        comunicazioneTestoTxtBox.focus()
    }

    private def valida() {

        def errori = []

        if (null == testo.descrizione) {
            errori << "Il campo Descrizione è obbligatorio\n"
        }

        if (null == testo.testo) {
            errori << "Il campo Testo è obbligatorio\n"
        }
        return errori
    }

}
