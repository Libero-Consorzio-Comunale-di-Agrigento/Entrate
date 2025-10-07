package it.finmatica.tr4

class TipoStatoContribuente {
    String descrizione
    String descrizioneBreve

    static mapping = {
        table 'tipi_stato_contribuente'
        version false

        id column: 'tipo_stato_contribuente', generator: 'assigned'
    }

    static constraints = {
        descrizione blank: false, maxSize: 100
        descrizioneBreve blank: false, maxSize: 4
    }
}
