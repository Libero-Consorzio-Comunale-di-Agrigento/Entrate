package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.RidImpagati;

import java.util.Date;
import java.util.Map;

public class RidImpagatiDTO implements it.finmatica.dto.DTO<RidImpagati> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String causale;
    String causaleStorno;
    String codFiscale;
    Date lastUpdated;
    Long documentoId;
    BigDecimal fattura;
    BigDecimal importoImpagato;
    String note;
    Long ruolo;
    String tipoTributo;
    Ad4UtenteDTO	utente;


    public RidImpagati getDomainObject () {
        return RidImpagati.createCriteria().get {
            eq('documentoId', this.documentoId)
            eq('fattura', this.fattura)
        }
    }
    public RidImpagati toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
