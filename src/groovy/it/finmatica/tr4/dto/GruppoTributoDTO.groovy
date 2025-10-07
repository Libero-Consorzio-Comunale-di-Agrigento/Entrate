package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.dto.TipoTributoDTO

public class GruppoTributoDTO implements it.finmatica.dto.DTO<GruppoTributo> {

	private static final long serialVersionUID = 1L;

	String gruppoTributo
	String descrizione

	TipoTributoDTO tipoTributo;

	public GruppoTributo getDomainObject () {
		return GruppoTributo.createCriteria().get {
			eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
			eq('gruppoTributo', this.gruppoTributo)
		}
	}

	public GruppoTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
