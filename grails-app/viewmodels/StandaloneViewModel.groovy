import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class StandaloneViewModel {

    // services
    SpringSecurityService springSecurityService

    // componenti
    Window self
    Window documentoWindow

    // dati
    Map operazioni = [
            "PRATICA"        : [
                    "ICI"  : "/pratiche/denunce/denunciaImu.zul",
                    "TARSU": "/pratiche/denunce/denunciaTari.zul",
                    "TASI" : "/pratiche/denunce/denunciaTasi.zul"
            ],
            "PRATICA_STORICA": [
                    "ICI" : "/pratiche/denunce/denunciaImu.zul",
                    "TASI": "/pratiche/denunce/denunciaTasi.zul"
            ],
            "CONTRIBUENTE"   : "/sportello/contribuenti/situazioneContribuente.zul",
            "CALCOLO"        : "/sportello/contribuenti/calcoloIndividuale.zul",
            "SOGGETTO"       : "/archivio/soggetto.zul",
            "ANOMALIE"       : "/ufficiotributi/bonificaDati/dichiarazioni.zul",
            "OGGETTICATASTO" : "/archivio/oggettiCatasto.zul",
            "OGGETTIWEBGIS"  : "/archivio/oggettiDaWebGis.zul",
            VIOLAZIONE       : [
                    A: "pratiche/violazioni/accertamentiManuali.zul"
            ]
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @QueryParam("sezione") String sezione
         , @QueryParam("idSoggetto") String idSoggetto
         , @QueryParam("idOggetti") String idOggetti
         , @QueryParam("idPratica") String idPratica
         , @QueryParam("tipoTributo") String tipoTributo
         , @QueryParam("tipoRapporto") String tipoRapporto
         , @QueryParam("anno") String anno
         , @QueryParam("elencoAnom") String elencoAnom
         , @QueryParam("oggetto") Long oggetto
         , @QueryParam("lettura") @Default("true") Boolean lettura) {

        this.self = w

        String zul
        def parametri

        switch (sezione) {
            case "PRATICA":
                zul = operazioni[sezione][tipoTributo]
                parametri = [pratica: idPratica, tipoRapporto: tipoRapporto, lettura: lettura, daBonifiche: false, storica: false]
                break
            case "PRATICA_STORICA":
                zul = operazioni[sezione][tipoTributo]
                parametri = [pratica: idPratica, tipoRapporto: tipoRapporto, lettura: true, daBonifiche: false, storica: true]
                break
            case "CONTRIBUENTE":
                zul = operazioni[sezione]
                parametri = [idSoggetto: idSoggetto, standalone: true]
                break
            case "CALCOLO":
                zul = operazioni[sezione]
                parametri = [idSoggetto: idSoggetto]
                break
            case "SOGGETTO":
                zul = operazioni[sezione]
                parametri = [idSoggetto: idSoggetto]
                break
            case "OGGETTICATASTO":
                zul = operazioni[sezione]
                parametri = [idOggetti: idOggetti]
                break
            case "OGGETTIWEBGIS":
                zul = operazioni[sezione]
                parametri = [idOggetti: idOggetti]
                break
            case "ANOMALIE":
                zul = operazioni[sezione]
                parametri = [anno: anno, elencoAnom: elencoAnom, oggetto: oggetto]
                break
            case "VIOLAZIONE":
                def pratica = PraticaTributo.get(idPratica)
                zul = operazioni[sezione][pratica.tipoPratica]
                parametri = [
                        pratica     : idPratica,
                        tipoRapporto: tipoRapporto,
                        lettura     : lettura,
                        situazione  : pratica?.tipoTributo?.tipoTributo == 'ICI' ? 'accManImu' : 'accManTari',
                        daBonifiche : false
                ]
                break
            default:
                break
        }
        creaPopup(zul, parametri)
    }

    private void creaPopup(String zul, def parametri) {

        documentoWindow = Executions.createComponents(zul, self, parametri)
        documentoWindow.onClose() {
            Clients.evalJavaScript("window.close();")
        }
        documentoWindow.doModal()
    }
}
