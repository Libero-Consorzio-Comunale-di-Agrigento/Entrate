package it.finmatica.tr4.dto.anomalie;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.dto.OggettoDTO

public class AnomaliaDTO implements it.finmatica.dto.DTO<Anomalia> {
    private static final long serialVersionUID = 1L;

    Long id;
	Long version
   // Short anno;
    String codFiscale;
    Date dateCreated
	Date lastUpdated
    String flagOk;
    OggettoDTO oggetto;
   // TipoAnomaliaDTO tipoAnomalia
	So4AmministrazioneDTO ente
	Ad4UtenteDTO	utente
	BigDecimal			renditaMedia
	BigDecimal			renditaMassima
	BigDecimal			valoreMedio
	BigDecimal			valoreMassimo
	AnomaliaParametroDTO anomaliaParametro
	
	SortedSet<AnomaliaPraticaDTO> anomaliePratiche
	
    public Anomalia getDomainObject () {
        return Anomalia.get(this.id)
    }
	
    public Anomalia toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
	
	public void addToAnomaliePratiche (AnomaliaPraticaDTO anomaliaPratica) {
		if (this.anomaliePratiche == null)
			this.anomaliePratiche = new TreeSet<AnomaliaPraticaDTO>()
		this.anomaliePratiche.add (anomaliaPratica);
		anomaliaPratica.anomalia = this
	}

	public void removeFromAnomaliePratiche (AnomaliaPraticaDTO anomaliaPratica) {
		if (this.anomaliePratiche == null)
			this.anomaliePratiche = new TreeSet<AnomaliaPraticaDTO>()
		this.anomaliePratiche.remove (anomaliaPratica);
		anomaliaPratica.anomalia = null
	}

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
