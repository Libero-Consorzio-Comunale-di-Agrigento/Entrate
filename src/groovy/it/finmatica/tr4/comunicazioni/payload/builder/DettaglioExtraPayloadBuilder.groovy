package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.DettaglioExtraPayload

class DettaglioExtraPayloadBuilder extends AbstractBuilder<DettaglioExtraPayload> {

    private DettaglioExtraPayload dettaglioExtra

    DettaglioExtraPayload crea(Closure definizione) {
        dettaglioExtra = new DettaglioExtraPayload()
        runClosure definizione
        return dettaglioExtra
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, dettaglioExtra)
    }

}
