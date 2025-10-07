package it.finmatica.tr4.dto

import it.finmatica.tr4.CoefficientiContabili
import it.finmatica.dto.DtoToEntityUtils

public class CoefficientiContabiliDTO implements it.finmatica.dto.DTO<CoefficientiContabili> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Short annoCoeff;
    BigDecimal coeff;


    public CoefficientiContabili getDomainObject () {
        return CoefficientiContabili.createCriteria().get {
            eq('anno', this.anno)
            eq('annoCoeff', this.annoCoeff)
        }
    }
    public CoefficientiContabili toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
