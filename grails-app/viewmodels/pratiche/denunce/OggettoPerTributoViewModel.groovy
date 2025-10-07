package pratiche.denunce

import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.ArchivioVieDTO
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class OggettoPerTributoViewModel {

    final Long TIPO_OGGETTO_TARSU = 5
    final String TITOLO = 'Oggetto per denuncia $titolo'

    // componenti
    Window self

    // Modello
    String titolo = ""
    TipoTributoDTO tipoTributo
    OggettoDTO oggetto
    def listaCategorieCatasto

    // Servizi
    OggettiService oggettiService
    CommonService commonService
    CompetenzeService competenzeService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("tipoTributo") String tipoTributo) {

        if (!tipoTributo?.trim()) {
            throw new RuntimeException("Specificare il tipoTributo")
        }

        // Al momento e' implementata la sola gestione per TARSU
        if (tipoTributo != 'TARSU') {
            throw new RuntimeException("Tributo ${tipoTributo} non supportato.")
        }

        self = w

        this.oggetto = new OggettoDTO(
                archivioVie: new ArchivioVieDTO(),
                fonte: Fonte.get(4L).toDTO(),
                tipoOggetto: TipoOggetto.get(TIPO_OGGETTO_TARSU).toDTO()
        )

        this.tipoTributo = competenzeService.tipiTributoUtenza().find { it.tipoTributo == tipoTributo }
        this.titolo = TITOLO.replace('$titolo', TipoTributo.get(tipoTributo).getTipoTributoAttuale())
        this.listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale == true }
    }

    @Command
    def onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        oggetto.archivioVie = event.data
    }

    @Command
    def onInserisciOggettoPerTributo() {
        oggetto = oggettiService.salvaOggetto(oggetto, null, false)
        Events.postEvent(Events.ON_CLOSE, self, [idOggetto: oggetto.id])
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
