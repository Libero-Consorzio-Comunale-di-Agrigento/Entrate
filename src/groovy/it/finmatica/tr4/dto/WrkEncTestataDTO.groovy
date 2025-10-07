package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkEncTestata

class WrkEncTestataDTO implements DTO<WrkEncTestata> {

    Long documentoId
    Integer progrDichiarazione
    Integer annoDichiarazione
    Integer annoImposta
    String codComune
    String codFiscale
    String denominazione
    String telefono
    String email
    String indirizzo
    String numCiv
    String scala
    String piano
    String interno
    String cap
    String comune
    String provincia
    Integer numImmobiliA
    Integer numImmobiliB
    BigDecimal imuDovuta
    BigDecimal eccedenzaImuDicPrec
    BigDecimal eccedenzaImuDicPrecF24
    BigDecimal rateImuVersate
    BigDecimal imuDebito
    BigDecimal imuCredito
    BigDecimal tasiDovuta
    BigDecimal eccedenzaTasiDicPrec
    BigDecimal eccedenzaTasiDicPrecF24
    BigDecimal tasiRateVersate
    BigDecimal tasiDebito
    BigDecimal tasiCredito
    BigDecimal imuCreditoDicPresente
    BigDecimal creditoImuRimborso
    BigDecimal creditoImuCompensazione
    BigDecimal tasiCreditoDicPresente
    BigDecimal creditoTasiRimborso
    BigDecimal creditoTasiCompensazione
    Date dataVariazione
    String utente
    Long tr4Ni
    Long tr4PraticaIci
    Long tr4PraticaTasi
    String firmaDichiarazione
    String sesso
    Date dataNascita
    String comuneNascita
    String provinciaNascita
    String codiceTracciato
    String nome

   WrkEncTestata getDomainObject () {
       return WrkEncTestata.createCriteria().get {
           eq('documentoId', this.documentoId)
           eq('progrDichiarazione', this.progrDichiarazione)
       }
   }

    WrkEncTestata toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}

