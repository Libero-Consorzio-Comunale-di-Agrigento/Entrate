package it.finmatica.tr4

class Anaana {

    String cognomeNome
    Integer fascia
    Byte stato
    String paternita
    String maternita
    Integer codFam
    String rapportoPar
    Byte sequenzaPar
    Integer matricolaPd
    Integer matricolaMd


    static mapping = {
        id column: "MATRICOLA", generator: "assigned"

        table "web_anaana"
        version false
    }

    static constraints = {
        cognomeNome nullable: true, maxSize: 100
        fascia nullable: true
        stato nullable: true
        paternita nullable: true, maxSize: 60
        maternita nullable: true, maxSize: 60
        codFam nullable: true
        rapportoPar nullable: true, maxSize: 2
        sequenzaPar nullable: true
        matricolaPd nullable: true
        matricolaMd nullable: true
    }
}
