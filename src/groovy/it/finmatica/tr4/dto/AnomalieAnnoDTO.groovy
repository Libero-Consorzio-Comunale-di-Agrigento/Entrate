package it.finmatica.tr4.dto;

import it.finmatica.tr4.AnomalieAnno;

import java.util.Date;
import java.util.Map;

public class AnomalieAnnoDTO implements it.finmatica.dto.DTO<AnomalieAnno> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Date dataElaborazione;
    BigDecimal scarto;
    Byte tipoAnomalia;


    public AnomalieAnno getDomainObject () {
        return AnomalieAnno.createCriteria().get {
            eq('tipoAnomalia', this.tipoAnomalia)
            eq('anno', this.anno)
        }
    }
    public AnomalieAnno toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
