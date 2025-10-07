package ufficiotributi.imposte

import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.InsolventiService
import it.finmatica.tr4.insolventi.FiltroRicercaInsolventi
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Bandbox
import org.zkoss.zul.Window

class InsolventiRicercaViewModel {

    //Services
    InsolventiService insolventiService

    // Componenti
    Window self

    //Comuni
    TipoTributoDTO tipoTributo
    def listaRuoli
    def bdRuoli
    Short anno
    def gruppoTributoAttivo
    def tributo
    def listaTipi = [
            "Tutti",
            "Imposta",
            "Liquidazione",
            "Accertamento"
    ]

    def isChangedTipo = false

    Boolean insolventiGenerale

    FiltroRicercaInsolventi filtri

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("filtri") def f,
         @ExecutionArgParam("anno") def an,
         @ExecutionArgParam("gruppoTributoAttivo") def gt,
         @ExecutionArgParam("codiceTributo") def ct,
         @ExecutionArgParam("insolventiGenerale") @Default("false") Boolean ig) {

        this.self = w

        this.insolventiGenerale = ig ?: false

        this.tipoTributo = tt
        this.filtri = f
        this.anno = an as Short
        this.gruppoTributoAttivo = gt

        if (this.gruppoTributoAttivo) {
            this.tributo = ct
        } else {
            this.tributo = "TUTTI"
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCerca() {

        //Converto i dati in maiuscolo
        if (filtri.cognome) {
            filtri.cognome = filtri.cognome.toUpperCase()
        }
        if (filtri.nome) {
            filtri.nome = filtri.nome.toUpperCase()
        }
        if (filtri.codFiscale) {
            filtri.codFiscale = filtri.codFiscale.toUpperCase()
        }

        //Imposto filtro su tributo se il checkbox "Gruppo e Tributo" è attivo
        if (gruppoTributoAttivo) {
            filtri.tributo = tributo
        } else {
            filtri.tributo = -1
        }

        Events.postEvent(Events.ON_CLOSE, self, [filtriAggiornati: filtri, isChangedTipo: isChangedTipo])
    }


    @Command
    def onCheckARuolo() {
        if (filtri.aRuolo == false) {
            if (filtri.ruolo != null) {
                filtri.ruolo = null
                BindUtils.postNotifyChange(null, null, this, "filtri")
            }
        }
    }

    @Command
    def onSvuotaFiltri() {
        filtri.pulisciFiltri(insolventiGenerale)
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    def onApriRuolo(@BindingParam("bd") Bandbox bd) {
        caricaRuoli()
        bdRuoli = bd
    }

    @Command
    def onSelezionaRuolo() {
        bdRuoli?.close()
    }

    @Command
    def onChangeTipo() {
        isChangedTipo = true
    }

    @Command
    def onPulisciRuolo(){
        filtri.ruolo = null
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    private caricaRuoli() {
        if (insolventiGenerale) {
            listaRuoli = insolventiService.getListaRuoli(tipoTributo, null, filtri.annoDa, filtri.annoA, null)
        } else {
            listaRuoli = insolventiService.getListaRuoli(tipoTributo, anno)
        }
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
    }
}
