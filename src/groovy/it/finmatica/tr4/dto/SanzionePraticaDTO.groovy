package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.SanzionePratica
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class SanzionePraticaDTO implements DTO<SanzionePratica> {
    private static final long serialVersionUID = 1L

    Long id
    BigDecimal abPrincipale
    BigDecimal altriComune
    BigDecimal altriErariale
    BigDecimal areeComune
    BigDecimal areeErariale
    SanzioneDTO sanzione
    Date lastUpdated
    BigDecimal fabbricatiDComune
    BigDecimal fabbricatiDErariale
    BigDecimal fabbricatiMerce
    Short giorni
    BigDecimal importo
    BigDecimal importoRuolo
    String note
    OggettoPraticaDTO oggettoPratica
    BigDecimal percentuale
    PraticaTributoDTO pratica
    BigDecimal riduzione
    BigDecimal riduzione2
    RuoloDTO ruolo
    BigDecimal rurali
    Byte semestri
    Short sequenza
    BigDecimal terreniComune
    BigDecimal terreniErariale
    Ad4UtenteDTO utente

    BigDecimal importoRidCalcolato
    BigDecimal importoRid2Calcolato
    BigDecimal importoLordoCalcolato
    BigDecimal importoLordoRidCalcolato
	BigDecimal importoLordoRid2Calcolato
	
    boolean eliminato = false

    SanzionePratica getDomainObject() {
        return SanzionePratica.createCriteria().get {
            eq('pratica.id', this.pratica.id)
            eq('sanzione.codSanzione', this.sanzione.codSanzione)
            eq('sanzione.tipoTributo.tipoTributo', this.sanzione.tipoTributo.tipoTributo)
            eq('sequenza', this.sequenza)
            eq("seqSanz", sanzione.sequenza)
        }
    }

    SanzionePratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    BigDecimal getImportoLordo() {
        return getDomainObject()?.getImportoLordo() ?: 0
    }

    BigDecimal getImportoTotale() {
        return getDomainObject()?.getImportoTotale() ?: 0
    }
}
