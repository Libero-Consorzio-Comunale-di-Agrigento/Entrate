package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.InvioMailPayload

class InvioMailPayloadBuilder extends AbstractBuilder {

    private InvioMailPayload invioMail

    InvioMailPayload crea(Closure definizione) {
        invioMail = new InvioMailPayload()
        runClosure definizione
        return invioMail
    }

    void destinatario(Closure destinatario) {
        invioMail.destinatari = invioMail.destinatari ?: []
        invioMail.destinatari += (new DestinatarioPayloadBuilder()).crea(destinatario)
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, invioMail)
    }

}
