package archivio

import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DuplicaNumeroFamiliariViewModel {

    // Componenti
    Window self

    // Service
    SoggettiService soggettiService

    // Modello
    def anno
    def dataDal
    def annoSelezionato
    def listaAnni = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        dataDal = new Date(0,00,01)
        listaAnni = soggettiService.listaFamiliariSoggettoResidente()
        annoSelezionato = (listaAnni.size()>0)? listaAnni?.get(0):null
        BindUtils.postNotifyChange(null, null, this, "dataDal")
        BindUtils.postNotifyChange(null, null, this, "annoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaAnni")
    }

    @Command
    onDuplicaNumeroFamiliari() {
        if (validaMaschera()) {
            duplicaNumeroFamiliari()
        }
    }

    @Command
    def onChangeAnno() {
        Integer giorno = dataDal.getAt(Calendar.DAY_OF_MONTH)
        Integer mese = dataDal.month
        Integer anno = anno - 1900
        dataDal = new Date(anno,mese,giorno)
        BindUtils.postNotifyChange(null, null, this, "dataDal")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private boolean validaMaschera() {
        def errori = []

        if (anno == null) {
            errori << "Valore obbligatorio sul campo Anno"
        }

        if (dataDal==null || dataDal < new Date(0,0,1)) {
            errori << "La Data di riferimento deve essere maggiore di 01/01/1900"
            if(anno){
                onChangeAnno()
            }
            else {
                dataDal = new Date(0,00,01)
            }
            BindUtils.postNotifyChange(null, null, this, "dataDal")
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    private duplicaNumeroFamiliari() {
        Long result;
        String messaggio;

        if(listaAnni.size()==0){
            result = 0
        }
        else {
            def applyResult = soggettiService.duplicaNumeroFamiliari(anno,dataDal,Long.parseLong(annoSelezionato?.anno?.toString()))
            result = applyResult.result
        }

        String title = ""
        String message = ""
        int buttons = Messagebox.OK
        def icon =  Messagebox.INFORMATION

        switch(result) {
            case 0 :
                title = "Informazione"
                message = "Non esistono Familiari soggetto Inseriti per Contribuenti non GSD"
                icon = Messagebox.INFORMATION
                buttons = Messagebox.OK
                break;
            case 1 :
                title = "Informazione"
                message = "Inserimento effettuato con successo"
                icon = Messagebox.INFORMATION
                buttons = Messagebox.OK
                break;
            case 2 :
                title = "Errore"
                message = messaggio
                icon = Messagebox.ERROR
                buttons = Messagebox.OK
                break;
        }
        Messagebox.show(message, title, buttons, icon,
                new org.zkoss.zk.ui.event.EventListener<Event>(){
                    public void onEvent(Event e){
                        if(Messagebox.ON_OK.equals(e.getName())){
                            onChiudi()
                        }
                    }
                }
        )
    }


}
