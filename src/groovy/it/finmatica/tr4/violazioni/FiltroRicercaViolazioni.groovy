package it.finmatica.tr4.violazioni

import it.finmatica.tr4.commons.TipoPratica

class FiltroRicercaViolazioni {

    String tipoPraticaIniziale

    def tipoPratica
    def tipoTributo
    def cognome
    def nome
    def cf
    def numeroIndividuale
    def codContribuente
    def tipiStatoSelezionati
    def tuttiTipiStatoSelezionati
    def tipoAtto
    def tipiAttoSelezionati
    def tuttiTipiAttoSelezionati
    def daAnno
    def aAnno
    def daData
    def aData
    def daNumeroPratica
    def aNumeroPratica
    def tipoNotifica
    def daDataNotifica
    def aDataNotifica
    def nessunaDataNotifica
    def daImporto
    def aImporto
    def daDataPagamento
    def aDataPagamento
    def indirizzo
    def indirizzoDenomUff
    def daCivico
    def aCivico
    def titoloOccupazione
    def naturaOccupazione
    def destinazioneUso
    def assenzaEstremiCat
    def codiceTributo
    def daCategoria
    def aCategoria
    def daTariffa
    def aTariffa
    def daDataAnagrafeTributaria
    def aDataAnagrafeTributaria
    def tipologiaRate
    def daImportoRateizzato
    def aImportoRateizzato
    def daDataRateazione
    def aDataRateazione
    def daDataStampa
    def aDataStampa
    def daStampare = false
    def daDataScadenza
    def aDataScadenza
    def daDataRifRavv
    def aDataRifRavv

    /**
     * T - Tutti
     *  S - Residenti
     *  N - Non Residenti
     */
    def residente = "T"

    /**
     * T - Tutti
     *  S - A Ruolo
     *  N - Non a Ruolo
     */
    def aRuolo = 'T'

    /**
     * T - Tutti
     *  S - Inviato a PagoPA
     *  N - Non inviato a PagoPA
     */
    def inviatoPagoPa = 'T'
    def conSpeseNotifica = 'T'

    // Filtri aggiuntivi selezionabili dopo la ricerca
    def tipoAttoSanzione = 'T'
    def statoSoggetto = 'E'
    def flagDenuncia = 'T'
    def tipoEvento = 'TUTTI'
    def flagPossesso = 'T'
    def soloPraticheTotali = false
    def tipoRapporto = 'T'

    def rateizzate = [
            tributi: [IMU  : true,
                      TASI : true,
                      TARI : true,
                      PUBBL: true,
                      COSAP: true
            ],
            tipo   : [S: true, L: true, A: true],
            conRate: 'T'
    ]

    // Filtri catalogo Stati e Tipi Atto -> Fuori dal "Filtro attivo"
    def statoAttiSelezionati
    def statoAttiSelezionatiTributo = [:]

    def resetRateizzate() {
        rateizzate.tributi.each {
            it.value = true
        }
        rateizzate.tipo.each {
            it.value = true
        }
        rateizzate.conRate = 'T'
    }

    def filtroAttivo() {
        return filtroAttivoNoTipiAtto() || tipiAttoSelezionati
    }

    def filtroAttivoNoTipiAtto() {
        return (
                cognome || nome || cf
                        || numeroIndividuale || codContribuente || tipiStatoSelezionati        /// || tipiAttoSelezionati
                        || daAnno || aAnno || daData || aData
                        || daNumeroPratica || aNumeroPratica || daDataNotifica || aDataNotifica || nessunaDataNotifica || tipoNotifica
                        || daImporto || aImporto || daDataPagamento || aDataPagamento
                        || indirizzo || daCivico || aCivico
                        || titoloOccupazione || naturaOccupazione || destinazioneUso || assenzaEstremiCat
                        || codiceTributo || daCategoria || aCategoria || daTariffa || aTariffa || daDataAnagrafeTributaria || aDataAnagrafeTributaria
                        || tipologiaRate || daImportoRateizzato || aImportoRateizzato || daDataRateazione || aDataRateazione || daDataStampa || aDataStampa
                        || daStampare || daDataScadenza || aDataScadenza || aRuolo != "T" || inviatoPagoPa != "T" || conSpeseNotifica != "T" || residente != "T" || dataRifRavvAttivo()
        )
    }

    def dataRifRavvAttivo() {
        return (tipoPraticaIniziale == TipoPratica.V.tipoPratica) && (daDataRifRavv || aDataRifRavv)
    }

    def filtroAttivoPerTipoPratica(String tipoPratica) {
        if (tipoPraticaIniziale == '*') {
            return filtroAttivoNoTipiAtto()
        } else {
            return filtroAttivo()
        }
    }

