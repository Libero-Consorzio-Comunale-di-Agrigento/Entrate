package it.finmatica.ad4.dto.dizionari;

import it.finmatica.ad4.dizionari.Ad4Comune;
import it.finmatica.dto.DtoToEntityUtils;
import java.util.Date;

public class Ad4ComuneDTO implements it.finmatica.dto.DTO<Ad4Comune> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer cap;
    int comune;
    Date dataSoppressione;
    String denominazione;
    Ad4ProvinciaDTO provincia;
    String siglaCodiceFiscale;
    Ad4StatoDTO stato;


    public Ad4Comune getDomainObject () {
        return Ad4Comune.get(this.id)
    }
    public Ad4Comune toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
