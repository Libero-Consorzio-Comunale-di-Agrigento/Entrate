package it.finmatica.so4.dto.strutturaPubblicazione;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.strutturaPubblicazione.So4AttrComponentePubb

public class So4AttrComponentePubbDTO implements it.finmatica.dto.DTO<So4AttrComponentePubb> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    String assegnazionePrevalente;
    String codiceIncarico;
    So4ComponentePubbDTO componente;
    Date dal;
    String descrizioneIncarico;
    String eMail;
    String fax;
    String gradazione;
    Integer ordinamento;
    BigDecimal percentualeImpiego;
    Boolean seResponsabile;
    String telefono;
    String tipoAssegnazione;


    public So4AttrComponentePubb getDomainObject () {
        return So4AttrComponentePubb.get(this.id)
    }
    public So4AttrComponentePubb toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
