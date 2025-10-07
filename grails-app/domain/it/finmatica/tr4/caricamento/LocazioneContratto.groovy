package it.finmatica.tr4.caricamento

class LocazioneContratto implements Serializable {

    String ufficio
    Short anno
    String serie
    Integer numero
    Integer sottoNumero
    Integer progressivoNegozio
    Date dataRegistrazione
    Date dataStipula
    String codiceOggetto
    String codiceNegozio
    BigDecimal importoCanone
    String valutaCanone
    String tipoCanone
    Date dataInizio
    Date dataFine

    static belongsTo = [locazioneTestata: LocazioneTestata]

    static hasMany = [
            locazioneSoggetti: LocazioneSoggetto,
            locazioneImmobili: LocazioneImmobile,
    ]

    static mapping = {
        id column: "contratti_id"
        locazioneTestata column: "testate_id"

        version false

        table "locazioni_contratti"
    }

    static constraints = {
        ufficio                    nullable: true
        anno                       nullable: true
        serie                      nullable: true
        numero                     nullable: true
        sottoNumero                nullable: true
        progressivoNegozio         nullable: true
        dataRegistrazione          nullable: true
        dataStipula                nullable: true
        codiceOggetto              nullable: true
        codiceNegozio              nullable: true
        importoCanone              nullable: true
        valutaCanone               nullable: true
        tipoCanone                 nullable: true
        dataInizio                 nullable: true
        dataFine                   nullable: true
    }
}
