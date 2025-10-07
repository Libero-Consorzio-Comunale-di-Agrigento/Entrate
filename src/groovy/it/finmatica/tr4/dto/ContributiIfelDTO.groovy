package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.ContributiIfel


public class ContributiIfelDTO implements it.finmatica.dto.DTO<ContributiIfel> {
    private static final long serialVersionUID = 1L

    Short anno
    BigDecimal aliquota

    public ContributiIfel getDomainObject () {
        return ContributiIfel.createCriteria().get {
            eq('anno', this?.anno)
        }
    }

    public ContributiIfel toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
