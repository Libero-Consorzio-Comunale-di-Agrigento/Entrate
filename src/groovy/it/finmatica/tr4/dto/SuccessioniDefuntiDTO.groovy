package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.SuccessioniDefunti;

import java.util.Date;
import java.util.Map;

public class SuccessioniDefuntiDTO implements it.finmatica.dto.DTO<SuccessioniDefunti> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String cittaNas;
    String cittaRes;
    String codFiscale;
    String cognome;
    String comune;
    Date dataApertura;
    Date dataNas;
    Date lastUpdated;
    String indirizzo;
    String nome;
    String note;
    Integer numero;
    Long pratica;
    String provNas;
    String provRes;
    String sesso;
    Short sottonumero;
    String statoSuccessione;
    String tipoDichiarazione;
    String ufficio;
    Ad4UtenteDTO	utente;
    Integer volume;


    public SuccessioniDefunti getDomainObject () {
        return SuccessioniDefunti.get(this.id)
    }
    public SuccessioniDefunti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
