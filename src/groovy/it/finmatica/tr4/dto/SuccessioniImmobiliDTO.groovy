package it.finmatica.tr4.dto;

import it.finmatica.tr4.SuccessioniImmobili;

import java.util.Map;

public class SuccessioniImmobiliDTO implements it.finmatica.dto.DTO<SuccessioniImmobili> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short annoDenuncia;
    String catasto;
    Integer denominatoreQuotaDef;
    String denuncia1;
    String denuncia2;
    String diritto;
    String foglio;
    String indirizzo;
    String natura;
    BigDecimal numeratoreQuotaDef;
    Long oggetto;
    String particella1;
    String particella2;
    Short progrImmobile;
    Short progrParticella;
    Integer progressivo;
    String sezione;
    Short subalterno1;
    String subalterno2;
    Long successione;
    Integer superficieEttari;
    BigDecimal superficieMq;
    BigDecimal vani;


    public SuccessioniImmobili getDomainObject () {
        return SuccessioniImmobili.createCriteria().get {
            eq('successione', this.successione)
            eq('progressivo', this.progressivo)
        }
    }
    public SuccessioniImmobili toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
