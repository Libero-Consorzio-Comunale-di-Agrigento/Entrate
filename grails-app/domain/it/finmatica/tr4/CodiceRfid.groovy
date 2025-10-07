package it.finmatica.tr4

import grails.plugins.springsecurity.SpringSecurityService

class CodiceRfid implements Serializable, Comparable<CodiceRfid> {

    SpringSecurityService springSecurityService

    Contribuente contribuente
    Oggetto oggetto
    String codRfid
    Contenitore contenitore
    Date dataConsegna
    Date dataRestituzione
    String note
    Date lastUpdated
    String utente
    String idCodiceRfid

    static mapping = {
        id composite: ['contribuente', 'oggetto', 'codRfid']
        contribuente column: 'cod_fiscale'
        oggetto column: 'oggetto'
        contenitore column: 'cod_contenitore'
        dataConsegna sqlType: 'Date'
        dataRestituzione sqlType: 'Date'
        lastUpdated column: 'data_variazione', sqlType: 'Date'
        utente column: 'utente'
        table 'CODICI_RFID'
        version false
    }

    static constraints = {
        codRfid maxSize: 100
        dataConsegna nullable: true
        dataRestituzione nullable: true
        note nullable: true
        idCodiceRfid nullable: true
        lastUpdated nullable: true
        utente nullable: true
    }

    static transients = ['springSecurityService', 'idCodiceRfid']

    def beforeValidate() {
        utente = springSecurityService?.currentUser?.id
    }

    def beforeInsert() {
        utente = springSecurityService?.currentUser?.id
    }

    def beforeUpdate() {
        utente = springSecurityService?.currentUser?.id
    }

    def afterLoad() {
        if (contribuente && oggetto && codRfid?.trim()) {
            idCodiceRfid = "$contribuente.codFiscale-$oggetto.id-$codRfid"
        }
    }

    @Override
    int compareTo(CodiceRfid o) {
        return contribuente.codFiscale <=> o.contribuente.codFiscale ?:
                oggetto.id <=> o.oggetto.id ?:
                        codRfid <=> o.codRfid
    }
}
