package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.MotivoCompensazione

public class MotivoCompensazioneDTO implements DTO<MotivoCompensazione>, Cloneable {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id

    public MotivoCompensazione getDomainObject() {
        return MotivoCompensazione.get(this.id)
    }

    public MotivoCompensazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as MotivoCompensazione
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    @Override
    public MotivoCompensazioneDTO clone(){
        def clone = new MotivoCompensazioneDTO()
        clone.id = new Long(this.id) // Il campo id mappa il campo motivoCompensazione dell'oggetto di dominio
        clone.descrizione = new String(this.descrizione)
        return clone
    }
}
