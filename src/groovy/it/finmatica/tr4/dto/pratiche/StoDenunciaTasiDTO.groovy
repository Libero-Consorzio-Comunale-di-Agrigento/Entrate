package it.finmatica.tr4.dto.pratiche;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.dto.FonteDTO;
import it.finmatica.tr4.pratiche.StoDenunciaTasi;

import java.util.Date;
import java.util.Map;

public class StoDenunciaTasiDTO implements it.finmatica.dto.DTO<StoDenunciaTasi> {

	private static final long serialVersionUID = 1L;

	Long					id;
	Date 					lastUpdated;
	long 					denuncia;
	boolean 				flagCf;
	boolean 				flagDenunciante;
	boolean 				flagFirma;
	FonteDTO				fonte;
	String 					note;
	Integer 				numTelefonico;
	StoPraticaTributoDTO 	pratica;
	String 					prefissoTelefonico;
	Integer					progrAnci;
	Ad4UtenteDTO			utente;


	public StoDenunciaTasi getDomainObject () {
		return StoDenunciaTasi.get(this.id)
	}
	public StoDenunciaTasi toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
