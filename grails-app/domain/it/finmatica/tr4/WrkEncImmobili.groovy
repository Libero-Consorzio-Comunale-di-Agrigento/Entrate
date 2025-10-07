package it.finmatica.tr4;

import java.io.Serializable;

class WrkEncImmobili implements Serializable {

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

    static mapping = {
        id composite: ['documentoId', 'progrDichiarazione', 'tipoImmobile', 'progrImmobile']

        tr4Oggetto column: "TR4_OGGETTO"
        tr4OggettoNew column: "TR4_OGGETTO_NEW"
        tr4OggettoPraticaIci column: "TR4_OGGETTO_PRATICA_ICI"
        tr4OggettoPraticaTasi column: "TR4_OGGETTO_PRATICA_TASI"
        dValoreAssArt5 column: "D_VALORE_ASS_ART_5"
        dValoreAssArt4 column: "D_VALORE_ASS_ART_4"
        dCasellaRigoG column: "D_CASELLA_RIGO_G"
        dCasellaRigoH column: "D_CASELLA_RIGO_H"

        version false
        table "WRK_ENC_IMMOBILI"
    }

    static constraints = {
        tipoAttivita nullable: true
        caratteristica nullable: true
        indirizzo nullable: true
        tipo nullable: true
        codCatastale nullable: true
        sezione nullable: true
        foglio nullable: true
        numero nullable: true
        subalterno nullable: true
        categoriaCatasto nullable: true
        classeCatasto nullable: true
        protocolloCatasto nullable: true
        annoCatasto nullable: true
        immobileStorico nullable: true
        valore nullable: true
        immobileEsente nullable: true
        percPossesso nullable: true
        dataVarImposta nullable: true
        flagAcquisto nullable: true
        flagCessione nullable: true
        agenziaEntrate nullable: true
        estremiTitolo nullable: true
        dCorrispettivoMedio nullable: true
        dCostoMedio nullable: true
        dRapportoSuperficie nullable: true
        dRapportoSupGg nullable: true
        dRapportoSoggetti nullable: true
        dRapportoSoggGg nullable: true
        dRapportoGiorni nullable: true
        dPercImponibilita nullable: true
        dValoreAssArt5 nullable: true
        dValoreAssArt4 nullable: true
        dCasellaRigoG nullable: true
        dCasellaRigoH nullable: true
        dRapportoCmsCm nullable: true
        dValoreAssParziale nullable: true
        dValoreAssCompl nullable: true
        aCorrispettivoMedioPerc nullable: true
        aCorrispettivoMedioPrev nullable: true
        aRapportoSuperficie nullable: true
        aRapportoSupGg nullable: true
        aRapportoSoggetti nullable: true
        aRapportoSoggGg nullable: true
        aRapportoGiorni nullable: true
        aPercImponibilita nullable: true
        aValoreAssoggettato nullable: true
        annotazioni nullable: true
        dataVariazione nullable: true
        utente nullable: true
        tr4Oggetto nullable: true
        tr4OggettoNew nullable: true
        tr4OggettoPraticaIci nullable: true
        tr4OggettoPraticaTasi nullable: true
        progrImmobileDich nullable: true
        indContinuita nullable: true
        flagAltro nullable: true
        descrizioneAltro nullable: true
        detrazione nullable: true
        codRiduzione nullable: true
        codEsenzione nullable: true
        inizioTermineAgevolazione nullable: true
        nonUtilizzDispTipo nullable: true
        nonUtilizzDispAutorita nullable: true
        nonUtilizzDispData nullable: true
        comodatoImmStruttTipo nullable: true
        comodatoImmStruttCom nullable: true
        equiparazioneAp nullable: true
    }
}
