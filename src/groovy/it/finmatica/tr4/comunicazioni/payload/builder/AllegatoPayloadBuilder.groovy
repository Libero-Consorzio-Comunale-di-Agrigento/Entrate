package it.finmatica.tr4.comunicazioni.payload.builder

import it.finmatica.tr4.comunicazioni.payload.AllegatoPayload

class AllegatoPayloadBuilder extends AbstractBuilder<AllegatoPayload> {

    private AllegatoPayload allegato

    AllegatoPayload crea(Closure definizione) {
        allegato = new AllegatoPayload()
        runClosure definizione
        return allegato
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, allegato)
    }
}
