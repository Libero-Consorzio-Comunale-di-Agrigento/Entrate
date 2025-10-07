package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkEncContitolari

class WrkEncContitolariDTO implements DTO<WrkEncContitolari> {

    Long documentoId
    Integer progrDichiarazione
    Integer progrContitolare
    String tipoImmobile
    Integer progrImmobile
    Integer numOrdine
    String denominazione
    String codFiscale
    String indirizzo
    String numCiv
    String scala
    String piano
    String interno
    String cap
    String comune
    String provincia
    BigDecimal percPossesso
    BigDecimal detrazione
    String firmaContitolare
    Long tr4Ni
    Date dataVariazione
    String utente
    String sesso
    Date dataNascita
    String comuneNascita
    String provinciaNascita

    WrkEncContitolari getDomainObject() {
        return WrkEncContitolari.createCriteria().get {
            eq('documentoId', this.documentoId)
            eq('progrDichiarazione', this.progrDichiarazione)
            eq('progrContitolare', this.progrContitolare)
            eq('tipoImmobile', this.tipoImmobile)
            eq('progrImmobile', this.progrImmobile)
        }
    }

    WrkEncContitolari toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
