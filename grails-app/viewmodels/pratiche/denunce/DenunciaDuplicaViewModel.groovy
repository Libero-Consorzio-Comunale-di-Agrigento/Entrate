package pratiche.denunce

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.pratiche.DenunciaIci
import it.finmatica.tr4.pratiche.DenunciaTasi
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DenunciaDuplicaViewModel extends DenunciaViewModel {

    DenunceService denunceService
    String tipoTributoAttuale
    short anno
    String tipo
    def codiceFiscale
    List<String> listaTipiTributo = []
    def listaOggetti = []
    short numeroContitolari = 0

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("denuncia") Long idPratica,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tipoRapporto") String tr,
         @ExecutionArgParam("listaOggetti") def lista) {
        self = w
        modifica = true

        if (tipoTributo in ['ICI', 'IMU'])
            denuncia = DenunciaIci.get(idPratica).toDTO(listaFetch)
        else
            denuncia = DenunciaTasi.get(idPratica).toDTO(listaFetch)

        tipoRapporto = tr
        anno = denuncia.pratica.anno
        calcolaListaTipiTributo()
        filtri.contribuente.codFiscale = denuncia.pratica.contribuente.codFiscale ?: ""

        listaOggetti = lista
        if (tipoTributo != 'TASI')
            calcolaListaContitolari()
    }

    private def calcolaListaTipiTributo() {
        tipoTributoAttuale = denuncia.pratica.tipoTributo.getTipoTributoAttuale(anno)
        listaTipiTributo = (tipoTributoAttuale == 'TASI') ? ["TASI"] : [tipoTributoAttuale, "TASI"]
    }

    @NotifyChange(["tipo", "listaTipiTributo"])
    @Command
    onChangeAnno() {
        calcolaListaTipiTributo()
        tipo = null
    }

    @Command
    onDuplicaDenuncia() {
        if (validaMaschera()) {
            if (numeroContitolari == (0 as short)) {
                String messaggio = "Duplicare la denuncia?"
                Messagebox.show(messaggio, "Attenzione",
                        Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.EXCLAMATION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    if (duplica(false)) {
                                        chiudi()
                                    }
                                }
                            }
                        }
                )
            } else {
                String messaggio = "Nella denuncia sono presenti contitolari, si vuole duplicare la denuncia anche per ciascuno di loro?"
                Messagebox.show(messaggio, "Attenzione",
                        Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.EXCLAMATION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    if (duplica(true)) {
                                        chiudi()
                                    }
                                }
                                if (Messagebox.ON_NO.equals(e.getName())) {
                                    if (duplica(false)) {
                                        chiudi()
                                    }
                                }
                            }
                        }
                )
            }
        }
    }

    @Command
    onChiudiPopup() {
        chiudi()
    }

    private boolean validaMaschera() {
        def messaggi = []

        if (anno == null || anno <= 0) {
            messaggi << ("Indicare l'anno della denuncia")
        }

        if (StringUtils.isEmpty(filtri.contribuente.codFiscale)) {
            messaggi << ("Indicare il codice fiscale del contribuente")
        }

        if (StringUtils.isEmpty(tipo)) {
            messaggi << ("Indicare il tipo di tributo")
        }

        if (messaggi.size() > 0) {
            messaggi.add(0, "Impossibile duplicare la denuncia:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }

        return true
    }

    private def duplica(boolean conContitolari) {
        def msg = "", tipoTributo
        try {
            tipoTributo = (tipo == "IMU") ? "ICI" : tipo
            msg = denunceService.duplicaDenuncia(denuncia.pratica, tipoTributo, anno, filtri.contribuente.codFiscale, conContitolari)
            if (!msg.isEmpty()) {
                Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 6000, true)
            }
            return true
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
                return false
            } else {
                throw e
            }
        }
    }

    // Calcola il numero totale di eventuali contitolari presnei vari oggettiContribuenti per
    // decidere se proporre la duplicazione anche per i contitolari
    private def calcolaListaContitolari() {
        def lista = []
        listaOggetti.each {
            lista = denunceService.contitolariOggetto(it.oggettoPratica.id)
            numeroContitolari += lista.size()
        }
    }
}
