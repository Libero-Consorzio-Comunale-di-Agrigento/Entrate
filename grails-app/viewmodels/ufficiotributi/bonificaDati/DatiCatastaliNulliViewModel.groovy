package ufficiotributi.bonificaDati


import java.util.List;

import it.finmatica.tr4.dto.OggettoDTO

import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.Default
import org.zkoss.bind.annotation.AfterCompose
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zul.Window

class DatiCatastaliNulliViewModel extends AnomalieDatiCatastaliViewModel {

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("oggetto") def oggetto
         , @ExecutionArgParam("anomalia") def anomalia
         , @ExecutionArgParam("lettura") @Default("true") Boolean lettura) {

        this.self = w
		
		this.lettura = lettura

        abilitaMappe = integrazioneWEBGISService.integrazioneAbilitata()

        if (oggetto) idOggetto = oggetto

        if (anomalia) idAnomalia = anomalia

        oggettoDTO = oggettiService.getOggetto(idOggetto)
        def oggettoDTORicerca = new OggettoDTO()
        oggettoDTORicerca.id = oggettoDTO.id

        def ricercaInArchivio = false

        if (oggettoDTO.foglio || oggettoDTO.numero || oggettoDTO.subalterno) {
            oggettoDTORicerca.foglio = oggettoDTO.foglio?.trim()
            oggettoDTORicerca.numero = oggettoDTO.numero?.trim()
            oggettoDTORicerca.subalterno = oggettoDTO.subalterno?.trim()
            ricercaInArchivio = true
        } else if (oggettoDTO.archivioVie) {
            oggettoDTORicerca.archivioVie = oggettoDTO.archivioVie
            oggettoDTORicerca.numCiv = oggettoDTO.numCiv
            ricercaInArchivio = true
        }
        oggettoDTORicerca.tipoOggetto = oggettoDTO.tipoOggetto

        if (ricercaInArchivio) {
            def ricercaArchivio = gestioneAnomalieService.getOggettiDaAchivioEstremiParziali(oggettoDTORicerca)
            oggettiDaArchivio = ricercaArchivio.lista
            listaFiltri = [ricercaArchivio.filtro]

            def ricercaCatasto = gestioneAnomalieService.getOggettiDaCatastoEstremiParziali(oggettoDTORicerca)
            oggettiDaCatasto = ricercaCatasto.lista
            listaFiltriCatasto = [ricercaCatasto.filtro]
        }

        filtri.indirizzo = oggettoDTO?.archivioVie?.denomUff
    }
		 
	@AfterCompose
	void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

		if(this.lettura) {
			componenti.each {
			    it.disabled = true
			}
		}
	}
}
