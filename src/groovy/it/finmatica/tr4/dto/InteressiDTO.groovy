package it.finmatica.tr4.dto;

import it.finmatica.tr4.Interessi;

import java.util.Date;
import java.util.Map;

public class InteressiDTO implements it.finmatica.dto.DTO<Interessi> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aliquota;
    Date dataFine;
    Date dataInizio;
    Short sequenza;
    String tipoInteresse;
    String tipoTributo;


    public Interessi getDomainObject () {
        return Interessi.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('sequenza', this.sequenza)
        }
    }
    public Interessi toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
