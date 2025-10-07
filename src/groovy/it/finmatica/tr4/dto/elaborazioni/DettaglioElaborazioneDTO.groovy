package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.EredeSoggettoDTO
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.elaborazioni.DettaglioElaborazione

class DettaglioElaborazioneDTO implements DTO<DettaglioElaborazione> {

    def id
    PraticaTributoDTO pratica
    ContribuenteDTO contribuente
    String flagSelezionato
    Long stampaId
    Long documentaleId
    Long tipografiaId
    Long avvisoAgidId
    Long appioId
    Long anagrId
	Long controlloAtId
	Long allineamentoAtId
    String nomeFile
    Integer numPagine
    // byte[] documento
    String utente
    Date dataVariazione
    String note
    ElaborazioneMassivaDTO elaborazione
    EredeSoggettoDTO eredeSoggetto

    @Override
    DettaglioElaborazione getDomainObject() {
        return DettaglioElaborazione.get(id)
    }

    DettaglioElaborazione toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}

