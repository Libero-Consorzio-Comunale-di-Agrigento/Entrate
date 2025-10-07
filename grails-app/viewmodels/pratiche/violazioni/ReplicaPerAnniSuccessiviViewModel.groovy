package pratiche.violazioni

import it.finmatica.tr4.interessiViolazioni.InteressiViolazioniService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class ReplicaPerAnniSuccessiviViewModel {

    // Componenti
    Window self

    // Services
    InteressiViolazioniService interessiViolazioniService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    DenunceService denunceService

    // Dati
    def impostazioni = [
            anniMax             : 10,
            annoDa              : null,
            annoA               : null,
            dataEmissione       : null,
            valoreRivalutato    : null,
            calcoloSanzioni     : null
    ]

    def listaInteressi = []

    PraticaTributo pratica
    String tipoTributo
    Short annoPratica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("pratica") def prtr) {

        this.self = w

        pratica = PraticaTributo.get(prtr)
        if(!prtr) {
            throw new Exception("Pratica non trovata : " + prtr);
        }

        tipoTributo = pratica.tipoTributo.tipoTributo
        annoPratica = pratica.anno

        impostazioni.annoDa = annoPratica + 1
        impostazioni.annoA = annoPratica + 1
        impostazioni.dataEmissione = new Date().clearTime()

        impostazioni.calcoloSanzioni = true

		/// ICI/IMU : A volte il valore degli ogpr risulta rivalutato anche se il flag_valore_rivalutato non
		/// risulta impostato. Si è deciso pertanto (#55555 nota 74) di recuperare il valore del flag esistente,
		/// nascondendolo all'utente, propagando così il valore corretto, mantenendo però così il flag errato
		impostazioni.valoreRivalutato = interessiViolazioniService.getPraticaRivalutata(pratica.id)

        onChangeEmissione()
    }

    @Command
    def onChangeAnnoDa() {
        rigeneraDateInteressi(true)
    }

    @Command
    def onChangeAnnoA() {
        rigeneraDateInteressi(true)
    }

    @Command
    def onChangeEmissione() {
        rigeneraDateInteressi(false)
    }

    @Command
    def onOK() {

        if (verificaImpostazioni() == false) {
			return
		}

        if(impostazioni.calcoloSanzioni) {
            interessiViolazioniService.preparaDateInteressi(listaInteressi, impostazioni)
        }

        def elencoPratiche = []

        try {
            elencoPratiche = liquidazioniAccertamentiService.replicaAccertamento(pratica.id, pratica.anno, impostazioni)
        }
        catch (Exception e) {
            Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        if (elencoPratiche.size() == 0) {
            Clients.showNotification("Accertamento non replicato.", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        }
        else {
            String message = '';

            def anniMancanti = elencoPratiche.findAll { it.pratica == 0 }.collect { it.anno }
            def numAnniMancanti = anniMancanti.size()

            if(numAnniMancanti > 0) {
                def anni = anniMancanti.join(", ");
                message = (numAnniMancanti > 1) ? "gli anni " : "l'anno "

                if(tipoTributo == 'TARSU') {
                    message = "Per " + message + anni + " non e' presente il ruolo per gli oggetti accertati o " + 
                                                                                "il ruolo non risulta inviato.\n\n" + 
                                                                                    "L'accertamento non puo' essere replicato"
                }
                else {
                    message = "Per " + message + anni + " non e' stato possibile replicare l'accertamento"
                }
            }
            if(message.isEmpty()) {
                Clients.showNotification("Accertamento/i replicato.", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            }
            else {
                message = "Attenzione :\n\n" + message
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 10000, true)
            }

            if(impostazioni.calcoloSanzioni) {
                /// Visto che ora la procedura di replica non calcola più le sanzioni lo si rifà qui
                calcolaSanzioniAccertamenti(elencoPratiche, impostazioni)
            }

            Events.postEvent(Events.ON_CLOSE, self, [elaborazioneEseguita: true])
        }
    }

    def calcolaSanzioniAccertamenti(def elencoPratiche, def impostazioniCalcolo) {

        def result = 0
        
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")

        def praticheNum = elencoPratiche.size()

        String subStr
        def index
        def ptr

        Long praticaId
        def interessiDal
        def interessiAl

        String dateInizio = impostazioniCalcolo.dateInizio ?: ''
        String dateFine = impostazioniCalcolo.dateFine ?: ''

        for (index = 0; index < praticheNum;index++) {

            praticaId = elencoPratiche[index].pratica

            ptr = index * 8

            interessiDal = null
            interessiAl = null

            if(dateInizio.size() > 0) {
                subStr = dateInizio.substring(ptr, ptr + 8)
                interessiDal = sdf.parse(subStr)

            }
            if(dateFine.size() > 0) {
                subStr = dateFine.substring(ptr, ptr + 8)
                interessiAl = sdf.parse(subStr)
            }

            def impostazioni = [
                interessiDal : interessiDal,
                interessiAl : interessiAl
            ]

            if(praticaId != 0) {
                def reportNow = calcolaSanzioniAccertamento(praticaId, impostazioni)
                if(result < reportNow.result) {
                    result = reportNow.result
                }
            }
        }

        if(result == 0) {
            Clients.showNotification("Eseguito calcolo sanzioni", Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 5000, true)
        }
    }

    def calcolaSanzioniAccertamento(Long praticaId, def impostazioni) {

        PraticaTributoDTO pratica = PraticaTributo.get(praticaId).toDTO()

        def listaOggetti = denunceService.getOggettiPratica(praticaId)

        def report = liquidazioniAccertamentiService.calcolaSanzioniAccertamentoManuale(pratica, impostazioni, listaOggetti)

        if (report.result != 0) {
            Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 5000, true)
        }

        return report
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def rigeneraDateInteressi(Boolean restore) {

        if(tipoTributo == 'TARSU') {

            def dateMax = impostazioni.dataEmissione ?: new Date().clearTime()

            def listaInteressi_Old = listaInteressi.clone()

            listaInteressi = interessiViolazioniService.getDatePerAnni(tipoTributo, impostazioni)

            if(restore) {
                listaInteressi.each { it ->
                    def dateOld = listaInteressi_Old.find { old -> it.anno == old.anno }
                    if(dateOld) {
                        if(dateOld.dataInizio) {
                            it.dataInizio = dateOld.dataInizio
                        }
                        if(dateOld.dataFine) {
                            it.dataFine = dateOld.dataFine
                        }
                    }
                }
            }
        }
        else {
            listaInteressi = []
        }
    
        BindUtils.postNotifyChange(null, null, this, "listaInteressi")
    }

    private def verificaImpostazioni() {

        String message = ""
        Boolean valid = true

        if(!impostazioni.annoDa) {
             message += "- Periodo di replica -> Anno Da non specificato\n"
        }
        if(!impostazioni.annoA) {
             message += "- Periodo di replica -> Anno A non specificato\n"
        }
        else {
            if(impostazioni.annoDa) {
                def anni = impostazioni.annoA - impostazioni.annoDa + 1
                if((anni < 1) || (anni > impostazioni.anniMax)) {
                    message += "- Periodo di replica -> Anno A non valido\n"
                }
            }
        }
        if(!impostazioni.dataEmissione) {
            message += "- Periodo di replica -> Data Emissione non specificata\n"
        }

        if(impostazioni.calcoloSanzioni) {

            def dateMax = impostazioni.dataEmissione ?: new Date().clearTime()

            listaInteressi.each { it ->
                if(!it.dataInizio) {
                    message += "- Interessi anno " + (it.anno as String) + " -> Data Inizio non specificata\n"
                }
                else {
                    if(it.dataInizio > dateMax) {
                        message += "- Interessi anno " + (it.anno as String) + " -> Data Inizio posteriore a Data Emissione!\n"
                    }
                }
                if(!it.dataFine) {
                    message += "- Interessi anno " + (it.anno as String) + " -> Data Fine non specificata\n"
                }
                else {
                    if(it.dataInizio) {
                        if(it.dataInizio > it.dataFine) {
                            message += "- Interessi anno " + (it.anno as String) + " -> Data Inizio deve essere precedente o uguale a Data Fine!\n"
                        }
                        else {
                            if(it.dataFine > dateMax) {
                                message += "- Interessi anno " + (it.anno as String) + " -> Data Fine posteriore a Data Emissione!\n"
                            }
                        }
                    }
                }
            }
        }

        if (!message.empty) {
            message = "Attenzione:\n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            valid = false
        }

        return valid
    }
}
