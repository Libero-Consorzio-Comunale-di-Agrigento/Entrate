package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RivalutazioneRendita

public class RivalutazioneRenditaDTO implements DTO<RivalutazioneRendita>, Cloneable {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aliquota;
    Short anno;
    TipoOggettoDTO tipoOggetto;


    public RivalutazioneRendita getDomainObject() {
        return RivalutazioneRendita.createCriteria().get {
            eq('anno', this.anno)
            eq('tipoOggetto.tipoOggetto', this.tipoOggetto.tipoOggetto)
        }
    }

    public RivalutazioneRendita toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as RivalutazioneRendita
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori*/
    public RivalutazioneRenditaDTO() {}

    public RivalutazioneRenditaDTO(TipoOggettoDTO to) {
        this.tipoOggetto = new TipoOggettoDTO(to.tipoOggetto, to.descrizione)
    }

    @Override
    public RivalutazioneRenditaDTO clone(){
        def clone = new RivalutazioneRenditaDTO(this.tipoOggetto)
        clone.anno = new Short(this.anno)
        clone.aliquota = new BigDecimal(this.aliquota)
        return clone
    }

}
