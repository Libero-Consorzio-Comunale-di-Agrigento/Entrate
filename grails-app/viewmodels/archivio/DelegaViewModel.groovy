package archivio

import it.finmatica.tr4.DelegheBancarie
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.DelegheBancarieDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DelegaViewModel {

    Window self
    SoggettiService soggettiService
    CommonService commonService
    CompetenzeService competenzeService

    //Modello
    DelegheBancarieDTO delega
    List<TipoTributoDTO> listaTipiTributo 	= []
    def selectedDelega
    boolean  modifica
    def listaBanche = []
    def listaSportelli = []
    String iban = ""
    String descAbi = ""
    String descCab = ""
    List listaFetchSoggetto = ["comuneResidenza","comuneResidenza.ad4Comune","comuneResidenza.ad4Comune.provincia","archivioVie"]
    Map filtri = [intestatario: [codFiscale: ""], codAbi: "", denominazioneAbi:"", codCab: "", denominazioneCab:""]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("delega") def selectedDelega,
         @ExecutionArgParam("modifica") boolean modificaDelega,
         @ExecutionArgParam("duplica")  @Default("false") boolean duplicaDelega,
         @ExecutionArgParam("codFiscale") @Default("") def codFiscale) {
        this.self = w
        modifica = modificaDelega

        listaTipiTributo = competenzeService.tipiTributoUtenza()

        listaBanche = soggettiService.listaBanche()

        if(selectedDelega) {
            if(duplicaDelega){
                delega = new DelegheBancarieDTO()
                delega.codFiscale = selectedDelega.codFiscale
                delega.tipoTributo = selectedDelega.tipoTributo
                delega.codAbi = selectedDelega.codAbi
                delega.codCab = selectedDelega.codCab
                delega.contoCorrente = selectedDelega.contoCorrente
                delega.codControlloCc = selectedDelega.codControlloCc
                delega.lastUpdated = selectedDelega.lastUpdated
                delega.note = selectedDelega.note
                delega.codiceFiscaleInt = selectedDelega.codiceFiscaleInt
                delega.cognomeNomeInt = selectedDelega.cognomeNomeInt
                delega.flagDelegaCessata = selectedDelega.flagDelegaCessata
                delega.dataRitiroDelega = selectedDelega.dataRitiroDelega
                delega.flagRataUnica = selectedDelega.flagRataUnica
                delega.cinBancario = selectedDelega.cinBancario
                delega.ibanPaese = selectedDelega.ibanPaese
                delega.ibanCinEuropa = selectedDelega.ibanCinEuropa
            }
            else {
                delega = DelegheBancarie.findByCodFiscaleAndTipoTributo(selectedDelega.codFiscale,selectedDelega.tipoTributo)?.toDTO()
            }

            //Calcolo IBAN
            iban = (delega)?delega.getIban():""


            //Calcolo Denominazione ABI
            filtri.intestatario.codFiscale = delega.codiceFiscaleInt
            if(delega.codAbi){
                def record =  soggettiService.controlloBanca(delega.codAbi.toString())
                if(record){
                    filtri.codAbi = record.getAt(0).codAbi
                    filtri.denominazioneAbi = record.getAt(0).denominazioneAbi
                }
            }

            //Calcolo Denominazione CAB
            if(delega.codCab){
                listaSportelli = soggettiService.listaSportelli(delega.codAbi.toString())
                def record =  soggettiService.controlloSportello(delega.codAbi.toString(),delega.codCab.toString())
                if(record){
                    delega.codCab = Integer.parseInt(record.getAt(0).codCab)
                    filtri.codCab =  record.getAt(0).codCab
                    filtri.denominazioneCab = record.getAt(0).denominazioneCab
                }
            }
        }
        else {
            this.delega = new DelegheBancarieDTO()
            delega.codFiscale = codFiscale
        }

        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "listaBanche")
        BindUtils.postNotifyChange(null, null, this, "listaSportelli")
    }

    @Command
    onSelectCodFiscaleInt(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        filtri.intestatario.codFiscale = selectedRecord?.codFiscale.toUpperCase()
        delega.codiceFiscaleInt = selectedRecord?.codFiscale?.toUpperCase()
        delega.cognomeNomeInt = selectedRecord?.cognome?.toUpperCase() + " " +selectedRecord?.nome?.toUpperCase()
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeCodFiscaleInt(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
      /* if (filtri.intestatario.codFiscale != "" && !event.target.isOpen()) {
            String messaggio = "Non è stato selezionato alcun soggetto.\n"
            messaggio += "Il soggetto con codice fiscale ${filtri?.intestatario?.codFiscale?.toUpperCase()} non è presente in anagrafe.\n"
            messaggio += "Si desidera inserirne uno nuovo?"
            Messagebox.show(messaggio, "Ricerca soggetto",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        public void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                creaPopupSoggetto("/archivio/soggetto.zul", [idSoggetto: -1, codiceFiscale: filtri.intestatario.codFiscale])
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                              //  svuotaCodiceFiscale()
                            }
                        }
                    }
            )
        }*/
    }


    @Command
    onSelectCodiceAbi() {
            if(filtri.codAbi){
                def record =  soggettiService.controlloBanca(filtri.codAbi.toString())
                if(record){
                    filtri.codAbi = record.getAt(0).codAbi
                    filtri.denominazioneAbi = record.getAt(0).denominazioneAbi
                    delega.codAbi = Integer.parseInt(record.getAt(0).codAbi)
                    listaSportelli = soggettiService.listaSportelli(delega.codAbi.toString())
                }
                else{
                    svuotaCodiceAbi()
                    svuotaCodiceCab()
                    Clients.showNotification("Banca non prevista.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
                }
            }
            else {
                svuotaCodiceAbi()
                svuotaCodiceCab()
            }
            onChangeIban()
            BindUtils.postNotifyChange(null, null, this, "delega")
            BindUtils.postNotifyChange(null, null, this, "filtri")
            BindUtils.postNotifyChange(null, null, this, "listaSportelli")

    }

    @Command
    onChangingCodiceAbi(@BindingParam("codice") def codice) {
        if(codice.value){
            listaBanche = soggettiService.listaBanche(codice.value.toString())
            BindUtils.postNotifyChange(null, null, this, "listaBanche")
        }
    }

    @Command
    onSelectCodiceCab() {
        if(filtri.codCab){
            def record =  soggettiService.controlloSportello(filtri.codAbi.toString(),filtri.codCab.toString())
            if(record){
                filtri.codCab = record.getAt(0).codCab
                filtri.denominazioneCab = record.getAt(0).denominazioneCab
                delega.codCab = Integer.parseInt(record.getAt(0).codCab)
            }
            else{
                svuotaCodiceCab()
                Clients.showNotification("Sportello bancario non previsto.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
            }
        }
        else {
            svuotaCodiceCab()
        }
        onChangeIban()
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


    @Command
    onChangeCodiceAbi(@BindingParam("codice") def codice) {
        if(codice.value){
            def record =  soggettiService.controlloBanca(codice.value.toString())
            if(record){
                filtri.codAbi = record.getAt(0).codAbi
                filtri.denominazioneAbi = record.getAt(0).denominazioneAbi
                delega.codAbi = Integer.parseInt(record.getAt(0).codAbi)
            }
            else{
                svuotaCodiceAbi()
                Clients.showNotification("Banca non prevista.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            }
            svuotaCodiceCab()
        }
        else {
            svuotaCodiceAbi()
            svuotaCodiceCab()
        }
        onChangeIban()
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeCodiceCab(@BindingParam("codice") def codice) {
        if(codice.value){
            def record =  soggettiService.controlloSportello(delega.codAbi.toString(),codice.value.toString())
            if(record){
                filtri.codCab = record.getAt(0).codCab
                filtri.denominazioneCab = record.getAt(0).denominazioneCab
                delega.codCab = Integer.parseInt(record.getAt(0).codCab)
            }
            else{
                svuotaCodiceCab()
                Clients.showNotification("Sportello bancario non previsto.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            }
        }
        else {
            svuotaCodiceCab()
        }
        onChangeIban()
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onCheckDelegaCessata() {
        if(!delega.flagDelegaCessata){
            delega.dataRitiroDelega = null
            BindUtils.postNotifyChange(null, null, this, "delega")
        }
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, [delega: null])
    }

    @Command
    onSalva() {
        if (validaMaschera()) {
            //In fase di inserimento o duplica controllare se esiste già
            if(!modifica){
                DelegheBancarie esisteDelega = DelegheBancarie.findByCodFiscaleAndTipoTributo(delega.codFiscale,delega.tipoTributo)
                if(esisteDelega){
                    def msg = "La Delega "+delega.codFiscale+" "+TipoTributo.findByTipoTributo(delega.tipoTributo)?.tipoTributoAttuale+" gia' presente!. La registrazione non puo' essere inserita."
                    Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                    return false
                }
            }
            delega.lastUpdated = new Date()
            delega.ibanPaese = delega.ibanPaese?.toUpperCase()
            delega.cinBancario = delega.cinBancario?.toUpperCase()
            delega.cognomeNomeInt = delega.cognomeNomeInt?.toUpperCase()
            delega.codiceFiscaleInt = filtri.intestatario.codFiscale?.toUpperCase()
            if(!delega.flagDelegaCessata){
                delega.dataRitiroDelega = null
            }
            delega = soggettiService.salvaDelegaBancaria(delega)
            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)
            Events.postEvent(Events.ON_CLOSE, self, [delega: delega])
        }
    }

    @Command
    onChangeIban() {
        iban = (delega)?delega.getIban():""
        BindUtils.postNotifyChange(null, null, this, "iban")
    }

    protected void creaPopupSoggetto(String zul, def parametri) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    (event.data.Soggetto) ? setSelectCodFiscale(event.data.Soggetto) : svuotaCodiceFiscale()
                }
            }
        }
        w.doModal()
    }

    def setSelectCodFiscale(def selectedRecord) {
        if (selectedRecord) {
            filtri.intestatario.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
            if (delega) {
                delega?.codiceFiscaleInt = selectedRecord?.codFiscale?.toUpperCase()
                delega.cognomeNomeInt = selectedRecord?.cognome?.toUpperCase() + " " +selectedRecord?.nome?.toUpperCase()
            }
            BindUtils.postNotifyChange(null, null, this, "delega")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    protected void svuotaCodiceFiscale() {
        if (delega) {
            delega?.codiceFiscaleInt = null
            delega.cognomeNomeInt = null
        }
        filtri.intestatario.codFiscale = ""
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    def svuotaCodiceAbi(){
        filtri.codAbi = ""
        filtri.denominazioneAbi = ""
        delega.codAbi = null
    }

    @Command
    def svuotaCodiceCab(){
        filtri.codCab = ""
        filtri.denominazioneCab = ""
        delega.codCab = null
        listaSportelli = []
        BindUtils.postNotifyChange(null, null, this, "delega")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    private boolean validaMaschera() {
        def errori = []

       if (delega.tipoTributo == null) {
            errori << "Indicare il Tipo Tributo!"
        }

        if (delega.codAbi == null) {
            errori << "Indicare Banca(ABI)!"
        }

        if (delega.codCab == null) {
            errori << "Indicare Sportello(CAB)!"
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }

        return true
    }

}
