package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaPartitaIva

class SamRispostaPartitaIvaDTO implements DTO<SamRispostaPartitaIva> {
	private static final long serialVersionUID = 1L

	Long id

	String partitaIva
	String codAttivita
	String tipologiaCodifica
	String stato
	Date dataCessazione
	String partitaIvaConfluenza
	
	SamRispostaDTO risposta
	
	SamCodiceRitornoDTO codiceRitorno
	SamTipoCessazioneDTO tipoCessazione
	
	SamRispostaPartitaIva getDomainObject() {
		return SamRispostaPartitaIva.get(this.id)
	}

	SamRispostaPartitaIva toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
