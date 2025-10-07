package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiStorici;

import java.util.Date;
import java.util.Map;

public class OggettiStoriciDTO implements it.finmatica.dto.DTO<OggettiStorici> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Short categoria;
    String codFiscale;
    BigDecimal consistenza;
    Date data;
    Date dataCessazione;
    Date dataDecorrenza;
    Long oggetto;
    Long oggettoPratica;
    Long pratica;
    String tipoPratica;
    Byte tipoTariffa;
    String tipoTributo;
    Short tributo;
    BigDecimal valore;


    public OggettiStorici getDomainObject () {
        return OggettiStorici.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
            eq('tipoTariffa', this.tipoTariffa)
            eq('dataDecorrenza', this.dataDecorrenza)
            eq('dataCessazione', this.dataCessazione)
            eq('valore', this.valore)
            eq('consistenza', this.consistenza)
            eq('oggetto', this.oggetto)
            eq('pratica', this.pratica)
            eq('tipoTributo', this.tipoTributo)
            eq('tipoPratica', this.tipoPratica)
            eq('data', this.data)
        }
    }
    public OggettiStorici toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
