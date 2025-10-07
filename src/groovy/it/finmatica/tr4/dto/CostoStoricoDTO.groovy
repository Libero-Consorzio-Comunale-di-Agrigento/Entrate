package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.CostoStorico;
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO;

import java.util.Date;
import java.util.Map;

public class CostoStoricoDTO implements it.finmatica.dto.DTO<CostoStorico> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    BigDecimal costo;
    Date lastUpdated;
    String note;
    OggettoPraticaDTO oggettoPratica;
    Ad4UtenteDTO	utente;


    public CostoStorico getDomainObject () {
        return CostoStorico.createCriteria().get {
            eq('oggettoPratica.id', this.oggettoPratica.id)
            eq('anno', this.anno)
        }
    }
    public CostoStorico toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
