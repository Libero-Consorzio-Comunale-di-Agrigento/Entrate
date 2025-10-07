package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkEncImmobili

class WrkEncImmobiliDTO implements DTO<WrkEncImmobili> {

    Long documentoId
    Integer progrDichiarazione
    String tipoImmobile
    Integer progrImmobile
    Integer numOrdine
    Integer tipoAttivita
    String caratteristica
    String indirizzo
    String tipo
    String codCatastale
    String sezione
    String foglio
    String numero
    String subalterno
    String categoriaCatasto
    String classeCatasto
    String protocolloCatasto
    String annoCatasto
    Integer immobileStorico
    BigDecimal valore
    Integer immobileEsente
    BigDecimal percPossesso
    String dataVarImposta
    Integer flagAcquisto
    Integer flagCessione
    String agenziaEntrate
    String estremiTitolo
    Integer dCorrispettivoMedio
    Integer dCostoMedio
    BigDecimal dRapportoSuperficie
    BigDecimal dRapportoSupGg
    BigDecimal dRapportoSoggetti
    BigDecimal dRapportoSoggGg
    BigDecimal dRapportoGiorni
    BigDecimal dPercImponibilita
    BigDecimal dValoreAssArt5
    BigDecimal dValoreAssArt4
    Integer dCasellaRigoG
    Integer dCasellaRigoH
    BigDecimal dRapportoCmsCm
    BigDecimal dValoreAssParziale
    BigDecimal dValoreAssCompl
    Integer aCorrispettivoMedioPerc
    Integer aCorrispettivoMedioPrev
    BigDecimal aRapportoSuperficie
    BigDecimal aRapportoSupGg
    BigDecimal aRapportoSoggetti
    BigDecimal aRapportoSoggGg
    BigDecimal aRapportoGiorni
    BigDecimal aPercImponibilita
    BigDecimal aValoreAssoggettato
    String annotazioni
    Date dataVariazione
    String utente
    Long tr4Oggetto
    Long tr4OggettoNew
    Long tr4OggettoPraticaIci
    Long tr4OggettoPraticaTasi
    Integer progrImmobileDich
    Integer indContinuita
    Integer flagAltro
    String descrizioneAltro
    BigDecimal detrazione
    // NUOVI
    String codRiduzione
    String codEsenzione
    String inizioTermineAgevolazione
    String nonUtilizzDispTipo
    String nonUtilizzDispAutorita
    Date nonUtilizzDispData
    String comodatoImmStruttTipo
    String comodatoImmStruttCom
    String equiparazioneAp

    WrkEncImmobili getDomainObject() {
        return WrkEncImmobili.createCriteria().get {
            eq('documentoId', this.documentoId)
            eq('progrDichiarazione', this.progrDichiarazione)
            eq('tipoImmobile', this.tipoImmobile)
            eq('progrImmobile', this.progrImmobile)
        }
    }

    WrkEncImmobili toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
