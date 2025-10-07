package ufficiotributi.imposte

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaRuoliPerSelezioneViewModel {

    private static Log log = LogFactory.getLog(ListaRuoliPerSelezioneViewModel)

    Window self

    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    ImposteService imposteService

    def listaRuoli
    def codFiscale
    def listaRuoliSelezionati = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idPratica") def idPratica,
         @ExecutionArgParam("codFiscale") def codFiscale
    ) {

        this.self = w
        this.codFiscale = codFiscale

        this.listaRuoli = listeDiCaricoRuoliService
                .findAllRuoliAutomatici(PraticaTributo.get(idPratica).toDTO())

        def prtr = PraticaTributo.get(idPratica)

        if (listaRuoli.size == 0) {
            listaRuoli = Ruolo.createCriteria().list {

                eq("tipoTributo", prtr.tipoTributo)
                ge("annoRuolo", prtr.anno)
                isNull("invioConsorzio")

                if (prtr.data){
                    ge("dataEmissione", prtr.data)
                }

                order("tipoRuolo", "asc")
                order("annoRuolo", "asc")
                order("annoEmissione", "asc")
                order("progrEmissione", "asc")
                order("dataEmissione", "asc")
                order("invioConsorzio", "asc")
            }
        }

        this.listaRuoliSelezionati += listaRuoli

        def messaggio = ""

        if (listaRuoliSelezionati.size == 1) {
            onSeleziona()
        }
    }

    @Command
    def onSeleziona() {
        def elencoRuoli = listaRuoliSelezionati*.id

        def messaggio = ""
        elencoRuoli.each {
            log.info("Inserimento a ruolo [${it}]")
            messaggio += imposteService.inserimentoARuolo(Ruolo.get(it), codFiscale)
        }

        if (!messaggio.replace('\n', '').trim().empty) {
            Messagebox.show(messaggio, "Inserimento a ruolo", null, null, Messagebox.INFORMATION, null, {}, [width: 800])
        }

        onChiudi()
    }


    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private chiudi(def idRuoli = null) {
        Events.postEvent(Events.ON_CLOSE, self, idRuoli ? [idRuoli: idRuoli] : null)
    }

}
