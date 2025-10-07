package it.finmatica.tr4

import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo

class ContribuentiOggettoAnno implements Serializable {

    short anno
    Categoria categoriaCatasto
    Categoria categoriaOgpr
    String classeCatasto
    Contribuente contribuente
    BigDecimal consistenza
    Date dataCessazione
    Date dataDecorrenza
    Date fineValidita
    boolean flagAbPrincipale
    boolean flagContenzioso
    boolean flagEsclusione
    boolean flagPossesso
    boolean flagRiduzione
    boolean immStorico
    Date inizioValidita
    Oggetto oggetto
    OggettoPratica oggettoPratica
    BigDecimal percPossesso
    PraticaTributo pratica
    TipoEventoDenuncia tipoEvento
    TipoOggetto tipoOggetto
    String tipoPratica
    String tipoRapporto
    Byte tipoTariffa
    TipoTributo tipoTributo
    Short tributo
    String utente
    BigDecimal valore

    static constraints = {
    }

    static mapping = {

        id composite: ['anno', 'contribuente', 'tipoTributo', 'inizioValidita', 'dataDecorrenza']

        categoriaCatasto column: "CATEGORIA_CATASTO", updateable: false, insertable: false
        categoriaOgpr column: "CATEGORIA_OGPR", updateable: false, insertable: false
        contribuente column: "COD_FISCALE"
        pratica column: "pratica"
        oggetto column: "oggetto"
        tipoOggetto column: 'tipo_oggetto'
        tipoTributo column: "tipo_tributo"
        oggettoPratica		column: "oggetto_pratica"

        version false
    }
}
