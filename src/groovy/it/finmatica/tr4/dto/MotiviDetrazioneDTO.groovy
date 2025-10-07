package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.MotiviDetrazione

public class MotiviDetrazioneDTO implements DTO<MotiviDetrazione>, Cloneable{
    private static final long serialVersionUID = 1L;

    Short motivoDetrazione;
    String tipoTributo
    String descrizione;


    public MotiviDetrazione getDomainObject() {
        return MotiviDetrazione.createCriteria().get {
            eq('motivoDetrazione', this.motivoDetrazione)
            eq('tipoTributo', this.tipoTributo)
        }
    }

    public MotiviDetrazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as MotiviDetrazione
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori*/
    public MotiviDetrazioneDTO() {}

    public MotiviDetrazioneDTO(String tipoTributo) {
        this.tipoTributo = tipoTributo
    }

    @Override
    public MotiviDetrazioneDTO clone(){
        def clone = new MotiviDetrazioneDTO(this.tipoTributo)
        clone.motivoDetrazione = new Short(this.motivoDetrazione)
        clone.descrizione = new String(this.descrizione)
        return clone
    }
}
