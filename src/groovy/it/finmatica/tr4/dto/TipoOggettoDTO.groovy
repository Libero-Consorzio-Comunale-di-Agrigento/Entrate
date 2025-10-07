package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoOggetto

public class TipoOggettoDTO implements it.finmatica.dto.DTO<TipoOggetto> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    long tipoOggetto;
	Set<OggettoTributoDTO> oggettiTributo;
	Set<RivalutazioneRenditaDTO> rivalutazioniRendita;

    public TipoOggetto getDomainObject () {
        return TipoOggetto.get(this.tipoOggetto)
    }
    public TipoOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as TipoOggetto
    }
	
	public String toString() {
		return "$tipoOggetto - $descrizione"
	}


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori*/
    public TipoOggettoDTO() {}

    public TipoOggettoDTO(Long tipoOggetto, String descrizione) {
        if (tipoOggetto) this.tipoOggetto = tipoOggetto
        this.descrizione = descrizione
    }

}
