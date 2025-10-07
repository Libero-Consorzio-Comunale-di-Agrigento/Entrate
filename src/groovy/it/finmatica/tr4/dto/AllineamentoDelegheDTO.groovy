package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.AllineamentoDeleghe;

import java.util.Date;
import java.util.Map;

public class AllineamentoDelegheDTO implements it.finmatica.dto.DTO<AllineamentoDeleghe> {
    private static final long serialVersionUID = 1L;

    Long id;
    String cinBancario;
    Integer codAbi;
    Integer codCab;
    String codControlloCc;
    String codFiscale;
    String codiceFiscaleInt;
    String cognomeNomeInt;
    String contoCorrente;
    Date dataInvio;
    Date lastUpdated;
    Byte ibanCinEuropa;
    String ibanPaese;
    String note;
    String stato;
    String tipoTributo;
    Ad4UtenteDTO	utente;


    public AllineamentoDeleghe getDomainObject () {
        return AllineamentoDeleghe.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('tipoTributo', this.tipoTributo)
        }
    }
    public AllineamentoDeleghe toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
