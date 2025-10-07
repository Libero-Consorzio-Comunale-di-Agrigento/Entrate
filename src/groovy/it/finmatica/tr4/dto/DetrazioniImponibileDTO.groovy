package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.tr4.DetrazioniImponibile


class DetrazioniImponibileDTO implements DTO<DetrazioniImponibile> {
    private static final long serialVersionUID = 1L

    Long id
    int aMese
    Short anno
    String codFiscale
    int daMese
    Date lastUpdated
    BigDecimal detrazione
    BigDecimal detrazioneAcconto
    BigDecimal detrazioneD
    BigDecimal detrazioneDAcconto
    BigDecimal detrazioneRimanente
    BigDecimal detrazioneRimanenteAcconto
    BigDecimal detrazioneRimanenteD
    BigDecimal detrazioneRimanenteDAcconto
    String flagRiog
    BigDecimal imponibile
    BigDecimal imponibileD
    String note
    Long oggettoPratica
    BigDecimal percDetrazione
    Ad4UtenteDTO utente


    DetrazioniImponibile getDomainObject() {
        return DetrazioniImponibile.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('oggettoPratica', this.oggettoPratica)
            eq('anno', this.anno)
            eq('daMese', this.daMese)
        }
    }

    DetrazioniImponibile toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
