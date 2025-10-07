package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.BeneficiariTributo
import it.finmatica.tr4.codicif24.CodiciF24Service
import it.finmatica.tr4.dto.BeneficiariTributoDTO
import it.finmatica.tr4.dto.CodiceF24DTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCodiciF24ViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    CodiciF24Service codiciF24Service

    // Componenti
    Window self

    // CodiceF24
    def codiceF24Selezionato
    def listaCodiciF24

    // Beneficiari
    def listaBeneficiari
    BeneficiariTributoDTO beneficiarioSelezionato

    def filtro
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        onRefresh()
    }

    @Command
    void onRefresh() {
        codiceF24Selezionato = null
        listaCodiciF24 = codiciF24Service.getListaCodiciF24(tipoTributoSelezionato.tipoTributo, filtro)

        onRefreshBeneficiari()

        BindUtils.postNotifyChange(null, null, this, "listaCodiciF24")
        BindUtils.postNotifyChange(null, null, this, "codiceF24Selezionato")
    }

    @Command
    onCheckboxCheck(
            @BindingParam("flagCheckbox") def flagCheckbox,
            @BindingParam("checkedCodiceF24") def checkedCodiceF24DTO) {

        if (flagCheckbox == 'flagStampaRateazione') {
            Messagebox.show("Il valore del flag verrà modificato. Proseguire?", "Stampa Rateazione", Messagebox.YES | Messagebox.NO,
                    Messagebox.QUESTION, {
                Event evt ->
                    if (Messagebox.ON_YES.equals(evt.getName())) {
                        checkedCodiceF24DTO.flagStampaRateazione = checkedCodiceF24DTO.flagStampaRateazione == 'S' ? null : 'S'
                        codiciF24Service.salvaCodiceF24(checkedCodiceF24DTO)
                    }
                    onRefresh()
            })
        }
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onModificaCodiceF24() {
    }

    @Command
    def onAggiungiCodiceF24() {
    }

    @Command
    def onDuplicaCodiceF24() {
    }

    @Command
    def onEliminaCodiceF24() {
    }

    @Command
    def onExportXlsCodiciF24() {

        Map fields = [
                "tributo"             : "Codice",
                "descrizione"         : "Descrizione",
                "rateazione"          : "Rateazione",
                "tipoCodice"          : "Tipo Codice",
                "flagStampaRateazione": "Stampa rateazione"
        ]

        def converters = [
                flagStampaRateazione: Converters.flagString,
                rateazione          : { tr -> CodiceF24DTO.tipiRateazione[tr] },
                tipoCodice          : { tc -> CodiceF24DTO.tipiCodice[tc] },
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CODICI_F24,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaCodiciF24, fields, converters)
    }

    @Command
    onSelectCodiceF24() {
        onRefreshBeneficiari()
    }

    @Command
    onRefreshBeneficiari() {

        listaBeneficiari = codiciF24Service.getBeneficiari(codiceF24Selezionato)
        beneficiarioSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaBeneficiari")
        BindUtils.postNotifyChange(null, null, this, "beneficiarioSelezionato")
    }

    @Command
    onSelectBeneficiario() {

    }

    @Command
    onNuovoBeneficiario() {

        commonService.creaPopup("/archivio/dizionari/dettaglioBeneficiarioTributo.zul",
                self,
                [
                        codiceF24   : codiceF24Selezionato?.tributo,
                        beneficiario: null,
                        lettura     : lettura
                ],
                {
                    event -> onRefreshBeneficiari()
                }
        )
    }

    @Command
    onModificaBeneficiario() {

        commonService.creaPopup("/archivio/dizionari/dettaglioBeneficiarioTributo.zul",
                self,
                [
                        codiceF24   : codiceF24Selezionato?.tributo,
                        beneficiario: beneficiarioSelezionato.getDomainObject(),
                        lettura     : lettura
                ],
                {
                    event -> onRefreshBeneficiari()
                }
        )
    }

    @Command
    onEliminaBeneficiario() {

        String messaggio = "Sicuro di voler eliminare il Beneficiario?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            codiciF24Service.eliminaBeneficiario(beneficiarioSelezionato)
                            onRefreshBeneficiari()
                        }
                    }
                }
        )
    }

    @Command
    def onExportXlsBeneficiari() {

        def listaCompleta = codiciF24Service.getListaCodiciF24(tipoTributoSelezionato.tipoTributo, filtro)
        def beneficiari = BeneficiariTributo.findAll().toDTO()

        Map fields = [
                "tributo"              : "Codice",
                "descrizione"          : "Descrizione",
                "rateazioneDescrizione": "Rateazione",
                "tipoCodice"           : "Tipo Codice",
                "flagStampaRateazione" : "Stampa rateazione",
                "codFiscale"           : "Cod.Fisc. Ben.",
                "intestatario"         : "Intestazione Ben.",
                "iban"                 : "IBAN BVeneficiario",
                "tassonomia"           : "Tassonomia",
                "tassonomiaAnniPrec"   : "Tassonomia A.P",
                "causaleQuota"         : "Causale Quota",
                "desMetadata"          : "Descr. Metadata",
        ]

        def converters = [
                flagStampaRateazione: Converters.flagString,
                "codFiscale"        : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.codFiscale },
                "intestatario"      : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.intestatario },
                "iban"              : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.iban },
                "tassonomia"        : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.tassonomia },
                "tassonomiaAnniPrec": { e -> beneficiari.find { it.tributoF24 == e.tributo }?.tassonomiaAnniPrec },
                "causaleQuota"      : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.causaleQuota },
                "desMetadata"       : { e -> beneficiari.find { it.tributoF24 == e.tributo }?.desMetadata }
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.BENEFICIARI_F24,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaCompleta, fields, converters)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCodiciF24Ricerca.zul", self,
                [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                listaCodiciF24 = codiciF24Service.getListaCodiciF24(tipoTributoSelezionato.tipoTributo, filtro)

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
                BindUtils.postNotifyChange(null, null, this, "listaCodiciF24")

            }
        })
    }

}
