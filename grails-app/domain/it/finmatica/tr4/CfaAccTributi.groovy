package it.finmatica.tr4

class CfaAccTributi implements Serializable {

    short annoAcc
    int numeroAcc
    String descrizioneAcc
    Integer esercizio
    String es
    BigDecimal capitolo
    Integer articolo
    String descrizioneCap
    Date dataAcc
    BigDecimal importoAttuale
    BigDecimal ordinativi
    BigDecimal disponibilita
    BigDecimal codiceLivello
    String descrizioneLivello

    static mapping = {
        id composite: ["annoAcc", "numeroAcc"]
        codiceLivello		column: "codice_livello_5"
        descrizioneLivello	column: "descrizione_livello_5"

        table "cfa_acc_tributi"
        version false
    }

    static constraints = {
        annoAcc             nullable: false, maxSize: 4
        numeroAcc           nullable: false, maxSize: 5
        descrizioneAcc      nullable: true
        esercizio           nullable: true, maxSize: 4
        es                  nullable: true, maxSize: 1
        capitolo            nullable: true
        articolo            nullable: true
        descrizioneCap      nullable: true
        dataAcc             nullable: true
        importoAttuale      nullable: true
        ordinativi          nullable: true
        disponibilita       nullable: true
        codiceLivello       nullable: true
        descrizioneLivello  nullable: true
    }
}
