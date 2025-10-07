package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.InstallazioneParametro

class InstallazioneParametroDTO implements DTO<InstallazioneParametro> {
    private static final long serialVersionUID = 1L

    String descrizione
    String parametro
    String valore


    InstallazioneParametro getDomainObject() {
        return InstallazioneParametro.get(this.parametro)
    }

    InstallazioneParametro toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
