package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.DetrazioniFigliCtr;

import java.util.Date;
import java.util.Map;

public class DetrazioniFigliCtrDTO implements it.finmatica.dto.DTO<DetrazioniFigliCtr> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String codFiscale;
    Date dataRiferimento;
    Date lastUpdated;
    BigDecimal detrazione;
    BigDecimal detrazioneAcconto;
    String note;
    Byte numeroFigli;
    Ad4UtenteDTO	utente;


    public DetrazioniFigliCtr getDomainObject () {
        return DetrazioniFigliCtr.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('dataRiferimento', this.dataRiferimento)
        }
    }
    public DetrazioniFigliCtr toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
