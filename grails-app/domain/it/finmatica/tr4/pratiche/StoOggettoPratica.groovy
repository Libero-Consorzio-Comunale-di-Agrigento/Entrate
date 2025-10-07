package it.finmatica.tr4.pratiche

import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.tipi.SiNoType

class StoOggettoPratica implements Comparable<StoOggettoPratica> {

    OggettoPraticaRendita oggettoPraticaRendita
    Tariffa tariffa
    CategoriaCatasto categoriaCatasto
    StoOggettoPratica oggettoPraticaRif
    StoOggettoPratica oggettoPraticaRifV
    StoOggettoPratica oggettoPraticaRifAp
    Fonte fonte
    //ClasseSuperficie	classeSuperficie
    TipoOggetto tipoOggetto
    CodiceTributo codiceTributo

    String numOrdine
    boolean immStorico

    String classeCatasto
    BigDecimal valore
    //BigDecimal 			rendita
    boolean flagProvvisorio
    boolean flagValoreRivalutato
    boolean flagFirma
    boolean flagUipPrincipale
    boolean flagDomicilioFiscale
    boolean flagContenzioso

    String titolo
    String estremiTitolo
    Short modello
    BigDecimal consistenzaReale
    BigDecimal consistenza
    BigDecimal locale
    BigDecimal coperta
    BigDecimal scoperta

    BigDecimal reddito

    BigDecimal impostaBase
    BigDecimal impostaDovuta

    Integer numConcessione
    Date dataConcessione
    Date inizioConcessione
    Date fineConcessione
    BigDecimal larghezza
    BigDecimal profondita
    Short codProOcc
    Short codComOcc
    String indirizzoOcc
    BigDecimal daChilometro
    BigDecimal aChilometro
    String lato
    TipoOccupazione tipoOccupazione

    String utente
    Date lastUpdated
    String note

    Short tipoQualita
    String qualita

    Integer quantita
    TitoloOccupazione titoloOccupazione
    NaturaOccupazione naturaOccupazione
    DestinazioneUso destinazioneUso
    AssenzaEstremiCatasto assenzaEstremiCatasto
    Date dataAnagrafeTributaria
    Short numeroFamiliari
    Short anno
    Short tipoTariffa

    Categoria categoria
    Short tipoCategoria

    static belongsTo = [pratica: StoPraticaTributo, oggetto: StoOggetto]
    static hasMany = [oggettiContribuente: StoOggettoContribuente]

    // https://www.tothenew.com/blog/significance-of-mappedby-in-grails-domain/#
    static mappedBy = [oggettiContribuente: 'oggettoPratica']

    static mapping = {
        id column: 'oggetto_pratica'
        tariffa column: "id_tariffa", updateable: false, insertable: false
        oggettoPraticaRif column: "oggetto_pratica_rif"
        oggettoPraticaRifV column: "oggetto_pratica_rif_v"
        oggettoPraticaRifAp column: "oggetto_pratica_rif_ap"
        pratica column: "pratica"
        oggetto column: "oggetto"
        categoriaCatasto column: "categoria_catasto"
        fonte column: "fonte"
        tipoOggetto column: "tipo_oggetto"
        codiceTributo column: "tributo"
        utente column: "utente"
        categoria column: "id_categoria", updateable: false, insertable: false
        tipoCategoria column: "categoria"
        dataConcessione sqlType: 'Date'
        inizioConcessione sqlType: 'Date'
        fineConcessione sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        dataAnagrafeTributaria sqlType: 'Date'

        flagProvvisorio type: SiNoType
        flagValoreRivalutato type: SiNoType
        flagFirma type: SiNoType
        flagUipPrincipale type: SiNoType
        flagDomicilioFiscale type: SiNoType
        flagContenzioso type: SiNoType
        immStorico type: SiNoType

        tipoOccupazione enumType: 'string'
        titoloOccupazione enumType: 'ordinal'
        naturaOccupazione enumType: 'ordinal'
        destinazioneUso enumType: 'ordinal'
        assenzaEstremiCatasto enumType: 'ordinal'

        oggettoPraticaRendita column: "oggetto_pratica_rendita", updateable: false, insertable: false

        table 'sto_web_oggetti_pratica'

        version false
    }

    int compareTo(StoOggettoPratica obj) {
        obj.numOrdine <=> numOrdine ?: obj.id <=> id
    }
}
