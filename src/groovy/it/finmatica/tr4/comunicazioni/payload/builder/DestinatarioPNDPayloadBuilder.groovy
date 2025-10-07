package it.finmatica.tr4.comunicazioni.payload.builder

import it.finmatica.tr4.comunicazioni.payload.DestinatarioPNDPayload

class DestinatarioPNDPayloadBuilder extends AbstractBuilder<DestinatarioPNDPayload> {

    DestinatarioPNDPayload destinatario

    DestinatarioPNDPayload crea(Closure definizione) {
        destinatario = new DestinatarioPNDPayload()
        runClosure definizione
        if (!destinatario.validate()) {
            throw validationThrowable(destinatario.errors.allErrors)
        }
        return destinatario
    }

    void tipoDestinatario(FlagTipoDestinatario value) {
        destinatario.tipoDestinatario = value.value
    }

    void tipoInvio(FlagTipoInvio value) {
        destinatario.tipoInvio = value.value
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, destinatario)
    }
}
