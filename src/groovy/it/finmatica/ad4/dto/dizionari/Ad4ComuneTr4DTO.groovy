package it.finmatica.ad4.dto.dizionari


import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils

class Ad4ComuneTr4DTO implements DTO<Ad4ComuneTr4> {
    private static final long serialVersionUID = 1L
    Integer comune
    Long provinciaStato
    Ad4ComuneDTO ad4Comune


    Ad4ComuneTr4 getDomainObject() {
        return Ad4ComuneTr4.createCriteria().get {
            eq('comune', this.comune)
            eq('provinciaStato', this.provinciaStato)
        }
    }

    Ad4ComuneTr4 toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
