package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Detrazione

public class DetrazioneDTO implements it.finmatica.dto.DTO<Detrazione> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aliquota;
    short anno;
    BigDecimal detrazione;
    BigDecimal detrazioneBase;
    BigDecimal detrazioneFiglio;
    BigDecimal detrazioneImponibile;
    BigDecimal detrazioneMaxFigli;
    String flagPertinenze;
    TipoTributoDTO tipoTributo;


    public Detrazione getDomainObject () {
        return Detrazione.createCriteria().get {
            eq('tipoTributo.tipoTributo', this?.tipoTributo?.tipoTributo)
            eq('anno', this?.anno)
        }
    }
    public Detrazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
