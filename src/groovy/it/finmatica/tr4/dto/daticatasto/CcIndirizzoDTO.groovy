package it.finmatica.tr4.dto.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.struttura.So4Amministrazione
import it.finmatica.tr4.daticatasto.CcIndirizzo

class CcIndirizzoDTO implements it.finmatica.dto.DTO<CcIndirizzo>{

	Long 				id
	Long				version
	Short				toponimo
	String				indirizzo
	String				civico1
	String				civico2
	String				civico3
	Short				codiceStrada
	CcFabbricatoDTO		fabbricato
	
	Ad4Utente			utente
	So4Amministrazione 	ente
	
	
	public CcIndirizzo getDomainObject () {
		return CcIndirizzo.get(this.id)
	}
	
	public CcIndirizzo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
	
	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
}
