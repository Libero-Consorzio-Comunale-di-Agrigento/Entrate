package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.contatti.ContattiService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Groupbox
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class DovutoVersatoViewModel {

    // componenti
    Window self
    @Wire("#paging")
    protected Paging paging

    ServletContext servletContext

    // services
    ImposteService imposteService
    ModelliService modelliService
    ContattiService contattiService
    ContribuentiService contribuentiService
    DocumentaleService documentaleService
    CommonService commonService
    CompetenzeService competenzeService
    ComunicazioniService comunicazioniService

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    def idSoggetto

    def filtro = [
            codFiscale : null,
            cognomeNome: null,
            tipoTributo: null,
            tributo    : null,
            anno       : null,
            dicDaAnno  : null,
            diffImpDa  : null,
            diffImpA   : null,
            tipoDiffImp: null,
            deceduti   : null,
            versamenti : null
    ]

    def tipiImposta = [
            2: "Imposta Arrotondota per Contribuente",
            3: "Imposta Arrotondota per Utenza",
            1: "Imposta Calcolata"
    ]

    def tipiDeceduto = [
            1: "Deceduti e Non Deceduti",
            2: "Solo Non Deceduti",
            3: "Solo Deceduti"
    ]

    def tipiPersona = [
            (-1): "Fisiche e Giuridiche",
            0   : "Fisiche",
            1   : "Giuridiche"
    ]

    def tipiVersamento = [
            1: "Tutti",
            2: "Con Versamenti",
            3: "Senza Versamenti"
    ]

    def tipiModelloLettera = [
            ICI  : [descrizioneOrd: 'DOV%', tipoContatto: 3],
            TASI : [descrizioneOrd: 'DOV_TASI%', tipoContatto: 44],
            ICP  : [descrizioneOrd: 'DOV_ICP%', tipoContatto: 41],
            TARSU: [descrizioneOrd: 'DOV_TARSU%', tipoContatto: 42],
            TOSAP: [descrizioneOrd: 'DOV_TOSAP%', tipoContatto: 43]
    ]

    def tipoModelloLettera
    def controllaContattiDovutoVersato = true
    def controllaContattiBonificaDichiarazioni = false
    def controllaContattiImmobiliNonLiquidabili = false

    boolean ricalcolaDovuto = false

    List<TipoTributoDTO> listaTipiTributo

    def listaDovutoVersatoCompleta = []
    def listaDovutoVersato = []

    String desTipoTributo

    def dovutoSelezionato
    def dovutiSelezionati = [:]
    def abilitaSelezioneMultipla = false
    def selezionePresente = false
    def abilitaStampa = false
    def dovutiDaStampare = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("cognomeNome") String cn,
         @ExecutionArgParam("codFiscale") String cf,
         @ExecutionArgParam("idSoggetto") Long idSoggetto,
         @ExecutionArgParam("tipoTributo") @Default("ICI") String tipoTributo,
         @ExecutionArgParam("anno") Short anno) {

        this.self = w

        this.idSoggetto = idSoggetto

        filtro.tipoTributo = TipoTributo.get(tipoTributo)
        filtro.anno = anno
        filtro.codFiscale = cf
        filtro.cognomeNome = cn

        filtro.tipoDiffImp = 1
        filtro.deceduti = 1
        filtro.tipoPersone = -1
        filtro.versamenti = 1

        listaTipiTributo = competenzeService.tipiTributoUtenza()

        filtro.tipoTributo = listaTipiTributo.find { it.tipoTributo == tipoTributo }

        BindUtils.postNotifyChange(null, null, this, "abilitaSelezioneMultipla")
    }


    @Command
    def onCerca(@BindingParam("groupbox") Groupbox gbFiltri, @BindingParam("reset") boolean reset) {

        if (!filtro.tipoTributo) {
            Clients.showNotification("Inserire Tipo Tributo.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        } else if (!filtro.anno) {
            Clients.showNotification("Inserire Anno di Riferimento.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        } else if (filtro.dicDaAnno && filtro.dicDaAnno > filtro.anno) {
            Clients.showNotification("Filtro Da Anno maggiore di Anno di Riferimento.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        if (ricalcolaDovuto) {
            imposteService.proceduraCalcolaImposta(filtro.anno, filtro.codFiscale?.toUpperCase(), filtro.cognomeNome?.toUpperCase(), filtro.tipoTributo.tipoTributo)
        }

        gbFiltri?.open = false

        if (reset) {
            listaDovutoVersato = []
            listaDovutoVersatoCompleta = []
            activePage = 0
        }

        if (activePage == 0) {
            listaDovutoVersatoCompleta = applicaFiltri(imposteService.getDovutoVersato(filtro))
            totalSize = listaDovutoVersatoCompleta.size()
            listaDovutoVersato = (totalSize < pageSize) ? listaDovutoVersatoCompleta : listaDovutoVersatoCompleta.subList(0, pageSize - 1)
        } else {
            int posDa = activePage * pageSize - 1
            int posA = ((activePage * pageSize) + pageSize - 1)

            if (posA > totalSize) {
                posA = totalSize
            }
            listaDovutoVersato = listaDovutoVersatoCompleta.subList(posDa, posA)
        }

        if (totalSize <= pageSize) activePage = 0
        paging?.setTotalSize(totalSize)

        desTipoTributo = listaDovutoVersato ? " - Tributo: " + listaDovutoVersato[0]?.descrizioneTitr : null

        abilitaSelezioneMultipla = listaDovutoVersatoCompleta.size() > 0
        resetMultiSelezione()

        dovutoSelezionato = null
        abilitaStampa()

        BindUtils.postNotifyChange(null, null, this, "listaDovutoVersato")
        BindUtils.postNotifyChange(null, null, this, "desTipoTributo")
        BindUtils.postNotifyChange(null, null, this, "activePage")
        BindUtils.postNotifyChange(null, null, this, "abilitaSelezioneMultipla")
        BindUtils.postNotifyChange(null, null, this, "dovutoSelezionato")
    }

    private def applicaFiltri(def lista) {
        lista.each {

            // Deceduti
            it.visibile = filtro.deceduti == 1 || (filtro.deceduti == 2 && it.statoSogg != 50) || (filtro.deceduti == 3 && it.statoSogg == 50)

            // Versamenti
            it.visibile &= filtro.versamenti == 1 || (filtro.versamenti == 2 && it.versato > 0) || (filtro.versamenti == 3 && it.versato == 0)


            // Persone fisiche o giuridiche
            it.visibile &= (filtro.tipoPersone == -1) || filtro.tipoPersone == it.tipoPersona

            it << [differenza        : (((it.dovutoArr == null) ? 0 : it.dovutoArr) - ((it.versato == null) ? 0 : it.versato))
                   , contribuente: (it.cognome + " " + (it.nome ?: ''))
                   , flagTardivo     : (it.tardivo != null) ? "S" : "N"
                   , flagDicPrec     : (it.dicPrec != null) ? "S" : "N"
                   , flagLiqCont     : (it.liqCont != null) ? "S" : "N"
                   , flagAccCont     : (it.accCont != null) ? "S" : "N"
                   , flagProprietario: (it.proprietario != null) ? "S" : "N"
                   , flagOccupante   : (it.occupante != null) ? "S" : "N"
            ]
        }

        return lista.findAll { it.visibile == true }
    }

    @Command
    onChangeTributo() {
        switch (filtro.tipoTributo.tipoTributo) {
            case 'ICI':
                break
            case 'TASI':
                filtro.dicDaAnno = null
                break
            case 'TARI':
                filtro.dicDaAnno = null
                ricalcolaDovuto = false
                break
            default:
                filtro.tipoDiffImp = 3
                filtro.dicDaAnno = null
                ricalcolaDovuto = false
        }

        listaDovutoVersato = []
        listaDovutoVersatoCompleta = []
        activePage = 0
        BindUtils.postNotifyChange(null, null, this, "listaDovutoVersato")
        BindUtils.postNotifyChange(null, null, this, "filtro")
        BindUtils.postNotifyChange(null, null, this, "ricalcolaDovuto")
    }

    private stampaLetteraGenerica() {

        def idSoggetto = dovutoSelezionato.ni
        def codFiscale = dovutoSelezionato.codFiscale
        def nomeFile = ""

        def parametri = [
                tipoStampa: ModelliService.TipoStampa.LETTERA_GENERICA,
                nomeFile  : nomeFile,
                soggetto: Soggetto.findById(idSoggetto).toDTO()
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    @Command
    def onInviaAppIO() {
        def tipoDocumento = documentaleService.recuperaTipoDocumento(null, 'G')
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, tipoDocumento)
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : dovutoSelezionato.codFiscale,
                 tipoTributo      : TipoTributo.findByTipoTributo(dovutoSelezionato.tipoTributo),
                 tipoComunicazione: tipoComunicazione,
                 pratica  : null,
                 tipologia: "G"
                ])
    }

    @Command
    onStampaDovuto() {

        selezionePresente()

        if (!selezionePresente && dovutoSelezionato) {
            // Stampa singola
            stampaLetteraGenerica()
        } else {
            // Stampa massiva

            commonService.creaPopup("/elaborazioni/creazioneElaborazione.zul",
                    self,
                    [
                            nomeElaborazione: "DOV_VERS_${(new Date().format("ddMMyyyy_hhmmss"))}",
                            tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_LETTERA_GENERICA,
                            tipoTributo     : filtro.tipoTributo.tipoTributo,
                            pratiche        : dovutiDaStampare
                    ])
        }
    }

    @Command
    onExportXls() {

        Map labels = [
                "contribuente" : "Contribuente"
                , "codFiscale" : "Codice Fiscale"
                , "dovuto"     : "Dovuto"
                , "dovutoArr"  : "Dovuto Arr."
                , "versato"    : "Versato"
                , "differenza" : "Differenza"
                , "flagTardivo": "T"
                , "dataNasc"   : "Data Nascita"
        ]

        if (filtro.tipoTributo.tipoTributo.equals('ICI')) {
            labels << ["flagDicPrec": "Dich. Prec."]
        }

        if (filtro.tipoTributo.tipoTributo.equals('ICI') || filtro.tipoTributo.tipoTributo.equals('TASI')) {
            labels << ["flagLiqCont": "Liq."]
        }


        labels << ["flagAccCont": "Accert."]

        if (filtro.tipoTributo.tipoTributo.equals('TASI')) {
            labels << [
                    "flagProprietario": "Proprietario"
                    , "flagOccupante" : "Occupante"
            ]
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_DOVUTO_VERSATO,
                [tipoTributo: filtro.tipoTributo.tipoTributo,
                 anno       : filtro.anno])

        XlsxExporter.exportAndDownload(nomeFile, listaDovutoVersatoCompleta, labels)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onSelezionaDovuto() {
        abilitaStampa()
    }

    @Command
    def onCheckDovuto(@BindingParam("dov") def dovuto) {
        if (dovutiSelezionati[dovuto.ni]) {
            dovutiDaStampare << [codFiscale: dovuto.codFiscale]
        } else {
            dovutiDaStampare -= [codFiscale: dovuto.codFiscale]
        }
        selezionePresente()
        abilitaStampa()
    }

    @Command
    def onCheckDovuti() {
        selezionePresente()

        dovutiSelezionati = [:]
        dovutiDaStampare = []

        // Se non era selezionata almeno un dovuto allora si vogliono selezionare tutti
        if (!selezionePresente) {
            listaDovutoVersatoCompleta.each {
                dovutiSelezionati << [(it.ni): true]
                dovutiDaStampare << [codFiscale: it.codFiscale]
            }
        }

        // Si aggiorna la presenza di selezione
        selezionePresente()
        abilitaStampa()

        BindUtils.postNotifyChange(null, null, this, "dovutiSelezionati")
    }

    private void selezionePresente() {
        selezionePresente = (dovutiSelezionati.containsValue(true))
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private resetMultiSelezione() {
        dovutiSelezionati = [:]
        dovutiDaStampare = []
        selezionePresente = false
        BindUtils.postNotifyChange(null, null, this, "dovutiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private void abilitaStampa() {
        abilitaStampa = selezionePresente || dovutoSelezionato
        BindUtils.postNotifyChange(null, null, this, "abilitaStampa")
    }

}
