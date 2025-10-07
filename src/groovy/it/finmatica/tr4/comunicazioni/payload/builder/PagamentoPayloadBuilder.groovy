package it.finmatica.tr4.comunicazioni.payload.builder

import it.finmatica.tr4.comunicazioni.payload.InvioPagamentoPayload

class PagamentoPayloadBuilder extends AbstractBuilder<InvioPagamentoPayload> {

    private InvioPagamentoPayload pagamento

    InvioPagamentoPayload crea(Closure definizione) {
        pagamento = new InvioPagamentoPayload()
        runClosure definizione
        return pagamento
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, pagamento)
    }
}
