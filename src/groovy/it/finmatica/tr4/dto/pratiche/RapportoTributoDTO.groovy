package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DTO
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.pratiche.RapportoTributo

class RapportoTributoDTO implements DTO<RapportoTributo>, Comparable<RapportoTributoDTO> {
    private static final long serialVersionUID = 1L

    Long id
    ContribuenteDTO contribuente
    PraticaTributoDTO pratica
    Integer sequenza
    String tipoRapporto


    RapportoTributo getDomainObject() {
        return RapportoTributo.createCriteria().get {
            eq('pratica.id', this.pratica.id)
            eq('sequenza', this.sequenza)
        }
    }

    RapportoTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    int compareTo(RapportoTributoDTO obj) {
        obj.pratica?.anno <=> pratica?.anno ?: pratica?.id <=> obj.pratica?.id ?: obj.sequenza <=> sequenza
    }

}
