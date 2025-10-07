package it.finmatica.so4.dto.struttura;

import it.finmatica.as4.dto.As4SoggettoCorrenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.struttura.So4Amministrazione

public class So4AmministrazioneDTO implements it.finmatica.dto.DTO<So4Amministrazione> {
    private static final long serialVersionUID = 1L;

    Set<So4AOODTO> aoo;
    String codice;
    Date dataIstituzione;
    Date dataSoppressione;
    boolean ente;
    Set<So4OtticaDTO> ottiche;
    As4SoggettoCorrenteDTO soggetto;

    public void addToAoo (So4AOODTO so4AOO) {
        if (this.aoo == null)
            this.aoo = new HashSet<So4AOODTO>()
        this.aoo.add (so4AOO);
        so4AOO.amministrazione = this
    }

    public void removeFromAoo (So4AOODTO so4AOO) {
        if (this.aoo == null)
            this.aoo = new HashSet<So4AOODTO>()
        this.aoo.remove (so4AOO);
        so4AOO.amministrazione = null
    }
    public void addToOttiche (So4OtticaDTO so4Ottica) {
        if (this.ottiche == null)
            this.ottiche = new HashSet<So4OtticaDTO>()
        this.ottiche.add (so4Ottica);
        so4Ottica.amministrazione = this
    }

    public void removeFromOttiche (So4OtticaDTO so4Ottica) {
        if (this.ottiche == null)
            this.ottiche = new HashSet<So4OtticaDTO>()
        this.ottiche.remove (so4Ottica);
        so4Ottica.amministrazione = null
    }

    public So4Amministrazione getDomainObject () {
        return So4Amministrazione.get(this.codice)
    }
    
    public So4Amministrazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
