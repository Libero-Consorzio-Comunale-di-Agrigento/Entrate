package it.finmatica.tr4.dto;

import it.finmatica.tr4.CapViario;

import java.util.Map;

public class CapViarioDTO implements it.finmatica.dto.DTO<CapViario> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer aCap;
    Integer cap;
    String capMunicipio;
    Short codComune;
    Short codProvincia;
    Integer daCap;
    String descrizione;
    String note;
    String siglaProvincia;


    public CapViario getDomainObject () {
        return CapViario.createCriteria().get {
            eq('codProvincia', this.codProvincia)
            eq('codComune', this.codComune)
            eq('descrizione', this.descrizione)
            eq('siglaProvincia', this.siglaProvincia)
            eq('cap', this.cap)
            eq('daCap', this.daCap)
            eq('aCap', this.aCap)
            eq('capMunicipio', this.capMunicipio)
            eq('note', this.note)
        }
    }
    public CapViario toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
