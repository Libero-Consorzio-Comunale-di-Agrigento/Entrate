package it.finmatica.tr4.dto;

import it.finmatica.tr4.ConsistenzaTributo;

import java.util.Map;

public class ConsistenzaTributoDTO implements it.finmatica.dto.DTO<ConsistenzaTributo> {
    private static final long serialVersionUID = 1L;

	BigDecimal consistenza;
    boolean flagEsenzione;
    TipoTributoDTO tipoTributo;
	PartizioneOggettoDTO partizioneOggetto

    public ConsistenzaTributo getDomainObject () {
        return ConsistenzaTributo.createCriteria().get {
            eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
            eq('partizioneOggetto.oggetto.id', this.partizioneOggetto.oggetto.id)
			eq('partizioneOggetto.sequenza', this.partizioneOggetto.sequenza)
        }
    }
    public ConsistenzaTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
