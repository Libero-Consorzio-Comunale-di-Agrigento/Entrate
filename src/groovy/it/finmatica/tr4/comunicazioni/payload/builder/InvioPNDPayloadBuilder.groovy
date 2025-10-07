package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.InvioPNDPayload

class InvioPNDPayloadBuilder extends AbstractBuilder {

    private InvioPNDPayload invioPND

    InvioPNDPayload crea(Closure definizione) {
        invioPND = new InvioPNDPayload()
        runClosure definizione
        if (!invioPND.validate()) {
            throw validationThrowable(invioPND.errors.allErrors)
        }
        return invioPND
    }

    void destinatario(Closure destinatario) {
        invioPND.destinatari = invioPND.destinatari ?: []
        invioPND.destinatari += (new DestinatarioPNDPayloadBuilder()).crea(destinatario)
    }

    void notificationFeePolicy(FlagNotificationFeePolicy value) {
        invioPND.notificationFeePolicy = value.value
    }

    void physicalCommunicationType(FlagPhysicalCommunicationType value) {
        invioPND.physicalCommunicationType = value.value
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, invioPND)
    }

}
