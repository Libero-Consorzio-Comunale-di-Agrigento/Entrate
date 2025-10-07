package it.finmatica.tr4.portale

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.dto.portale.SprVIciPraticheDettagliDTO
import it.finmatica.tr4.dto.portale.SprVPraticheDTO

import java.sql.CallableStatement

class IMUIntegrazionePortaleStrategy extends AbstractIntegrazionePortaleStrategy {

    private static final String TIPO_TRIBUTO_ICI = "ICI"
    private static final String CODICE_APPLICATIVO_ICI = "TR4_ICI"
    final static def CODICE_TRACCIATO = "PWEB"

    SpringSecurityService springSecurityService

    List<SprVIciPraticheDettagliDTO> elencoDettagliPratica(Long idPratica) {
        log.debug "Recupero dettagli $TIPO_TRIBUTO_ICI per pratica id: ${idPratica}"
        return SprVIciPraticheDettagli.createCriteria().list() {
            eq('idPratica', idPratica)
        }.toDTO()
    }

    String acquisisciPratiche(List<SprVPraticheDTO> praticheDaAcquisire) {
        String utente = springSecurityService.principal.username
        String msg = "Acquisizione IMU completata con errori o avvisi."
        DocumentoCaricato documentoCaricato = null

        try {

            documentoCaricato = creaDocumentoCaricatoComune(utente)

            def progrDichiarazione = 1
            praticheDaAcquisire.each { praticaDto ->
                log.info "Acquisizione pratica ${praticaDto.idPratica} (Tipo: $TIPO_TRIBUTO_ICI) con strategy ${this.class.simpleName}..."

                def wrkTestataDto = praticaDto.toEncTestata(documentoCaricato.id, progrDichiarazione++, CODICE_TRACCIATO)
                def wrkTestataDomain = wrkTestataDto.toDomain().save(flush: true, failOnError: true)
                log.info "Creata WrkEncTestata [id: ${wrkTestataDomain.id}, progrDichiarazione: ${wrkTestataDto.progrDichiarazione}]"

                List<SprVIciPraticheDettagliDTO> dettagliPraticaRecuperati = elencoDettagliPratica(praticaDto.idPratica)
                dettagliPraticaRecuperati.each { dettaglioDto ->
                    salvaDettaglioPratica(dettaglioDto, documentoCaricato.id, wrkTestataDto.progrDichiarazione, wrkTestataDomain.id)
                }

                settaAcquisitaDb(praticaDto.idPratica)

                log.info "Importazione del documento ${documentoCaricato.id} (Tipo: $TIPO_TRIBUTO_ICI in corso..."
                msg = eseguiCaricamentoDb(documentoCaricato.id, utente)
                log.info "Importazione eseguita per documento ${documentoCaricato.id}: ${msg}"

            }

            return msg ?: "Importazione IMU completata senza messaggio di ritorno specifico."

        } catch (Exception e) {
            log.error("Errore durante l'importazione dei dati da Portale per tipo tributo $TIPO_TRIBUTO_ICI con strategy ${this.class.simpleName}", e)
            throw e
        }
    }

    protected salvaDettaglioPratica(Object dettaglioDto, Long documentoCaricatoId, Integer progrTestataPadre, Long idTestataPadre) {
        SprVIciPraticheDettagliDTO iciDettaglio = dettaglioDto

        def wrkImmobileDto = iciDettaglio.toWrkEncImmobili(documentoCaricatoId, progrTestataPadre)
        def wrkImmobileDomain = wrkImmobileDto.toDomain().save(flush: true, failOnError: true)

        log.info "Creato WrkEncImmobili [id: ${wrkImmobileDomain.id}, progrImmobile: ${wrkImmobileDto.progrImmobile}] per Testata id: ${idTestataPadre}, progrTestata: ${progrTestataPadre}"
    }

    protected DocumentoCaricato creaDocumentoCaricatoComune(String utente) {
        String nomeDocumento = "Acquisizione da portale (${tipoTributoSupportato}) ${new Date().format('yyyyMMdd-HHmmss')}"
        DocumentoCaricato doc = new DocumentoCaricato(
                titoloDocumento: TitoloDocumento.findById(ID_TITOLO_DOCUMENTO_ACQUISIZIONE_PORTALE),
                nomeDocumento: nomeDocumento,
                stato: 1, // Assumiamo stato 1 = 'Da Elaborare'
                utente: utente
        ).save(flush: true, failOnError: true)
        log.info "Creato DocumentoCaricato [id: ${doc.id}, nome: ${nomeDocumento}] (Strategy: ${tipoTributoSupportato})"
        return doc
    }

    protected eseguiCaricamentoDb(long idDocumento, String utente) {

        String messaggio = ""
        try {
            sessionFactory.currentSession.doWork { connection ->
                CallableStatement call = connection.prepareCall("{call CARICA_DIC_ENC_ECPF.ESEGUI_WEB(?, ?, ?)}")
                call.setLong(1, idDocumento)
                call.setString(2, utente)
                call.registerOutParameter(3, java.sql.Types.VARCHAR)
                call.execute()
                messaggio = call.getString(3)
            }
        } catch (Exception e) {
            log.error("Errore esecuzione CARICA_DIC_ENC_ECPF.ESEGUI_WEB per documento ${idDocumento}", e)
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n') ?: e.message.length())
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n') ?: e.cause.cause.message.length())
            } else {
                messaggio = "Errore imprevisto durante l'esecuzione della procedura DB: ${e.getMessage()}"
            }
        }
        return messaggio
    }

    @Override
    String getTipoTributoSupportato() {
        return TIPO_TRIBUTO_ICI
    }

    @Override
    String getCodiceApplicativo() {
        return CODICE_APPLICATIVO_ICI
    }
}
