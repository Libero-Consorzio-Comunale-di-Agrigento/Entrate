package it.finmatica.tr4


class RelazioneOggettoCalcolo implements Serializable {

    Short anno
    TipoAliquota tipoAliquota
    TipoOggetto tipoOggetto
    CategoriaCatasto categoriaCatasto


    static mapping = {
        id column: "id_relazione", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "RELAZIONI_OGGETTI_CALCOLO_NR"]
        tipoOggetto column: "tipo_oggetto"
        categoriaCatasto column: "categoria_catasto"
        columns {
            tipoAliquota {
                column name: "tipo_tributo"
                column name: "tipo_aliquota"
            }
        }
        version false
        table "RELAZIONI_OGGETTI_CALCOLO"
    }

    static constraints = {
        anno nullable: false, maxSize: 4
        categoriaCatasto nullable: true
        tipoAliquota nullable: true
        tipoOggetto nullable: false
    }
}
