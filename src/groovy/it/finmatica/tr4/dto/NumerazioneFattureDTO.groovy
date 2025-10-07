package it.finmatica.tr4.dto;

import it.finmatica.tr4.NumerazioneFatture;

import java.util.Date;
import java.util.Map;

public class NumerazioneFattureDTO implements it.finmatica.dto.DTO<NumerazioneFatture> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Date dataEmissione;
    Integer numero;


    public NumerazioneFatture getDomainObject () {
        return NumerazioneFatture.createCriteria().get {
            eq('anno', this.anno)
            eq('numero', this.numero)
        }
    }
    public NumerazioneFatture toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
