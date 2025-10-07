package pratiche.stampa.filename

import document.FileNameGenerator
import it.finmatica.tr4.commons.TipoPratica

class StampaFilenamePratica implements StampaFilenameStrategy {

    def pratica
    def codFiscale

    StampaFilenamePratica(pratica, codFiscale) {
        this.pratica = pratica
        this.codFiscale = codFiscale
    }

    String generate(def params) {
        if (!pratica) {
            return null
        }
        def generatorTitle = FileNameGenerator.GENERATORS_TITLES.PRAT
        TipoPratica tipoPratica = TipoPratica.valueOf(pratica.tipoPratica)
        switch (tipoPratica) {
            case TipoPratica.A:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.ACC
                break
            case TipoPratica.L:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.LIQ
                break
            case TipoPratica.S:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.SOL
                break
            case TipoPratica.D:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.DEN
                break
        }
        return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                generatorTitle,
                [idDocumento      : pratica.id,
                 numeroOrdineErede: params?.numeroOrdineErede,
                 codFiscale       : codFiscale])
    }
}
