package it.finmatica.tr4.dto.portale

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.WrkEncImmobiliDTO
import it.finmatica.tr4.portale.SprVIciPraticheDettagli
import org.hibernate.annotations.Immutable

@Immutable
class SprVIciPraticheDettagliDTO implements DTO<SprVIciPraticheDettagli> {

    private def CARATTERISTICHE = [
            '1': "Terreno",
            '2': "Area fabbricabile",
            '3': "Fabbricato con valore determinato sulla base della rendita catastale",
            '4': "Fabbricato con valore determinato sulla base delle scritture contabili",
            '5': "Abitazione principale",
            '6': "Pertinenza",
            '7': "Beni merce"
    ]

    Long idPratica
    String acquistoCessioneAltro
    Integer annoProtocollo
    String autorita
    String caratteristicaImmobile
    String catastoFoglio
    String catastoParticella
    String catastoSezione
    String catastoSubalterno
    String categoriaQualita
    String classe
    String comuneResidenza
    String dataDenunciaProvvedimento
    String dataPossessoVariazione
    String descrizioneAltroAcquistoCessione
    BigDecimal detrazioneAbitazionePrincipale
    String equiparazioneAbitazionePrincipale
    String esenzioni
    String indirizzoCap
    String indirizzoCivico
    String indirizzoDenominazione
    String indirizzoProvincia
    String indirizzoToponimo
    String inizioTermineAgevolazione
    String numeroProtocollo
    BigDecimal percPossesso
    String riduzioni
    Long sequenzaImmobile
    String tipoAgevolazione
    String tU
    BigDecimal valore

    SprVIciPraticheDettagli getDomainObject() {
        return SprVIciPraticheDettagli.findByIdPraticaAndSequenzaImmobile(this.idPratica, this.sequenzaImmobile)
    }

    SprVIciPraticheDettagli toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    String getDescrizioneCaratteristica() {
        return CARATTERISTICHE[caratteristicaImmobile] ?: 'Non definita'
    }

    String getIndirizzoCompleto() {
        return "${indirizzoToponimo ?: ''} ${indirizzoDenominazione ?: ''} ${indirizzoCivico ?: ''}"
    }

    boolean isRidotto() {
        return riduzioni != '0'
    }

    boolean isEsente() {
        return esenzioni != '0'
    }

    WrkEncImmobiliDTO toWrkEncImmobili(def documentoId, def progressivoDichiarazione) {
        return new WrkEncImmobiliDTO(
                documentoId: documentoId,
                progrDichiarazione: progressivoDichiarazione,
                progrImmobile: sequenzaImmobile,
                numOrdine: sequenzaImmobile,
                indirizzo: getIndirizzoCompleto(),
                tipoImmobile: determinaTipo(),
                sezione: catastoSezione,
                numero: catastoParticella,
                foglio: catastoFoglio,
                subalterno: catastoSubalterno,
                categoriaCatasto: categoriaQualita,
                protocolloCatasto: numeroProtocollo,
                annoCatasto: annoProtocollo,
                valore: valore,
                percPossesso: percPossesso,
                dataVariazione: Date.parse('dd/MM/yyy', dataPossessoVariazione),
                codEsenzione: esenzioni,
                codRiduzione: riduzioni,
                caratteristica: caratteristicaImmobile
        )
    }

    private String determinaTipo() {
        switch (caratteristicaImmobile) {
            case ['5', '6', '7']:
                return '3'
            default:
                return caratteristicaImmobile
        }
    }
}
