package it.finmatica.tr4.dto;

import it.finmatica.tr4.SpeseIstruttoria;

import java.util.Map;

public class SpeseIstruttoriaDTO implements it.finmatica.dto.DTO<SpeseIstruttoria> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aImporto;
    Short anno;
    BigDecimal daImporto;
    BigDecimal percInsolvenza;
    BigDecimal spese;
    String tipoTributo;


    public SpeseIstruttoria getDomainObject () {
        return SpeseIstruttoria.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('anno', this.anno)
            eq('daImporto', this.daImporto)
        }
    }
    public SpeseIstruttoria toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
