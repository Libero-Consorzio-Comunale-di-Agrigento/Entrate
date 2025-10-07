package it.finmatica.so4.dto.strutturaPubblicazione;

import it.finmatica.as4.dto.As4SoggettoCorrenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4OtticaDTO
import it.finmatica.so4.strutturaPubblicazione.So4ComponentePubb

public class So4ComponentePubbDTO implements it.finmatica.dto.DTO<So4ComponentePubb> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    Integer ciSoggettoGp4;
    Date dal;
    String nominativoSoggetto;
    So4OtticaDTO ottica;
    Long progrUnita;
    As4SoggettoCorrenteDTO soggetto;
    String stato;


    public So4ComponentePubb getDomainObject () {
        return So4ComponentePubb.get(this.id)
    }
    public So4ComponentePubb toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
