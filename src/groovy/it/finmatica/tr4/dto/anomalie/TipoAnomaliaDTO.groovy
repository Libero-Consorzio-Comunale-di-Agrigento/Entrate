package it.finmatica.tr4.dto.anomalie

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.commons.TipoIntervento

class TipoAnomaliaDTO implements DTO<TipoAnomalia> {
	private static final long serialVersionUID = 1L

	String descrizione
	short tipoAnomalia
	String tipoBonifica
	String dettagliIndipendenti
	TipoIntervento tipoIntervento
	String nomeMetodo
	String zul

	TipoAnomalia getDomainObject() {
		return TipoAnomalia.findByTipoAnomalia(this.tipoAnomalia)
	}

	TipoAnomalia toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
