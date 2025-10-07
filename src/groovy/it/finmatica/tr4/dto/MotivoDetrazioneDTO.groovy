package it.finmatica.tr4.dto;

import it.finmatica.tr4.MotivoDetrazione;

import java.util.Map;

public class MotivoDetrazioneDTO implements it.finmatica.dto.DTO<MotivoDetrazione> {
    private static final long serialVersionUID = 1L;

    String id;
    String descrizione;
    int motivoDetrazione;
    TipoTributoDTO tipoTributo


    public MotivoDetrazione getDomainObject () {
        return MotivoDetrazione.createCriteria().get {
            eq('id', this.id)
        }
    }
    public MotivoDetrazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
