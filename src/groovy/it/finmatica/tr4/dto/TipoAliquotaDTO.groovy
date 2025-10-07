package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoAliquota

class TipoAliquotaDTO implements DTO<TipoAliquota> {
    private static final long serialVersionUID = 1L

    String descrizione
    Integer tipoAliquota
    TipoTributoDTO tipoTributo

    Set<AliquotaDTO> aliquote

    TipoAliquota getDomainObject() {
        return TipoAliquota.createCriteria().get {
            eq('tipoTributo.tipoTributo', this?.tipoTributo?.tipoTributo)
            eq('tipoAliquota', this?.tipoAliquota)
        }
    }

    TipoAliquota toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    void addToAliquote(AliquotaDTO aliquota) {
        if (this.aliquote == null) {
            this.aliquote = new HashSet<AliquotaDTO>()
        }
        this.aliquote.add(aliquota)
        aliquota.tipoAliquota = this
    }

    void removeToAliquote(AliquotaDTO aliquota) {
        if (this.aliquote == null) {
            this.aliquote = new HashSet<AliquotaDTO>()
        }
        this.aliquote.remove(aliquota)
        aliquota.tipoAliquota = null
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
