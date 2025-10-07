package pratiche.stampa.filename

import document.FileNameGenerator

class StampaFilenameGeneric implements StampaFilenameStrategy {

    def codFiscale

    StampaFilenameGeneric(def codFiscale) {
        this.codFiscale = codFiscale
    }

    String generate(def params) {
        return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.GEN,
                [idDocumento: 0,
                 codFiscale : codFiscale])
    }
}
