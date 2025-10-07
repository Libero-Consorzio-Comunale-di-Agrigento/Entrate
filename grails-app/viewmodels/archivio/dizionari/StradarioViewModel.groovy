package archivio.dizionari

import it.finmatica.tr4.ArchivioVie
import it.finmatica.tr4.DenominazioneVia
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.stradario.StradarioService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class StradarioViewModel {

    // Componenti
    Window self

    // Services
    StradarioService stradarioService
    CommonService commonService

    // Comuni
    def listaVie
    def viaSelezionata
    def filtroVieAttivo

    def listaDenominazioni
    def denominazioneSelezionata
    def filtroDenominazioniAttivo

    def filtri
    def ordinamento
    def pagingVie = [
            activePage: 0,
            pageSize  : 30,
            totalSize : 0
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        ordinamento = "cod"

        onRefreshVie()
    }

    @Command
    def onRefreshVie() {

        resetPaginazioneVie()

        refreshVie()
    }

    private void refreshVie() {
        listaVie = stradarioService.getListaVie(pagingVie.pageSize, pagingVie.activePage, ordinamento, filtri, false)
        viaSelezionata = null

        pagingVie.totalSize = listaVie.size() > 0 ? listaVie[0].totale : 0

        denominazioneSelezionata = null
        listaDenominazioni = null

        BindUtils.postNotifyChange(null, null, this, "listaVie")
        BindUtils.postNotifyChange(null, null, this, "viaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "pagingVie")
        BindUtils.postNotifyChange(null, null, this, "denominazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaDenominazioni")
    }

    @Command
    def onRefreshDenom() {

        if (viaSelezionata == null) {
            return
        }

        listaDenominazioni = stradarioService.getListaDenominazioni(viaSelezionata.codVia, filtri)
        denominazioneSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "listaDenominazioni")
        BindUtils.postNotifyChange(null, null, this, "denominazioneSelezionata")
    }

    @Command
    def onSelectVia() {
        onRefreshDenom()
    }

    @Command
    def onPagingVie() {
        refreshVie()
    }

    @Command
    def onExportXlsVie() {

        Map fields
        def listaVieTotale = stradarioService.getListaVie(0, 0, ordinamento, null, true)

        fields = [
                "codVia"  : "Codice Via",
                "denomUff": "Denominazione Ufficiale",
                "denomOrd": "Denominazione Ordinamento"
        ]

        def converters = [
                codVia: Converters.decimalToInteger
        ]

        XlsxExporter.exportAndDownload("Stradario_Vie", listaVieTotale, fields, converters)
    }

    @Command
    def onOpenFiltriVie() {
        commonService.creaPopup(
                "/archivio/dizionari/ricercaStradario.zul", self,
                [
                        tipo  : "vie",
                        filtri: filtri
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.ricarica) {
                            if (event.data?.filtri && event.data?.filtroAttivo != null) {

                                this.filtri = event.data.filtri
                                this.filtroVieAttivo = event.data.filtroAttivo

                                BindUtils.postNotifyChange(null, null, this, "filtri")
                                BindUtils.postNotifyChange(null, null, this, "filtroVieAttivo")

                                onRefreshVie()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onOpenFiltriDenom() {
        commonService.creaPopup(
                "/archivio/dizionari/ricercaStradario.zul", self,
                [
                        tipo  : "denominazioni",
                        filtri: filtri
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.ricarica) {
                            if (event.data?.filtri && event.data?.filtroAttivo != null) {

                                this.filtri = event.data.filtri
                                this.filtroDenominazioniAttivo = event.data.filtroAttivo

                                BindUtils.postNotifyChange(null, null, this, "filtri")
                                BindUtils.postNotifyChange(null, null, this, "filtroDenominazioniAttivo")

                                onRefreshDenom()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onModificaDenom() {

        if (denominazioneSelezionata.progrVia == 1 || denominazioneSelezionata.progrVia == 99) {
            return
        }

        commonService.creaPopup(
                "/archivio/dizionari/dettaglioStradarioDenominazione.zul", self,
                [
                        "codVia"       : viaSelezionata.codVia,
                        "modifica"     : true,
                        "denominazione": denominazioneSelezionata
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.esegui) {
                            if (event.data?.parametri) {

                                def denom = stradarioService.getDenominazione(viaSelezionata.codVia, event.data.parametri.progrVia)

                                denom.descrizione = event.data.parametri.descNominativo

                                stradarioService.salvaDenominazione(denom)

                                Clients.showNotification("Denominazione salvata", Clients.NOTIFICATION_TYPE_INFO,
                                        null, "middle_center", 3000, true)

                                onRefreshDenom()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onAggiungiDenom() {
        commonService.creaPopup(
                "/archivio/dizionari/dettaglioStradarioDenominazione.zul", self,
                [
                        "codVia"       : viaSelezionata.codVia,
                        "modifica"     : false,
                        "denominazione": null
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.esegui) {
                            if (event.data?.parametri) {

                                DenominazioneVia denomVia = new DenominazioneVia()

                                denomVia.progrVia = event.data.parametri.progrVia
                                denomVia.descrizione = event.data.parametri?.descNominativo?.toUpperCase()
                                denomVia.archivioVie = ArchivioVie.get(viaSelezionata.codVia)

                                stradarioService.salvaDenominazione(denomVia)

                                Clients.showNotification("Denominazione salvata", Clients.NOTIFICATION_TYPE_INFO,
                                        null, "middle_center", 3000, true)

                                onRefreshDenom()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onDuplicaDenom() {

        def denominazione = [:]

        denominazione.progrVia = null
        denominazione.descrizione = denominazioneSelezionata.descrizione

        commonService.creaPopup(
                "/archivio/dizionari/dettaglioStradarioDenominazione.zul", self,
                [
                        "codVia"       : viaSelezionata.codVia,
                        "modifica"     : false,
                        "denominazione": denominazione
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.esegui) {
                            if (event.data?.parametri) {

                                DenominazioneVia denomVia = new DenominazioneVia()

                                denomVia.progrVia = event.data.parametri.progrVia
                                denomVia.descrizione = event.data.parametri?.descNominativo?.toUpperCase()
                                denomVia.archivioVie = ArchivioVie.get(viaSelezionata.codVia)

                                stradarioService.salvaDenominazione(denomVia)

                                Clients.showNotification("Denominazione salvata", Clients.NOTIFICATION_TYPE_INFO,
                                        null, "middle_center", 3000, true)

                                onRefreshDenom()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onEliminaDenom() {

        String messaggio = "Eliminare la Denominazione?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {

                            def denom = stradarioService.getDenominazione(viaSelezionata.codVia, denominazioneSelezionata.progrVia)
                            stradarioService.eliminaDenominazione(denom)

                            Clients.showNotification("Denominazione eliminata", Clients.NOTIFICATION_TYPE_INFO,
                                    null, "middle_center", 3000, true)

                            onRefreshDenom()
                        }
                    }
                }
        )


    }

    @Command
    def onExportXlsDenom() {

        Map fields

        fields = [
                "codVia"     : "Codice Via",
                "denomUff"   : "Denominazione Ufficiale",
                "progrVia"   : "Progressivo Via",
                "descrizione": "Descrizione"
        ]

        def converters = [
                codVia  : Converters.decimalToInteger,
                progrVia: Converters.decimalToInteger,
                denomUff: { denom -> viaSelezionata.denomUff }
        ]

        XlsxExporter.exportAndDownload("Stradario_Denominazioni", listaDenominazioni, fields, converters)
    }

    private resetPaginazioneVie() {
        pagingVie.activePage = 0
        pagingVie.totalSize = 0
        BindUtils.postNotifyChange(null, null, this, "pagingVie")
    }

}
