package pratiche.stampa.filename

import document.FileNameGenerator

class StampaFilenameLetteraGenerica implements StampaFilenameStrategy {

    def codFiscale

    StampaFilenameLetteraGenerica(codFiscale) {
        this.codFiscale = codFiscale
    }

    String generate(def params) {
        if (!params?.modelloSelezionato) {
            return null
        }
        return FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.LGE,
                [modello   : params.modelloSelezionato.modello,
                 codFiscale: codFiscale])
    }
}
