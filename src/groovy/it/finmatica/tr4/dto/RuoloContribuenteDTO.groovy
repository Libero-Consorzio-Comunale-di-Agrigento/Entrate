package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class RuoloContribuenteDTO implements DTO<RuoloContribuente>, Comparable<RuoloContribuenteDTO> {
    private static final long serialVersionUID = 1L

    Long id
    Short aMese
    CodiceTributoDTO codiceTributo
    BigDecimal consistenza
    ContribuenteDTO contribuente
    Short daMese
    Date dataCartella
    Date lastUpdated
    Date decorrenzaInteressi
    Short giorniRuolo
    BigDecimal importo
    Short mesiRuolo
    String note
    String numeroCartella
    OggettoImpostaDTO oggettoImposta
    PraticaTributoDTO pratica
    RuoloDTO ruolo
    Short semestri
    Short sequenza
    Set<SgravioDTO> sgravi
    Ad4UtenteDTO utente

    def totaleSgraviCalcolato

    void addToSgravi(SgravioDTO sgravio) {
        if (this.sgravi == null)
            this.sgravi = new HashSet<SgravioDTO>()
        this.sgravi.add(sgravio)
        sgravio.ruoloContribuente = this
    }

    void removeFromSgravi(SgravioDTO sgravio) {
        if (this.sgravi == null)
            this.sgravi = new HashSet<SgravioDTO>()
        this.sgravi.remove(sgravio)
        sgravio.ruoloContribuente = null
    }

    RuoloContribuente getDomainObject() {
        return RuoloContribuente.createCriteria().get {
            eq('ruolo.id', this.ruolo.id)
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('sequenza', this.sequenza)
        }
    }

    RuoloContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    BigDecimal getTotaleSgravi() {
        sgravi?.flatten().sum { it.importo ?: 0 }
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    @Override
    int compareTo(RuoloContribuenteDTO rc) {
        return ruolo.tipoRuolo <=> rc.ruolo.tipoRuolo ?:
                ruolo.annoRuolo <=> rc.ruolo.annoRuolo ?:
                        ruolo.annoEmissione <=> rc.ruolo.annoEmissione ?:
                                ruolo.progrEmissione <=> rc.ruolo.progrEmissione ?:
                                        ruolo.dataEmissione <=> rc.ruolo.dataEmissione ?:
                                                ruolo.invioConsorzio <=> rc.ruolo.invioConsorzio
        /*RUOLI.TIPO_RUOLO ASC,
        RUOLI.ANNO_RUOLO ASC,
        RUOLI.ANNO_EMISSIONE ASC,
        RUOLI.PROGR_EMISSIONE ASC,
        RUOLI_OGGETTO.TRIBUTO ASC,
        RUOLI.DATA_EMISSIONE ASC,
        RUOLI.INVIO_CONSORZIO ASC*/
    }

}
