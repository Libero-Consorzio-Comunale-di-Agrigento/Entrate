package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiIci93;

import java.util.Map;

public class OggettiIci93DTO implements it.finmatica.dto.DTO<OggettiIci93> {
    private static final long serialVersionUID = 1L;

    Long id;
    Boolean areaFabbr93;
    Boolean conduzione93;
    Boolean esenzione93;
    Boolean percentuale93;
    Boolean riduzione93;
    Boolean tipoBene93;
    Boolean tipoRendita93;


    public OggettiIci93 getDomainObject () {
        return OggettiIci93.get(this.id)
    }
    public OggettiIci93 toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
