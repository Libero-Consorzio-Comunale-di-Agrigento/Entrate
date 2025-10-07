package it.finmatica.tr4.dto;

import it.finmatica.tr4.SuccessioniEredi;

import java.util.Date;
import java.util.Map;

public class SuccessioniErediDTO implements it.finmatica.dto.DTO<SuccessioniEredi> {
    private static final long serialVersionUID = 1L;

    Long id;
    String categoria;
    String cittaNas;
    String cittaRes;
    String codFiscale;
    String cognome;
    Date dataNas;
    String denominazione;
    String indirizzo;
    String nome;
    Long pratica;
    Short progrErede;
    Integer progressivo;
    String provNas;
    String provRes;
    String sesso;
    Long successione;


    public SuccessioniEredi getDomainObject () {
        return SuccessioniEredi.createCriteria().get {
            eq('successione', this.successione)
            eq('progressivo', this.progressivo)
        }
    }
    public SuccessioniEredi toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
