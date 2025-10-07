package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Modelli

class ModelliDTO implements DTO<Modelli> {
    private static final long serialVersionUID = 1L

    Long modello
    String tipoTributo
    String descrizione
    String path
    String nomeDw
    String flagSottomodello
    String codiceSottomodello
    String flagEditabile
    String flagStandard
    String dbFunction
    String flagF24
    String flagAvvisoAgid
    String flagWeb
    String flagEredi

    def tipoModello
    def versioni

    Modelli getDomainObject() {
        return Modelli.get(this.modello)
    }

    Modelli toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
