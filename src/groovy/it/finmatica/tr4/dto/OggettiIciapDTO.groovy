package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiIciap;

import java.util.Date;
import java.util.Map;

public class OggettiIciapDTO implements it.finmatica.dto.DTO<OggettiIciap> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Integer classeSup;
    String codFiscale;
    BigDecimal consistenza;
    Date data;
    BigDecimal impostaBase;
    BigDecimal impostaDovuta;
    Long oggetto;
    Long oggettoPratica;
    Long oggettoPraticaRif;
    Long pratica;
    Byte settore;
    String tipoPratica;


    public OggettiIciap getDomainObject () {
        return OggettiIciap.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('oggettoPraticaRif', this.oggettoPraticaRif)
            eq('consistenza', this.consistenza)
            eq('settore', this.settore)
            eq('classeSup', this.classeSup)
            eq('impostaBase', this.impostaBase)
            eq('impostaDovuta', this.impostaDovuta)
            eq('pratica', this.pratica)
            eq('tipoPratica', this.tipoPratica)
            eq('data', this.data)
            eq('oggetto', this.oggetto)
        }
    }
    public OggettiIciap toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
