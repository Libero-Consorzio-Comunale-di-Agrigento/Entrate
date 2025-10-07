package it.finmatica.tr4.dto;

import it.finmatica.tr4.CoefficientiDomestici;
import it.finmatica.dto.DtoToEntityUtils;

import java.util.Map;

public class CoefficientiDomesticiDTO implements it.finmatica.dto.DTO<CoefficientiDomestici> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    BigDecimal coeffAdattamento;
    BigDecimal coeffAdattamentoNoAp;
    BigDecimal coeffProduttivita;
    BigDecimal coeffProduttivitaNoAp;
    Byte numeroFamiliari;


    public CoefficientiDomestici getDomainObject () {
        return CoefficientiDomestici.createCriteria().get {
            eq('anno', this.anno)
            eq('numeroFamiliari', this.numeroFamiliari)
        }
    }
    public CoefficientiDomestici toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
