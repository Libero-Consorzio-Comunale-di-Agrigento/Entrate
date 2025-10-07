package it.finmatica.tr4.dto.datiesterni


import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.dto.CivicoOggettoDTO
import it.finmatica.tr4.dto.UtilizzoOggettoDTO

import java.sql.Blob
import java.util.Set

class DocumentoCaricatoDTO implements DTO<DocumentoCaricato> {
    private static final long serialVersionUID = 1L

    Long id
    String cartellaDocMulti
    byte[] contenuto
    Date lastUpdated
    String nomeDocumento
    String note
    Short stato
    TitoloDocumentoDTO titoloDocumento
    Ad4UtenteDTO utente
    Set<DocumentoCaricatoMultiDTO> documentiCaricatiMulti
	So4AmministrazioneDTO 	ente

    DocumentoCaricato getDomainObject() {
        return DocumentoCaricato.get(this.id)
    }

    DocumentoCaricato toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    void addToDocumentiCaricatiMulti(DocumentoCaricatoMultiDTO documentoCaricatoMulti) {
		if (this.documentiCaricatiMulti == null)
			this.documentiCaricatiMulti = new HashSet<DocumentoCaricatoMultiDTO>()
        this.documentiCaricatiMulti.add(documentoCaricatoMulti)
		documentoCaricatoMulti.documentoId = this
	}

    void removeFromDocumentiCaricatiMulti(DocumentoCaricatoMultiDTO documentoCaricatoMulti) {
		if (this.documentiCaricatiMulti == null)
			this.documentiCaricatiMulti = new HashSet<CivicoOggettoDTO>()
        this.documentiCaricatiMulti.remove(documentoCaricatoMulti)
		documentoCaricatoMulti.documentoId = null
	}


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
