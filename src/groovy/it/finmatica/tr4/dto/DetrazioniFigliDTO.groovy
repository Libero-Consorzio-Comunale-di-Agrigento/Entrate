package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.DetrazioniFigli;

import java.util.Date;
import java.util.Map;

public class DetrazioniFigliDTO implements it.finmatica.dto.DTO<DetrazioniFigli> {
    private static final long serialVersionUID = 1L;

    Long id;
    Byte aMese;
    Short anno;
    String codFiscale;
    Byte daMese;
    Date lastUpdated;
    BigDecimal detrazione;
    BigDecimal detrazioneAcconto;
    String note;
    Byte numeroFigli;
    Ad4UtenteDTO	utente;


    public DetrazioniFigli getDomainObject () {
        return DetrazioniFigli.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('daMese', this.daMese)
        }
    }
    public DetrazioniFigli toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
