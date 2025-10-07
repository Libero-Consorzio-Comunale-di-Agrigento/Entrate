package it.finmatica.tr4.dto;

import it.finmatica.tr4.SogeiDic;

import java.util.Map;

public class SogeiDicDTO implements it.finmatica.dto.DTO<SogeiDic> {
    private static final long serialVersionUID = 1L;

    Long id;
    String dati;
    Long numContrib;
    Integer progrContrib;
    String tipoRecord;


    public SogeiDic getDomainObject () {
        return SogeiDic.get(this.id)
    }
    public SogeiDic toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
