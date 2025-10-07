package it.finmatica.tr4.comunicazioni

class TipoComunicazione {

    private final DA_FIRMARE_DESCR = [
            'DF': 'Da firmare manualmente',
            'FA': 'Da firmare automaticamente',
            'NF': 'Da non firmare'

    ]

    private final DA_PROTOCOLLARE = [
            'S': 'Si',
            'N': 'No'
    ]

    String tipoComunicazioneDescr
    String infoPND
    String emailMittente
    String tipoDocumentoProtocollo
    String fascicoloAnno
    String tagAppio
    String daTimbrare
    String infoAPPIO
    String tagMail
    String classCod
    String infoMail
    String tipoComunicazione
    String fascicoloNumero
    String daProtocollare
    String nominativoMittente
    String daFirmare
    String infoFasciolo
    String tagPnd
    String codiceTassonomia

    def getDaFirmareDescr() {
        if (daFirmare == null) {
            return null
        }

        return DA_FIRMARE_DESCR[daFirmare]
    }

    def getDaProtocollareDescr() {
        if (daProtocollare == null) {
            return null
        }

        return DA_PROTOCOLLARE[daProtocollare]
    }

    def getFlagPec() {
        return !(tagMail ?: "").empty
    }

    def getFlagPnd() {
        return !(tagPnd ?: "").empty
    }
}


