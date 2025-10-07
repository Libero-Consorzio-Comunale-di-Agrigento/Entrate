package it.finmatica.tr4.modelli

interface ModelliTools {

    def finalizzaPagineDocumento()

    def allegaDocumento(byte[] pdf, def aggiungiPaginaBianca, def tag)

    def creaPaginaBianca()
}
