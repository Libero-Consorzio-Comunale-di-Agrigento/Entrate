package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.ContattoContribuente
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class ContattoContribuenteDTO implements DTO<ContattoContribuente> {
    private static final long serialVersionUID = 1L

    Long id
    Short anno
    ContribuenteDTO contribuente
    Date data
    Integer numero
    Short sequenza
    String testo
    TipoContattoDTO tipoContatto
    TipoRichiedenteDTO tipoRichiedente
    TipoTributoDTO tipoTributo
    PraticaTributoDTO pratica


    ContattoContribuente getDomainObject () {
        return ContattoContribuente.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('sequenza', this.sequenza)
        }
    }

    ContattoContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
