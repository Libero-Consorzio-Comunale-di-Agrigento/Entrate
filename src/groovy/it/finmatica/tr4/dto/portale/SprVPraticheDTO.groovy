package it.finmatica.tr4.dto.portale

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.WrkEncTestataDTO
import it.finmatica.tr4.portale.SprVPratiche

class SprVPraticheDTO implements DTO<SprVPratiche> {

    Long idPratica
    Integer annoPratica
    Long idSpr
    Long idApplicativo
    String tipoTributo
    Date dataRichiesta
    String numeroProtocollo
    String dataProtocollo
    String titolo
    String tipoStep
    String chiaveStep
    String nomeStep
    String ragioneSocialeRich
    String cognomeRich
    String nomeRich
    String codiceFiscaleRich
    String partitaIvaRich
    String ragioneSocialeBen
    String cognomeBen
    String nomeBen
    String codiceFiscaleBen
    String partitaIvaBen
    String indirizzoBen
    String comuneBen
    String provinciaBen

    boolean selezionata

    SprVPratiche getDomainObject() {
        return SprVPratiche.get(this.idPratica)
    }

    SprVPratiche toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    String getContribuente() {
        return "${ragioneSocialeBen ?: cognomeBen ?: ''} ${nomeBen ?: ''}".trim()
    }

    String getCodiceFiscale() {
        return codiceFiscaleBen ?: partitaIvaBen ?: ''
    }


    WrkEncTestataDTO toEncTestata(def documentoId, def progressivoDichiarazione, def codiceTracciato) {
        return new WrkEncTestataDTO(
                codiceTracciato: codiceTracciato,
                documentoId: documentoId,
                annoDichiarazione: annoPratica,
                annoImposta: annoPratica,
                codFiscale: getCodiceFiscale(),
                denominazione: ragioneSocialeBen ?: cognomeBen,
                nome: nomeBen,
                indirizzo: indirizzoBen?.substring(0, 35),
                comune: comuneBen,
                provincia: provinciaBen,
                progrDichiarazione: progressivoDichiarazione
        )
    }
}
