package it.finmatica.tr4.pratiche


import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.dto.MoltiplicatoreDTO
import it.finmatica.tr4.dto.RivalutazioneRenditaDTO
import it.finmatica.tr4.tipi.SiNoType

class OggettoPratica implements Comparable<OggettoPratica> {

    OggettoPraticaRendita oggettoPraticaRendita
    Tariffa tariffa
    CategoriaCatasto categoriaCatasto
    OggettoPratica oggettoPraticaRif
    OggettoPratica oggettoPraticaRifV
    OggettoPratica oggettoPraticaRifAp
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

    String flagDatiMetrici
    BigDecimal percRiduzioneSup
	
	boolean flagNullaOsta

    static belongsTo = [pratica: PraticaTributo, oggetto: Oggetto]
    static hasMany = [partizioniOggettoPratica: PartizioneOggettoPratica
                      , costiStorici          : CostoStorico
                      , oggettiContribuente   : OggettoContribuente
                      , oggettiOgim           : OggettoOgim
    ]

    static mapping = {
        id column: 'oggetto_pratica', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "OGGETTI_PRATICA_NR"]
        //anno				column: "anno", updateable: false, insertable: false
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
		flagNullaOsta type: SiNoType

        tipoOccupazione enumType: 'string'
        titoloOccupazione enumType: 'ordinal'
        naturaOccupazione enumType: 'ordinal'
        destinazioneUso enumType: 'ordinal'
        assenzaEstremiCatasto enumType: 'ordinal'

        oggettoPraticaRendita column: "oggetto_pratica_rendita", updateable: false, insertable: false

        table 'web_oggetti_pratica'

        version false

    }

    static constraints = {
        tariffa nullable: true
        numOrdine nullable: true, maxSize: 5
        immStorico nullable: true, maxSize: 1
        categoriaCatasto nullable: true, maxSize: 3
        classeCatasto nullable: true, maxSize: 2
        valore nullable: true
        flagProvvisorio nullable: true, maxSize: 1
        flagValoreRivalutato nullable: true, maxSize: 1
        titolo nullable: true, maxSize: 1
        estremiTitolo nullable: true, maxSize: 60
        modello nullable: true
        flagFirma nullable: true, maxSize: 1
        fonte nullable: true
        consistenzaReale nullable: true
        consistenza nullable: true
        locale nullable: true
        coperta nullable: true
        scoperta nullable: true
        codiceTributo nullable: true
        flagUipPrincipale nullable: true, maxSize: 1
        reddito nullable: true
        impostaBase nullable: true
        impostaDovuta nullable: true
        flagDomicilioFiscale nullable: true, maxSize: 1
        numConcessione nullable: true
        dataConcessione nullable: true
        inizioConcessione nullable: true
        fineConcessione nullable: true
        larghezza nullable: true
        profondita nullable: true
        codProOcc nullable: true
        codComOcc nullable: true
        indirizzoOcc nullable: true, maxSize: 50
        daChilometro nullable: true, scale: 4
        aChilometro nullable: true, scale: 4
        lato nullable: true, maxSize: 1
        tipoOccupazione nullable: true, maxSize: 1
        flagContenzioso nullable: true, maxSize: 1
        oggettoPraticaRif nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        oggettoPraticaRifV nullable: true
        tipoQualita nullable: true
        qualita nullable: true, maxSize: 60
        tipoOggetto nullable: true
        oggettoPraticaRifAp nullable: true
        quantita nullable: true
        titoloOccupazione nullable: true
        naturaOccupazione nullable: true
        destinazioneUso nullable: true
        assenzaEstremiCatasto nullable: true
        dataAnagrafeTributaria nullable: true
        numeroFamiliari nullable: true
        lastUpdated nullable: true
        anno nullable: true
        tipoTariffa nullable: true
        categoria nullable: true
        tipoCategoria nullable: true
        oggettoPraticaRendita nullable: true
        flagDatiMetrici nullable: true
        percRiduzioneSup nullable: true
    }

    static transients = ['springSecurityService', 'valoreRivalutato', 'valoreDichiarato', 'valoreLiquidato', 'valoreAccertato', 'renditaDaRiferimenti']
    def springSecurityService

    def beforeValidate() {
        tipoCategoria = categoria?.categoria
        tipoTariffa = tariffa?.tipoTariffa
        utente = springSecurityService.currentUser.id
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser.id
    }

    BigDecimal valoreRivalutato
    BigDecimal renditaDaRiferimenti

    BigDecimal getRenditaDaRiferimenti() {

        def listaRif = RiferimentoOggetto.createCriteria().list {
            projections {
                groupProperty("oggetto.id")
                groupProperty("inizioValidita")
                max("rendita")
            }
            le("daAnno", pratica.anno)
            ge("aAnno", pratica.anno)
            eq("oggetto.id", this.oggetto.id)

            order("inizioValidita", "desc")
        }
        return (listaRif.size == 1) ? listaRif[0][2] : null
    }

    BigDecimal getValoreRivalutato() {

        def rendita = getRenditaDaRiferimenti()

        List<MoltiplicatoreDTO> moltiplicatori = OggettiCache.MOLTIPLICATORI.valore
        MoltiplicatoreDTO m = moltiplicatori.find {
            it.anno == pratica.anno && it.categoriaCatasto.categoriaCatasto == (this.categoriaCatasto ?: oggetto.categoriaCatasto)?.categoriaCatasto
        }

        List<RivalutazioneRenditaDTO> rivalutazioniRendite = OggettiCache.RIVALUTAZIONI_RENDITA.valore
        RivalutazioneRenditaDTO rr = rivalutazioniRendite.find {
            it.anno == pratica.anno && it.tipoOggetto.tipoOggetto == (this.tipoOggetto ?: oggetto.tipoOggetto).tipoOggetto
        }
        return rendita ? ((rendita * (m?.moltiplicatore ?: 1) * (100 + (rr?.aliquota ?: 0)) / 100)) : null
    }

    int compareTo(OggettoPratica obj) {
        obj.numOrdine <=> numOrdine ?: obj.id <=> id
    }
}
