package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RuoloOggetto
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class RuoloOggettoDTO implements DTO<RuoloOggetto> {
    private static final long serialVersionUID = 1L

    RuoloDTO ruolo
    RuoloContribuenteDTO ruoloContribuente
    Short aMese
    BigDecimal addizionaleEca
    BigDecimal addizionalePro
    Short annoRuolo
    Short categoria
    BigDecimal consistenza
    Short daMese
    Date dataCartella
    Date lastUpdated
    Date decorrenzaInteressi
    Short giorniRuolo
    BigDecimal importo
    Boolean importoLordo
    BigDecimal imposta
    BigDecimal iva
    BigDecimal maggiorazioneEca
    BigDecimal maggiorazioneTares
    Short mesiRuolo
    String note
    String numeroCartella
    OggettoDTO oggetto
    OggettoImpostaDTO oggettoImposta
    OggettoPraticaDTO oggettoPratica
    PraticaTributoDTO pratica
    Short semestri
    Short tipoTariffa
    TipoTributoDTO tipoTributo
    CodiceTributoDTO codiceTributo
    Ad4UtenteDTO utente
    String codFiscale

    // TODO da sistemare funzione
    RuoloOggetto getDomainObject() {
        return RuoloOggetto.createCriteria().get {
            eq('ruolo.id', this.ruolo.id)
            eq('contribuente.codFiscale', this.ruoloContribuente.contribuente.codFiscale)
            eq('sequenza', this.ruoloContribuente.sequenza)
        }
    }

    RuoloOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