    def validate() {
        def error = ""

        error += checkEstremi(daCivico, aCivico, "N. Civico")
        error += checkEstremi(daAnno, aAnno, "Anno")
        error += checkEstremi(daData, aData, "Data")
        error += checkEstremi(daDataNotifica, aDataNotifica, "Data Notifica")
        error += checkEstremi(daImporto, aImporto, "Importo")
        error += checkEstremi(daDataPagamento, aDataPagamento, "Data Pagamento")
        error += checkEstremi(daCategoria, aCategoria, "Categoria")
        error += checkEstremi(daTariffa, aTariffa, "Tariffa")
        error += checkEstremi(daImportoRateizzato, aImportoRateizzato, "Imp.Rateizzato")
        error += checkEstremi(daDataRateazione, aDataRateazione, "Data Rateazione")
        error += checkEstremi(daDataAnagrafeTributaria, aDataAnagrafeTributaria, "Data Anagr.Tributaria")
        error += checkEstremi(daDataStampa, aDataStampa, "Data Stampa")
        error += checkEstremi(daDataScadenza, aDataScadenza, "Data Scadenza")

        if (tipoPraticaIniziale == TipoPratica.V.tipoPratica) {
            error += checkEstremi(daDataScadenza, aDataScadenza, "Data Pagamento")
        }


        def isDaNumeroNotEmpty = daNumeroPratica != null && daNumeroPratica != ""
        def isANumeroNotEmpty = aNumeroPratica != null && aNumeroPratica != ""

        if (isANumeroNotEmpty && aNumeroPratica.contains('%') &&
                (!isDaNumeroNotEmpty || (isDaNumeroNotEmpty && !daNumeroPratica.contains('%')))) {
            error += "Carattere '%' non consentito nel campo Numero A"
        }

        // Nel caso in cui sia dal che al contengono un valore numerico si controlla che dal < al
        if (isANumeroNotEmpty && isDaNumeroNotEmpty && daNumeroPratica.isNumber() && aNumeroPratica.isNumber()) {
            if ((aNumeroPratica as Long) < (daNumeroPratica as Long)) {
                error += "Numero Dal deve essere minore di Numero Al"
            }
        }


        return error
    }

    FiltroRicercaViolazioni clone() {

        FiltroRicercaViolazioni cloned = new FiltroRicercaViolazioni()

        cloned.tipoPratica = this.tipoPratica
        cloned.tipoTributo = this.tipoTributo
        cloned.cognome = this.cognome
        cloned.nome = this.nome
        cloned.cf = this.cf
        cloned.numeroIndividuale = this.numeroIndividuale
        cloned.codContribuente = this.codContribuente
        cloned.tipiStatoSelezionati = this.tipiStatoSelezionati
        cloned.tuttiTipiStatoSelezionati = this.tuttiTipiStatoSelezionati
        cloned.tipoAtto = this.tipoAtto
        cloned.tipiAttoSelezionati = this.tipiAttoSelezionati
        cloned.tuttiTipiAttoSelezionati = this.tuttiTipiAttoSelezionati
        cloned.daAnno = this.daAnno
        cloned.aAnno = this.aAnno
        cloned.daData = this.daData
        cloned.aData = this.aData
        cloned.daNumeroPratica = this.daNumeroPratica
        cloned.aNumeroPratica = this.aNumeroPratica
        cloned.tipoNotifica = this.tipoNotifica
        cloned.daDataNotifica = this.daDataNotifica
        cloned.aDataNotifica = this.aDataNotifica
        cloned.nessunaDataNotifica = this.nessunaDataNotifica
        cloned.daImporto = this.daImporto
        cloned.aImporto = this.aImporto
        cloned.daDataPagamento = this.daDataPagamento
        cloned.aDataPagamento = this.aDataPagamento
        cloned.indirizzo = this.indirizzo
        cloned.indirizzoDenomUff = this.indirizzoDenomUff
        cloned.daCivico = this.daCivico
        cloned.aCivico = this.aCivico
        cloned.titoloOccupazione = this.titoloOccupazione
        cloned.naturaOccupazione = this.naturaOccupazione
        cloned.destinazioneUso = this.destinazioneUso
        cloned.assenzaEstremiCat = this.assenzaEstremiCat
        cloned.codiceTributo = this.codiceTributo
        cloned.daCategoria = this.daCategoria
        cloned.aCategoria = this.aCategoria
        cloned.daTariffa = this.daTariffa
        cloned.aTariffa = this.aTariffa
        cloned.daDataAnagrafeTributaria = this.daDataAnagrafeTributaria
        cloned.aDataAnagrafeTributaria = this.aDataAnagrafeTributaria
        cloned.tipologiaRate = this.tipologiaRate
        cloned.daImportoRateizzato = this.daImportoRateizzato
        cloned.aImportoRateizzato = this.aImportoRateizzato
        cloned.daDataRateazione = this.daDataRateazione
        cloned.aDataRateazione = this.aDataRateazione
        cloned.daDataStampa = this.daDataStampa
        cloned.aDataStampa = this.aDataStampa
        cloned.daStampare = this.daStampare
        cloned.aRuolo = this.aRuolo
        cloned.inviatoPagoPa = this.inviatoPagoPa
        cloned.conSpeseNotifica = this.conSpeseNotifica

        cloned.tipoAttoSanzione = this.tipoAttoSanzione
        cloned.statoSoggetto = this.statoSoggetto
        cloned.aRuolo = this.aRuolo
        cloned.flagDenuncia = this.flagDenuncia
        cloned.tipoEvento = this.tipoEvento
        cloned.flagPossesso = this.flagPossesso
        cloned.soloPraticheTotali = this.soloPraticheTotali
        cloned.tipoRapporto = this.tipoRapporto

        cloned.rateizzate = this.rateizzate.clone()

        cloned.statoAttiSelezionati = this.statoAttiSelezionati ?: []

        cloned.daDataScadenza = this.daDataScadenza
        cloned.aDataScadenza = this.aDataScadenza

        cloned.daDataRifRavv = this.daDataRifRavv
        cloned.aDataRifRavv = this.aDataRifRavv

        cloned.residente = this.residente

        return cloned
    }

    private checkEstremi(def da, def a, def label) {
        if (da && a && da > a) {
            return "Valori di $label non coerenti.\n"
        }

        return ""
    }
}
