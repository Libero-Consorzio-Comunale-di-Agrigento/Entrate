package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCategorieRicercaViewModel extends RicercaViewModel {

	def tipoTributo
	
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)
		
		this.tipoTributo = tt
		
        this.titolo = 'Ricerca Categorie'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCodiceTributo, filtro.aCodiceTributo, 'Codice Tributo')
        errors += validaEstremi(filtro.daCategoria, filtro.aCategoria, 'Categoria')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.descrizione ||
                filtro.descrizionePrec ||
                filtro.daCodiceTributo || filtro.aCodiceTributo ||
                filtro.daCategoria || filtro.aCategoria ||
                filtro.flagDomestica != 'Tutti' ||
                filtro.flagGiorni != 'Tutti' ||
				(filtro.flagNoDepag != 'Tutti' && this.tipoTributo == 'CUNI'))
    }

    @Override
    def getFiltroIniziale() {
        return [flagDomestica: 'Tutti',
                flagGiorni   : 'Tutti',
				flagNoDepag  : 'Tutti']
    }
}
