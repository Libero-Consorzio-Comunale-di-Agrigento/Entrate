package it.finmatica.so4.dto.struttura;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.strutturaPubblicazione.So4UnitaPubbDTO
import it.finmatica.so4.struttura.So4Ottica

public class So4OtticaDTO implements it.finmatica.dto.DTO<So4Ottica> {
    private static final long serialVersionUID = 1L;

    So4AmministrazioneDTO amministrazione;
    String codice;
    String descrizione;
    boolean gestioneRevisioni;
    boolean istituzionale;
    String note;
    Set<So4UnitaDTO> unita;
    Set<So4UnitaPubbDTO> unitaPubb;

    public void addToUnita (So4UnitaDTO so4Unita) {
        if (this.unita == null)
            this.unita = new HashSet<So4UnitaDTO>()
        this.unita.add (so4Unita);
        so4Unita.ottica = this
    }

    public void removeFromUnita (So4UnitaDTO so4Unita) {
        if (this.unita == null)
            this.unita = new HashSet<So4UnitaDTO>()
        this.unita.remove (so4Unita);
        so4Unita.ottica = null
    }
    public void addToUnitaPubb (So4UnitaPubbDTO so4UnitaPubb) {
        if (this.unitaPubb == null)
            this.unitaPubb = new HashSet<So4UnitaPubbDTO>()
        this.unitaPubb.add (so4UnitaPubb);
        so4UnitaPubb.ottica = this
    }

    public void removeFromUnitaPubb (So4UnitaPubbDTO so4UnitaPubb) {
        if (this.unitaPubb == null)
            this.unitaPubb = new HashSet<So4UnitaPubbDTO>()
        this.unitaPubb.remove (so4UnitaPubb);
        so4UnitaPubb.ottica = null
    }

    public So4Ottica getDomainObject () {
        return So4Ottica.get(this.codice)
    }
    public So4Ottica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
