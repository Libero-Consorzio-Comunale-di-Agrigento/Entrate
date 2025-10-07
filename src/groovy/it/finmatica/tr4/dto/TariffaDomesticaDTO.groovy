package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TariffaDomestica

public class TariffaDomesticaDTO implements it.finmatica.dto.DTO<TariffaDomestica> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    BigDecimal tariffaQuotaFissa;
    BigDecimal tariffaQuotaVariabile;
    BigDecimal tariffaQuotaFissaNoAp;
    BigDecimal tariffaQuotaVariabileNoAp;
    Byte numeroFamiliari;
	Short svuotamentiMinimi

    public TariffaDomestica getDomainObject() {
        return TariffaDomestica.createCriteria().get {
            eq('anno', this.anno)
            eq('numeroFamiliari', this.numeroFamiliari)
        }
    }

    public TariffaDomestica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
