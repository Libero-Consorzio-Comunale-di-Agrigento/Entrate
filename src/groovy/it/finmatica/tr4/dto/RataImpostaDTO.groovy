package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.RataImposta;

import java.util.Map;

public class RataImpostaDTO implements it.finmatica.dto.DTO<RataImposta> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal addizionaleEca;
    BigDecimal addizionalePro;
    Short anno;
    String codFiscale;
    Integer contoCorrente;
    BigDecimal imposta;
    BigDecimal impostaRound;
    BigDecimal iva;
    BigDecimal maggiorazioneEca;
    String note;
    Long numBollettino;
    Long oggettoImposta;
    Byte rata;
    String tipoTributo;
    Ad4UtenteDTO	utente;


    public RataImposta getDomainObject () {
        return RataImposta.get(this.id)
    }
    public RataImposta toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
