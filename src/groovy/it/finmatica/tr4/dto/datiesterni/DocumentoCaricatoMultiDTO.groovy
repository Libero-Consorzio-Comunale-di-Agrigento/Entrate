package it.finmatica.tr4.dto.datiesterni

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.datiesterni.DocumentoCaricatoMulti

class DocumentoCaricatoMultiDTO implements DTO<DocumentoCaricatoMulti> {
    private static final long serialVersionUID = 1L

    Long id
    byte[] contenuto
    byte[] contenuto2
    Date lastUpdated
    Long documentoId
    String nomeDocumento
    String nomeDocumento2
    String note
    Ad4UtenteDTO utente
    DocumentoCaricatoDTO documentoCaricato


    DocumentoCaricatoMulti getDomainObject() {
        return DocumentoCaricatoMulti.createCriteria().get {
            eq('id', this.id)
        }
    }

    DocumentoCaricatoMulti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
