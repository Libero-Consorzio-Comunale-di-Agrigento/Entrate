package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.NotificaOggetto
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

public class NotificaOggettoDTO implements it.finmatica.dto.DTO<NotificaOggetto>, Comparable<NotificaOggettoDTO> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short annoNotifica;
    ContribuenteDTO contribuente
    Date lastUpdated;
    String note;
    OggettoDTO oggetto;
    PraticaTributoDTO pratica;


    public NotificaOggetto getDomainObject () {
        return NotificaOggetto.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
        }
    }
    public NotificaOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	int compareTo(NotificaOggettoDTO obj) {
		oggetto?.id				 <=> obj?.oggetto?.id?:
		contribuente?.codFiscale <=> obj?.contribuente.codFiscale?:
		annoNotifica			 <=> obj.annoNotifica
	}

}
