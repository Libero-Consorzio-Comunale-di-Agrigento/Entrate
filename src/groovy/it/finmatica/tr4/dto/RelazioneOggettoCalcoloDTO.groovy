package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RelazioneOggettoCalcolo

public class RelazioneOggettoCalcoloDTO implements it.finmatica.dto.DTO<RelazioneOggettoCalcolo> {

    private static final long serialVersionUID = 1L

    Long id
    Short anno
    TipoAliquotaDTO tipoAliquota
    TipoOggettoDTO tipoOggetto
    CategoriaCatastoDTO categoriaCatasto

    // Non su db
    def catCatastoString

    public RelazioneOggettoCalcolo getDomainObject() {
        return RelazioneOggettoCalcolo.get(this.id)
    }

    public RelazioneOggettoCalcolo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
