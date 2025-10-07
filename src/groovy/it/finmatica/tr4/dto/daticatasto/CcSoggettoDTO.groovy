package it.finmatica.tr4.dto.daticatasto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.daticatasto.CcSoggetto

class CcSoggettoDTO implements it.finmatica.dto.DTO<CcSoggetto>{

	Long 					id
	Long					version
	String					codiceAmministrativo
	String					sezione
	Integer					identificativoSoggetto
	
	String					tipoSoggetto
	String					cognome
	String					nome
	String					sesso
	String					luogoNascita
	String					codiceFiscale
	String					indicazioniSupplementari
	String					denominazione
	String					sede
	Date					dataNascita
	
	Ad4UtenteDTO			utente
	So4AmministrazioneDTO 	ente
	
	Set<CcTitolaritaDTO> 	titolarita
	
	public void addToTitolarita (CcTitolaritaDTO tit) {
		if (this.titolarita == null)
			this.titolarita = new HashSet<CcTitolaritaDTO>()
		this.titolarita.add (tit);
		tit.id = this
	}

	public void removeFromTitolarita (CcTitolaritaDTO tit) {
		if (this.titolarita == null)
			this.titolarita = new HashSet<CcTitolaritaDTO>()
		this.titolarita.remove (tit);
		tit.id = null
	}
	
	public CcSoggetto getDomainObject () {
		return CcSoggetto.get(this.id)
	}
	
	public CcSoggetto toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	public String getCognNome(CcSoggettoDTO soggetto) {
		return ((soggetto.nome)?:"") + " " + ((soggetto.cognome)?:"")
	}
}
