package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.DetrazioniFigliOgim;

import java.util.Date;
import java.util.Map;

public class DetrazioniFigliOgimDTO implements it.finmatica.dto.DTO<DetrazioniFigliOgim> {
    private static final long serialVersionUID = 1L;

    Long id;
    Byte aMese;
    Byte daMese;
    Date lastUpdated;
    BigDecimal detrazione;
    BigDecimal detrazioneAcconto;
    String note;
    Byte numeroFigli;
    Long oggettoImposta;
    Ad4UtenteDTO	utente;


    public DetrazioniFigliOgim getDomainObject () {
        return DetrazioniFigliOgim.createCriteria().get {
            eq('oggettoImposta', this.oggettoImposta)
            eq('daMese', this.daMese)
        }
    }
    public DetrazioniFigliOgim toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
