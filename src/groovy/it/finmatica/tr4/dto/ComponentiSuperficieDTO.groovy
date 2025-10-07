package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.ComponentiSuperficie

public class ComponentiSuperficieDTO implements DTO<ComponentiSuperficie>, Cloneable {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aConsistenza;
    Short anno;
    BigDecimal daConsistenza;
    Short numeroFamiliari;


    public ComponentiSuperficie getDomainObject() {
        return ComponentiSuperficie.createCriteria().get {
            eq('anno', this.anno)
            eq('numeroFamiliari', this.numeroFamiliari)
        }
    }

    public ComponentiSuperficie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as ComponentiSuperficie
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    @Override
    public ComponentiSuperficieDTO clone(){
        def clone = new ComponentiSuperficieDTO()
        clone.anno = new Short(this.anno)
        clone.numeroFamiliari = new Short(this.numeroFamiliari)
        clone.daConsistenza = this.daConsistenza ? new BigDecimal(this.daConsistenza) : null
        clone.aConsistenza = this.aConsistenza ? new BigDecimal(this.aConsistenza) : null
        return clone
    }
}
