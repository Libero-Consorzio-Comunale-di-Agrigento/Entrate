package ufficiotributi.detrazioni

import commons.OrdinamentoMutiColonnaViewModel
import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.CompensazioniService
import it.finmatica.tr4.imposte.DetrazioniService
import it.finmatica.tr4.imposte.FiltroRicercaImposteDetrazioni
import it.finmatica.tr4.imposte.ImposteService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zul.Window
import ufficiotributi.imposte.CompensazioniGroupsModel

// Aggiunto UT, ufficio tributo, per evitare conflitto con archivio.dizionari.ListaDetrazioniViewModel
class ListaDetrazioniUTViewModel extends OrdinamentoMutiColonnaViewModel {

    // Services
    ImposteService imposteService
    CommonService commonService
    DetrazioniService detrazioniService
    CompensazioniService compensazioniService
    TributiSession tributiSession
    CompetenzeService competenzeService

    // Componenti
    Window self

    // Comuni
    def tabSelezionato
    def listaDetrazioni, listaAliquote
    def listaMotivi, listaTipiAliquota
    def detrazioneSelezionata, aliquotaSelezionata
    def detrazioniGroupsModel
    def totaleDetrazione
    def lettura = true
    def competenzeLettura, competenzeScrittura, competenzeTipiTributo
    def pagingDetrazioni = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]
    def pagingAliquote = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]
    def filtroAttivo
    FiltroRicercaImposteDetrazioni filtriRicerca


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codice") def cod) {

        this.self = w
        this.tabSelezionato = cod

        controllaCompetenze()

        filtriRicerca = tributiSession.filtroRicercaImposteDetrazioni

        campiOrdinamento = [
                'nominativo' : [verso: VERSO_ASC, posizione: 0]
        ]

        campiCssOrdinamento = [
                'nominativo' : CSS_ASC,
                'tipo_aliquota': CSS_ASC,
        ]

        if (filtriRicerca) {
            caricaDetrazioni()
        } else {

            filtriRicerca = new FiltroRicercaImposteDetrazioni()

            // Si imposta il tipo tributo di default in base alle competenze
            filtriRicerca.tipoTributo = competenzeTipiTributo.find { it.tipoTributo == 'ICI' } ?:
                    competenzeTipiTributo.find { it.tipoTributo == 'TASI' } ?: null

            onRicerca()
        }

        controllaPermessiLettura()

    }

    @Override
    void caricaLista() {
        onRefresh()
    }

    @Command
    def onRefresh() {
        resetPaginazione()
        caricaDetrazioni()
    }

    @Command
    def onCambioPagina() {
        caricaDetrazioni()
    }

    @Command
    def onCambiaTipoTributo() {
        onRefresh()
    }

    @Command
    def onRicerca() {

        def filtri = filtriRicerca.preparaRicercaDetrazioni()

        commonService.creaPopup("/ufficiotributi/detrazioni/detrazioniRicerca.zul", self, [
                filtri        : filtri,
                tabSelezionato: tabSelezionato,
                tipiTributo   : competenzeTipiTributo
        ], { e ->
            if (e.data?.filtriAggiornati) {
                filtriRicerca = e.data.filtriAggiornati
                tributiSession.filtroRicercaImposteDetrazioni = filtriRicerca
                controllaPermessiLettura()
                onRefresh()
                BindUtils.postNotifyChange(null, null, this, "filtriRicerca")
            }
        })

    }

    @Command
    def onModifica() {

        def ni = tabSelezionato == "detrazioni" ? detrazioneSelezionata.ni : aliquotaSelezionata.ni

        commonService.creaPopup("/ufficiotributi/detrazioni/detrazioniDettaglio.zul", self,
                [
                        ni    : ni,
                        tipoTributo   : filtriRicerca.tipoTributo,
                        anno          : 9999,
                        oggettoPratica: tabSelezionato == "detrazioni" ? detrazioneSelezionata.oggettoPratica : aliquotaSelezionata.oggettoPratica,
                        lettura       : lettura
                ], { e ->

        })

    }

    @Command
    def onExportXls() {

        def fields

        if (tabSelezionato == "detrazioni") {

            def listaDetrazioniTotale = detrazioniService.getListaDetrazioni(filtriRicerca, pagingDetrazioni, true).records

            fields = [
                    "anno"             : "Anno",
                    "motivoDetr"       : "Motivo",
                    "nominativo"       : "Contribuente",
                    "codFiscale"       : "Cod. Fiscale",
                    "detrazione"       : "Detrazione",
                    "detrazioneAcconto": "Det. Acconto",
                    "oggetto"          : "Oggetto",
                    "tipoOggetto"      : "T",
                    "indirizzo"        : "Indirizzo",
                    "pratica"          : "Pratica"
            ]

            def formatters = [
                    anno       : Converters.decimalToInteger,
                    tipoOggetto: Converters.decimalToInteger,
                    oggetto    : Converters.decimalToInteger,
                    pratica    : Converters.decimalToInteger
            ]

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.DETRAZIONI,
                    [tipoTributo: filtriRicerca.tipoTributo.tipoTributoAttuale])

            XlsxExporter.exportAndDownload(nomeFile, listaDetrazioniTotale, fields, formatters)

        } else if (tabSelezionato == "aliquote") {

            def listaAliquoteTotale = detrazioniService.getListaAliquote(filtriRicerca, pagingAliquote, campiOrdinamento, true).records

            fields = [
                    "nominativo"  : "Contribuente",
                    "codFiscale"  : "Cod. Fiscale",
                    "oggetto"     : "Oggetto",
                    "tipoOggetto" : "T",
                    "indirizzo"   : "Indirizzo",
                    "tipoAliquota": "Tipo Aliquota",
                    "dal"         : "Dal",
                    "al"          : "Al",
                    "pratica"     : "Pratica"
            ]

            def formatters = [
                    anno       : Converters.decimalToInteger,
                    tipoOggetto: Converters.decimalToInteger,
                    oggetto    : Converters.decimalToInteger,
                    pratica    : Converters.decimalToInteger
            ]

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.ALIQUOTE,
                    [tipoTributo: filtriRicerca.tipoTributo.tipoTributoAttuale])

            XlsxExporter.exportAndDownload(nomeFile, listaAliquoteTotale, fields, formatters)
        }

    }

    @Command
    def onCheckOrdinamento(@BindingParam("valore") String valore) {
        filtriRicerca.ordinamento = valore
        tributiSession.filtroRicercaImposteDetrazioni = filtriRicerca
        BindUtils.postNotifyChange(null, null, this, "filtriRicerca")
        onRefresh()
    }

    private def caricaDetrazioni() {

        if (tabSelezionato == "detrazioni") {

            def result = detrazioniService.getListaDetrazioni(filtriRicerca, pagingDetrazioni)

            listaDetrazioni = result.records
            pagingDetrazioni.totalSize = result.totali.totNum
            totaleDetrazione = result.totali.totDetrazione

            detrazioniGroupsModel =
                    new CompensazioniGroupsModel(
                            listaDetrazioni as Object[],
                            { a, b ->
                                a.anno <=> b.anno ?: a.motivoDetrazione <=> b.motivoDetrazione
                            }
                    )

            detrazioneSelezionata = null

            listaMotivi = detrazioniService.getMotiviDetrazione(filtriRicerca.tipoTributo)
            controllaFiltroAttivo()

            BindUtils.postNotifyChange(null, null, this, "detrazioneSelezionata")
            BindUtils.postNotifyChange(null, null, this, "pagingDetrazioni")
            BindUtils.postNotifyChange(null, null, this, "listaDetrazioni")
            BindUtils.postNotifyChange(null, null, this, "detrazioniGroupsModel")
            BindUtils.postNotifyChange(null, null, this, "totaleDetrazione")

        } else if (tabSelezionato == "aliquote") {

            def result = detrazioniService.getListaAliquote(filtriRicerca, pagingAliquote, campiOrdinamento)
            listaAliquote = result.records
            pagingAliquote.totalSize = result.totali

            aliquotaSelezionata = null

            listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll { it.tipoTributo.tipoTributo == filtriRicerca.tipoTributo.tipoTributo }
            controllaFiltroAttivo()

            BindUtils.postNotifyChange(null, null, this, "aliquotaSelezionata")
            BindUtils.postNotifyChange(null, null, this, "pagingAliquote")
            BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        }
    }

    private def resetPaginazione() {

        if (tabSelezionato == "detrazioni") {
            pagingDetrazioni.activePage = 0
            pagingDetrazioni.totalSize = 0
        } else if (tabSelezionato == "aliquote") {
            pagingAliquote.activePage = 0
            pagingAliquote.totalSize = 0
        }

        BindUtils.postNotifyChange(null, null, this, "pagingDetrazioni")
        BindUtils.postNotifyChange(null, null, this, "pagingAliquote")
    }

    private def controllaFiltroAttivo() {

        if (tabSelezionato == "detrazioni") {
            filtroAttivo = filtriRicerca.isDirtyDetrazioni(listaMotivi)
        } else if (tabSelezionato == "aliquote") {
            filtroAttivo = filtriRicerca.isDirtyAliquote(listaTipiAliquota)
        }

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private def controllaCompetenze() {

        competenzeScrittura = competenzeService.tipiTributoUtenzaScrittura()
                .findAll { it.tipoTributo in ["ICI", "TASI"] }
                .collectEntries { [(it.tipoTributo): true] }
        competenzeLettura = competenzeService.tipiTributoUtenzaLettura()
                .findAll { it.tipoTributo in ["ICI", "TASI"] }
                .collectEntries { [(it.tipoTributo): true] }

        competenzeTipiTributo = competenzeService.tipiTributoUtenza().findAll {
            it.tipoTributo in
                    (competenzeScrittura.collect { it.key } +
                            competenzeLettura.collect { it.key })
        }

        BindUtils.postNotifyChange(null, null, this, "competenzeScrittura")
        BindUtils.postNotifyChange(null, null, this, "competenzeLettura")
        BindUtils.postNotifyChange(null, null, this, "competenzeTipiTributo")
    }

    private def controllaPermessiLettura() {

        lettura = competenzeLettura[filtriRicerca.tipoTributo.tipoTributo]

        BindUtils.postNotifyChange(null, null, this, "lettura")
    }


}
