package it.finmatica.tr4.dto

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Compensazione
import it.finmatica.tr4.CompensazioneRuolo
import it.finmatica.tr4.MotivoCompensazione

class CompensazioniDTO implements it.finmatica.dto.DTO<Compensazione> {
    private static final long serialVersionUID = 1L

    Integer idCompensazione
    ContribuenteDTO contribuente
    String tipoTributo
    Short anno
    MotivoCompensazione motivoCompensazione
    BigDecimal compensazione
    Ad4Utente utente
    boolean flagAutomatico
    String note
    Date lastUpdated


    Compensazione getDomainObject() {
        return CompensazioneRuolo.get(idCompensazione)
    }

    Compensazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
