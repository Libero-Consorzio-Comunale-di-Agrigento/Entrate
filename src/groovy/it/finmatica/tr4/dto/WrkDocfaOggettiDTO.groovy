package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkDocfaOggetti

class WrkDocfaOggettiDTO implements it.finmatica.dto.DTO<WrkDocfaOggetti> {
    Integer documentoId
    Integer documentoMultiId
    Integer progrOggetto
    String tipoOperazione
    String sezione
    String foglio
    String numero
    String subalterno
    Long codVia
    String indirizzo
    String numCivico
    String piano
    String scala
    String interno
    String zona
    String categoria
    String classe
    String consistenza
    Short superficieCatastale
    Long rendita
    Integer tr4Oggetto

    public WrkDocfaOggetti getDomainObject() {
        return WrkDocfaOggetti.findByDocumentoIdAndDocumentoMultiIdAndProgrOggetto(
                this.documentoId,
                this.documentoMultiId,
                this.progrOggetto)
    }

    public WrkDocfaOggetti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
