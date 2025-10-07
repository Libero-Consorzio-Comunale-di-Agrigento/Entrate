package sportello.contribuenti

import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class SituazioneContribuenteRenditeOggettoViewModel {

    Window self

    OggettiService oggettiService

    def renditeOggetto = []
    def renditeOggettoValDich = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("oggettoSelezionato") def oggettoSelezionato) {

        this.self = w

        def renditaSuValoreDichiarato = [:]

        renditaSuValoreDichiarato.numOrdine = oggettoSelezionato.numOrdine
        renditaSuValoreDichiarato.valore = oggettoSelezionato.valore
        renditaSuValoreDichiarato.rendita = oggettiService.getRenditaOggettoPratica(
                oggettoSelezionato.valore, oggettoSelezionato.tipoOggetto, oggettoSelezionato.anno, oggettoSelezionato.categoriaCatasto)
        renditaSuValoreDichiarato.mesiPossesso = oggettoSelezionato.mesiPossesso
        renditaSuValoreDichiarato.flagPossesso = oggettoSelezionato.flagPossesso
        renditaSuValoreDichiarato.flagAbPrincipale = oggettoSelezionato.flagAbPrincipale ? 'S' : 'N'

        renditeOggettoValDich = []
        renditeOggettoValDich << renditaSuValoreDichiarato

        renditeOggetto = []
        Oggetto.get(oggettoSelezionato.oggetto).riferimentiOggetto.each { renditeOggetto << it }

        renditeOggetto = renditeOggetto.sort { r1, r2 -> (r1.oggetto.id <=> r2.oggetto.id) ?: (r1.inizioValidita <=> r2.inizioValidita) }

    }

    @Command onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
