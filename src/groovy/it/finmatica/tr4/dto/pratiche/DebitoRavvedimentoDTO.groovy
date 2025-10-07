package it.finmatica.tr4.dto.pratiche;

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.dto.*

import it.finmatica.tr4.pratiche.DebitoRavvedimento;

import java.util.Date;
import java.util.Map;

class DebitoRavvedimentoDTO implements it.finmatica.dto.DTO<DebitoRavvedimento> {
    private static final long serialVersionUID = 1L
	
    Long ruolo
	
	Date scadenzaPrimaRata
	Date scadenzaRata2
	Date scadenzaRata3
	Date scadenzaRata4
	
	BigDecimal importoPrimaRata
	BigDecimal importoRata2
	BigDecimal importoRata3
	BigDecimal importoRata4
	
	BigDecimal versatoPrimaRata
	BigDecimal versatoRata2
	BigDecimal versatoRata3
	BigDecimal versatoRata4

	BigDecimal maggiorazioneTaresPrimaRata
	BigDecimal maggiorazioneTaresRata2
	BigDecimal maggiorazioneTaresRata3
	BigDecimal maggiorazioneTaresRata4

	String note

	String utente
    Date lastUpdated
	
	PraticaTributoDTO pratica

    public DebitoRavvedimento getDomainObject () {
        return DebitoRavvedimento.createCriteria().get {
            eq('pratica.id', this.pratica.id)
            eq('ruolo', this.ruolo)
        }
    }
    DebitoRavvedimento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
