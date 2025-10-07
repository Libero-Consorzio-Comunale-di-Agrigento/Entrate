package it.finmatica.tr4.dto;

import it.finmatica.tr4.TerreniRidotti;

import java.util.Map;

public class TerreniRidottiDTO implements it.finmatica.dto.DTO<TerreniRidotti> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String codFiscale;
    String note;
    BigDecimal valore;


    public TerreniRidotti getDomainObject () {
        return TerreniRidotti.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
        }
    }
    public TerreniRidotti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
