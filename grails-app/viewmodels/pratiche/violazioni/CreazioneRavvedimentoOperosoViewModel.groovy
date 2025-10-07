package pratiche.violazioni

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Scadenza
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CreazioneRavvedimentoOperosoViewModel {

    // componenti
    Window self

    ImposteService imposteService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    CanoneUnicoService canoneUnicoService
    CommonService commonService
    CompetenzeService competenzeService
    IntegrazioneDePagService integrazioneDePagService

    Boolean lettura = false
    Boolean dePagAbilitato = false

    def anno
    def daAnno
    def adAnno

    def tipoVersamento
    def rata = null

    def tipiVersamento = ['A': 'Acconto', 'S': 'Saldo', 'U': 'Unico']
    def listaRate = []

    def tipologia = 'V'
    def tipologie = ['D': 'Ravvedimento su Dichiarazione', 'V': 'Ravvedimento su Versamento']

    def dataVersamento

    def tipoTributo
    def modificaTipoTributo
    def cambioTipoVersamento
    def presentiSanzioni

    def tipiTributo = [:]

    Contribuente contribuente
    String codFiscale
    def calcoloSanzioni
    def pratica

    def gruppiTributo
    def gruppoTributo

    /// Dati per TARSU
    def dettagliRuoli = []
    def totaliDebiti = [:]

    def dettagliCrediti = []
    def totaliCrediti = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") String anno,
         @ExecutionArgParam("pratica") @Default("-1") BigDecimal pratica,
         @ExecutionArgParam("codFiscale") String codFiscale,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("tipoVersamento") @Default("") String tipoVersamento,
         @ExecutionArgParam("cambioTipoVersamento") @Default("true") String cambioTipoVersamento,
         @ExecutionArgParam("presentiSanzioni") @Default("false") boolean presentiSanzioni,
         @ExecutionArgParam("calcoloSanzioni") @Default("false") boolean calcoloSanzioni) {

        this.self = w

        dataVersamento = liquidazioniAccertamentiService.getDataOdierna(false)

        if (pratica != -1) {
            PraticaTributo prtr = PraticaTributo.get(pratica)
            tt = prtr.tipoTributo.tipoTributo
            anno = prtr.anno
            if (prtr.dataRiferimentoRavvedimento) {
                dataVersamento = prtr.dataRiferimentoRavvedimento
            }
            if (!codFiscale) {
                codFiscale = prtr.contribuente.codFiscale
            }
        }

        daAnno = (anno != 'Tutti' ? anno as Integer : null)
        if (daAnno == null) {
            def annoCorrente = new Date().year + 1900
            this.daAnno = (tt == 'ICI') ? annoCorrente : (annoCorrente - 1)
        }

        contribuente = Contribuente.get(codFiscale)
        if (!contribuente) {
            throw new Exception('Contribuente ' + codFiscale + ' non trovato !')
        }

        this.codFiscale = codFiscale
        this.calcoloSanzioni = calcoloSanzioni
        this.pratica = pratica == -1 ? null : pratica

        this.dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        List<TipoTributoDTO> tipiTributoScrittura = competenzeService.tipiTributoUtenzaScrittura()

        tipiTributo = [:]
        tipiTributoScrittura.findAll { it.tipoTributo in ['ICI', 'TARSU', 'CUNI'] }.each { ttd ->
            tipiTributo[ttd.tipoTributo] = ttd.getTipoTributoAttuale() + ' - ' + ttd.descrizione
        }
        if (tipiTributo[tt] == null) {
            tt = ''
        }

        this.modificaTipoTributo = tt == ''
        this.tipoTributo = (tt != '' ? tt : null)
        this.tipoVersamento = tipiVersamento.find { it.key == tipoVersamento }
        this.cambioTipoVersamento = cambioTipoVersamento
        this.presentiSanzioni = presentiSanzioni

        if ((this.pratica) && (this.tipoTributo in ['TARSU'])) {
            this.lettura = true
        }

        caricaGruppiTributo()

        onSelezionaTipoTributo()

        if (!tipoVersamento.empty) {
            this.rata = listaRate?.find { it.rata == (tipoVersamento as short) }
        }
    }

    @Command
    def onCalcolaSanzioni() {

        if (!validaInput()) {
            return
        }

        def message = ""

        if (presentiSanzioni) {
            message = "Le sanzioni verranno eliminate e ricalcolate. Proseguire?"
        } else {
            message = "Le sanzioni verranno ricalcolate. Proseguire?"
        }

        Map params = new HashMap()
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        Messagebox.show(message, "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {

                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                try {
                                    String tipoVersSanz
                                    switch (tipoTributo) {
                                        default:
                                            tipoVersSanz = tipoVersamento.key
                                            break
                                        case 'CUNI':
                                            tipoVersSanz = rata as String
                                            break
                                        case 'TARSU':
                                            tipoVersSanz = null
                                            break
                                    }
                                    liquidazioniAccertamentiService.calcolaSanzioniRavvedimento(pratica, tipoVersSanz)
                                } catch (Exception ex) {
                                    if (ex instanceof Application20999Error) {
                                        Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                                    } else {
                                        throw ex
                                    }
                                }
                                Events.postEvent("onClose", self, [generateSanzioni: true])
                                break
                            case Messagebox.ON_NO:
                                onChiudi()
                        }
                    }
                }
                , params)
    }

    @Command
    def onCreaRavvedimento() {

        if (!validaInput()) {
            return
        }

        def results = null

        try {
            def tipoEvento = TipoEventoDenuncia.R0

            if (tipoTributo == 'TARSU') {
                results = liquidazioniAccertamentiService.creaRavvedimentoSuRuoli(
                        codFiscale,
                        daAnno,
                        tipoTributo,
                        tipoEvento,
                        dataVersamento,
                        dettagliRuoli,
                        dettagliCrediti
                )

                if (results.contatore != 0 && results.pratica != null) {
                    liquidazioniAccertamentiService.calcolaSanzioniRavvedimento(results.pratica, null)
                }
            } else {
                if (tipoTributo == 'CUNI') {
                    tipologia = 'V'
                    tipoVersamento = null
                } else {
                    rata = null
                }

                results = liquidazioniAccertamentiService.creaRavvedimenti(
                        codFiscale,
                        daAnno,
                        adAnno,
                        dataVersamento,
                        tipoVersamento,
                        tipologia,
                        tipoTributo,
                        rata?.rata,
                        null,
                        gruppoTributo
                )
            }
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }

        if (results.contatore == 0) {
            Clients.showNotification("Ravvedimento/i non generato/i.", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            if (results.pratica != null) {
                Clients.showNotification("Ravvedimento/i generato/i.", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            }
            Events.postEvent("onClose", self, [pratica: results.pratica])
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent("onClose", self, null)
    }

    @Command
    def onChangeAnnoDa() {

        adAnno = (daAnno) ? daAnno : null
        BindUtils.postNotifyChange(null, null, this, "adAnno")
        controlloTipoVersamento()

        caricaRateCuni()

        ricaricaDatiTarsu()
    }

    @Command
    def controlloTipoVersamento() {

        if (adAnno && daAnno > adAnno) {
            Clients.showNotification("I campi 'Da Anno' e 'Ad Anno' sono incoerenti.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            adAnno = null
            BindUtils.postNotifyChange(null, null, this, "adAnno")
        }

        if (adAnno && adAnno > daAnno) {
            tipoVersamento = "U"
            cambioTipoVersamento = false
        } else {
            tipoVersamento = null
            cambioTipoVersamento = true
        }

        BindUtils.postNotifyChange(null, null, this, "cambioTipoVersamento")
        BindUtils.postNotifyChange(null, null, this, "tipoVersamento")
    }

    @Command
    def onSelezionaTipoTributo() {

        if (tipoTributo == 'TARSU') {
            this.self.setWidth("1060px")
        } else {
            this.self.setWidth("600px")
        }

        if (tipoTributo == 'CUNI') {
            adAnno = null
            caricaRateCuni()
            tipologia = 'V'

            caricaGruppiTributo()

            BindUtils.postNotifyChange(null, null, this, "adAnno")
        }
        if (tipoTributo == 'TARSU') {
            adAnno = null
            tipologia = 'V'

            ricaricaDatiTarsu()

            BindUtils.postNotifyChange(null, null, this, "adAnno")
        }

        self.invalidate()
    }

    @Command
    def onSelezionaGruppoTributo() {
        if (tipoTributo == 'CUNI') {
            caricaRateCuni()
        }
    }

    @Command
    def onChangeVersatoRata(@BindingParam("rata") def rataId) {

        sistemaVersatoRateTarsu(rataId)
        distribuisciCreditiTarsu(false)
        aggiornaResiduoRateTarsu()
        ricalcolaTotaliTarsu()
    }

    @Command
    def onDropVersatoSuRata(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx, @BindingParam("rata") def rataId) {

        DropEvent event = (DropEvent) ctx.getTriggerEvent()

        String versato = event.dragged.label
        def versatoSplit = versato.split(' ')

        versato = ((versatoSplit.size() > 1) ? versatoSplit[1] : versatoSplit[0]) ?: '0'
        versato = versato.replace('.', '');
        versato = versato.replace(',', '.');
        def versatoVal = Float.parseFloat(versato)

        aggiungiVersatoARata(rataId, versatoVal)

        distribuisciCreditiTarsu(false)
        aggiornaResiduoRateTarsu()
        ricalcolaTotaliTarsu()
    }

    @Command
    def onDistribuisciResiduo() {

        annullaVersatoRate()
        distribuisciCreditiTarsu(true)
        aggiornaResiduoRateTarsu()
        ricalcolaTotaliTarsu()
    }

    @Command
    def onAnnullaVersatoRate() {

        annullaVersatoRate()
        distribuisciCreditiTarsu(false)
        aggiornaResiduoRateTarsu()
        ricalcolaTotaliTarsu()
    }

    @Command
    def onAggiungiVersamento() {

        nuovoVersamento()
    }

    @Command
    def onApriNoteCredito(@BindingParam("arg") def nota) {

        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onApriIUVCredito(@BindingParam("arg") def iuv) {

        Messagebox.show(iuv, "IUV", Messagebox.OK, Messagebox.INFORMATION)
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------

    private ricaricaDatiTarsu() {

        if (tipoTributo == 'TARSU') {

            caricaDettagliTarsu()
            caricaCrediti()
            distribuisciCreditiTarsu(false)
            aggiornaResiduoRateTarsu()

            ricalcolaTotaliTarsu()
        }
    }

    private caricaDettagliTarsu() {

        if (pratica != null) {
            dettagliRuoli = liquidazioniAccertamentiService.getDettagliRuoliDaRavvedimento(pratica)
        } else {
            dettagliRuoli = liquidazioniAccertamentiService.getDettagliRuoliPerRavvedimento(daAnno, codFiscale)
        }
    }

    private caricaCrediti() {

        if (pratica != null) {
            dettagliCrediti = liquidazioniAccertamentiService.getCreditiDaRavvedimento(pratica)
        } else {
            dettagliCrediti = liquidazioniAccertamentiService.getCreditiPerRavvedimento(daAnno, codFiscale)
        }

        totaliCrediti.versato = dettagliCrediti.sum { it.importoVersato } ?: 0
        totaliCrediti.lordo = dettagliCrediti.sum { it.importo } ?: 0

        totaliCrediti.disponibile = totaliCrediti.lordo
        totaliCrediti.residuo = totaliCrediti.disponibile

        //	I servizi non lo vogliono pi� (2024/04/03)
        //	assegnaCreditiTarsu()

        BindUtils.postNotifyChange(null, null, this, "dettagliCrediti")
        BindUtils.postNotifyChange(null, null, this, "totaliCrediti")
    }

    /// Prova ad assegnare crediti alle voci dei debiti
    private assegnaCreditiTarsu() {

        if (this.lettura)
            return

        //	if(!this.dePagAbilitato)
        //		return;

        dettagliCrediti.each { credito ->

            def residuo = credito.importo

            if (credito.ruolo) {

                def rata = cercaRataPerCredito(credito.ruolo, credito.rata)
                if (rata) {
                    aggiungiVersatoARata(rata.rataId, residuo)
                    distribuisciCreditiTarsu(false)
                    residuo -= rata.importo
                }
            }

            while (residuo > 0) {
                def rata = cercaRataPerCredito(0, credito.rata)
                if (!rata) break;

                aggiungiVersatoARata(rata.rataId, residuo)
                distribuisciCreditiTarsu(false)
                residuo -= rata.importo
            }
        }
    }

    /// Cerca una rata in base a ruolo e numero rata
    private cercaRataPerCredito(def ruolo, def numRata) {

        def rataRuolo = null

        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if (!rata.superato) {
                    if (((ruolo == 0) || (rata.ruolo == ruolo)) && (rata.rata == numRata)) {
                        //	if (rata.IUV) {
                        if (rata.importo > (rata.versato ?: 0)) {
                            if (!rataRuolo) {
                                rataRuolo = rata    /// Prendo la prima disponibile, in ordine cronologico
                            }
                        }
                        //	}
                    }
                }
            }
        }

        return rataRuolo
    }

    /// Procedura di distribuzione dei crediti sulle rate
    private distribuisciCreditiTarsu(Boolean spalmaResiduo) {

        if (this.lettura)
            return

        Double residuo = totaliCrediti.disponibile
        Double versato

        /// Processa le rate con versamento a valore dichiarato
        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if ((rata.scaduta) && (!rata.superato)) {
                    if (rata.versatoDichiarato != null) {
                        versato = rata.versatoDichiarato
                        if (versato < 0) versato = 0.0
                        if (versato > residuo) versato = residuo
                        if (versato > rata.importo) versato = rata.importo
                        rata.versato = versato
                        rata.versatoDichiarato = rata.versato

                        residuo -= rata.versato
                    }
                } else {
                    rata.versato = 0
                }
            }
        }

        /// Quindi spalma l'eventuale residuo
        if (spalmaResiduo) {
            /// Prima nelle caselle senza versato dichiarato
            dettagliRuoli.each { dettaglio ->
                dettaglio.rate.each { rata ->
                    if ((rata.scaduta) && (!rata.superato)) {
                        if (rata.versatoDichiarato == null) {
                            versato = (residuo < rata.importo) ? residuo : rata.importo
                            rata.versato = versato
                            rata.versatoDichiarato = rata.versato

                            residuo -= rata.versato
                        }
                    }
                }
            }
            /// Poi in quelle con versato a 0
            dettagliRuoli.each { dettaglio ->
                dettaglio.rate.each { rata ->
                    if ((rata.scaduta) && (!rata.superato)) {
                        if ((rata.versatoDichiarato ?: rata.versato) == 0) {
                            versato = (residuo < rata.importo) ? residuo : rata.importo
                            rata.versato = versato

                            residuo -= rata.versato
                        }
                    }
                }
            }
        }

        totaliCrediti.residuo = residuo

        BindUtils.postNotifyChange(null, null, this, "totaliCrediti")
    }

    /// Annulla il versato delle rate
    private annullaVersatoRate() {

        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if ((rata.scaduta) && (!rata.superato)) {
                    rata.versato = 0
                    rata.versatoDichiarato = null
                }
            }
        }
    }

    /// Aggiunge un versato ad una rata
    private aggiungiVersatoARata(def rataId, def versato) {

        def rataRuolo = null

        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if (rata.rataId == rataId) {
                    rata.versatoDichiarato = (rata.versatoDichiarato ?: 0) + versato
                }
            }
        }
    }

    /// Imposta il valoroe dichiarato di una rata
    private sistemaVersatoRateTarsu(def rataId) {

        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if (rata.rataId == rataId) {
                    rata.versatoDichiarato = rata.versato ?: 0
                }
            }
        }
    }

    /// Dopo variazione dei crediti, ricarica e reimposta dovuto/versato
    def ricaricaEdAggiornaCrediti() {

        caricaCrediti()
        distribuisciCreditiTarsu(false)
        aggiornaResiduoRateTarsu()

        ricalcolaTotaliTarsu()
    }

    ///	Ricalcola i residuio delle rate da versato
    private aggiornaResiduoRateTarsu() {

        def dovuto = 0
        def residuo = 0
        def versamenti = 0

        dettagliRuoli.each { dettaglio ->
            dettaglio.rate.each { rata ->
                if ((rata.scaduta) && (!rata.superato)) {
                    rata.residuo = rata.importo - (rata.versato ?: 0)
                    dovuto += rata.importo
                    versamenti += (rata.versato ?: 0)
                    residuo += rata.residuo
                }
            }
        }

        totaliDebiti.dovuto = dovuto
        totaliDebiti.versamenti = versamenti
        totaliDebiti.residuo = residuo

        BindUtils.postNotifyChange(null, null, this, "totaliDebiti")
    }

    /// Ricalcola i totali
    private ricalcolaTotaliTarsu() {

        BindUtils.postNotifyChange(null, null, this, "dettagliRuoli")
    }

    /// Valida i totali delle rate dei ruoli
    private validaTotaliTarsu() {

        def errori = []

        if (!this.lettura) {
            if (totaliDebiti.residuo < 0.01) {
                errori << "Non esiste alcun dovuto da ravvedere !"
            }
            if (totaliCrediti.residuo > 0.99) {
                errori << "Esiste del versato residuo non assegnato !"
            }
        }

        return errori
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------

    private validaInput() {

        def errori = []

        if (tipoTributo == 'TARSU') {

            def erroriTarsu = validaTotaliTarsu()
            errori.addAll(erroriTarsu)
        }

        if (!tipoVersamento && (!(tipoTributo in ['TARSU', 'CUNI']))) {
            errori << "Indicare un tipo versamento."
        }

        if (!calcoloSanzioni) {
            if (!daAnno) {
                errori << "Indicare un valore per 'Da anno'"
            }

            if (!tipoTributo) {
                errori << "Indicare un tipo tributo."
            }

            if (!tipologia) {
                errori << "Indicare una tipologia."
            }

            if (!dataVersamento) {
                errori << "Indicare una Data Riferimento Ravvedimento."
            }

            if (adAnno && daAnno > adAnno) {
                errori << "I campi 'Da Anno' e 'Ad Anno' sono incoerenti."
            }

            if (tipoTributo == 'CUNI' && (rata ?: -1) == -1) {
                errori << "Indicare una rata."
            }
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    private caricaRateCuni() {

        def tipoTributoRaw = TipoTributo.get(tipoTributo)

        def listaRateRaw = Scadenza.findAllByTipoTributoAndTipoScadenzaAndAnnoAndTipoOccupazioneAndGruppoTributo(tipoTributoRaw, "V", daAnno, 'P', gruppoTributo)
        if (listaRateRaw.empty) {
            listaRateRaw = Scadenza.findAllByTipoTributoAndTipoScadenzaAndAnnoAndTipoOccupazioneAndGruppoTributo(tipoTributoRaw, "V", daAnno, null, gruppoTributo)
        }
        listaRate = listaRateRaw
                .sort { it.rata }
                .toDTO()

        BindUtils.postNotifyChange(null, null, this, "listaRate")
    }

    private def nuovoVersamento() {

        commonService.creaPopup("/versamenti/versamento.zul",
                self,
                [
                        codFiscale : this.codFiscale,
                        tipoTributo: this.tipoTributo,
                        anno       : this.daAnno as Short,
                        sequenza   : 0,
                        lettura    : false,
                        trasferisci: false
                ],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            ricaricaEdAggiornaCrediti()
                        }
                    }
                }
        )
    }

    private caricaGruppiTributo() {

        if (tipoTributo) {

            gruppiTributo = canoneUnicoService.getElencoCodiciTributo([tipoTributo: tipoTributo]).unique().sort { it.key }
                    .collectEntries { [(it.contoCorrente): it.descrizioneCc] }
            gruppoTributo = null
            if (pratica) {
                def gruppiPratica = integrazioneDePagService.getGruppiTributoPratica(pratica as Long)
                if (gruppiPratica.size() > 0) {
                    String codice = gruppiPratica[0].gruppoTributo as String
                    gruppoTributo = gruppiTributo.find { (it.key as String) == codice }?.key
                }
            }

            BindUtils.postNotifyChange(null, null, this, "gruppiTributo")
            BindUtils.postNotifyChange(null, null, this, "gruppoTributo")
        }
    }
}
