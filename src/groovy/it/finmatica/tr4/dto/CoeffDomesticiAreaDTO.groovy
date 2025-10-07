package it.finmatica.tr4.dto;

import it.finmatica.tr4.CoeffDomesticiArea;

import java.util.Map;

public class CoeffDomesticiAreaDTO implements it.finmatica.dto.DTO<CoeffDomesticiArea> {
    private static final long serialVersionUID = 1L;

    Long id;
    String area;
    BigDecimal coeffAdattamento;
    BigDecimal coeffAdattamentoSup;
    BigDecimal coeffProduttivitaMax;
    BigDecimal coeffProduttivitaMed;
    BigDecimal coeffProduttivitaMin;
    Byte numeroFamiliari;


    public CoeffDomesticiArea getDomainObject () {
        return CoeffDomesticiArea.createCriteria().get {
            eq('area', this.area)
            eq('numeroFamiliari', this.numeroFamiliari)
        }
    }
    public CoeffDomesticiArea toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
