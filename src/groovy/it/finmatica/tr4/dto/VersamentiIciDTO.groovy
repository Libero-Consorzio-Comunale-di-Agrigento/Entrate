package it.finmatica.tr4.dto;

import it.finmatica.tr4.VersamentiIci;

import java.util.Map;

public class VersamentiIciDTO implements it.finmatica.dto.DTO<VersamentiIci> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String codFiscale;
    BigDecimal importoVersato;
    BigDecimal importoVersatoAcconto;


    public VersamentiIci getDomainObject () {
        return VersamentiIci.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('importoVersato', this.importoVersato)
            eq('importoVersatoAcconto', this.importoVersatoAcconto)
        }
    }
    public VersamentiIci toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
