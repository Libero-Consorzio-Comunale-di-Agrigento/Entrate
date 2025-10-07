package it.finmatica.tr4.modelli

abstract class AbstractModelliTools implements ModelliTools {


    byte[] doc

    AbstractModelliTools(byte[] doc) {
        this.doc = doc
    }

    def allegaDocumento(byte[] doc, def aggiungiPaginaBianca = false, def tag) {
        def tipo = ModelliCommons.detectType(doc).extension
        switch (tipo) {
            case ".pdf":
                return _allegaPdf(doc, aggiungiPaginaBianca, tag)
                break
            default:
                throw new RuntimeException("Tipo di documento da allegare non supportato [${tipo}]")
        }
    }

    protected def _allegaPdf(byte[] pdf, def aggiungiPaginaBianca, def tag = null) {
        throw new RuntimeException("Funzionalità non supportata")
    }
}

