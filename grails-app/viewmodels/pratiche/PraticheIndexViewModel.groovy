package pratiche

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Window

class PraticheIndexViewModel {

    // services
    def springSecurityService
    CompetenzeService competenzeService
    CommonService commonService

    def cbTributiAbilitati = [:]

    // componenti
    Window self

    // sezioni (referenziate dal listitem a sinistra)
    def sezioni = ["denunce"     : "/pratiche/denunce/listaDenunce.zul",
                   "solleciti"   : "/pratiche/solleciti/listaSolleciti.zul",
                   "liquidazioni": "/pratiche/violazioni/listaLiquidazioni.zul",
                   "ravvedimenti": "/pratiche/ravvedimenti/listaRavvedimenti.zul",
                   "accertamenti": "/pratiche/violazioni/listaAccertamenti.zul",
                   "utenzeTari"  : "/pratiche/utenze/elencoUtenze.zul",
                   "canoni"      : "/ufficiotributi/canoneunico/listaCanoni.zul",
                   "rateazioni"  : "/pratiche/rateazione/listaRateazioni.zul",
                   "insolventi"  : "/pratiche/insolventi/listaInsolventi.zul",
                   "elaborazioni": "/elaborazioni/listaElaborazioni.zul"]

    String selectedSezione
    String urlSezione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        String elemento = Sessions.getCurrent().getAttribute("elemento")
        Sessions.getCurrent().removeAttribute("elemento")
        setSelectedSezione(elemento)

        verificaCompetenze()
    }

    List<String> getPatterns() {
        return sezioni.collect { it.key }
    }

    void handleBookmarkChange(String bookmark) {
        setSelectedSezione(bookmark)
    }

    void setSelectedSezione(String value) {
        if (value == null || value.length() == 0) {
            urlSezione = null
        }

        selectedSezione = value
        urlSezione = sezioni[selectedSezione]

        BindUtils.postNotifyChange(null, null, this, "urlSezione")
    }

    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
        }
    }
}
