package ufficiotributi.canoneunico

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ChiudiConcessioneCUViewModel {

    // services
    def springSecurityService

    CommonService commonService
    CanoneUnicoService canoneUnicoService
    DenunceService denunceService

    // componenti
    Window self

    boolean abilitaTrasferisci = false

    // dati
    String annoTributo
    Short anno
    Date dataDecorrenzaOrig
    Date dataChiusura

    SoggettoDTO soggDestinazione
    Date fineOccupazione
    Date inizioOccupazione
    Date dataDecorrenza

    def listaAnni = []
    def listaCanoni = []
    def canoneSelezionato = null
    def canoniSelezionati = [:]
    def selectedAnyCanone = false

    Boolean visualizzaCanoni = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") Short a,
         @ExecutionArgParam("dataChiusura") def dc,
         @ExecutionArgParam("dataDecorrenza") def dd,
         @ExecutionArgParam("trasferisci") def tr,
         @ExecutionArgParam("listaCanoni") def lc) {

        this.self = w

        abilitaTrasferisci = (tr) ? true : false

        def anniParam = commonService.decodificaAnniPresSucc()
        listaAnni = canoneUnicoService.getElencoAnni(anniParam.anniSucc, anniParam.anniSucc + anniParam.anniPrec, 2021)
		
        def elencoCanoni = lc ?: []
        listaCanoni = elencoCanoni.findAll { it.dettagli.dataCessazione == null }
        visualizzaCanoni = !listaCanoni.empty

        if (listaCanoni.size() == 1) {
            onCheckAllCanoni()
        }

        anno = a ?: Calendar.getInstance().get(Calendar.YEAR)
        annoTributo = anno as String

        dataDecorrenzaOrig = dd
        dataChiusura = dc ?: canoneUnicoService.getDataOdierna()
    }

    @Command
    def onApriRicercaSoggDest() {

        commonService.creaPopup("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true]) { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    soggDestinazioneSelezionato(event.data.Soggetto)
                }
            }
        }
    }

    @Command
    def onEliminaSoggDest() {

        soggDestinazione = null
        inizioOccupazione = null
        dataDecorrenza = null

        BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
        BindUtils.postNotifyChange(null, null, this, "inizioOccupazione")
        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    def soggDestinazioneSelezionato(SoggettoDTO soggDest) {

        soggDestinazione = soggDest

        anno = Calendar.getInstance().get(Calendar.YEAR)
        annoTributo = anno as String

        BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
        BindUtils.postNotifyChange(null, null, this, "anno")
        BindUtils.postNotifyChange(null, null, this, "annoTributo")
    }

    @Command
    def onSelectAnno() {
		
		Short annoNow = anno
		if(anno < 2021) anno = 2021
		if(anno > 2099) anno = 2099
		
		if(anno != annoNow) {
			annoTributo = anno as String
			BindUtils.postNotifyChange(null, null, this, "anno")
			BindUtils.postNotifyChange(null, null, this, "annoTributo")
		}

        Date maxDate = new Date(anno - 1900, 11, 31)

        if (dataChiusura) {
            if (dataChiusura > maxDate) dataChiusura = maxDate
        } else {
            dataChiusura = maxDate
        }

        fineOccupazione = null

        BindUtils.postNotifyChange(null, null, this, "dataChiusura")
        BindUtils.postNotifyChange(null, null, this, "fineOccupazione")
    }

    @Command
    onCambiaInizioOccupazione() {

        // Se si annulla la data inizio occupazione
        if (!inizioOccupazione) {
            // Si annulla anche la data decorrenza
            dataDecorrenza = null
        } else {
            dataDecorrenza = denunceService.fGetDecorrenzaCessazione(inizioOccupazione, 1)
        }

        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onCanoneSelected() {

    }

    @Command
    def onCheckCanone(@BindingParam("detail") def detail) {

        selectedAnyCanoneRefresh()
    }

    @Command
    def onCheckAllCanoni() {

        canoniSelezionati = [:]

        if (!selectedAnyCanone) {

            listaCanoni.each() { it -> (canoniSelezionati << [(it.oggettoPraticaRef): true]) }
        }

        BindUtils.postNotifyChange(null, null, this, "canoniSelezionati")
        selectedAnyCanoneRefresh()
    }

    @Command
    onEseguiChiusura() {

        if (verificaParametri() != false) {

            def canoniDaChiudere

            if (visualizzaCanoni) {
                canoniDaChiudere = canoniSelezionati.findAll { k, v -> v }.collect { it.key as Long }
            } else {
                canoniDaChiudere = null
            }

            def datiChiusura = [
                    anno                 : anno,
                    dataFineOccupazione  : fineOccupazione,
                    dataChiusura         : dataChiusura,
                    soggDestinazione     : soggDestinazione,
                    dataInizioOccupazione: inizioOccupazione,
                    dataDecorrenza       : dataDecorrenza,
                    canoniDaChiudere     : canoniDaChiudere
            ]
			
            Events.postEvent(Events.ON_CLOSE, self, [datiChiusura: datiChiusura])
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    // Verifica coerenza parametri chiusura
    private def verificaParametri() {

        def report = verificaData()

        if (report.result == 0) {

            if (visualizzaCanoni) {

                def elencoCanoniDaChiudere = canoniSelezionati.findAll { k, v -> v }.collect { it.key as Long }
                def canoniDaChiudere = listaCanoni.findAll { it.oggettoPraticaRef in elencoCanoniDaChiudere }

                report = canoneUnicoService.verificaSubentro(anno, canoniDaChiudere, dataChiusura, soggDestinazione)
            }
        }

        if (report.result != 0) {

            Messagebox.show(report.message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
            return false
        }

        return true
    }

    // Verifica coerenza data selezionata
    private def verificaData() {

        String messaggio = ""
        Long result = 0

        Short annoCorrente = 2099    // Calendar.getInstance().get(Calendar.YEAR)
        if ((anno < 2000) || (anno > annoCorrente)) {
            messaggio += "Valore di Anno non valido !\n"
            result = 2
        }

        if (dataChiusura <= dataDecorrenzaOrig) {
            messaggio += "Data di chiusuranon non coerente con la Data di decorrenza originale !\n"
            result = 2
        }

        Calendar calendarChiusura = Calendar.getInstance()
        calendarChiusura.setTime(dataChiusura)

        if (calendarChiusura.get(Calendar.YEAR) > anno) {
            messaggio += "La data di chiusura deve essere compresa entro l'anno attuale !\n"
            result = 2
        }

        if (soggDestinazione != null) {
            if (!dataDecorrenza) {
                messaggio += "Campo 'Data decorrenza' non valorizzato\n"
                result = 2
            }

            if ((dataDecorrenza != null) && (dataChiusura != null) && (dataDecorrenza < dataChiusura)) {
                messaggio += "Impossibile trasferire gli oggetti in una data precedente alla data di cessazione\n"
                result = 2
            }
        } else {
            if ((dataDecorrenza != null) || (inizioOccupazione != null)) {
                messaggio += "Indicare il contribuente su cui trasferire gli oggetti\n"
                result = 2
            }
        }

        return [message: messaggio, result: result]
    }

    def selectedAnyCanoneRefresh() {

        selectedAnyCanone = (canoniSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyCanone")
    }
}
