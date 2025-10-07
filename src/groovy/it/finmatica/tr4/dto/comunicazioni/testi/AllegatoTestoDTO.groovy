package it.finmatica.tr4.dto.comunicazioni.testi

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.comunicazioni.testi.AllegatoTesto

class AllegatoTestoDTO implements DTO<AllegatoTesto> {

    Long id
    ComunicazioneTestiDTO comunicazioneTesti
    Short sequenza
    String descrizione
    String nomeFile
    byte[] documento
    Ad4UtenteDTO utente
    Date dataVariazione
    String note


    AllegatoTesto getDomainObject() {
        return AllegatoTesto.findByComunicazioneTestiAndSequenza(comunicazioneTesti.getDomainObject(), sequenza)
    }

    AllegatoTesto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as AllegatoTesto
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori
     */

}
