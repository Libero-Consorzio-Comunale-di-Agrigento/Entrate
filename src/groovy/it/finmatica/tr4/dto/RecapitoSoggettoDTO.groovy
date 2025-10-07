package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RecapitoSoggetto

public class RecapitoSoggettoDTO implements it.finmatica.dto.DTO<RecapitoSoggetto> {
    private static final long serialVersionUID = 1L;
	
	Long id
	TipoTributoDTO tipoTributo
	TipoRecapitoDTO tipoRecapito
	String descrizione
	ArchivioVieDTO archivioVie
	Integer numCiv
	String suffisso
	String scala
	String piano
	Short interno
	Date dal
	Date al
	Ad4UtenteDTO utente
	Date lastUpdated
	String note
	Ad4ComuneTr4DTO	comuneRecapito
	Integer cap
	String zipcode
	String presso
	SoggettoDTO soggetto

	def uuid = UUID.randomUUID().toString().replace('-', '')
	
    public RecapitoSoggetto getDomainObject () {
        return RecapitoSoggetto.get(this.id)
    }
    public RecapitoSoggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	public String getIndirizzo() {
		String indirizzo = (archivioVie && archivioVie.denomUff? archivioVie.denomUff : descrizione?: "") + (numCiv ? ", $numCiv" : "") + (suffisso ? "/$suffisso" : "")
		return indirizzo
	}
}
