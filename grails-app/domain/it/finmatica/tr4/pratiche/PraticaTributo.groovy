package it.finmatica.tr4.pratiche

import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.tipi.SiNoType

class PraticaTributo implements Comparable<PraticaTributo> {

    Contribuente contribuente
    TipoTributo tipoTributo
    PraticaTributo praticaTributoRif
    TipoCarica tipoCarica
    TipoStato tipoStato
    TipoAtto tipoAtto
    TipoEventoDenuncia tipoEvento
    String tipoViolazione


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
    TipoNotifica tipoNotifica
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
    String tipoRavvedimento
    String flagDePag
    Long documentoId
    String calcoloRate
    boolean flagIntRateSoloEvasa
    Date dataScadenza
    boolean flagRateOneri
    Date scadenzaPrimaRata
    Date dataRiferimentoRavvedimento

    SortedSet<OggettoPratica> oggettiPratica

    static hasMany = [
            oggettiPratica       : OggettoPratica,
            familiariPratica     : FamiliarePratica,
            rapportiTributo      : RapportoTributo,
            notificheOggetto     : NotificaOggetto,
            versamenti           : Versamento,
            sanzioniPratica      : SanzionePratica,
            webCalcoliIndividuale: WebCalcoloIndividuale,
            contattiContribuente : ContattoContribuente,
            rate                 : RataPratica,
            iter             : IterPratica,
            ruoliContribuente : RuoloContribuente,
            debitiRavvedimento: DebitoRavvedimento
    ]


    static mapping = {
        id column: "pratica", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "PRATICHE_TRIBUTO_NR"]
        utente column: "utente", ignoreNotFound: true
        importoRidotto2 column: "importo_ridotto_2"
        tipoTributo column: "tipo_tributo"
        tipoCarica column: "tipo_carica"
        contribuente column: "cod_fiscale"
        praticaTributoRif column: "pratica_rif"
        tipoStato column: "stato_accertamento"
        tipoAtto column: "tipo_atto"
        numRata column: "rate"
        flagDePag column: "flag_depag"
        tipoViolazione column: "tipo_violazione"
        dataScadenza column: "data_scadenza"

        documentoCaricatoMulti column: 'documento_multi_id'

        data sqlType: 'Date', column: 'DATA'
        dataNotifica sqlType: 'Date', column: 'DATA_NOTIFICA'
        tipoNotifica column: "TIPO_NOTIFICA"
        lastUpdated sqlType: 'Date', column: 'DATA_VARIAZIONE'
        scadenzaPrimaRata column: 'SCADENZA_PRIMA_RATA'
        dataRiferimentoRavvedimento column: 'DATA_RIF_RAVVEDIMENTO'

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

        flagIntRateSoloEvasa type: SiNoType
        flagRateOneri type: SiNoType


        table 'pratiche_tributo'

        version false
    }

    boolean getFlagDenuncia() {
        this.flagDenuncia ?: false
    }

    static constraints = {
        data nullable: true
        numero nullable: true, maxSize: 15
        tipoCarica nullable: true
        denunciante nullable: true, maxSize: 60
        indirizzoDen nullable: true, maxSize: 50
        comuneDenunciante nullable: true
        codFiscaleDen nullable: true, maxSize: 16
        partitaIvaDen nullable: true, maxSize: 11
        dataNotifica nullable: true
        tipoNotifica nullable: true
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
        tipoRavvedimento nullable: true
        flagDePag nullable: true
        documentoId nullable: true
        calcoloRate nullable: true
        flagIntRateSoloEvasa nullable: true
        tipoViolazione nullable: true
        dataScadenza nullable: true
        flagRateOneri nullable: true
        scadenzaPrimaRata nullable: true
        dataRiferimentoRavvedimento nullable: true
    }

    def springSecurityService
    static transients = ['springSecurityService',
                         'webCalcoloIndividuale',
                         'contattoContribuente'
    ]

    def beforeValidate() {
        versamenti*.beforeValidate()
        utente =  springSecurityService.currentUser?.id ?: utente
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser?.id ?: utente
    }


    int compareTo(PraticaTributo obj) {
        obj.anno <=> anno ?: id <=> obj.id
    }

    void setWebCalcoloIndividuale(WebCalcoloIndividuale webCalcoloIndividuale) {
        if (webCalcoloIndividuale)
            addToWebCalcoliIndividuale(webCalcoloIndividuale)
        else
            webCalcoliIndividuale?.clear()
    }

    WebCalcoloIndividuale getWebCalcoloIndividuale() {
        (webCalcoliIndividuale?.empty) ? null : webCalcoliIndividuale?.getAt(0)
    }

    void setContattoContribuente(ContattoContribuente contattoContribuente) {
        if (contattoContribuente)
            addToContattiContribuente(contattoContribuente)
        else
            contattiContribuente?.clear()
    }

    ContattoContribuente getContattoContribuente() {
        (contattiContribuente?.empty) ? null : contattiContribuente?.getAt(0)
    }
}
