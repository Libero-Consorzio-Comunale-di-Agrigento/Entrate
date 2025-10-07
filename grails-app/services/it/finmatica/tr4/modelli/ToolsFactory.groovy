package it.finmatica.tr4.modelli

import org.apache.log4j.Logger

abstract class ToolsFactory {

    private static final Logger log = Logger.getLogger(ToolsFactory.class)

    static ModelliTools tools(byte[] doc) {
        def type = ModelliCommons.detectType(doc)

        log.info("Tipo file [${type.extension}]")

        if (type.extension in ['.doc', '.docx', '.odt']) {
            return new WordTools(doc)
        } else if ('.pdf' in type.extension) {
            return new PDFTools(doc)
        } else {
            throw new RuntimeException("Formato [${type.extension}] non supportato.")
        }
    }
}
