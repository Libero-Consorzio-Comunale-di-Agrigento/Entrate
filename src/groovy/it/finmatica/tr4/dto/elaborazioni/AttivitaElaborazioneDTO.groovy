package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.ModelliDTO
import it.finmatica.tr4.dto.comunicazioni.DettaglioComunicazioneDTO
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione

class AttivitaElaborazioneDTO implements DTO<AttivitaElaborazione> {

    Long id
    Date dataAttivita
    TipoAttivitaDTO tipoAttivita
    StatoAttivitaDTO statoAttivita
    ModelliDTO modello
    String flagF24
    String utente
    Date dataVariazione
    String note
    TipoSpedizioneDTO tipoSpedizione
    String testoAppio
    // byte[] documento

    ElaborazioneMassivaDTO elaborazione
    String flagNotifica
    DettaglioComunicazioneDTO dettaglioComunicazione

    @Override
    AttivitaElaborazione getDomainObject() {
        return AttivitaElaborazione.get(id)
    }

    AttivitaElaborazione toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    Map asMap() {
        this.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [(it.name): this."$it.name"]
        }
    }
}
