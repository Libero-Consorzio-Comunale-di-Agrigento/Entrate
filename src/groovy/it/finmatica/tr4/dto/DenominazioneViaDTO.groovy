package it.finmatica.tr4.dto;

import it.finmatica.tr4.DenominazioneVia;

import java.util.Map;

public class DenominazioneViaDTO implements it.finmatica.dto.DTO<DenominazioneVia> {
    private static final long serialVersionUID = 1L;

    Long id;
    ArchivioVieDTO archivioVie;
    String descrizione;
    Byte progrVia;


    public DenominazioneVia getDomainObject () {
        return DenominazioneVia.createCriteria().get {
            eq('codVia', this.archivioVieDTO.id)
            eq('progrVia', this.progrVia)
        }
    }
    public DenominazioneVia toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
