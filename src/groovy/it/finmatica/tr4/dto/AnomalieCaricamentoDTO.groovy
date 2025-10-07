package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.AnomalieCaricamento

class AnomalieCaricamentoDTO implements DTO<AnomalieCaricamento> {
    private static final long serialVersionUID = 1L

    Long id
    String codFiscale
    String cognome
    String datiOggetto
    String descrizione
    Long documentoId
    String nome
    String note
    Long oggetto
    Short sequenza


    AnomalieCaricamento getDomainObject() {
        return AnomalieCaricamento.createCriteria().get {
            eq('documentoId', this.documentoId)
            eq('sequenza', this.sequenza)
        }
    }

    AnomalieCaricamento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
