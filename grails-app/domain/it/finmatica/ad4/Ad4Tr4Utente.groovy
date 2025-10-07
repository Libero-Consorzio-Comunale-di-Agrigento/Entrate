package it.finmatica.ad4

class Ad4Tr4Utente implements Serializable {

    String id
    String nominativo
    String tipoUtente

    static hasMany = [
            dirittiAccesso: Ad4Tr4DirittoAccesso
    ]

    static mapping = {
        id(column: 'utente', generator: 'assigned', type: 'string')
        table 'ad4_v_utenti'
        version false
    }
}
