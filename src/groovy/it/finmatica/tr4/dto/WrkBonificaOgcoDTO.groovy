package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkBonificaOgco;

import java.util.Map;

public class WrkBonificaOgcoDTO implements it.finmatica.dto.DTO<WrkBonificaOgco> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codFiscale;
    Long oggettoPraticaRif;
    String tipoTributo;


    public WrkBonificaOgco getDomainObject () {
        return WrkBonificaOgco.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('codFiscale', this.codFiscale)
            eq('oggettoPraticaRif', this.oggettoPraticaRif)
        }
    }
    public WrkBonificaOgco toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
