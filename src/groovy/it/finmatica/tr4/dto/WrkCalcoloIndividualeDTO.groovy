package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkCalcoloIndividuale;

import java.util.Map;

public class WrkCalcoloIndividualeDTO implements it.finmatica.dto.DTO<WrkCalcoloIndividuale> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal accontoAb;
    BigDecimal accontoAltri;
    BigDecimal accontoAltriErar;
    BigDecimal accontoAree;
    BigDecimal accontoAreeErar;
    BigDecimal accontoDetrazione;
    BigDecimal accontoDetrazioneImponibile;
    BigDecimal accontoFabbricatiD;
    BigDecimal accontoFabbricatiDErar;
    BigDecimal accontoRurali;
    BigDecimal accontoTerreni;
    BigDecimal accontoTerreniErar;
    BigDecimal numFabbricatiAb;
    BigDecimal numFabbricatiAltri;
    BigDecimal numFabbricatiD;
    BigDecimal numFabbricatiRurali;
    BigDecimal numeroFabbricati;
    BigDecimal saldoAb;
    BigDecimal saldoAltri;
    BigDecimal saldoAltriErar;
    BigDecimal saldoAree;
    BigDecimal saldoAreeErar;
    BigDecimal saldoDetrazione;
    BigDecimal saldoDetrazioneImponibile;
    BigDecimal saldoFabbricatiD;
    BigDecimal saldoFabbricatiDErar;
    BigDecimal saldoRurali;
    BigDecimal saldoTerreni;
    BigDecimal saldoTerreniErar;
    BigDecimal totAb;
    BigDecimal totAltri;
    BigDecimal totAltriErar;
    BigDecimal totAree;
    BigDecimal totAreeErar;
    BigDecimal totDetrazione;
    BigDecimal totDetrazioneImponibile;
    BigDecimal totFabbricatiD;
    BigDecimal totFabbricatiDErar;
    BigDecimal totRurali;
    BigDecimal totTerreni;
    BigDecimal totTerreniErar;
    BigDecimal totaleTerreni;


    public WrkCalcoloIndividuale getDomainObject () {
        return WrkCalcoloIndividuale.get(this.id)
    }
    public WrkCalcoloIndividuale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
