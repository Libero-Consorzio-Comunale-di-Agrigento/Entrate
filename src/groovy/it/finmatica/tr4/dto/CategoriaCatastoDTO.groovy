package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CategoriaCatasto

public class CategoriaCatastoDTO implements DTO<CategoriaCatasto> {
    private static final long serialVersionUID = 1L

    String categoriaCatasto
    String descrizione
    String eccezione
    boolean flagReale


    public CategoriaCatasto getDomainObject() {
        return CategoriaCatasto.findByCategoriaCatasto(this.categoriaCatasto)
    }

    public CategoriaCatasto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    public String toString() {

        if (!categoriaCatasto || !descrizione) {
            return null
        }

        return "$categoriaCatasto - $descrizione"
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
