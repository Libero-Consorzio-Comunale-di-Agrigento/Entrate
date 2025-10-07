package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.InvioAppIOPayload

class InvioAppIOPayloadBuilder extends AbstractBuilder {

    private InvioAppIOPayload invioAppIO

    InvioAppIOPayload crea(Closure definizione) {
        invioAppIO = new InvioAppIOPayload()
        runClosure definizione
        return invioAppIO
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, invioAppIO)
    }

}
