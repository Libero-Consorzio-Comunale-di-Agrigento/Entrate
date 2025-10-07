package sportello.contribuenti

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoEventoDenuncia
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import java.text.DecimalFormat

class BonificaSuperficieDatiMetriciViewModel {

    private def DM_PERCRID = 80
    private def DM_RID = 'N'

    // Componenti
    def self

    // Servizi
    def denunceService
    def contribuentiService

    // Model
    def messaggioCreazioneVariazione = ""
    def inizioOccupazione
    def dataDecorrenza
    def flagDaDatiMetrici = true
    def superficie
    def flagRiduzioneSuperficie

    def listaUtenze = []
    def contribuente
    def anno
    def datoMetrico

    def labelRiduzioneSuperficie
    def oggetto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def anno,
         @ExecutionArgParam("soggetto") def soggetto,
         @ExecutionArgParam("oggetto") def oggetto,
         @ExecutionArgParam("datoMetrico") def datoMetrico
    ) {
        this.self = w

        DM_PERCRID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_PERCRID' }?.valore?.trim() as Double) ?: 80.0
        DM_RID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_RID' }?.valore?.trim()) ?: 'N'

        messaggioCreazioneVariazione = "Verra' creata un Denuncia di Variazione per l'anno ${anno} per l'oggetto ${oggetto.oggetto}"

        this.oggetto = oggetto

        this.contribuente = soggetto.contribuente
        this.anno = anno as short
        this.datoMetrico = datoMetrico

        recuperaSupDaDM()

        listaUtenze = denunceService.getLocaliAreeVariazioneCessazione(
                soggetto.contribuente.codFiscale,
                -1,
                'TARSU',
                TipoEventoDenuncia.V
        ).findAll { it.oggetto == oggetto.oggetto && it.oggettoPratica == oggetto.oggettoPratica }

    }

    @Command
    def onGeneraVariazione() {

        def errori = []

        if (!dataDecorrenza) {
            errori << "Campo 'Data decorrenza' non valorizzato."
        }

        listaUtenze.each {
            if (it.dataDecorrenza > dataDecorrenza) {
                errori << "La data di decorrenza della variazione non puo' essere precedente a quella dell'oggetto da variare (${it.dataDecorrenza.format("dd/MM/yyyy")})"
            }
        }

        if (!errori.isEmpty()) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return
        }

        contribuentiService.variaOggettoTarsu(
                anno, contribuente, listaUtenze,
                inizioOccupazione, dataDecorrenza, datoMetrico,
                flagDaDatiMetrici, superficie, flagRiduzioneSuperficie,
                "Inserimento del ${new Date().format('dd/MM/yyyy')}")

        Events.postEvent(Events.ON_CLOSE, self, [variazioneCreata: true])
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCambiaInizioOccupazione() {
        // Se si annulla la data inizio occupazione
        if (!inizioOccupazione) {
            // Si annulla anche la data decorrenza
            dataDecorrenza = null
        } else {
            dataDecorrenza = denunceService.fGetDecorrenzaCessazione(inizioOccupazione, 0)
        }

        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onCheckDatiMetrici() {
        if (!flagDaDatiMetrici) {
            flagRiduzioneSuperficie = false
            BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
        } else {
            recuperaSupDaDM()
        }
    }

    @Command
    def onCheckRiduzioneSuperficie() {
        if (flagRiduzioneSuperficie) {
            superficie = (datoMetrico.superficie.replace(',', '.') as Double) * DM_PERCRID / 100
        } else {
            superficie = (datoMetrico.superficie.replace(',', '.') as Double)
        }

        BindUtils.postNotifyChange(null, null, this, "superficie")
        BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
    }

    private recuperaSupDaDM() {
        String patternNumero = "#,##0.00"
        DecimalFormat numero = new DecimalFormat(patternNumero)
        this.labelRiduzioneSuperficie = "Rid. ${numero.format(DM_PERCRID)} % "
        flagRiduzioneSuperficie = DM_RID == 'S'

        if (flagRiduzioneSuperficie) {
            superficie = (datoMetrico.superficie.replace(',', '.') as Double) * DM_PERCRID / 100
        } else {
            superficie = (datoMetrico.superficie.replace(',', '.') as Double)
        }
        BindUtils.postNotifyChange(null, null, this, "superficie")
        BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
    }
}
