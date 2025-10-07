package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.PeriodiImponibile;

import java.util.Date;
import java.util.Map;

public class PeriodiImponibileDTO implements it.finmatica.dto.DTO<PeriodiImponibile> {
    private static final long serialVersionUID = 1L;

    Long id;
    int aMese;
    Short anno;
    String codFiscale;
    Byte daMese;
    Date lastUpdated;
    String flagRiog;
    BigDecimal imponibile;
    BigDecimal imponibileD;
    String note;
    Long oggettoPratica;
    Ad4UtenteDTO	utente;


    public PeriodiImponibile getDomainObject () {
        return PeriodiImponibile.createCriteria().get {
            eq('daMese', this.daMese)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('codFiscale', this.codFiscale)
        }
    }
    public PeriodiImponibile toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
