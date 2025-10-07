package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.GruppiSanzione

public class GruppiSanzioneDTO implements it.finmatica.dto.DTO<GruppiSanzione> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Short gruppoSanzione;
    String stampaTotale;


    public GruppiSanzione getDomainObject () {
        return GruppiSanzione.findByGruppoSanzione(this.gruppoSanzione)
    }
    public GruppiSanzione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
