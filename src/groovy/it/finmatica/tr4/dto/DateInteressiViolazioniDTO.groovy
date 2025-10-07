package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.commons.*
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.DateInteressiViolazioni

class DateInteressiViolazioniDTO implements DTO<DateInteressiViolazioni> {

    private static final long serialVersionUID = 1L

    TipoTributoDTO tipoTributo
    Short anno
    Date dataAttoDa
    Date dataAttoA
    Date dataInizio
    Date dataFine

    public DateInteressiViolazioni getDomainObject () {
        return DateInteressiViolazioni.createCriteria().get {
            eq('tipoTributo', this.tipoTributo.getDomainObject())
            eq('anno', this.anno)
            eq('dataAttoDa', this.dataAttoDa)
        }
    }

    public DateInteressiViolazioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
}
