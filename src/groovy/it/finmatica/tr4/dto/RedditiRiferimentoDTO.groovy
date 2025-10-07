package it.finmatica.tr4.dto;

import it.finmatica.tr4.RedditiRiferimento;

import java.util.Map;

public class RedditiRiferimentoDTO implements it.finmatica.dto.DTO<RedditiRiferimento> {
    private static final long serialVersionUID = 1L;

    Long id;
    Long pratica;
    BigDecimal reddito;
    Short sequenza;
    String tipo;


    public RedditiRiferimento getDomainObject () {
        return RedditiRiferimento.createCriteria().get {
            eq('pratica', this.pratica)
            eq('sequenza', this.sequenza)
        }
    }
    public RedditiRiferimento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
