package it.finmatica.tr4.dto;

import it.finmatica.tr4.commons.TipoOccupazione;
import it.finmatica.tr4.LimiteCalcolo;
import it.finmatica.tr4.TipoTributo;

import java.math.BigDecimal;
import java.util.Date;
import java.util.Map;

public class LimiteCalcoloDTO implements it.finmatica.dto.DTO<LimiteCalcolo> {
    private static final long serialVersionUID = 1;

    Long id;
	
	Short anno
	Short sequenza
	
	BigDecimal limiteImposta
	BigDecimal limiteViolazione
	BigDecimal limiteRata
	
	TipoTributoDTO tipoTributo
	String gruppoTributo
	TipoOccupazione tipoOccupazione

    public LimiteCalcolo getDomainObject () {
        return LimiteCalcolo.createCriteria().get {
            eq('tipoTributo', this.tipoTributo.getDomainObject())
            eq('anno', this.anno)
            eq('sequenza', this.sequenza)
        }
    }
    public LimiteCalcolo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
