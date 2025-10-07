package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.WebCalcoloDettaglio
import it.finmatica.tr4.WebCalcoloIndividuale
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO;



class WebCalcoloIndividualeDTO implements it.finmatica.dto.DTO<WebCalcoloIndividuale> {
	private static final long serialVersionUID = 1L;
	
	Long id
	Long version
	ContribuenteDTO contribuente
	Date lastUpdated
	Date dateCreated
	Ad4UtenteDTO utente
	So4AmministrazioneDTO ente
	short anno
	TipoTributoDTO tipoTributo
	PraticaTributoDTO pratica
	String tipoCalcolo
	BigDecimal numeroFabbricati
	BigDecimal totaleTerreniRidotti
	BigDecimal saldoDetrazioneStd
	Set<WebCalcoloDettaglio> webCalcoloDettagli;

	public WebCalcoloIndividuale getDomainObject () {
        return WebCalcoloIndividuale.get(this.id)
    }
    public WebCalcoloIndividuale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
