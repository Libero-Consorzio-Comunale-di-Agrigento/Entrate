package it.finmatica.tr4.comunicazioni.payload.builder


import grails.util.Holders
import it.finmatica.tr4.comunicazioni.ComunicazioniValidationException
import org.springframework.context.MessageSource
import org.springframework.validation.ObjectError

abstract class AbstractBuilder<T> {

    protected runClosure(Closure runClosure) {
        // Create clone of closure for threading access.
        Closure runClone = runClosure.clone()

        // Set delegate of closure to this builder.
        runClone.delegate = this

        // And only use this builder as the closure delegate.
        runClone.resolveStrategy = Closure.DELEGATE_ONLY

        // Run closure code.
        runClone()
    }

    protected settaValori(String name, def arguments, def obj) {
        def method = obj.metaClass.methods
                .find { it.name == "set${name.capitalize()}" }
        if (method) {
            method.invoke(obj, *arguments)
        } else {
            throw new RuntimeException("Metodo [$name] non definito")
        }
    }

    protected validationThrowable(List<ObjectError> errors) {
        def messageSource = (MessageSource) Holders.grailsApplication.mainContext.getBean("messageSource")

        def error = messageSource.getMessage(errors[0], Locale.default)

        return new ComunicazioniValidationException(error)
    }
}
