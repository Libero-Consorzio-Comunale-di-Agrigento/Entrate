package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Modelli
import it.finmatica.tr4.ModelliVersione

public class ModelliVersioneDTO implements it.finmatica.dto.DTO<ModelliVersione> {
    private static final long serialVersionUID = 1L;

    def id
    Integer versione
    byte[] documento
    String utente
    String note
    Date dataVariazione

    def modello


    public ModelliVersione getDomainObject() {
        return Modelli.get(this.id)
    }

    public ModelliVersione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
