package it.finmatica.tr4.dto;

import it.finmatica.tr4.Si4TipiAbilitazione;

import java.util.Map;
import java.util.Set;

public class Si4TipiAbilitazioneDTO implements it.finmatica.dto.DTO<Si4TipiAbilitazione> {
    private static final long serialVersionUID = 1L;

    Long id;
    String descrizione;
    Set<Si4AbilitazioniDTO> si4Abilitazionis;
    String tipoAbilitazione;

    public void addToSi4Abilitazionis (Si4AbilitazioniDTO si4Abilitazioni) {
        if (this.si4Abilitazionis == null)
            this.si4Abilitazionis = new HashSet<Si4AbilitazioniDTO>()
        this.si4Abilitazionis.add (si4Abilitazioni);
        si4Abilitazioni.si4TipiAbilitazione = this
    }

    public void removeFromSi4Abilitazionis (Si4AbilitazioniDTO si4Abilitazioni) {
        if (this.si4Abilitazionis == null)
            this.si4Abilitazionis = new HashSet<Si4AbilitazioniDTO>()
        this.si4Abilitazionis.remove (si4Abilitazioni);
        si4Abilitazioni.si4TipiAbilitazione = null
    }

    public Si4TipiAbilitazione getDomainObject () {
        return Si4TipiAbilitazione.get(this.id)
    }
    public Si4TipiAbilitazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
