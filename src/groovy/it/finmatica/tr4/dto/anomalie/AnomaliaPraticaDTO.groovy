package it.finmatica.tr4.dto.anomalie

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.anomalie.AnomaliaPratica
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO

class AnomaliaPraticaDTO implements DTO<AnomaliaPratica>, Comparable<AnomaliaPraticaDTO> {
	Long id
	Long version
	OggettoContribuenteDTO oggettoContribuente
	String	flagOk
	Date 	dateCreated
	Date 	lastUpdated
	AnomaliaPraticaDTO	anomaliaPraticaRif
	AnomaliaDTO anomalia
	BigDecimal			rendita
	BigDecimal			valore
	Ad4UtenteDTO	utente
	
	boolean principale
	
	public AnomaliaPratica getDomainObject() {
		return AnomaliaPratica.get(this.id)
	}
	
	public AnomaliaPratica toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
	
	int compareTo(AnomaliaPraticaDTO obj) {
		if (id) {
			obj?.oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita <=> oggettoContribuente.oggettoPratica.oggettoPraticaRendita.rendita?:
			oggettoContribuente.contribuente.codFiscale <=> obj.oggettoContribuente.contribuente.codFiscale?:
			anomaliaPraticaRif <=> obj.anomaliaPraticaRif?:
			oggettoContribuente.oggettoPratica.id <=> obj.oggettoContribuente.oggettoPratica.id?:
			id <=> obj.id
		} else {
			1
		}
	}
	
	public boolean isPrincipale() {
		AnomaliaPratica.countByAnomaliaPraticaRif(this.getDomainObject())
	}

}
