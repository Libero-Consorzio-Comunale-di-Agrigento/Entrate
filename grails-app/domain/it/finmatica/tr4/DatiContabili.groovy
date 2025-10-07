package it.finmatica.tr4

import it.finmatica.tr4.commons.*

class DatiContabili implements Serializable {

    Long id
    TipoTributo tipoTributo
    Short anno
    String tipoImposta
    String tipoPratica
    Date emissioneDal
    Date emissioneAl
    Date ripartizioneDal
    Date ripartizioneAl
    CodiceTributo tributo
    String codTributoF24
    String descrizioneTitr
    TipoStato statoPratica
    Short annoAcc
    Integer numeroAcc
    TipoOccupazione tipoOccupazione
    String codEnteComunale

    //CodiceF24 codTributoF24
    //static hasMany = [ codTributoF24  : CodiceF24]

    static mapping = {
        id          column: 'id_dato_contabile', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "DATI_CONTABILI_NR"]
        tipoTributo column: "tipo_tributo"
        tributo     column: "tributo"
        statoPratica column: "stato_pratica"
        codTributoF24 column: "cod_tributo_f24"
        codEnteComunale column: "cod_ente_comunale"

        tipoOccupazione enumType: 'string'

        table 'dati_contabili'
        version false
    }

    static constraints = {
        tipoTributo nullable: true, maxSize: 5
        anno nullable: true
        tipoImposta nullable: true, maxSize:1
        tipoPratica nullable: true, maxSize:1
        emissioneDal nullable: true
        emissioneAl nullable: true
        tributo nullable: true
        codTributoF24 nullable: true, maxSize:4
        descrizioneTitr nullable: true, maxSize:5
        statoPratica nullable: true, maxSize:2
        annoAcc nullable: true
        numeroAcc nullable: true
        tipoOccupazione nullable: true, maxSize: 1
        codEnteComunale nullable: true, maxSize: 4
    }
}
