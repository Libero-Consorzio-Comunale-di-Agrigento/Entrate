package it.finmatica.tr4.pratiche

import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.tipi.SiNoType

class StoPraticaTributo implements Comparable<StoPraticaTributo> {

    Contribuente contribuente
    TipoTributo tipoTributo
    StoPraticaTributo praticaTributoRif
    TipoCarica tipoCarica
    TipoStato tipoStato
    TipoAtto tipoAtto
    TipoEventoDenuncia tipoEvento

    short anno
    String tipoPratica

    Date data
    String numero
    String numeroPadded
    String denunciante
    String indirizzoDen
    Ad4ComuneTr4 comuneDenunciante
    String codFiscaleDen
    String partitaIvaDen
    Date dataNotifica
    BigDecimal impostaTotale
    BigDecimal importoTotale
    BigDecimal importoRidotto
    String motivo
    String utente
    Date lastUpdated
    String note
    boolean flagAdesione
    BigDecimal impostaDovutaTotale
    boolean flagDenuncia
    boolean flagAnnullamento
    BigDecimal importoRidotto2
    String tipoCalcolo
    BigDecimal versatoPreRate
    Date dataRateazione
    BigDecimal mora
    Short numRata
    String tipologiaRate
    BigDecimal importoRate
    BigDecimal aliquotaRate

    SortedSet<StoOggettoPratica> oggettiPratica

    static hasMany = [
            oggettiPratica       : StoOggettoPratica,
            rapportiTributo      : StoRapportoTributo
    ]

    static mapping = {
        id column: "pratica"
        utente column: "utente", ignoreNotFound: true
        importoRidotto2 column: "importo_ridotto_2"
        tipoTributo column: "tipo_tributo"
        tipoCarica column: "tipo_carica"
        contribuente column: "cod_fiscale"
        praticaTributoRif column: "pratica_rif"
        tipoStato column: "stato_accertamento"
        tipoAtto column: "tipo_atto"
        numRata column: "rate"

        data sqlType: 'Date', column: 'DATA'
        dataNotifica sqlType: 'Date', column: 'DATA_NOTIFICA'
        lastUpdated sqlType: 'Date', column: 'DATA_VARIAZIONE'

        numeroPadded formula: "lpad(numero, 15, ' ')"

        columns {
            comuneDenunciante {
                column name: "cod_com_den"
                column name: "cod_pro_den"
            }
        }

        flagAdesione type: SiNoType
        flagDenuncia type: SiNoType
        flagAnnullamento type: SiNoType

        impostaTotale updateable: false
        importoRidotto updateable: false
        importoRidotto2 updateable: false
        importoTotale updateable: false
		impostaDovutaTotale updateable: false
		
        versamenti cascade: 'all-delete-orphan'
        sanzioniPratica cascade: 'all-delete-orphan'
        rate cascade: 'all-delete-orphan'
        iter cascade: 'all-delete-orphan'

        table 'sto_pratiche_tributo'
        version false
    }

    boolean getFlagDenuncia() {
        this.flagDenuncia ?: false
    }

    static constraints = {
        tipoPratica inList: ['A', 'D', 'L', 'I', 'C', 'K', 'T', 'V', 'G']
        data nullable: true
        numero nullable: true, maxSize: 15
        tipoCarica nullable: true
        denunciante nullable: true, maxSize: 60
        indirizzoDen nullable: true, maxSize: 50
        comuneDenunciante nullable: true
        codFiscaleDen nullable: true, maxSize: 16
        partitaIvaDen nullable: true, maxSize: 11
        dataNotifica nullable: true
        impostaTotale nullable: true, updates: false
        importoTotale nullable: true, updates: false
        importoRidotto nullable: true, updates: false
        tipoStato nullable: true
        motivo nullable: true, maxSize: 2000
        praticaTributoRif nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        flagAdesione nullable: true, maxSize: 1
        impostaDovutaTotale nullable: true, updates: false
        flagDenuncia nullable: true, maxSize: 1
        flagAnnullamento nullable: true, maxSize: 1
        importoRidotto2 nullable: true, updates: false
        tipoAtto nullable: true
        tipoCalcolo nullable: true
        lastUpdated nullable: true
        versatoPreRate nullable: true
        dataRateazione nullable: true
        mora nullable: true
        numRata nullable: true
        tipologiaRate nullable: true
        importoRate nullable: true
        aliquotaRate nullable: true
    }

    int compareTo(StoPraticaTributo obj) {
        obj.anno <=> anno ?: id <=> obj.id
    }
}
