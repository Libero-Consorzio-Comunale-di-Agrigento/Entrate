package pratiche.stampa.filename

import document.FileNameGenerator
import grails.util.Holders
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.modelli.ModelliService

class StampaFilenameComunicazione implements StampaFilenameStrategy {

    def modelliService

    def anno
    def codFiscale
    def pratica
    def ruolo

    StampaFilenameComunicazione(anno, codFiscale, pratica, ruolo) {
        this.anno = anno
        this.codFiscale = codFiscale
        this.pratica = pratica
        this.ruolo = ruolo

        this.modelliService = (ModelliService) Holders.getApplicationContext().getBean('modelliService')


    }

    String generate(def params) {

        if (params.modelloSelezionato.tipoTributo == 'CUNI') {
            def elaborazione = modelliService.determinaElaborazione(params.modelloSelezionato.tipoTributo, (pratica?.id ?: 0), null)
            return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                    FileNameGenerator.GENERATORS_TITLES.COM,
                    [tipoTributo   : params.modelloSelezionato.tipoTributo,
                     anno          : anno,
                     idElaborazione: elaborazione,
                     codFiscale    : codFiscale])
        }
        def tipoTributoAttuale = OggettiCache.TIPI_TRIBUTO.valore
                .find { trib ->
                    trib.tipoTributo == params?.modelloSelezionato?.tipoTributo
                }?.getTipoTributoAttuale()
        if (ruolo != null) {
            return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                    FileNameGenerator.GENERATORS_TITLES.COM,
                    [tipoTributo: tipoTributoAttuale,
                     idDocumento: ruolo.id,
                     codFiscale : codFiscale])
        }
        return FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.COM,
                [tipoTributo: tipoTributoAttuale,
                 idDocumento: anno,
                 codFiscale : codFiscale])
    }
}
