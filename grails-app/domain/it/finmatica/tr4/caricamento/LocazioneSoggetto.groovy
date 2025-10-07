package it.finmatica.tr4.caricamento

class LocazioneSoggetto implements Serializable {

    String ufficio
    Short anno
    String serie
    Integer numero
    Integer sottoNumero
    Integer progressivoSoggetto
    Integer progressivoNegozio
    String tipoSoggetto
    String codFiscale
    String sesso
    String cittaNascita
    String provNascita
    Date dataNascita
    String cittaRes
    String provRes
    String indirizzoRes
    String numCivRes
    Date dataSubentro
    Date dataCessazione

    static belongsTo = [locazioneContratto: LocazioneContratto]

    static mapping = {
        id column: "soggetti_id"
        locazioneContratto column: "contratti_id"

        version false

        table "locazioni_soggetti"
    }

    static constraints = {
        ufficio nullable: true
        anno nullable: true
        serie nullable: true
        numero nullable: true
        sottoNumero nullable: true
        progressivoSoggetto nullable: true
        progressivoNegozio nullable: true
        tipoSoggetto nullable: true
        codFiscale nullable: true
        sesso nullable: true
        cittaNascita nullable: true
        provNascita nullable: true
        dataNascita nullable: true
        cittaRes nullable: true
        provRes nullable: true
        indirizzoRes nullable: true
        numCivRes nullable: true
        dataSubentro nullable: true
        dataCessazione nullable: true
    }
}
