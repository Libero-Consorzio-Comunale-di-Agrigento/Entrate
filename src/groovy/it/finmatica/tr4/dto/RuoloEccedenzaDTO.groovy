package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RuoloEccedenza
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class RuoloEccedenzaDTO implements DTO<RuoloEccedenza>, Comparable<RuoloEccedenzaDTO> {
    private static final long serialVersionUID = 1L

    Long id
    RuoloDTO ruolo
    ContribuenteDTO contribuente
    CodiceTributoDTO codiceTributo
    Short categoria
    Short sequenza
    Date dal
    Date al
    String flagDomestica
    Short numeroFamiliari
    BigDecimal imposta
    BigDecimal addizionalePro
    BigDecimal importoRuolo
    BigDecimal importoMinimi
    BigDecimal totaleSvuotamenti
    BigDecimal superficie
    BigDecimal costoUnitario
    BigDecimal costoSvuotamento
    BigDecimal svuotamentiSuperficie
    BigDecimal costoSuperficie
    BigDecimal eccedenzaSvuotamenti
    String note

    Ad4UtenteDTO utente
    Date lastUpdated

    RuoloEccedenza getDomainObject() {
        return RuoloEccedenza.createCriteria().get {
            eq('ruolo.id', this.ruolo.id)
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('codiceTributo.tributo', this.codiceTributo.tributo)
            eq('categoria', this.categoria)
            eq('sequenza', this.sequenza)
        }
    }

    RuoloEccedenza toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    @Override
    int compareTo(RuoloEccedenzaDTO rc) {
        return ruolo.tipoRuolo <=> rc.ruolo.tipoRuolo ?:
                ruolo.annoRuolo <=> rc.ruolo.annoRuolo ?:
                        ruolo.annoEmissione <=> rc.ruolo.annoEmissione ?:
                                ruolo.progrEmissione <=> rc.ruolo.progrEmissione ?:
                                        ruolo.dataEmissione <=> rc.ruolo.dataEmissione ?:
                                                ruolo.invioConsorzio <=> rc.ruolo.invioConsorzio
    }
}
