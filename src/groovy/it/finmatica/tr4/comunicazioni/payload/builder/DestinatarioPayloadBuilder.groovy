package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.DestinatarioPayload

class DestinatarioPayloadBuilder extends AbstractBuilder<DestinatarioPayload> {

    def DestinatarioPayload destinatario

    DestinatarioPayload crea(Closure definizione) {
        destinatario = new DestinatarioPayload()
        runClosure definizione
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
