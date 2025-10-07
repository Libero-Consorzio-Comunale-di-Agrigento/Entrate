package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

public class DocumentoContribuenteDTO implements DTO<DocumentoContribuente> {
    private static final long serialVersionUID = 1L

    static TITOLO_LENGTH = 130

    Long id
    ContribuenteDTO contribuente
    Date dataInserimento
    Date lastUpdated
    byte[] documento
    String informazioni
    String nomeFile
    String note
    Short sequenza
    String titolo
    Ad4UtenteDTO utente
    Date validitaAl
    Date validitaDal

    Long idDocumentoGdm
    Long idMessaggio
    Long idRiferimento
    Short annoProtocollo
    Long numeroProtocollo
    String dataInvioPec
    String dataRicezionePec
    PraticaTributoDTO pratica
    Long idComunicazionePnd
    String dataSpedizionePnd
    String statoPnd
    Byte tipoCanale

    Short sequenzaPrincipale

    public DocumentoContribuente getDomainObject() {
        return DocumentoContribuente.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('sequenza', this.sequenza)
        }
    }

    public DocumentoContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
