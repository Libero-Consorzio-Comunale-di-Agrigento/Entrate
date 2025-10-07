package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WebCalcoloDettaglio
import it.finmatica.tr4.sportello.TipoOggettoCalcolo



class WebCalcoloDettaglioDTO implements it.finmatica.dto.DTO<WebCalcoloDettaglio> {
	private static final long serialVersionUID = 1L;
	
	Long id
	Long version
	Date lastUpdated
	Date dateCreated
	Ad4UtenteDTO utente
	WebCalcoloIndividualeDTO calcoloIndividuale
	int ordinamento
	Integer numFabbricati
	TipoOggettoCalcolo	tipoOggetto
	BigDecimal	versAcconto
	BigDecimal	versAccontoErar
	BigDecimal	acconto
	BigDecimal	accontoErar
	BigDecimal	saldo
	BigDecimal	saldoErar

	public WebCalcoloDettaglio getDomainObject () {
        return WebCalcoloDettaglio.get(this.id)
    }
    public WebCalcoloDettaglio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
