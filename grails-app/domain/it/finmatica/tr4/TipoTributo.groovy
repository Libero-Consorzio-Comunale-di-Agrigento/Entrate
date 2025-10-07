package it.finmatica.tr4

import groovy.sql.Sql

class TipoTributo {

    def dataSource

    String tipoTributo
    String descrizione
    String codEnte
    Integer contoCorrente
    String descrizioneCc
    String testoBollettino
    String flagCanone
    String flagTariffa
    String flagLiqRiog
    String ufficio
    String indirizzoUfficio
    String codUfficio
    String tipoUfficio

    static transients = ['tipoTributoAttuale']

    static hasMany = [codiciTributo       : CodiceTributo
                      , utilizziTributo   : UtilizzoTributo
                      , consistenzeTributo: ConsistenzaTributo
                      , versamenti        : Versamento
                      , oggettiTributo    : OggettoTributo]

    static mapping = {
        id name: "tipoTributo", generator: "assigned"
        table "tipi_tributo"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        descrizione maxSize: 100
        codEnte nullable: true, maxSize: 5
        contoCorrente nullable: true
        descrizioneCc nullable: true, maxSize: 100
        testoBollettino nullable: true, maxSize: 2000
        flagCanone nullable: true, maxSize: 1
        flagTariffa nullable: true, maxSize: 1
        flagLiqRiog nullable: true, maxSize: 1
        ufficio nullable: true, maxSize: 100
        indirizzoUfficio nullable: true, maxSize: 200
        codUfficio nullable: true, maxSize: 6
        tipoUfficio nullable: true, maxSize: 1
    }


    public String getTipoTributoAttuale(Short anno = null) {

        Calendar calendar = GregorianCalendar.getInstance()
        def pAnno = anno ?: calendar.get(Calendar.YEAR)
        String r
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_descrizione_titr(?, ?)}'
                , [Sql.VARCHAR, this.tipoTributo, pAnno]) {
            r = it
        }
        return r
    }


    // Per conversione da DTO a Domain
    void setTipoTributoAttuale(String tipoTributoAttuale) {

    }

}
