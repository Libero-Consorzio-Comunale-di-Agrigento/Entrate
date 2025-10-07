package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.ModelliDettaglio;

import java.util.Map;

public class ModelliDettaglioDTO implements it.finmatica.dto.DTO<ModelliDettaglio> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short modello;
    BigDecimal parametroId;
    String testo;


    public ModelliDettaglio getDomainObject () {
        return ModelliDettaglio.createCriteria().get {
            eq('modello', this.modello)
            eq('parametroId', this.parametroId)
        }
    }
    public ModelliDettaglio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
