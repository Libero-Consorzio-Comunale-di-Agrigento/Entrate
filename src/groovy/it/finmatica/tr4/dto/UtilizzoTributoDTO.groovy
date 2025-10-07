package it.finmatica.tr4.dto;

import it.finmatica.tr4.UtilizzoTributo;

import java.util.Map;

public class UtilizzoTributoDTO implements it.finmatica.dto.DTO<UtilizzoTributo> {
    private static final long serialVersionUID = 1L;

    TipoTributoDTO tipoTributo;
    TipoUtilizzoDTO tipoUtilizzo;


    public UtilizzoTributo getDomainObject () {
        return UtilizzoTributo.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('tipoUtilizzo', this.tipoUtilizzo)
        }
    }
    public UtilizzoTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
