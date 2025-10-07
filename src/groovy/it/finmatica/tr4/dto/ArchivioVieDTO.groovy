package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO;
import it.finmatica.tr4.ArchivioVie;

import java.util.Date;
import java.util.Map;
import java.util.Set;

public class ArchivioVieDTO implements it.finmatica.dto.DTO<ArchivioVie> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date lastUpdated;
    String denomOrd;
    String denomUff;
    Set<DenominazioneViaDTO> denominazioniVia;
    So4AmministrazioneDTO ente;
    String note;
    Ad4UtenteDTO	utente;

    public void addToDenominazioniVia (DenominazioneViaDTO denominazioneVia) {
        if (this.denominazioniVia == null)
            this.denominazioniVia = new HashSet<DenominazioneViaDTO>()
        this.denominazioniVia.add (denominazioneVia);
        denominazioneVia.archivioVie = this
    }

    public void removeFromDenominazioniVia (DenominazioneViaDTO denominazioneVia) {
        if (this.denominazioniVia == null)
            this.denominazioniVia = new HashSet<DenominazioneViaDTO>()
        this.denominazioniVia.remove (denominazioneVia);
        denominazioneVia.archivioVie = null
    }

    public ArchivioVie getDomainObject () {
        return ArchivioVie.get(this.id)
    }
    public ArchivioVie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
