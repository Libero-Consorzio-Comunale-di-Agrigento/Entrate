package it.finmatica.tr4.dto;

import it.finmatica.tr4.commons.TipoOccupazione;
import it.finmatica.tr4.Scadenza;
import it.finmatica.tr4.TipoTributo;

import java.util.Date;
import java.util.Map;

public class ScadenzaDTO implements it.finmatica.dto.DTO<Scadenza> {
    private static final long serialVersionUID = 1L;

    Long id;
	
	Short anno
	Short sequenza
	String tipoScadenza
	Short rata
	String tipoVersamento
	Date dataScadenza
	
	TipoTributoDTO tipoTributo
	
	String gruppoTributo
	TipoOccupazione tipoOccupazione

    public Scadenza getDomainObject () {
        return Scadenza.createCriteria().get {
            eq('tipoTributo', this.tipoTributo.getDomainObject())
            eq('anno', this.anno)
            eq('sequenza', this.sequenza)
        }
    }
    public Scadenza toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
