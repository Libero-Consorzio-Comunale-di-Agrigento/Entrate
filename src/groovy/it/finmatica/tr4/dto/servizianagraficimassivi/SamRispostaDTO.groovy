package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamRisposta

class SamRispostaDTO implements DTO<SamRisposta> {
	private static final long serialVersionUID = 1L

	Long id

	String tipoRecord
	String codFiscale
	String cognome
	String nome
	String denominazione
	String sesso
	Date dataNascita
	String comuneNascita
	String provinciaNascita
	String comuneDomicilio
	String provinciaDomicilio
	String capDomicilio
	String indirizzoDomicilio
	Date dataDomicilio
	Date dataDecesso
	String presenzaEstinzione
	Date dataEstinzione
	String partitaIva
	String statoPartitaIva
	String codAttivita
	String tipologiaCodifica
	Date dataInizioAttivita
	Date dataFineAttivita
	String comuneSedeLegale
	String provinciaSedeLegale
	String capSedeLegale
	String indirizzoSedeLegale
	Date dataSedeLegale
	String codFiscaleRap
	Date dataDecorrenzaRap
	Long documentoId
	
	SamInterrogazioneDTO interrogazione
	
	SamCodiceRitornoDTO codiceRitorno
	SamFonteDomSedeDTO fonteDomicilio
	SamFonteDecessoDTO fonteDecesso
	SamFonteDomSedeDTO fonteSedeLegale
	SamCodiceCaricaDTO codiceCarica

    Ad4UtenteDTO utente;
    Date lastUpdated
	
	SamRisposta getDomainObject() {
		return SamRisposta.get(this.id)
	}

	SamRisposta toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
