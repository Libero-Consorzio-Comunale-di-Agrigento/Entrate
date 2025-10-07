package it.finmatica.tr4.dto.anomalie;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.anomalie.AnomaliaParametro
import it.finmatica.tr4.dto.TipoTributoDTO

public class AnomaliaParametroDTO implements it.finmatica.dto.DTO<AnomaliaParametro> {
    private static final long serialVersionUID = 1L;

    Long id;
	Long version
    Short anno;
	TipoAnomaliaDTO tipoAnomalia
    Date dateCreated
	Date lastUpdated
    //String flagSistemate
	String flagImposta
	TipoTributoDTO tipoTributo
	String categorie
	BigDecimal scarto
	BigDecimal randitaDa
	BigDecimal randitaA
    So4AmministrazioneDTO ente
	Ad4UtenteDTO	utente
	boolean locked
	Set<AnomaliaDTO> anomalie
	BigDecimal			renditaMedia
	BigDecimal			renditaMassima
	BigDecimal			valoreMedio
	BigDecimal			valoreMassimo
    BigDecimal			renditaDa
    BigDecimal			renditaA
	
    public AnomaliaParametro getDomainObject () {
        return AnomaliaParametro.get(this.id)
    }
	
    public AnomaliaParametro toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
	
	public void addToAnomalie (AnomaliaDTO anomalia) {
		if (this.anomalie == null)
			this.anomalie = new HashSet<AnomaliaDTO>()
		this.anomalie.add (anomalia);
		anomalia.anomaliaParametro = this
	}

	public void removeFromAnomalie (AnomaliaDTO anomalia) {
		if (this.anomalie == null)
			this.anomalie = new HashSet<AnomaliaDTO>()
		this.anomalie.remove (anomalia);
		anomalia.anomaliaParametro = null
	}

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
