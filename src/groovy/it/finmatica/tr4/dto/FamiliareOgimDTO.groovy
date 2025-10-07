package it.finmatica.tr4.dto;

import it.finmatica.tr4.FamiliareOgim;

import java.util.Date;
import java.util.Map;

public class FamiliareOgimDTO implements it.finmatica.dto.DTO<FamiliareOgim> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    Date dal;
    Date lastUpdated;
    String dettaglioFaog;
    String dettaglioFaogBase;
    String note;
    Short numeroFamiliari;
	OggettoImpostaDTO oggettoImposta

    public FamiliareOgim getDomainObject () {
        return FamiliareOgim.createCriteria().get {
            eq('oggettoImposta', this.oggettoImposta)
            eq('dal', this.dal)
        }
    }
    public FamiliareOgim toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
