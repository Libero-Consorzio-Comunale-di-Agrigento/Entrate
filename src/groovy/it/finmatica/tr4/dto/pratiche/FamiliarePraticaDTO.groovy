package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.pratiche.FamiliarePratica

class FamiliarePraticaDTO implements it.finmatica.dto.DTO<FamiliarePratica> {
    private static final long serialVersionUID = 1L

    def uuid = UUID.randomUUID().toString().replace('-', '')

    Long id
    PraticaTributoDTO pratica
    String rapportoPar
    SoggettoDTO soggetto

    FamiliarePratica getDomainObject() {
        return FamiliarePratica.createCriteria().get {
            eq('pratica.id', this.pratica.id)
            eq('soggetto.id', this.soggetto.id)
        }
    }

    FamiliarePratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
