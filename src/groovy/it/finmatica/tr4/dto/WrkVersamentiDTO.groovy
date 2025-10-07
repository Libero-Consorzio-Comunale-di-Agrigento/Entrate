package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.WrkVersamenti
import it.finmatica.tr4.dto.anomalie.CausaleDTO
import it.finmatica.dto.DtoToEntityUtils

class WrkVersamentiDTO implements DTO<WrkVersamenti> {
    private static final long serialVersionUID = 1L

    ContribuenteDTO contribuente
    BigDecimal abPrincipale
    BigDecimal altriComune
    BigDecimal altriErariale
    BigDecimal altriFabbricati
    Short anno
    BigDecimal areeComune
    BigDecimal areeErariale
    BigDecimal areeFabbricabili
    CausaleDTO causale
    String codFiscale
    String cognomeNome
    Date dataPagamento
    Date dataReg
    Date dataScadenza
    Date lastUpdated
    BigDecimal detrazione
    BigDecimal disposizione
    Short fabbricati
    BigDecimal fabbricatiD
    BigDecimal fabbricatiDComune
    BigDecimal fabbricatiDErariale
    String flagContribuente
    BigDecimal importoVersato
    BigDecimal maggiorazioneTares
    String note
    Short numFabbricatiAb
    Short numFabbricatiAltri
    Short numFabbricatiAree
    Short numFabbricatiD
    Short numFabbricatiRurali
    Short numFabbricatiTerreni
    Long progressivo
    Byte rata
    Long ruolo
    BigDecimal rurali
    BigDecimal ruraliComune
    BigDecimal ruraliErariale
    String sanzioneRavvedimento
    BigDecimal terreniAgricoli
    BigDecimal terreniComune
    BigDecimal terreniErariale
    String tipoIncasso
    TipoTributoDTO tipoTributo
    String tipoVersamento
    String ufficioPt
    Long documentoId
    String identificativoOperazione
    String flagOk
    String noteVersamento

    WrkVersamenti getDomainObject() {
        return WrkVersamenti.get(this.progressivo)
    }

    WrkVersamenti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
