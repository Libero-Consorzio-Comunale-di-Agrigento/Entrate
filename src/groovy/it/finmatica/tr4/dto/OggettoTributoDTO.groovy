package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.OggettoTributo

public class OggettoTributoDTO implements DTO<OggettoTributo> {
	private static final long serialVersionUID = 1L;

	TipoOggettoDTO tipoOggetto;
	TipoTributoDTO tipoTributo;


	public OggettoTributo getDomainObject() {
		return OggettoTributo.createCriteria().get {
			eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
			eq('tipoOggetto.tipoOggetto', this.tipoOggetto.tipoOggetto)
		}
	}

	public OggettoTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


	/**
	 * Necessario per le reflection dei frameworks
	 * rimuovibile se vengono rimossi anche tutti gli altri costruttori
	 */
	public OggettoTributoDTO(){
	}

	public OggettoTributoDTO(TipoOggettoDTO tiog, TipoTributoDTO titr ){
		this.tipoOggetto = tiog
		this.tipoTributo = titr
	}


}
