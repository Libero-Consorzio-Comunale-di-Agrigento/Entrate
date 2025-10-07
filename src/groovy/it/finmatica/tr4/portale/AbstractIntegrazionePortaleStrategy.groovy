package it.finmatica.tr4.portale


import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.TitoloDocumento
import org.apache.commons.logging.LogFactory
import org.hibernate.SessionFactory

import java.sql.CallableStatement

abstract class AbstractIntegrazionePortaleStrategy implements IntegrazionePortaleStrategy {

    protected final log = LogFactory.getLog(getClass())

    protected static final String STEP_ACQUISITO = "ACQUISITO"
    protected static final Long ID_TITOLO_DOCUMENTO_ACQUISIZIONE_PORTALE = 40L

    SessionFactory sessionFactory

    /**
     * Aggiorna lo step di una pratica nel database.
     * @param idPratica L'ID della pratica da aggiornare.
     * @return true se l'aggiornamento ha avuto successo, false altrimenti.
     */
    protected boolean settaAcquisitaDb(Long idPratica) {
        String applicativo = codiceApplicativo
        log.info "Aggiornamento step pratica ${idPratica} con applicativo ${applicativo}, step ${STEP_ACQUISITO} (Strategy: ${tipoTributoSupportato})"
        try {
            sessionFactory.currentSession.doWork { connection ->
                CallableStatement callableStatement = connection.prepareCall("{call spr_pratiche_pkg.upd_step_pratica(?, ?, ?)}")
                callableStatement.setLong(1, idPratica)
                callableStatement.setString(2, applicativo)
                callableStatement.setString(3, STEP_ACQUISITO)
                callableStatement.execute()
            }
            log.info "Step pratica ${idPratica} aggiornato con successo."
            return true
        } catch (Exception e) {
            log.error("Errore aggiornamento step pratica ${idPratica}, applicativo ${applicativo} (Strategy: ${tipoTributoSupportato})", e)
            return false // O rilanciare l'eccezione se preferito
        }
    }
}
