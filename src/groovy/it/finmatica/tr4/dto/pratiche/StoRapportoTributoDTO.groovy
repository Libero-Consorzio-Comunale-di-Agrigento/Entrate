package it.finmatica.tr4.dto.pratiche;

import it.finmatica.tr4.dto.ContribuenteDTO;
import it.finmatica.tr4.pratiche.StoRapportoTributo;

import java.util.Map;

public class StoRapportoTributoDTO implements it.finmatica.dto.DTO<StoRapportoTributo>, Comparable<StoRapportoTributoDTO> {

	private static final long serialVersionUID = 1L;

	Long id;
	ContribuenteDTO contribuente;
	StoPraticaTributoDTO pratica;
	Integer sequenza;
	String tipoRapporto;


	public StoRapportoTributo getDomainObject () {
		return StoRapportoTributo.createCriteria().get {
			eq('pratica.id', this.pratica.id)
			eq('sequenza', this.sequenza)
		}
	}
	public StoRapportoTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	int compareTo(StoRapportoTributoDTO obj) {
		obj.pratica?.anno <=> pratica?.anno?: pratica?.id <=> obj.pratica?.id?: obj.sequenza <=> sequenza
	}
}
