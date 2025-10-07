package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TariffaNonDomestica

public class TariffaNonDomesticaDTO implements DTO<TariffaNonDomestica>, Cloneable {
    private static final long serialVersionUID = 1L;

    Short anno
    Short tributo
    Short categoria
    BigDecimal tariffaQuotaFissa
    BigDecimal tariffaQuotaVariabile
    BigDecimal importoMinimi

    public TariffaNonDomestica getDomainObject() {
        return TariffaNonDomestica.createCriteria().get {
            eq('anno', this.anno)
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
        }
    }

    public TariffaNonDomestica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as TariffaNonDomestica
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori
     */

    public TariffaNonDomesticaDTO() {}

    public TariffaNonDomesticaDTO(def annoTributo, def codiceTributo) {
        this.anno = annoTributo as Short
        this.tributo = codiceTributo as Short
    }

    @Override
    public TariffaNonDomesticaDTO clone() {
        def clone = new TariffaNonDomesticaDTO()
        clone.anno = this.anno ? new Short(this.anno) : null
        clone.tributo = this.tributo ? new Short(this.tributo) : null
        clone.categoria = this.categoria ? new Short(this.categoria) : null
        clone.tariffaQuotaFissa = this.tariffaQuotaFissa != null ? new BigDecimal(this.tariffaQuotaFissa) : null
        clone.tariffaQuotaVariabile = this.tariffaQuotaVariabile != null ? new BigDecimal(this.tariffaQuotaVariabile) : null
        clone.importoMinimi = this.importoMinimi != null ? new BigDecimal(this.importoMinimi) : null
        return clone
    }
}
