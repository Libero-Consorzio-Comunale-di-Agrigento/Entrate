package it.finmatica.tr4.caricamento

class LocazioneImmobile implements Serializable {

    String ufficio
    Short anno
    String serie
    Integer numero
    Integer sottoNumero
    Integer progressivoImmobile
    Integer progressivoNegozio
    String immAccatastamento
    String tipoCatasto
    String flagIp
    String codiceCatasto
    String sezUrbComCat
    String foglio
    String particellaNum
    String particellaDen
    String subalterno
    String indirizzo

    static belongsTo = [locazioneContratto: LocazioneContratto]

    static mapping = {
        id column: "immobili_id"
        locazioneContratto column: "contratti_id"

        version false

        table "locazioni_immobili"
    }

    static constraints = {
        ufficio nullable: true
        anno nullable: true
        serie nullable: true
        numero nullable: true
        sottoNumero nullable: true
        progressivoImmobile nullable: true
        progressivoNegozio nullable: true
        immAccatastamento nullable: true
        tipoCatasto nullable: true
        flagIp nullable: true
        codiceCatasto nullable: true
        sezUrbComCat nullable: true
        foglio nullable: true
        particellaNum nullable: true
        particellaDen nullable: true
        subalterno nullable: true
        indirizzo nullable: true
    }
}
