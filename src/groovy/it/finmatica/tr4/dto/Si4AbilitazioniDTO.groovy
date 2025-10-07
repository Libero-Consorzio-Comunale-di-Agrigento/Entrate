package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Si4Abilitazioni

public class Si4AbilitazioniDTO implements it.finmatica.dto.DTO<Si4Abilitazioni> {
    private static final long serialVersionUID = 1L;

    Long id;
    Set<Si4CompetenzeDTO> si4Competenzes;
    Si4TipiAbilitazioneDTO si4TipiAbilitazione;
    Si4TipiOggettoDTO si4TipiOggetto;

    public void addToSi4Competenzes(Si4CompetenzeDTO si4Competenze) {
        if (this.si4Competenzes == null)
            this.si4Competenzes = new HashSet<Si4CompetenzeDTO>()
        this.si4Competenzes.add (si4Competenze);
        si4Competenze.si4Abilitazioni = this
    }

    public void removeFromSi4Competenzes (Si4CompetenzeDTO si4Competenze) {
        if (this.si4Competenzes == null)
            this.si4Competenzes = new HashSet<Si4CompetenzeDTO>()
        this.si4Competenzes.remove (si4Competenze);
        si4Competenze.si4Abilitazioni = null
    }

    public Si4Abilitazioni getDomainObject () {
        return Si4Abilitazioni.get(this.id)
    }
    public Si4Abilitazioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
