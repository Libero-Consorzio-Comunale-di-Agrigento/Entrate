package it.finmatica.tr4.dto;

import it.finmatica.tr4.ExportPersonalizzati;

import java.util.Map;

public class ExportPersonalizzatiDTO implements it.finmatica.dto.DTO<ExportPersonalizzati> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codiceIstat;
    String descrizione;
    Integer tipoExport;


    public ExportPersonalizzati getDomainObject () {
        return ExportPersonalizzati.createCriteria().get {
            eq('tipoExport', this.tipoExport)
            eq('codiceIstat', this.codiceIstat)
        }
    }
    public ExportPersonalizzati toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
