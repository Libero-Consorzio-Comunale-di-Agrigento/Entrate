package pratiche.stampa.filename

import document.FileNameGenerator

class StampaFilenameSgravio implements StampaFilenameStrategy {

    def anno
    def ruolo
    def codFiscale

    StampaFilenameSgravio(anno, ruolo, codFiscale) {
        this.anno = anno
        this.ruolo = ruolo
        this.codFiscale = codFiscale
    }

    String generate(def params) {
        if (!ruolo) {
            return null
        }
        return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.SGR,
                [anno       : anno ?: ruolo.annoRuolo,
                 idDocumento: ruolo.id,
                 codFiscale : codFiscale])
    }
}
