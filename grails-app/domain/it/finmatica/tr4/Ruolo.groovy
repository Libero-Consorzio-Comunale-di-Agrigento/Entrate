package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.tipi.SiNoType

class Ruolo {

    TipoTributo tipoTributo
    int tipoRuolo
    Short annoRuolo
    Short annoEmissione
    Short progrEmissione
    Date dataEmissione
    String descrizione
    Short rate
    boolean specieRuolo
    Short codSede
    Date dataDenuncia
    Date scadenzaPrimaRata
    Date invioConsorzio
    Ruolo ruoloRif
    Ad4Utente utente
    Date lastUpdated
    String note
    boolean importoLordo
    Short aAnnoRuolo
    String cognomeResp
    String nomeResp
    Date dataFineInteressi
    String statoRuolo
    Ruolo ruoloMaster
    Date scadenzaRata2
    Date scadenzaRata3
    Date scadenzaRata4
    String tipoCalcolo
    String tipoEmissione
    BigDecimal percAcconto
    String flagCalcoloTariffaBase
    String flagTariffeRuolo
    Date scadenzaAvviso1
    Date scadenzaAvviso2
    Date scadenzaAvviso3
    Date scadenzaAvviso4
    Date scadenzaRataUnica
    Date scadenzaAvvisoUnico

    String flagDePag

    Date terminePagamento
    Short progrInvio
    String flagIscrittiAltroRuolo
    String flagEliminaDepag

    static hasMany = [oggettiImposta     : OggettoImposta
                      , ruoliContribuente: RuoloContribuente
                      , ruoliEccedenze   : RuoloEccedenza
                      , versamenti       : Versamento]

    static mapping = {
        ///	id column: "ruolo", generator: "assigned"
        id column: "ruolo", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "RUOLI_NR"]

        tipoTributo column: "tipo_tributo"
        ruoloRif column: "ruolo_rif"
        ruoloMaster column: "ruolo_master"
        utente column: "utente", ignoreNotFound: true
        dataEmissione type: 'date', column: 'data_emissione'
        dataDenuncia type: 'date', column: 'data_denuncia'
        scadenzaPrimaRata type: 'date', column: 'scadenza_prima_rata'
        invioConsorzio type: 'date', column: 'invio_consorzio'
        lastUpdated type: 'date', column: 'data_variazione'
        dataFineInteressi type: 'date', column: 'data_fine_interessi'
        scadenzaRata2 type: 'date', column: 'scadenza_rata_2'
        scadenzaRata3 type: 'date', column: 'scadenza_rata_3'
        scadenzaRata4 type: 'date', column: 'scadenza_rata_4'
        scadenzaAvviso1 type: 'date', column: 'scadenza_avviso_1'
        scadenzaAvviso2 type: 'date', column: 'scadenza_avviso_2'
        scadenzaAvviso3 type: 'date', column: 'scadenza_avviso_3'
        scadenzaAvviso4 type: 'date', column: 'scadenza_avviso_4'
        scadenzaRataUnica type: 'date', column: 'scadenza_rata_unica'
        scadenzaAvvisoUnico type: 'date', column: 'scadenza_avviso_unico'

        flagDePag column: 'flag_depag'

        terminePagamento type: 'date', column: 'termine_pagamento'
        progrInvio column: "progr_invio"
        scadenzaRataUnica type: 'date'
        scadenzaAvvisoUnico type: 'date'

        importoLordo type: SiNoType
        specieRuolo type: 'numeric_boolean'
        table 'ruoli'
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        //progrEmissione unique: ["annoEmissione", "annoRuolo", "tipoRuolo", "tipoTributo"]
        dataEmissione nullable: true
        descrizione maxSize: 100
        rate nullable: true
        codSede nullable: true
        dataDenuncia nullable: true
        scadenzaPrimaRata nullable: true
        invioConsorzio nullable: true
        ruoloRif nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        importoLordo nullable: true, maxSize: 1
        aAnnoRuolo nullable: true
        cognomeResp nullable: true, maxSize: 30
        nomeResp nullable: true, maxSize: 30
        dataFineInteressi nullable: true
        statoRuolo nullable: true, inList: ['RID_EMESSI', 'RID_CARICATI']
        ruoloMaster nullable: true
        scadenzaRata2 nullable: true
        scadenzaRata3 nullable: true
        scadenzaRata4 nullable: true
        tipoCalcolo nullable: true, inList: ['T', 'N']
        tipoEmissione nullable: true, inList: ['A', 'S', 'T', 'X']
        tipoRuolo inList: [1, 2, 3, 4, 5]
        percAcconto nullable: true
        flagCalcoloTariffaBase nullable: true
        flagTariffeRuolo nullable: true
        scadenzaAvviso1 nullable: true
        scadenzaAvviso2 nullable: true
        scadenzaAvviso3 nullable: true
        scadenzaAvviso4 nullable: true
        scadenzaRataUnica nullable: true
        scadenzaAvvisoUnico nullable: true
        flagDePag nullable: true
        flagIscrittiAltroRuolo nullable: true
        flagEliminaDepag nullable: true

        terminePagamento nullable: true
        progrInvio nullable: true
        scadenzaRataUnica nullable: true
        scadenzaAvvisoUnico nullable: true
    }

    def springSecurityService
    static transients = ['springSecurityService']
}
