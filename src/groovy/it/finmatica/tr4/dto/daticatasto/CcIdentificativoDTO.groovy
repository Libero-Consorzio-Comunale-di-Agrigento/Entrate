package it.finmatica.tr4.dto.daticatasto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.daticatasto.CcIdentificativo

class CcIdentificativoDTO implements it.finmatica.dto.DTO<CcIdentificativo>{

	Long					id
	Long					version
	String					sezioneUrbana
	String					foglio
	String					numero
	Short					denominatore
	String					subalterno
	String					edificialita
	CcFabbricatoDTO			fabbricato
	
	Ad4UtenteDTO			utente
	So4AmministrazioneDTO 	ente
	
	
	public CcIdentificativo getDomainObject () {
		return CcIdentificativo.get(this.id)
	}
	
	public CcIdentificativo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
	
	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
}
