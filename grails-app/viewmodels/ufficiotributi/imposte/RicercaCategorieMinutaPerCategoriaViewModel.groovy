package ufficiotributi.imposte

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class RicercaCategorieMinutaPerCategoriaViewModel {

    // Services
    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Componenti
    Window self

    // Dati
    def listaTipiTributo
    def tipoTributoSelezionato
    def listaTributi
    def tributoSelezionato
    def listaCategorie
    def categoriaDaSelezionata
    def categoriaASelezionata
    def ordinamento = "A"
    def filtro = "DND"


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tributo") def trib) {

        this.self = w

        this.listaTipiTributo = TipoTributo.list()
        this.tipoTributoSelezionato = listaTipiTributo.find { it.tipoTributo == "TARSU" }

        this.listaTributi = listeDiCaricoRuoliService.getTributiRicercaMinutaCategoria(tipoTributoSelezionato.tipoTributo);
        this.tributoSelezionato = listaTributi.find { it.tributo == trib } ?: listaTributi[0]

        this.listaCategorie = listeDiCaricoRuoliService.getCategoriaRicercaMinutaCategoria(tipoTributoSelezionato.tipoTributo, tributoSelezionato.tributo)
        this.categoriaDaSelezionata = !listaCategorie.isEmpty() ? listaCategorie[0] : null
        this.categoriaASelezionata = !listaCategorie.isEmpty() ? listaCategorie[listaCategorie.size() - 1] : null
    }

    @Command
    onCerca() {

        if (categoriaDaSelezionata?.categoria > categoriaASelezionata?.categoria) {
            Clients.showNotification("La Categoria A non può essere maggiore della Categoria Da.", Clients.NOTIFICATION_TYPE_WARNING,
                    null, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, ["filtri": [
                tipoTributo: tipoTributoSelezionato,
                tributo    : tributoSelezionato.tributo,
                categoriaDa: categoriaDaSelezionata?.categoria ?: 1,
                categoriaA : categoriaASelezionata?.categoria ?: 99999,
                filtro     : filtro,
                ordinamento: ordinamento
        ]])

    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onChangeTipoTributo() {
        this.listaTributi = listeDiCaricoRuoliService.getTributiRicercaMinutaCategoria(tipoTributoSelezionato.tipoTributo);
        this.listaCategorie = listeDiCaricoRuoliService.getCategoriaRicercaMinutaCategoria(tipoTributoSelezionato.tipoTributo, tributoSelezionato.tributo)

        BindUtils.postNotifyChange(null, null, this, "listaTributi")
        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }


}
