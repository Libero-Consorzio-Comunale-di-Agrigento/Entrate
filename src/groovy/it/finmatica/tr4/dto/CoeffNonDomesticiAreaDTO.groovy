package it.finmatica.tr4.dto;

import it.finmatica.tr4.CoeffNonDomesticiArea;

import java.util.Map;

public class CoeffNonDomesticiAreaDTO implements it.finmatica.dto.DTO<CoeffNonDomesticiArea> {
    private static final long serialVersionUID = 1L;

    Long id;
    String area;
    Short categoria;
    BigDecimal coeffPotenzialeMax;
    BigDecimal coeffPotenzialeMin;
    BigDecimal coeffProduzioneMax;
    BigDecimal coeffProduzioneMin;
    String tipoComune;
    Short tributo;


    public CoeffNonDomesticiArea getDomainObject () {
        return CoeffNonDomesticiArea.createCriteria().get {
            eq('tributo', this.tributo)
            eq('tipoComune', this.tipoComune)
            eq('area', this.area)
            eq('categoria', this.categoria)
        }
    }
    public CoeffNonDomesticiArea toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
