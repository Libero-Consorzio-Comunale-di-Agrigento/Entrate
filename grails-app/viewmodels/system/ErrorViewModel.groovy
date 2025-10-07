package system

import grails.validation.ValidationException
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeException
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.StaleObjectStateException
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.dao.QueryTimeoutException
import org.springframework.orm.hibernate3.HibernateJdbcException
import org.springframework.orm.hibernate3.HibernateOptimisticLockingFailureException
import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.UiException
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window
import wslite.rest.RESTClientException

import java.sql.SQLException

class ErrorViewModel {

    private static Log log = LogFactory.getLog(ErrorViewModel.class)

    // Service
    CommonService commonService

    // component
    def self

    // eccezione
    def title

    // mostrare dettagli
    def dettagli = false

    // auto closable
    def autoClosable = false
    def autoTime = 2500

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        self = w
        Throwable exception = Executions.getCurrent().getAttribute("javax.servlet.error.exception")
        log.error(exception.message, exception)
        def cause = (exception instanceof UiException ? exception.cause : null)
        if (cause != null) {
            checkException(cause)
        } else {
            checkException(exception)
        }
    }

    private void checkException(Throwable e) {
        if (e instanceof DataIntegrityViolationException) {
            title = "Record non modificabile o eliminabile: esistono dipendenze."
        } else if (e instanceof StaleObjectStateException || e instanceof HibernateOptimisticLockingFailureException) {
            title = "Record modificato da un altro utente."
        } else if (e instanceof ValidationException) {
            title = "Verificare i campi compilati"
        } else if (e instanceof HibernateJdbcException) {
            title = e.getSQLException().message
        } else if (e instanceof RESTClientException) {
            title = "Errore di comunicazione con il servizio"
        } else if (e instanceof CompetenzeException) {
            // Se exception da competenze non si mostra la dialog, ma solo un messaggio di errore.
            Clients.showNotification(e.message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 3000, true)
            Events.postEvent("onClose", self, null)
        } else if (e instanceof Application20999Error) {
            Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            Events.postEvent("onClose", self, null)
        } else if (e instanceof SQLException || e instanceof QueryTimeoutException) {
            def message = commonService.extractOraMessage(e, "ORA-20999")
            def oraError = ["ORA-20006", "ORA-20007"]

            if (message.empty) {
                oraError.each {
                    def errorMessage = commonService.extractOraMessage(e, it)
                    message += "${errorMessage}${errorMessage.empty ? '' : '\n'}"
                }
            }

            if (!message.empty) {
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                Events.postEvent("onClose", self, null)
            } else {
                title = "Errore generico:\n\n ${e.message}"
            }
        } else {
            title = "Errore generico:\n\n ${e.message}"
        }
    }

    @Command
    onClose(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        dettagli = false
        Events.postEvent("onClose", self, null)
    }

    @Command
    checkClose(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        if (autoClosable)
            Events.postEvent("onClose", self, null)
    }

}
