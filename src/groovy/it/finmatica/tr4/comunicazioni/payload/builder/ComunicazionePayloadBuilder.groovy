package it.finmatica.tr4.comunicazioni.payload.builder


import it.finmatica.tr4.comunicazioni.payload.ComunicazionePayload

class ComunicazionePayloadBuilder extends AbstractBuilder<ComunicazionePayload> {

    static final DATA_FORMAT = 'dd/MM/yyyy'
    static final DATA_PRATICA_FORMAT = 'dd/MM/yyyy'

    private ComunicazionePayload comunicazione

    ComunicazionePayloadBuilder(String codEnte,
                                String idRifApplicativo,
                                String cognome,
                                String codFiscalePIVA,
                                String oggetto,
                                String tipoComunicazione,
                                Date data = new Date()) {

        comunicazione = new ComunicazionePayload(
                codEnte: codEnte,
                idRifApplicativo: idRifApplicativo,
                cognomeRgs: cognome,
                cfiscPiva: codFiscalePIVA,
                data: data.format(ComunicazionePayloadBuilder.DATA_FORMAT),
                oggetto: oggetto,
                tipoComunicazione: tipoComunicazione,
                inSospeso: FlagSospeso.YES.value
        )

    }

    ComunicazionePayload crea(Closure definizione) {
        runClosure definizione
        return comunicazione
    }

    void inSospeso(FlagSospeso value) {
        comunicazione.inSospeso = value.value
    }

    void daFirmare(FlagFirma value) {
        comunicazione.daFirmare = value?.value
    }

    void dataPratica(Date data) {
        comunicazione.dataPratica = data.format(DATA_PRATICA_FORMAT)
    }

    void allegato(Closure allegato) {
        comunicazione.allegati = comunicazione.allegati ?: []
        comunicazione.allegati += (new AllegatoPayloadBuilder()).crea(allegato)
    }

    void dettaglioExtra(Closure dettaglioExtra) {
        comunicazione.dettagliExtra = comunicazione.dettagliExtra ?: []
        comunicazione.dettagliExtra += (new DettaglioExtraPayloadBuilder()).crea(dettaglioExtra)
    }

    void invioAppIO(Closure invioAppIO) {
        comunicazione.invioAppIO = comunicazione.invioAppIO ?: []
        comunicazione.invioAppIO += (new InvioAppIOPayloadBuilder()).crea(invioAppIO)
    }

    void invioMail(Closure invioMail) {
        comunicazione.invioMail = comunicazione.invioMail ?: []
        comunicazione.invioMail += (new InvioMailPayloadBuilder()).crea(invioMail)
    }

    void invioPND(Closure invioPND) {
        comunicazione.invioPND = comunicazione.invioPND ?: []
        comunicazione.invioPND += (new InvioPNDPayloadBuilder()).crea(invioPND)
    }

    void pagamento(Closure pagamento) {
        comunicazione.pagamenti = comunicazione.pagamenti ?: []
        comunicazione.pagamenti += (new PagamentoPayloadBuilder()).crea(pagamento)
    }

    def propertyMissing(String name) {
        throw new RuntimeException("Proprietà [$name] non definita")
    }

    def methodMissing(String name, arguments) {
        settaValori(name, arguments, comunicazione)
    }
}
