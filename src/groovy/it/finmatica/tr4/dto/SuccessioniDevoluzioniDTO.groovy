package it.finmatica.tr4.dto;

import it.finmatica.tr4.SuccessioniDevoluzioni;

import java.util.Map;

public class SuccessioniDevoluzioniDTO implements it.finmatica.dto.DTO<SuccessioniDevoluzioni> {
    private static final long serialVersionUID = 1L;

    Long id;
    Boolean agevolazionePrimaCasa;
    Integer denominatoreQuota;
    Integer numeratoreQuota;
    Short progrErede;
    Short progrImmobile;
    Integer progressivo;
    Long successione;


    public SuccessioniDevoluzioni getDomainObject () {
        return SuccessioniDevoluzioni.createCriteria().get {
            eq('successione', this.successione)
            eq('progressivo', this.progressivo)
        }
    }
    public SuccessioniDevoluzioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
