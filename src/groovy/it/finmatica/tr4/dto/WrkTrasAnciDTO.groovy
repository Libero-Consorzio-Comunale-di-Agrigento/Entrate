package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkTrasAnci;

import java.util.Map;

public class WrkTrasAnciDTO implements it.finmatica.dto.DTO<WrkTrasAnci> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal anno;
    String dati;
    BigDecimal progressivo;


    public WrkTrasAnci getDomainObject () {
        return WrkTrasAnci.createCriteria().get {
            eq('anno', this.anno)
            eq('progressivo', this.progressivo)
        }
    }
    public WrkTrasAnci toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
