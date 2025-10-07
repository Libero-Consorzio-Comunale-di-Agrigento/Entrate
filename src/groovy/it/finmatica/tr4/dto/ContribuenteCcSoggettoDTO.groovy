package it.finmatica.tr4.dto

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.ContribuenteCcSoggetto
import it.finmatica.tr4.dto.ContribuenteDTO

class ContribuenteCcSoggettoDTO implements it.finmatica.dto.DTO<ContribuenteCcSoggetto> {
    private static final long serialVersionUID = 1L

    Long id
    ContribuenteDTO contribuente
    Long id_soggetto
    String note
    Ad4UtenteDTO utente
    SoggettoDTO soggetto

    public ContribuenteCcSoggetto getDomainObject() {
        return ContribuenteCcSoggetto.get(id)
    }

    public ContribuenteCcSoggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
