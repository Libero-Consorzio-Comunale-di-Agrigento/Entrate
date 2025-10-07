package it.finmatica.tr4.ufficiotributi.datiesterni

class FiltroRicercaImportDati {
    def titoloDocumentoId
    def stato = 0
    def nomeFile
    def daIdDocumento
    def aIdDocumento

    def validate(){
        def error = ""

        error += checkEstremi(daIdDocumento, aIdDocumento, "Id documento")

        return error
    }

    private checkEstremi(def da, def a, def label) {
        if (da && a && da > a) {
            return "Valori di $label non coerenti.\n"
        }

        return ""
    }

    def isAttivo() {
        return titoloDocumentoId || nomeFile || daIdDocumento || aIdDocumento || stato != 0
    }

}
