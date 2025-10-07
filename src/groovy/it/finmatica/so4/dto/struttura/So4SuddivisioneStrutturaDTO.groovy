package it.finmatica.so4.dto.struttura;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.struttura.So4SuddivisioneStruttura

public class So4SuddivisioneStrutturaDTO implements it.finmatica.dto.DTO<So4SuddivisioneStruttura> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abbreviazione;
    String codice;
    String descrizione;
    Integer ordinamento;
    So4OtticaDTO ottica;


    public So4SuddivisioneStruttura getDomainObject () {
        return So4SuddivisioneStruttura.get(this.id)
    }
    public So4SuddivisioneStruttura toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
