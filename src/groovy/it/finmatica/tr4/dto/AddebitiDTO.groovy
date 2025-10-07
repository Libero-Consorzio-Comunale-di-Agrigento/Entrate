package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.Addebiti;

import java.util.Date;
import java.util.Map;

public class AddebitiDTO implements it.finmatica.dto.DTO<Addebiti> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abi;
    String cab;
    String codFiscale;
    String codiceControllo;
    String cognomeNomeORagioneSociale;
    Date lastUpdated;
    String note;
    String numeroCCorrente;
    String tributo;
    Ad4UtenteDTO	utente;


    public Addebiti getDomainObject () {
        return Addebiti.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('tributo', this.tributo)
            eq('cognomeNomeORagioneSociale', this.cognomeNomeORagioneSociale)
            eq('abi', this.abi)
            eq('cab', this.cab)
            eq('numeroCCorrente', this.numeroCCorrente)
            eq('codiceControllo', this.codiceControllo)
            eq('utente', this.utente)
            eq('lastUpdated', this.lastUpdated)
            eq('note', this.note)
        }
    }
    public Addebiti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
