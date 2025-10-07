package archivio.dizionari

import it.finmatica.tr4.dto.TipoOggettoDTO
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaRivalutazioniRenditaRicercaViewModel extends RicercaViewModel {

    Collection<TipoOggettoDTO> tipiOggettoList

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipiOggettoList") Collection<TipoOggettoDTO> tipiOggettoList) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Rivalutazioni Rendita'

        this.tipiOggettoList = new ArrayList<TipoOggettoDTO>(Arrays.asList(new TipoOggettoDTO(null, "")))
        this.tipiOggettoList.addAll(tipiOggettoList)
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Anno')
        errors += validaEstremi(filtro.daAliquota, filtro.aAliquota, 'Aliquota')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da || filtro.a || filtro.tipoOggetto || filtro.daAliquota || filtro.aAliquota)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
