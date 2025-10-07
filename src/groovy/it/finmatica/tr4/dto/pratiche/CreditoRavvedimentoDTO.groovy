package it.finmatica.tr4.dto.pratiche;

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.CreditoRavvedimento;

import java.math.BigDecimal;
import java.util.Date;
import java.util.Map;

class CreditoRavvedimentoDTO implements it.finmatica.dto.DTO<CreditoRavvedimento> {
    private static final long serialVersionUID = 1L

	Short sequenza
	
	String descrizione
	Short anno
	Short rata
	Long ruolo
	Date dataPagamento
	BigDecimal importoVersato
	BigDecimal sanzioni
	BigDecimal interessi
	BigDecimal altro
	String codIUV
    String note

    String utente
    Date lastUpdated
	
	PraticaTributoDTO pratica

    public CreditoRavvedimento getDomainObject () {
        return CreditoRavvedimento.createCriteria().get {
            eq('pratica.id', this.pratica.id)
            eq('sequenza', this.sequenza)
        }
    }
    CreditoRavvedimento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
