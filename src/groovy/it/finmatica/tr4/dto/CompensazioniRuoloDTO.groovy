package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.tr4.CompensazioneRuolo
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO

class CompensazioniRuoloDTO implements it.finmatica.dto.DTO<CompensazioneRuolo> {
    private static final long serialVersionUID = 1L

    Short anno
    ContribuenteDTO contribuente
    BigDecimal compensazione
    Date lastUpdated
    boolean flagAutomatico
    MotivoCompensazioneDTO motivoCompensazione
    String note
    OggettoPraticaDTO oggettoPratica
    RuoloDTO ruolo
    Ad4UtenteDTO utente


    CompensazioneRuolo getDomainObject() {
        return CompensazioneRuolo.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('anno', this.anno)
            eq('ruolo.id', this.ruolo.id)
            eq('oggettoPratica.id', this.oggettoPratica.id)
        }
    }

    CompensazioneRuolo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
