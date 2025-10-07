package it.finmatica.tr4.dto;

import it.finmatica.tr4.ImpreseArtiProfessioni;

import java.util.Map;

public class ImpreseArtiProfessioniDTO implements it.finmatica.dto.DTO<ImpreseArtiProfessioni> {
    private static final long serialVersionUID = 1L;

    Long id;
    String descrizione;
    Long pratica;
    Short sequenza;
    Byte settore;


    public ImpreseArtiProfessioni getDomainObject () {
        return ImpreseArtiProfessioni.createCriteria().get {
            eq('pratica', this.pratica)
            eq('sequenza', this.sequenza)
        }
    }
    public ImpreseArtiProfessioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
