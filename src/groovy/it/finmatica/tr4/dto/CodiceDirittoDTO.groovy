package it.finmatica.tr4.dto;

import it.finmatica.tr4.CodiceDiritto;
import it.finmatica.dto.DtoToEntityUtils

import java.util.Map;

public class CodiceDirittoDTO implements it.finmatica.dto.DTO<CodiceDiritto> {
    private static final long serialVersionUID = 1L;

    String codDiritto;
    String descrizione;
    String eccezione;
    String flagTrattaCessazione;
    String flagTrattaIscrizione;
    String note;
    Short ordinamento;


    public CodiceDiritto getDomainObject () {
        return CodiceDiritto.findByCodDiritto(this.codDiritto)
    }
    public CodiceDiritto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
