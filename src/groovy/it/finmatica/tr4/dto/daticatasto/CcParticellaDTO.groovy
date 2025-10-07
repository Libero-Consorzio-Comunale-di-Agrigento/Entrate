package it.finmatica.tr4.dto.daticatasto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.daticatasto.CcParticella

class CcParticellaDTO implements it.finmatica.dto.DTO<CcParticella>{

	Long		 			id
	Long					version
	String					codiceAmministrativo
	String					sezione
	Integer					idImmobile
	String					tipoImmobile
	Integer					progressivo
		
	Integer					foglio
	String					numero
	Short					denominatore
	String					subalterno
	String					edificialita
	
	CodiceQualitaDTO		codiceQualita
	String					classe
	Integer					ettari
	Short					are
	Short					centiare
	
	Boolean					flagReddito
	Boolean					flagPorzione
	Boolean					flagDeduzioni
	
	BigDecimal				redditoDominicaleLire
	BigDecimal				redditoAgrarioLire
	BigDecimal				redditoDominicaleEuro
	BigDecimal				redditoAgrarioEuro
	
	Date					dataEfficiaciaInizio
	Date					dataRegAttiInizio
	String 					tipoNotaInizio
	String					numeroNotaInizio
	String					progrNotaInizio
	Short					annoNotaInizio
	
	Date					dataEfficiaciaFine
	Date					dataRegAttiFine
	String 					tipoNotaFine
	String					numeroNotaFine
	String					progrNotaFine
	Short					annoNotaFine
	
	String					partita
	String					annotazione
	
	Integer					idMutazioneIniziale
	Integer					idMutazioneFinale
	
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
	
	public CcParticella getDomainObject () {
		return CcParticella.get(this.id)
	}
	
	public CcParticella toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	
}
