package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.PraticaTributo

class DocumentoContribuente implements Serializable {

    Short sequenza
    String titolo
    String nomeFile
    byte[] documento
    Date dataInserimento
    Date validitaDal
    Date validitaAl
    Date lastUpdated
    String informazioni
    Ad4Utente utente

    Long idDocumentoGdm
    Long idMessaggio
    Long idRiferimento
    Short annoProtocollo
    Long numeroProtocollo
    String dataInvioPec
    String dataRicezionePec
    PraticaTributo pratica
    Long idComunicazionePnd
    String dataSpedizionePnd
    String statoPnd
    String note
    Byte tipoCanale

    Short sequenzaPrincipale

    static belongsTo = [contribuente: Contribuente]


    static mapping = {
        id composite: ["contribuente", "sequenza"]
        contribuente column: "cod_fiscale"
        table 'documenti_contribuente'
        version false
        dataInserimento sqlType: 'Date'
        validitaDal sqlType: 'Date'
        validitaAl sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        utente column: "utente", ignoreNotFound: true
        pratica column: "pratica"
    }

    static constraints = {
        contribuente maxSize: 16
        sequenza nullable: true
        sequenzaPrincipale nullable: true
        titolo nullable: true, maxSize: 130
        nomeFile nullable: true
        documento nullable: true
        dataInserimento nullable: true
        validitaDal nullable: true
        validitaAl nullable: true
        informazioni nullable: true, maxSize: 2000
        utente nullable: true, maxSize: 8
        lastUpdated nullable: true
        note nullable: true, maxSize: 2000
        idDocumentoGdm nullable: true
        idMessaggio nullable: true
        idRiferimento nullable: true
        annoProtocollo nullable: true
        numeroProtocollo nullable: true
        dataInvioPec nullable: true
        dataRicezionePec nullable: true
        pratica nullable: true
        idComunicazionePnd nullable: true
        dataSpedizionePnd nullable: true
        statoPnd nullable: true
        tipoCanale nullable: true
    }

    void beforeDelete() {
        DocumentoContribuente.withNewSession {
            DocumentoContribuente.findAllByContribuenteAndSequenzaPrincipale(contribuente, sequenza)
                    .each {
                        it.delete(flush: true)
                    }
        }
    }
}
