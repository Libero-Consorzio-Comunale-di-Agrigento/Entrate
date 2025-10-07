package it.finmatica.tr4.dto;

import it.finmatica.tr4.ViolazioniDettagliOgim;

import java.util.Map;

public class ViolazioniDettagliOgimDTO implements it.finmatica.dto.DTO<ViolazioniDettagliOgim> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal detrazione;
    BigDecimal detrazioneAcconto;
    BigDecimal detrazioneSaldo;
    BigDecimal numFabbricatiAbIci;
    BigDecimal numFabbricatiAbImu;
    BigDecimal numFabbricatiAltriIci;
    BigDecimal numFabbricatiAltriImu;
    BigDecimal numFabbricatiFabbDImu;
    BigDecimal numFabbricatiRuraliImu;
    Long pratica;


    public ViolazioniDettagliOgim getDomainObject () {
        return ViolazioniDettagliOgim.createCriteria().get {
            eq('pratica', this.pratica)
            eq('detrazione', this.detrazione)
            eq('detrazioneAcconto', this.detrazioneAcconto)
            eq('detrazioneSaldo', this.detrazioneSaldo)
            eq('numFabbricatiAbImu', this.numFabbricatiAbImu)
            eq('numFabbricatiRuraliImu', this.numFabbricatiRuraliImu)
            eq('numFabbricatiAltriImu', this.numFabbricatiAltriImu)
            eq('numFabbricatiAbIci', this.numFabbricatiAbIci)
            eq('numFabbricatiAltriIci', this.numFabbricatiAltriIci)
            eq('numFabbricatiFabbDImu', this.numFabbricatiFabbDImu)
        }
    }
    public ViolazioniDettagliOgim toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
