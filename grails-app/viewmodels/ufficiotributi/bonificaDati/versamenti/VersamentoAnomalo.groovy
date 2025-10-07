package ufficiotributi.bonificaDati.versamenti

import it.finmatica.tr4.anomalie.Causale

class VersamentoAnomalo {

    private final def tipiVersamento = [
            1   : 'A', 'A': 'A',
            2   : 'S', 'S': 'S',
            3   : 'U', 'U': 'U',
            null: null
    ]

    private final def tipiVersamentoAnomaloAnci = [
            'A': 1,
            'S': 2,
            'U': 3
    ]

    private def versamentoOriginale

    def tipoIncasso = null
    def tipoTributo = null
    def tributoDes = null
    def anno = null
    def identificativoOperazione = null
    def codFiscale = null
    def flagContribuente = null
    def tipoVersamento = null
    def rata = null
    def flagRavvedimento
    def sanzioneRavvedimento
    def dataPagamento
    def importoVersato
    def flagOk
    def note
    def noteVersamento

    static def nuovoVersamentoAnomalo() {
        return new VersamentoAnomalo()
    }

    VersamentoAnomalo crea(def tipoIncasso, def versamento) {

        // Settare prima di tutto perché utilizzato per determinare diverse proprietà
        this.tipoIncasso = tipoIncasso

        this.versamentoOriginale = versamento

        this.codFiscale = versamento.codFiscale
        this.flagContribuente = (versamento.flagContribuente == 'S')
        determinaTipoVersamento()
        determinaFlagRavvedimento()
        this.sanzioneRavvedimento = versamento.sanzioneRavvedimento == null ? 'null' : versamento.sanzioneRavvedimento
        this.importoVersato = versamento.importoVersato
        this.flagOk = versamento.flagOk

        // Proprietà specifiche dei due fiversi tipi di versamento
        if (tipoIncasso == 'ANCI') {
            this.anno = versamento.annoFiscale
            this.dataPagamento = versamento.dataVersamento
            this.note = null
        } else {
            this.noteVersamento = versamento.noteVersamento
            this.tipoTributo = versamento.tipoTributo
            this.tributoDes = versamento.tipoTributo.getTipoTributoAttuale(versamento.anno) + ' - ' + versamento.tipoTributo.descrizione
            this.anno = versamento.anno
            this.identificativoOperazione = versamento.identificativoOperazione
            this.rata = versamento.rata
            this.dataPagamento = versamento.dataPagamento
            this.note = versamento.note
        }

        return this
    }

    def update() {
        // Parti comuni
        versamentoOriginale.codFiscale = codFiscale
        versamentoOriginale.flagContribuente = flagContribuente ? 'S' : null
        versamentoOriginale.sanzioneRavvedimento = (sanzioneRavvedimento == 'null' ? null : sanzioneRavvedimento)

        versamentoOriginale.flagOk = flagOk ? 'S' : null

        // Proprietà specifiche dei due fiversi tipi di versamento
        if (tipoIncasso == 'ANCI') {
            versamentoOriginale.dataVersamento = dataPagamento
            versamentoOriginale.tipoVersamento = tipiVersamentoAnomaloAnci[tipoVersamento]
            versamentoOriginale.flagRavvedimento = flagRavvedimento ? 1 : 0
        } else {
            versamentoOriginale.note = note
            versamentoOriginale.anno = anno
            versamentoOriginale.identificativoOperazione = identificativoOperazione
            versamentoOriginale.rata = rata
            versamentoOriginale.dataPagamento = dataPagamento
            versamentoOriginale.tipoVersamento = (tipoVersamento == 'null' ? null : tipoVersamento)
            versamentoOriginale.noteVersamento = noteVersamento
            determinaFlagRavvedimentoWrkVersamenti()
        }

        return versamentoOriginale
    }

    /**
     Flag ravvedimento per i versamenti da incasso:
     true solo se la causale vale 50100, 50109, 50150, 50180
     */
    private void determinaFlagRavvedimento() {

        if (tipoIncasso == 'ANCI') {
            // In db può valere 0, 1 e null. Null sarà considerato false.
            this.flagRavvedimento = (this.flagRavvedimento != null
                    && this.flagRavvedimento)
        } else {
            switch (versamentoOriginale.causale?.causale) {
                case '50100':
                case '50109':
                case '50150':
                case '50180':
                case '50190':
                    this.flagRavvedimento = true
                    break
                default:
                    this.flagRavvedimento = false
            }
        }
    }

    private void determinaFlagRavvedimentoWrkVersamenti() {

        def codCausale

        if (flagRavvedimento) {
            switch (versamentoOriginale.causale?.causale) {
                case '50000':
                    codCausale = '50100'
                    break
                case '50009':
                    codCausale = '50109'
                    break
                case '50200':
                    codCausale = '50109'
                    break
                    // TODO: missing default case
            }
        } else if (versamentoOriginale.causale?.causale in ['50100', '50109', '50150', '50180', '50190']) {
            switch (versamentoOriginale.causale?.causale) {
                case '50109':
                    codCausale = '50009'
                    break
                default:
                    codCausale = '50000'
            }
        }

        // Se il codice causale è cambiato si associa al versamento
        if (codCausale) {
            versamentoOriginale.causale =
                    Causale.findByCausaleAndTipoTributo(codCausale, versamentoOriginale.causale.tipoTributo.getDomainObject()).toDTO()
        }
    }

    private void determinaTipoVersamento() {
        this.tipoVersamento = tipiVersamento[versamentoOriginale.tipoVersamento]
    }

}
