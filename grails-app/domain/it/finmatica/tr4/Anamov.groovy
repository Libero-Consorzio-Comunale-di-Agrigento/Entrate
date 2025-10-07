package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Anamov implements Serializable {

    Long matricola
    Integer codMov
    Integer codEve
    Integer dataEve
    Short codComEve
    Short codProEve
    Short annoPratica
    Short pratica
    Date dataReg

    static mapping = {
        id column: "ANAMOV", generator: "assigned"

        table "web_anamov"
        version false

        dataReg sqlType: 'Date', column: 'data_reg'
    }

    static constraints = {
        matricola nullable: true
        codMov nullable: true
        codEve nullable: true
        dataEve nullable: true
        codProEve nullable: true
        codComEve nullable: true
        annoPratica nullable: true
        pratica nullable: true
        dataReg nullable: true
    }
}
