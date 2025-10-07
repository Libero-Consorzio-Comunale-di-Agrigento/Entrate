package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.UtilizzoOggetto;

import java.util.Date;
import java.util.Map;

public class UtilizzoOggettoDTO implements it.finmatica.dto.DTO<UtilizzoOggetto>, Comparable<UtilizzoOggettoDTO> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    Short anno;
    Date dal;
    Date dataScadenza;
    Date lastUpdated;
    String intestatario;
    Byte mesiAffitto;
    SoggettoDTO soggetto;
    String note;
    OggettoDTO oggetto;
    Integer sequenza;
    TipoTributoDTO tipoTributo;
    TipoUsoDTO tipoUso;
    TipoUtilizzoDTO tipoUtilizzo;
    Ad4UtenteDTO	utente;

    def uuid = UUID.randomUUID().toString().replace('-', '')

    public UtilizzoOggetto getDomainObject () {
        return UtilizzoOggetto.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('tipoTributo.id', this.tipoTributo.tipoTributo)
            eq('anno', this.anno)
            eq('tipoUtilizzo.id', this.tipoUtilizzo?.id)
            eq('sequenza', this.sequenza)
        }
    }
    public UtilizzoOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	int compareTo(UtilizzoOggettoDTO obj) {
		oggetto?.id					<=> obj?.oggetto?.id?:
		tipoTributo?.tipoTributo	<=> obj?.tipoTributo?.tipoTributo?:
		tipoUtilizzo?.id			<=> obj.tipoUtilizzo?.id?:
		anno 						<=> obj?.anno?:
		sequenza					<=> obj?.sequenza
	}

}
