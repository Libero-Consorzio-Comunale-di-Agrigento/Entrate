package it.finmatica.tr4.dto.daticatasto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.daticatasto.CcTitolarita

class CcTitolaritaDTO implements it.finmatica.dto.DTO<CcTitolarita>{

	Long 					id
	Long					version
	String					codiceAmministrativo
	String					sezione
	
	CcParticellaDTO			particella
	CcFabbricatoDTO			fabbricato
	CcSoggettoDTO			soggetto
	
	CcCodiceDirittoDTO		codiceDiritto
	String					titoloNonCodificato
	
	Long					quotaNumeratore
	Long					quotaDenominatore
	
	String					regime
	Integer					idSoggettoRiferimento
	
	Date					dataValiditaDal
	Date					dataRegAttiDal
	String 					tipoNotaDal
	String					numeroNotaDal
	String					progrNotaDal
	Short					annoNotaDal
	
	String					partita
	
	Date					dataValiditaAl
	Date					dataRegAttiAl
	String 					tipoNotaAl
	String					numeroNotaAl
	String					progrNotaAl
	Short					annoNotaAl
	
	Integer					idMutazioneIniziale
	Integer					idMutazioneFinale
	Integer					identificativoTitolarita
	
	String					codiceCausaleAttoGen
	String					descrizioneAttoGen
	
	String					codiceCausaleAttoCon
	String					descrizioneAttoCon
	
	Ad4UtenteDTO			utente
	So4AmministrazioneDTO 	ente
	
	public CcTitolarita getDomainObject () {
		return CcTitolarita.get(this.id)
	}
	
	public CcTitolarita toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
}
