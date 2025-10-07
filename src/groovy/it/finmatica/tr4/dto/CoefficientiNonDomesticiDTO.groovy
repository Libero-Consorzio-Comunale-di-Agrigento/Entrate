package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CoefficientiNonDomestici

public class CoefficientiNonDomesticiDTO implements DTO<CoefficientiNonDomestici>, Cloneable {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Short categoria;
    BigDecimal coeffPotenziale;
    BigDecimal coeffProduzione;
    Short tributo;


    public CoefficientiNonDomestici getDomainObject() {
        return CoefficientiNonDomestici.createCriteria().get {
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
            eq('anno', this.anno)
        }
    }

    public CoefficientiNonDomestici toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as CoefficientiNonDomestici
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori
     */
    public CoefficientiNonDomesticiDTO() {}

    public CoefficientiNonDomesticiDTO(def annoTributo, def codiceTributo) {
        this.anno = annoTributo as Short
        this.tributo = codiceTributo as Short
    }


    @Override
    public CoefficientiNonDomesticiDTO clone() {
        def clone = new CoefficientiNonDomesticiDTO()
        clone.anno = this.anno ? new Short(this.anno) : null
        clone.tributo = this.tributo ? new Short(this.tributo) : null
        clone.categoria = this.categoria ? new Short(this.categoria) : null
        clone.coeffPotenziale = this.coeffPotenziale != null ? new BigDecimal(this.coeffPotenziale) : null
        clone.coeffProduzione = this.coeffProduzione != null ? new BigDecimal(this.coeffProduzione) : null
        return clone
    }

}
