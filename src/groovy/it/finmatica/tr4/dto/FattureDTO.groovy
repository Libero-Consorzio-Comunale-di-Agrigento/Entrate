package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.Fatture;

import java.util.Date;
import java.util.Map;

public class FattureDTO implements it.finmatica.dto.DTO<Fatture> {
    private static final long serialVersionUID = 1L;

    Short anno;
    Short annoRif;
    String codFiscale;
    Date dataEmissione;
    Date dataScadenza;
    Date lastUpdated;
    BigDecimal fattura;
    BigDecimal fatturaRif;
    String flagDelega;
    String flagStampa;
    BigDecimal importoTotale;
    String note;
    Integer numero;
    Integer numeroRif;
    Ad4UtenteDTO	utente;


    public Fatture getDomainObject () {
        return Fatture.get(this.fattura)
    }
    public Fatture toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
