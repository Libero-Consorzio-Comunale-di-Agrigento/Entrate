package it.finmatica.tr4.dto.comunicazioni.testi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.comunicazioni.testi.ComunicazioneTesti
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO

class ComunicazioneTestiDTO implements DTO<ComunicazioneTesti>, Cloneable {

    Long id
    String tipoTributo
    TipiCanaleDTO tipoCanale
    String tipoComunicazione
    String descrizione
    String oggetto
    String testo
    String utente
    Date dataVariazione
    String note
    def allegatiTesto

    def testoModificato
    def oggettoModificato
    def presenzaAllegati

    ComunicazioneTesti getDomainObject() {
        return ComunicazioneTesti.get(this.id)
    }

    ComunicazioneTesti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as ComunicazioneTesti
    }

    void addToAllegatiTesto(AllegatoTestoDTO allegatoTesto) {
        if (this.allegatiTesto == null)
            this.allegatiTesto = new HashSet<AllegatoTestoDTO>()
        this.allegatiTesto.add(allegatoTesto)
        allegatoTesto.comunicazioneTesti = this
    }

    void removeFromAllegatiTesto(AllegatoTestoDTO allegatoTesto) {
        if (this.allegatiTesto == null)
            this.allegatiTesto = new HashSet<AllegatoTestoDTO>()
        this.allegatiTesto.remove(allegatoTesto)
        allegatoTesto.comunicazioneTesti = null
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori
     */

}
