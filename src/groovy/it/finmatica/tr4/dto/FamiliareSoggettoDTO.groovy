package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.FamiliareSoggetto

class FamiliareSoggettoDTO implements DTO<FamiliareSoggetto> {

    private static final long serialVersionUID = 1L

    Long id
    Date al
    Short anno
    Date dal
    Date lastUpdated
    String note
    Short numeroFamiliari
    SoggettoDTO soggetto

    def uuid = UUID.randomUUID().toString().replace('-', '')

    FamiliareSoggetto getDomainObject() {
        return FamiliareSoggetto.createCriteria().get {
            eq('soggetto.id', this.soggetto.id)
            eq('anno', this.anno)
            eq('dal', this.dal)
        }
    }

    FamiliareSoggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
