package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.OggettoPratica

class Oggetto {

    Edificio edificio
    Fonte fonte
    TipoOggetto tipoOggetto
    TipoUso tipoUso
    ArchivioVie archivioVie
    CategoriaCatasto categoriaCatasto

    String descrizione

    String indirizzoLocalita

    Integer numCiv
    String suffisso
    String scala
    String piano
    Short interno
    String sezione
    String sezionePadded
    String foglio
    String foglioPadded
    String numero
    String numeroPadded
    String subalterno
    String subalternoPadded
    String zona
    String zonaPadded
    String estremiCatasto
    String partita
    String partitaPadded
    Integer progrPartita
    String protocolloCatasto
    Short annoCatasto
    String classeCatasto
    BigDecimal consistenza
    BigDecimal vani
    String qualita
    Integer ettari
    Byte are
    Byte centiare
    String flagSostituito
    String flagCostruitoEnte

    Ad4Utente utente
    Date lastUpdated
    String note
    String codEcografico
    TipoQualita tipoQualita
    Date dataCessazione
    BigDecimal superficie
    BigDecimal idImmobile

    String indirizzo

    BigDecimal latitudine
    BigDecimal longitudine
	BigDecimal aLatitudine
	BigDecimal aLongitudine

    SortedSet<CivicoOggetto> civiciOggetto
    SortedSet<PartizioneOggetto> partizioniOggetto
    SortedSet<UtilizzoOggetto> utilizziOggetto
    SortedSet<NotificaOggetto> notificheOggetto
    SortedSet<RiferimentoOggetto> riferimentiOggetto
    SortedSet<OggettoPratica> oggettiPratica
    SortedSet<CodiceRfid> codiciRfid

    static hasMany = [riferimentiOggetto : RiferimentoOggetto
                      , oggettiPratica   : OggettoPratica
                      , civiciOggetto    : CivicoOggetto
                      , partizioniOggetto: PartizioneOggetto
                      , notificheOggetto : NotificaOggetto
                      , utilizziOggetto  : UtilizzoOggetto
                      , codiciRfid       : CodiceRfid]

    static mapping = {
        id column: 'oggetto', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "OGGETTI_NR"]
        edificio column: 'edificio'
        fonte column: 'fonte'
        tipoOggetto column: 'tipo_oggetto'
        tipoUso column: 'tipo_uso'
        archivioVie column: 'cod_via'
        categoriaCatasto column: 'categoria_catasto'
        tipoQualita column: 'tipo_qualita'
        ente column: 'ente'
        lastUpdated sqlType: 'Date', column: 'DATA_VARIAZIONE'
        dataCessazione sqlType: 'Date', column: 'DATA_CESSAZIONE'
        utente column: "utente", ignoreNotFound: true

        sezionePadded formula: "lpad(sezione, 3, ' ')"
        foglioPadded formula: "lpad(foglio, 5, ' ')"
        numeroPadded formula: "lpad(numero, 5, ' ')"
        subalternoPadded formula: "lpad(subalterno, 4, ' ')"
        zonaPadded formula: "lpad(zona, 3, ' ')"
        partitaPadded formula: "lpad(partita, 8, ' ')"

        // in questo modo riesco a cancellare tutti i figli
        civiciOggetto cascade: 'none'
        utilizziOggetto cascade: 'all-delete-orphan'
        partizioniOggetto cascade: 'all-delete-orphan'
        riferimentiOggetto cascade: 'all-delete-orphan'
        notificheOggetto cascade: 'all-delete-orphan'
        codiciRfid cascade: 'all-delete-orphan'

        table 'oggetti'
        version false
    }

    static constraints = {
        descrizione nullable: true, maxSize: 60
        edificio nullable: true
        indirizzoLocalita nullable: true, maxSize: 36
        archivioVie nullable: true
        numCiv nullable: true
        suffisso nullable: true, maxSize: 5
        scala nullable: true, maxSize: 5
        piano nullable: true, maxSize: 5
        interno nullable: true
        sezione nullable: true, maxSize: 3
        foglio nullable: true, maxSize: 5
        numero nullable: true, maxSize: 5
        subalterno nullable: true, maxSize: 4
        zona nullable: true, maxSize: 3
        estremiCatasto nullable: true, maxSize: 20
        partita nullable: true, maxSize: 8
        progrPartita nullable: true
        protocolloCatasto nullable: true, maxSize: 6
        annoCatasto nullable: true
        categoriaCatasto nullable: true, maxSize: 3
        classeCatasto nullable: true, maxSize: 2
        tipoUso nullable: true
        consistenza nullable: true
        vani nullable: true
        qualita nullable: true, maxSize: 60
        ettari nullable: true
        are nullable: true
        centiare nullable: true
        flagSostituito nullable: true, maxSize: 1
        flagCostruitoEnte nullable: true, maxSize: 1
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        codEcografico nullable: true, maxSize: 15
        tipoQualita nullable: true
        dataCessazione nullable: true
        lastUpdated nullable: true
        superficie nullable: true
        idImmobile nullable: true
        latitudine nullable: true
        longitudine nullable: true
        aLatitudine nullable: true
        aLongitudine nullable: true
    }

    def springSecurityService

    static transients = ['indirizzo', 'springSecurityService']

    public String getIndirizzo() {
        return (archivioVie ? archivioVie?.denomUff : indirizzoLocalita ?: "") + (numCiv ? ", $numCiv" : "") + (suffisso ? "/$suffisso" : "") + (interno ? " int. $interno" : "")
    }

    def beforeValidate() {
        utente = springSecurityService.currentUser
        utilizziOggetto*.beforeValidate()
        riferimentiOggetto*.beforeValidate()
        codiciRfid*.beforeValidate()
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser
        utilizziOggetto*.beforeValidate()
        riferimentiOggetto*.beforeValidate()
        codiciRfid*.beforeValidate()
    }
}
