package it.finmatica.tr4.dto;

import it.finmatica.tr4.CostiTarsu;

import java.util.Map;

public class CostiTarsuDTO implements it.finmatica.dto.DTO<CostiTarsu> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    BigDecimal costoFisso;
    BigDecimal costoVariabile;
    String raggruppamento;
    Short sequenza;
    String tipoCosto;


    public CostiTarsu getDomainObject () {
        return CostiTarsu.createCriteria().get {
            eq('anno', this.anno)
            eq('sequenza', this.sequenza)
            eq('tipoCosto', this.tipoCosto)
        }
    }
    public CostiTarsu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
