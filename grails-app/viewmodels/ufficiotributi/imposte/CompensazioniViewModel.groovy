package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.CompensazioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CompensazioniViewModel {

    //Componenti
    Window self

    //Services
    CommonService commonService
    CompensazioniService compensazioniService

    //Comuni
    def compensazioneSelezionata
    def compensazioniGroupsModel
    def listaCompensazioni
    def filtri
    def listaMotivi
    def listaMotiviReverse
    def filtroAttivo = false
    def pagingCompensazioni = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        initFiltri()
        onRicercaCompensazioni()
    }

    @Command
    def onCambioPagina() {
        caricaCompensazioni()
    }

    @Command
    def onRefresh() {
        resetPaginazione()
        caricaCompensazioni()
    }

    @Command
    def onRicercaCompensazioni() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniRicerca.zul", self, [filtri: filtri], { e ->
            if (e.data?.filtriAggiornati) {
                filtri = e.data.filtriAggiornati
                resetPaginazione()
                caricaCompensazioni()
            }
        })
    }

    @Command
    def onCalcoloCompensazioni() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [
                        tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.CALCOLO_COMPENSAZIONI,
                        modalitaCodFiscale: 'N',
                        modalitaAnno      : 'N'
                ], { e ->

            if (!e.data) {
                return
            }

            if (!e.data?.messaggio?.trim()) {
                caricaCompensazioni()
                Clients.showNotification("Calcolo compensazioni eseguito", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            } else {
                Clients.showNotification(e.data.messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            }

        })
    }

    @Command
    def onGeneraVersamenti() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [
                        tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.GENERA_VERSAMENTI,
                        modalitaCodFiscale: 'N',
                        modalitaAnno      : 'N'
                ], { e ->

            if (!e.data) {
                return
            }

            if (!e.data?.messaggio?.trim()) {
                Clients.showNotification("Inserimento versamenti eseguito", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            } else {
                Clients.showNotification(e.data.messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            }

            onRefresh()
        })
    }

    @Command
    def onModificaCompensazione() {

        commonService.creaPopup("/ufficiotributi/imposte/dettaglioCompensazione.zul", self,
                [
                        isModifica              : true,
                        isClonazione            : false,
                        compensazioneSelezionata: compensazioneSelezionata
                ], { e ->
            onRefresh()
        })
    }

    @Command
    def onExportXls() {

        def fields
        def listaCompensazioniTotale = compensazioniService.getListaCompensazioni(filtri,
                [
                        activePage: 0,
                        pageSize  : Integer.MAX_VALUE,
                        totalSize : 0
                ]).records

        fields = [
                "desTitr"       : "Tipo Tributo",
                "anno"          : "Anno",
                "motivo"        : "Motivo",
                "nominativo"    : "Contribuente",
                "codFiscale"    : "Codice Fiscale",
                "compensazione" : "Compensazione",
                "flagAutomatico": "Auto",
                "flagVers"      : "Vers.",
                "note"          : "Note"
        ]

        def formatters = [
                anno          : Converters.decimalToInteger,
                motivo        : { row ->
                    def motivo = listaMotivi.find { it.motivoCompensazione == row.motivoCompensazione }
                    return (motivo != null) ? "${motivo.motivoCompensazione} - ${motivo.descrizione}" : null
                },
                flagAutomatico: Converters.flagString,
                flagVers      : Converters.flagString
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPENSAZIONI,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaCompensazioniTotale, fields, formatters)

    }

    private def caricaCompensazioni() {

        def result = compensazioniService.getListaCompensazioni(filtri, pagingCompensazioni)
        listaCompensazioni = result.records
        pagingCompensazioni.totalSize = result.totalCount

        compensazioniGroupsModel =
                new CompensazioniGroupsModel(
                        listaCompensazioni as Object[],
                        { a, b ->
                            a.anno <=> b.anno ?: a.motivoCompensazione <=> b.motivoCompensazione
                        }
                )

        compensazioneSelezionata = null

        listaMotivi = compensazioniService.getMotivi()
        listaMotiviReverse = listaMotivi.reverse()

        controllaFiltroAttivo()

        BindUtils.postNotifyChange(null, null, this, "compensazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "pagingCompensazioni")
        BindUtils.postNotifyChange(null, null, this, "listaCompensazioni")
        BindUtils.postNotifyChange(null, null, this, "compensazioniGroupsModel")
        BindUtils.postNotifyChange(null, null, this, "listaMotivi")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviReverse")

    }


    private def initFiltri() {

        listaMotivi = compensazioniService.getMotivi()
        listaMotiviReverse = listaMotivi.reverse()

        filtri = [
                tipoTributo    : "TARSU",
                annoDa         : null,
                annoA          : null,
                compensazioneDa: null,
                compensazioneA : null,
                motivoDa       : listaMotivi[0],
                motivoA        : listaMotiviReverse[0]
        ]
    }

    private def resetPaginazione() {
        pagingCompensazioni.activePage = 0
        pagingCompensazioni.totalSize = 0

        BindUtils.postNotifyChange(null, null, this, "pagingCompensazioni")
    }

    private def controllaFiltroAttivo() {

        filtroAttivo = (filtri.tipoTributo != "TARSU") ||
                (filtri.annoDa != null) ||
                (filtri.annoA != null) ||
                (filtri.compensazioneDa != null) ||
                (filtri.compensazioneA != null) ||
                (filtri.motivoDa.motivoCompensazione != listaMotivi[0].motivoCompensazione) ||
                (filtri.motivoA.motivoCompensazione != listaMotiviReverse[0].motivoCompensazione)

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

}
