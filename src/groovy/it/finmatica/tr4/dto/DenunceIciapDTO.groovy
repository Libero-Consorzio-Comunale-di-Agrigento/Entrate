package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.DenunceIciap;

import java.util.Date;
import java.util.Map;

public class DenunceIciapDTO implements it.finmatica.dto.DTO<DenunceIciap> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codAttivita;
    Boolean coeffReddito;
    BigDecimal consistenza;
    BigDecimal coperta;
    Date dataCompilazione;
    Date dataIntegrazione;
    Date lastUpdated;
    String desProf;
    String flagAlbo;
    String flagCf;
    String flagDenunciante;
    String flagFirma;
    String flagSettore;
    String flagStagionale;
    String flagVersamento;
    BigDecimal importoIntegrazione;
    BigDecimal locale;
    String note;
    Byte numUip;
    BigDecimal reddito;
    String redditoZero;
    BigDecimal riduzione;
    BigDecimal scoperta;
    Byte settore;
    BigDecimal superficie;
    Ad4UtenteDTO	utente;


    public DenunceIciap getDomainObject () {
        return DenunceIciap.get(this.id)
    }
    public DenunceIciap toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
