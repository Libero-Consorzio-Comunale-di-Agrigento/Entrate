package it.finmatica.tr4.dto.daticatasto

import java.util.Date;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.daticatasto.CcFabbricato

class CcFabbricatoDTO implements it.finmatica.dto.DTO<CcFabbricato>{

	Long 			id
	Long			version
	String			codiceAmministrativo
	String			sezione
	Integer			idImmobile
	String			tipoImmobile
	Integer			progressivo
	
	String			zona
	String			categoria
	String			classe
	
	BigDecimal		consistenza
	BigDecimal		superficie
	BigDecimal		renditaLire
	BigDecimal		renditaEuro
	
	String			lotto
	String			edificio
	String			scala
	String			interno1
	String			interno2
	String			piano1
	String			piano2
	String			piano3
	String			piano4
	
	Date			dataEfficiaciaInizio
	Date			dataRegAttiInizio
	String 			tipoNotaInizio
	String			numeroNotaInizio
	String			progrNotaInizio
	Short			annoNotaInizio
	
	Date			dataEfficiaciaFine
	Date			dataRegAttiFine
	String 			tipoNotaFine
	String			numeroNotaFine
	String			progrNotaFine
	Short			annoNotaFine
	
	String			partita
	String			annotazione
	
	Integer			idMutazioneIniziale
	Integer			idMutazioneFinale
	
	String		protocolloNotifica
	Date		dataNotifica
	
	So4AmministrazioneDTO 	ente
	Ad4UtenteDTO			utente
	
	Set<CcIdentificativoDTO> 	identificativi
	Set<CcIndirizzoDTO> 		indirizzi
	Set<CcTitolaritaDTO> 		titolarita

	public void addToIdentificativi (CcIdentificativoDTO identificativo) {
		if (this.identificativi == null)
			this.identificativi = new HashSet<CcIdentificativoDTO>()
		this.identificativi.add (identificativo);
		identificativo.id = this
	}

	public void removeFromIdentificativi (CcIdentificativoDTO identificativo) {
		if (this.identificativi == null)
			this.identificativi = new HashSet<CcIdentificativoDTO>()
		this.identificativi.remove (identificativo);
		identificativo.id = null
	}
	
	public void addToIndirizzi (CcIndirizzoDTO indirizzo) {
		if (this.indirizzi == null)
			this.indirizzi = new HashSet<CcIndirizzoDTO>()
		this.indirizzi.add (indirizzo);
		indirizzo.id = this
	}

	public void removeFromIndirizzi (CcIndirizzoDTO indirizzo) {
		if (this.indirizzi == null)
			this.indirizzi = new HashSet<CcIndirizzoDTO>()
		this.indirizzi.remove (indirizzo);
		indirizzo.id = null
	}
	
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
	
	public CcFabbricato getDomainObject () {
		return CcFabbricato.get(this.id)
	}
	
	public CcFabbricato toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
}
