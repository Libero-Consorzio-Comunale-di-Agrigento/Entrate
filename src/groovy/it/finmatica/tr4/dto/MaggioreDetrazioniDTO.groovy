package it.finmatica.tr4.dto;

import it.finmatica.tr4.MaggioreDetrazione;

import java.util.Map;

public class MaggioreDetrazioniDTO implements it.finmatica.dto.DTO<MaggioreDetrazione> {
    private static final long serialVersionUID = 1L;

    Short anno
    ContribuenteDTO contribuente
    BigDecimal detrazione
    BigDecimal detrazioneAcconto
    BigDecimal detrazioneBase
    String flagDetrazionePossesso
    int motDetrazione
    String note
    TipoTributoDTO tipoTributo
	MotivoDetrazioneDTO motivoDetrazione

    public MaggioreDetrazione getDomainObject () {
        return MaggioreDetrazione.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
            eq('anno', this.anno)
        }
    }
	
    public MaggioreDetrazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
