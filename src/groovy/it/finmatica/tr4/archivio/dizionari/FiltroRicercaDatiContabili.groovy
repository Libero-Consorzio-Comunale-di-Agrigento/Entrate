package it.finmatica.tr4.archivio.dizionari

import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.TipoStatoDTO
import it.finmatica.tr4.dto.TipoTributoDTO

class FiltroRicercaDatiContabili {

	TipoTributoDTO tipoTributo
	Short anno
	String tipoImposta = ""
	String tipoPratica = ""
	Date emissioneDal
	Date emissioneAl
	Date ripartizioneDal
	Date ripartizioneAl
	CodiceTributoDTO tributo
	String codTributoF24 = ""
	String descrizioneTitr = ""
	TipoStatoDTO statoPratica
	Short annoAcc
	Integer numeroAcc
	def cfAaccTributo
	def codiceTipoTributo
	TipoOccupazione tipoOccupazione
	String codEnteComunale = ''

	boolean isDirty() {
		
		return  (this.tipoTributo != null) ||
				(this.anno != null) ||
				(this.tipoImposta != "") ||
				(this.tipoPratica != "") ||
				(this.emissioneDal != null) ||
				(this.emissioneAl != null) ||
				(this.ripartizioneDal != null) ||
				(this.ripartizioneAl != null) ||
				(this.tributo != null) ||
				(this.codTributoF24 != "") ||
				(this.descrizioneTitr != "") ||
				(this.tipoOccupazione != null) ||
				(this.statoPratica != null) ||
				(this.annoAcc != null) ||
				(this.numeroAcc != null) ||
				(this.codEnteComunale != '')
	}
	
	String getFiltroTipoTributo() {

		String filtro = null

		if(tipoTributo) {
			filtro = tipoTributo.tipoTributo
		}

		return filtro
	}
}
