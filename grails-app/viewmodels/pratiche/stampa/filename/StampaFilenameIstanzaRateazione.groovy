package pratiche.stampa.filename

import document.FileNameGenerator

class StampaFilenameIstanzaRateazione implements StampaFilenameStrategy {
    def pratica
    def codFiscale

    StampaFilenameIstanzaRateazione(pratica, codFiscale) {
        this.pratica = pratica
        this.codFiscale = codFiscale
    }

    String generate(def params) {
        if (!pratica) {
            return null
        }
        return FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.RAI,
                [idDocumento: pratica.id,
                 codFiscale : codFiscale])
    }
}
