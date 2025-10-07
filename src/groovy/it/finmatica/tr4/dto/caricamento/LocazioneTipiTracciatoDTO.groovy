package it.finmatica.tr4.dto.caricamento

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.caricamento.LocazioneTipiTracciato

class LocazioneTipiTracciatoDTO implements DTO<LocazioneTipiTracciato> {

    Long id
    Long titoloDocumento
    Date dataInizio
    Date dataFine
    String tipoLocazione
    String tracciato

    LocazioneTipiTracciato getDomainObject() {
        return LocazioneTipiTracciato.get(tipoTracciato)
    }

    public LocazioneTipiTracciato toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
