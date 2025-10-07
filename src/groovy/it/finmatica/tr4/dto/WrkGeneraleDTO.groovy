package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkGenerale

class WrkGeneraleDTO implements DTO<WrkGenerale> {
    private static final long serialVersionUID = 1L

    Long id
    Short anno
    String dati
    BigDecimal progressivo
    String tipoTrattamento


    WrkGenerale getDomainObject() {
        return WrkGenerale.createCriteria().get {
            eq('tipoTrattamento', this.tipoTrattamento)
            eq('anno', this.anno)
            eq('progressivo', this.progressivo)
        }
    }

    WrkGenerale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
