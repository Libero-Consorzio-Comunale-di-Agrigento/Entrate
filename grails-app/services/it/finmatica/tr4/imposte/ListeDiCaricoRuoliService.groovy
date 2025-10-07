package it.finmatica.tr4.imposte

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.SpecieRuolo
import it.finmatica.tr4.commons.TipoRuolo
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.RuoliAutomaticiDTO
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Date
import java.text.DecimalFormat

@Transactional(rollbackFor = [RuntimeException.class, Application20999Error.class])
class ListeDiCaricoRuoliService {

    static transactional = false

    def springSecurityService
    def sessionFactory
    CommonService commonService
    IntegrazioneDePagService integrazioneDePagService

    def dataSource
    TributiSession tributiSession

    static enum Tracciato {
        T290("290"), T600("600")

        final code

        private Tracciato(String code) {
            this.code = code
        }
    }

    def getListaAnni() {

        def lista = RuoliElenco.createCriteria().list() {
            projections { distinct("annoRuolo") }
            order("annoRuolo", "rutrDesc")
        }
        lista << ""
    }

    // Verifica dati lista di carico
    def verificaListaDiCarico(RuoloDTO ruolo) {

        def subReport = [:]

        String message = ''
        Long result = 0

        Boolean esistente = (ruolo.id ?: 0) > 0

        Short tipoRuolo = ruolo.tipoRuolo ?: -1
        Boolean specieRuolo = ruolo.specieRuolo
        String tipoCalcolo = ruolo.tipoCalcolo
        String tipoEmissione = ruolo.tipoEmissione

        Short annoRuolo = ruolo.annoRuolo ?: 0
        Short annoEmissione = ruolo.annoEmissione ?: 0
        Short progEmissione = ruolo.progrEmissione ?: -1

        def dataEmissione = ruolo.dataEmissione
        def dataInvio = ruolo.invioConsorzio

        if ((tipoRuolo != TipoRuolo.PRINCIPALE.tipoRuolo) && (tipoRuolo != TipoRuolo.SUPPLETTIVO.tipoRuolo)) {
            message += "Tipo Ruolo non impostato o non valido\n"
            result = 2
        }
        if (specieRuolo != SpecieRuolo.ORDINARIO.specieRuolo) {
            if ((tipoCalcolo != 'T') && (tipoCalcolo != 'N')) {
                message += "Tipo Calcolo non impostato o non valido\n"
                result = 2
            }
        }
        if ((tipoEmissione != 'A') && (tipoEmissione != 'S') && (tipoEmissione != 'T')) {
            message += "Tipo Emissione non impostato o non valido\n"
            result = 2
        }

        if ((annoRuolo < 1990) || (annoRuolo > 2099)) {
            message += "Anno Ruolo non valido, specificare un valore compreso tra 1990 e 2099\n"
            result = 2
        }
        if ((annoEmissione < 1990) || (annoEmissione > 2099)) {
            message += "Anno Emissione non valido, specificare un valore compreso tra 1990 e 2099\n"
            result = 2
        }
        if ((progEmissione < 1) || (progEmissione > 32767)) {
            message += "Progr. Emissione non valido, specificare un valore compreso tra 1 e 99\n"
            result = 2
        }
        if (dataEmissione == null) {
            message += "Data Emissione non valida, specificare un valore\n"
            result = 2
        } else if ((dataEmissione != null) && (dataInvio != null) && (dataEmissione.clearTime() > dataInvio.clearTime())) {
            message += "Data Emissione non puo' essere posteriore alla data Invio Consorzio\n"
            result = 2
        }

        String descrizione = ruolo.descrizione ?: ''
        if (descrizione.length() < 3) {
            message += "Descrizione non valida, deve contenere almeno tre caratteri\n"
            result = 2
        }

        Short numRate = ruolo.rate ?: 0
        Boolean flagDePag = (ruolo.flagDePag == 'S')

        def today = Calendar.getInstance().getTime()
        def rataAttuale
        def rataPrecedente

        if ((numRate < 1) || (numRate > 4)) {
            message += "Numero Rate non valida, deve essere compreso tra 1 e 4\n"
            result = 2
        }
        if (numRate > 0) {
            if (!ruolo.scadenzaPrimaRata) {
                message += "Rate: Scadenze 1 non compilata\n"
                if (result < 1) {
                    result = 1
                }
            }
            if (flagDePag) {
                if (!ruolo.scadenzaAvviso1) {
                    message += "Rate: Scadenze Avvisi 1 non compilata\n"
                    if (result < 1) {
                        result = 1
                    }
                } else {
                    if (ruolo.scadenzaPrimaRata <= today) {
                        message += "Rate: Scadenze Avvisi 1 non valida, deve essere posteriore a data odierna\n"
                        result = (esistente) ? 1 : 2
                    }
                }
            }
        }
        if (numRate > 1) {
            subReport = verificaScadenzaRata(ruolo.scadenzaRata2, ruolo.scadenzaPrimaRata, 2)
            if (subReport.result > 0) {
                message += subReport.message
                if (result < subReport.result) {
                    result = subReport.result
                }
            }
            if (flagDePag) {
                subReport = verificaScadenzaAvviso(ruolo.scadenzaAvviso2, ruolo.scadenzaAvviso1, 2)
                if (subReport.result > 0) {
                    message += subReport.message
                    if (result < subReport.result) {
                        result = subReport.result
                    }
                }
            }
        }
        if (numRate > 2) {
            subReport = verificaScadenzaRata(ruolo.scadenzaRata3, ruolo.scadenzaRata2, 3)
            if (subReport.result > 0) {
                message += subReport.message
                if (result < subReport.result) {
                    result = subReport.result
                }
            }
            if (flagDePag) {
                subReport = verificaScadenzaAvviso(ruolo.scadenzaAvviso3, ruolo.scadenzaAvviso2, 3)
                if (subReport.result > 0) {
                    message += subReport.message
                    if (result < subReport.result) {
                        result = subReport.result
                    }
                }
            }
        }
        if (numRate > 3) {
            subReport = verificaScadenzaRata(ruolo.scadenzaRata4, ruolo.scadenzaRata3, 4)
            if (subReport.result > 0) {
                message += subReport.message
                if (result < subReport.result) {
                    result = subReport.result
                }
            }
            if (flagDePag) {
                subReport = verificaScadenzaAvviso(ruolo.scadenzaAvviso4, ruolo.scadenzaAvviso3, 4)
                if (subReport.result > 0) {
                    message += subReport.message
                    if (result < subReport.result) {
                        result = subReport.result
                    }
                }
            }
        }

        if (ruolo.scadenzaRataUnica != null && ruolo.scadenzaRataUnica == ruolo.scadenzaPrimaRata) {
            message += "Rate: Scadenze 1 non valida, deve essere diversa da Scadenza Rata Unica\n"
            result = 2
        }

        if (flagDePag && ruolo.scadenzaAvvisoUnico != null && ruolo.scadenzaAvvisoUnico == ruolo.scadenzaAvviso1) {
            message += "Rate: Scadenze Avvisi 1 non valida, deve essere diversa da Scadenza Avviso Unico\n"
            result = 2
        }

        if (ruolo.id == null) {
            if (checkRuoloEsistente(ruolo)) {
                message += "Progr. Emissione gia' presente per questo Tipo Tributo, Anno Ruolo ed Anno Emissione\n"
                result = 2
            }
        }

        subReport = checkCoerenzaInvioConsorzio(ruolo)
        if (subReport.result > 0) {
            message += subReport.message
            if (result < subReport.result) {
                result = subReport.result
            }
        }

        return [result: result, message: message]
    }

    // Verifica dati ruolo coattivo
    def verificaRuoloCoattivo(RuoloDTO ruolo) {

        String message = ''
        Long result = 0

        Short annoRuolo = ruolo.annoRuolo ?: 0
        Short annoEmissione = ruolo.annoEmissione ?: 0
        Short progEmissione = ruolo.progrEmissione ?: -1

        def dataEmissione = ruolo.dataEmissione
        def dataInvio = ruolo.invioConsorzio

        if ((annoRuolo < 1990) || (annoRuolo > 2099)) {
            message += "Anno Ruolo non valido, specificare un valore compreso tra 1990 e 2099\n"
            result = 1
        }
        if ((annoEmissione < 1990) || (annoEmissione > 2099)) {
            message += "Anno Emissione non valido, specificare un valore compreso tra 1990 e 2099\n"
            result = 1
        }
        if ((progEmissione < 1) || (progEmissione > 32767)) {
            message += "Progr. Emissione non valido, specificare un valore compreso tra 1 e 32767\n"
            result = 1
        }
        if (dataEmissione == null) {
            message += "Data Emissione è obbligatoria\n"
            result = 1
        }
        if ((dataEmissione != null) && (dataInvio != null) && (dataEmissione > dataInvio)) {
            message += "Data Emissione non puo' essere posteriore alla data Invio Consorzio\n"
            result = 1
        }

        String descrizione = ruolo.descrizione ?: ''
        if (descrizione.length() < 3) {
            message += "Descrizione non valida, deve contenere almeno tre caratteri\n"
            result = 1
        }

        if (ruolo.id == null) {
            if (checkRuoloEsistente(ruolo)) {
                message += "- Progr. Emissione gia\' presente per questo Tipo Tributo, Anno Ruolo ed Anno Emissione\n"
                result = 1
            }
        }

        return [result: result, message: message]
    }

    // Verifica coerenza data scadenza rata con precedente
    def verificaScadenzaRata(java.util.Date rataAttuale, java.util.Date rataPrecedente, Integer rata) {

        String message = ''
        Long result = 0

        if (!rataAttuale) {
            message += "Rate: Scadenze ${rata} non compilata !\n"
            if (result < 1) {
                result = 1
            }
        } else {
            if (rataPrecedente == null) rataPrecedente = new java.util.Date()
            if (rataPrecedente > rataAttuale) {
                message += "Rate: Scadenze ${rata} non valida, deve essere posteriore o uguale a Scadenze ${rata - 1}\n"
                result = 2
            }
        }

        return [result: result, message: message]
    }

    // Verifica coerenza data scadenza avviso con precedente
    def verificaScadenzaAvviso(java.util.Date rataAttuale, java.util.Date rataPrecedente, Integer rata) {

        String message = ''
        Long result = 0

        if (!rataAttuale) {
            message += "Rate: Scadenze Avvisi ${rata} non compilata\n"
            if (result < 1) {
                result = 1
            }
        } else {
            if (rataPrecedente == null) {
                rataPrecedente = new java.util.Date()
            }
            if (rataPrecedente > rataAttuale) {
                message += "Rate: Scadenze Avvisi ${rata} non valida, deve essere posteriore o uguale a Scadenze Avvisi ${rata - 1}\n"
                result = 2
            }
        }

        return [result: result, message: message]
    }

    // Salva la lista di carico
    def salvaListaDiCarico(RuoloDTO ruoloDTO, def eliminaCalcoloPrecedente = false) {

        String message = ''
        Long result = 0

        if (eliminaCalcoloPrecedente) {
            if (ruoloDTO.id) {
                // Si deve passare il valore negativo per indicare alla procedure di non eliminare la testata.
                proceduraEliminazioneRuolo(ruoloDTO.id * -1, null)
            }
        }

        Ruolo ruolo = ruoloDTO.getDomainObject()

        if (ruolo == null) {
            ruolo = new Ruolo()
            ruolo.tipoTributo = ruoloDTO.tipoTributo.getDomainObject()
            ruolo.specieRuolo = ruoloDTO.specieRuolo
            ruolo.annoRuolo = ruoloDTO.annoRuolo
            ruolo.annoEmissione = ruoloDTO.annoEmissione
            ruolo.progrEmissione = ruoloDTO.progrEmissione
        }

        ruolo.tipoRuolo = ruoloDTO.tipoRuolo
        ruolo.tipoCalcolo = ruoloDTO.tipoCalcolo

        ruolo.tipoEmissione = ruoloDTO.tipoEmissione
        ruolo.percAcconto = ruoloDTO.percAcconto

        ruolo.importoLordo = ruoloDTO.importoLordo
        ruolo.flagTariffeRuolo = ruoloDTO.flagTariffeRuolo
        ruolo.flagCalcoloTariffaBase = ruoloDTO.flagCalcoloTariffaBase
        ruolo.flagIscrittiAltroRuolo = ruoloDTO.flagIscrittiAltroRuolo

        ruolo.dataEmissione = ruoloDTO.dataEmissione

        ruolo.invioConsorzio = ruoloDTO.invioConsorzio
        ruolo.progrInvio = ruoloDTO.progrInvio

        ruolo.descrizione = ruoloDTO.descrizione
        ruolo.note = ruoloDTO.note

        ruolo.rate = ruoloDTO.rate

        ruolo.scadenzaPrimaRata = ruoloDTO.scadenzaPrimaRata
        ruolo.scadenzaRata2 = ruoloDTO.scadenzaRata2
        ruolo.scadenzaRata3 = ruoloDTO.scadenzaRata3
        ruolo.scadenzaRata4 = ruoloDTO.scadenzaRata4
        ruolo.scadenzaRataUnica = ruoloDTO.scadenzaRataUnica

        ruolo.flagDePag = ruoloDTO.flagDePag
        ruolo.flagEliminaDepag = ruoloDTO.flagEliminaDepag

        ruolo.scadenzaAvviso1 = ruoloDTO.scadenzaAvviso1
        ruolo.scadenzaAvviso2 = ruoloDTO.scadenzaAvviso2
        ruolo.scadenzaAvviso3 = ruoloDTO.scadenzaAvviso3
        ruolo.scadenzaAvviso4 = ruoloDTO.scadenzaAvviso4
        ruolo.scadenzaAvvisoUnico = ruoloDTO.scadenzaAvvisoUnico

        ruolo.cognomeResp = ruoloDTO.cognomeResp
        ruolo.nomeResp = ruoloDTO.nomeResp

        ruolo.utente = springSecurityService.currentUser

        ruolo.save(flush: true, failOnError: true)

        return [result: result, message: message, ruolo: ruolo.toDTO()]
    }

    // Salva il ruolo coattivo
    def salvaRuoloCoattivo(RuoloDTO ruoloDTO) {

        String message = ''
        Long result = 0

        Ruolo ruolo = ruoloDTO.getDomainObject()

        if (ruolo == null) {
            ruolo = new Ruolo()
            ruolo.tipoTributo = ruoloDTO.tipoTributo.getDomainObject()
            ruolo.tipoRuolo = ruoloDTO.tipoRuolo
            ruolo.specieRuolo = ruoloDTO.specieRuolo
            ruolo.annoRuolo = ruoloDTO.annoRuolo
            ruolo.annoEmissione = ruoloDTO.annoEmissione
            ruolo.progrEmissione = ruoloDTO.progrEmissione
        }

        ruolo.dataEmissione = ruoloDTO.dataEmissione

        ruolo.terminePagamento = ruoloDTO.terminePagamento

        ruolo.invioConsorzio = ruoloDTO.invioConsorzio
        ruolo.progrInvio = ruoloDTO.progrInvio

        ruolo.descrizione = ruoloDTO.descrizione

        ruolo.utente = springSecurityService.currentUser

        ruolo.save(flush: true, failOnError: true)

        return [result: result, message: message, ruolo: ruolo.toDTO()]
    }

    // Lancia procedura eliminazione ruolo
    def proceduraEliminazioneRuolo(Long ruoloId, String codFiscale) {

        try {
            Sql sql = new Sql(dataSource)

            sql.call('{call ELIMINAZIONE_RUOLO(?, ?)}',
                    [
                            ruoloId,
                            codFiscale
                    ]
            )

            return "OK"
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def ruoloDi(def dataEmissione, def dataDenuncia, def scadenzaPrimaRata, def invioConsorzio) {

        try {
            Sql sql = new Sql(dataSource)

            sql.call('{call RUOLI_DI(?, ?, ?, ?)}',
                    [
                            dataEmissione ? new Date(dataEmissione.getTime()) : null,
                            dataDenuncia ? new Date(dataDenuncia.getTime()) : null,
                            scadenzaPrimaRata ? new Date(scadenzaPrimaRata.getTime()) : null,
                            invioConsorzio ? new Date(invioConsorzio.getTime()) : null,
                    ]
            )

            return "OK"
        }
        catch (Exception e) {

            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }
    }

    // Lancia procedura inserimento ruolo coattivo
    def proceduraInserimentoRuoloCoattivo(Long ruoloId, String tipoPratica, String tipoEvento, def notificaDal, def notificaAl, def diffDovutoVersato) {

        try {
            def pUtente = springSecurityService.currentUser.id

            Sql sql = new Sql(dataSource)

            sql.call('{call INSERIMENTO_RUOLO_COATTIVO(?, ?, ?, ?, ?, ?, ?)}',
                    [
                            ruoloId,
                            tipoPratica,
                            tipoEvento,
                            notificaDal ? new Date(notificaDal.getTime()) : null,
                            notificaAl ? new Date(notificaAl.getTime()) : null,
                            pUtente,
                            diffDovutoVersato
                    ]
            )

            return "OK"
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    // Verifica esistenza del ruolo
    def checkRuoloEsistente(RuoloDTO ruolo) {

        Boolean esistente = false

        def esistenti = Ruolo.createCriteria().get {
            eq('tipoTributo.tipoTributo', ruolo.tipoTributo.tipoTributo)
            eq('tipoRuolo', ruolo.tipoRuolo)
            eq('annoRuolo', ruolo.annoRuolo)
            eq('annoEmissione', ruolo.annoEmissione)
            eq('progrEmissione', ruolo.progrEmissione)
        }

        return (esistenti != null)
    }

    // Verifica coerenza impostazioni emissione tra tuoli
    def checkCoerenzaInvioConsorzio(RuoloDTO ruolo) {

        def report = [
                result : 0,
                message: ''
        ]

        Long totalCount = 0

        if (ruolo.invioConsorzio) {

            def filtri = [:]

            String flagTariffeRuolo = ruolo.flagTariffeRuolo ?: 'N'

            filtri << ['tipoTributo': ruolo.tipoTributo.tipoTributo]
            filtri << ['annoRuolo': ruolo.annoRuolo]
            filtri << ['idRuolo': ruolo.id ?: 0]
            filtri << ['flagTariffeRuolo': flagTariffeRuolo]

            String sql = """
					SELECT
						COUNT(*) AS NUM_RUOLI
					FROM
						RUOLI
					WHERE
						TIPO_TRIBUTO = :tipoTributo AND
						ANNO_RUOLO = :annoRuolo AND
						INVIO_CONSORZIO IS NOT NULL AND
						NVL(FLAG_TARIFFE_RUOLO,'N') <> :flagTariffeRuolo AND
						RUOLO <> :idRuolo
			"""

            def results = sessionFactory.currentSession.createSQLQuery(sql).with {

                filtri.each { k, v ->
                    setParameter(k, v)
                }
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

                list()
            }

            results.each {
                totalCount += (it['NUM_RUOLI'] as Long) ?: 0
            }
        }

        if (totalCount > 0) {
            report.message = "Non è possibile emettere ruoli con modalità di calcolo diverse per lo stesso anno (tariffe/coefficienti)\n"
            report.result = 2
        }

        return report
    }

    // Verifica coerenza calcolo con precedente
    def checkCalcoloRuolo(RuoloDTO ruolo) {

        def report = [
                result : 0,
                message: ''
        ]

        if (ruolo.id) {

            String campi = ""

            Ruolo ruoloRaw = Ruolo.get(ruolo.id)

            if (ruolo.importoLordo != ruoloRaw.importoLordo) {
                if (!campi.isEmpty()) {
                    campi += ", "
                }
                campi += "Importo Lordo"
            }
            if (ruolo.flagTariffeRuolo != ruoloRaw.flagTariffeRuolo) {
                if (!campi.isEmpty()) {
                    campi += ", "
                }
                campi += "Tariffa Precalcolata"
            }
            if (ruolo.flagCalcoloTariffaBase != ruoloRaw.flagCalcoloTariffaBase) {
                if (!campi.isEmpty()) {
                    campi += ", "
                }
                campi += "Tariffa Base"
            }
            if (ruolo.rate != ruoloRaw.rate) {
                if (!campi.isEmpty()) {
                    campi += ", "
                }
                campi += "Numero Rate"
            }

            if (!campi.isEmpty()) {
                report.message = "E' stato modificato il valore di (${campi})"
                report.result = 1
            }
        }

        return report
    }

    // Legge utenze del ruolo
    def getUtenzeRuolo(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        def ruoliId = "(" + parametriRicerca?.ruoli?.join(",") + ",-1)"
        def codTributo = parametriRicerca?.tributo

        int listDeceduti = parametriRicerca?.listDeceduti ?: -1
        int hasPEC = parametriRicerca?.hasPEC ?: -1

        Boolean perExport = parametriRicerca.perExport ?: false

        String selectPerExport = ''
        String fromPerExport = ''
        String wherePerExport = ''

        if (perExport) {

            selectPerExport = """
                        , DECODE(CATE.CATEGORIA,null,'',TO_CHAR(CATE.CATEGORIA))||' - '||
                                                NVL(CATE.DESCRIZIONE,'(SENZA DESCRIZIONE)') as DES_CATEGORIA
                        , DECODE(TARI.TIPO_TARIFFA,null,'',TO_CHAR(TARI.TIPO_TARIFFA))||' - '||
                                                NVL(TARI.DESCRIZIONE,'(SENZA DESCRIZIONE)') as DES_TARIFFA
            """
            fromPerExport = """
                        , CATEGORIE CATE
                        , TARIFFE TARI
            """
            wherePerExport = """
                        RUOG.TRIBUTO = CATE.TRIBUTO(+) AND 
                        RUOG.CATEGORIA = CATE.CATEGORIA(+) AND 
                        RUOG.TRIBUTO = TARI.TRIBUTO(+) AND 
                        RUOG.CATEGORIA = TARI.CATEGORIA(+) AND 
                        RUOG.TIPO_TARIFFA = TARI.TIPO_TARIFFA(+) AND 
                        RUOG.ANNO_RUOLO = TARI.ANNO(+) AND 
            """
        }

        def parameters = [:]

        String extraFilter = ""
        String postFilter = ""
        String temp

        if (codTributo) {
            parameters << [codTributo: codTributo]
            extraFilter += "AND RUOG.TRIBUTO = :codTributo "
        }

        temp = (String) parametriRicerca?.codFiscale
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [codFiscale: temp + '%']
            extraFilter += "AND RUOG.COD_FISCALE LIKE (:codFiscale) "
        }
        temp = (String) parametriRicerca?.cognome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [cognome: temp + '%']
            extraFilter += "AND SOGGETTI.COGNOME_RIC LIKE (:cognome) "
        }
        temp = (String) parametriRicerca?.nome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [nome: temp + '%']
            extraFilter += "AND SOGGETTI.NOME_RIC LIKE (:nome) "
        }

        String query = """
					SELECT
						RUOG.TIPO_TRIBUTO,
						RUOG.RUOLO,
						RUOG.TRIBUTO CODICE_TRIBUTO,
						TRANSLATE(SOGGETTI.COGNOME_NOME,'/',' ') COGNOME_NOME,
						CONTRIBUENTI.COD_FISCALE,
						CONTRIBUENTI.NI,
						DECODE(CONTRIBUENTI.COD_CONTROLLO,NULL,TO_CHAR(CONTRIBUENTI.COD_CONTRIBUENTE), 
							CONTRIBUENTI.COD_CONTRIBUENTE || '-' || CONTRIBUENTI.COD_CONTROLLO) COD_CONTR,
						DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI_OGGE.DENOM_ORD) IND_ORD,
						DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI_OGGE.DENOM_UFF ||
			 									DECODE(OGGE.NUM_CIV,NULL,'',', ' || OGGE.NUM_CIV ) || 
			 										DECODE( OGGE.SUFFISSO,NULL,'','/' || OGGE.SUFFISSO)) IND_OGGE,
						LPAD(OGGE.NUM_CIV,6) NUM_CIV,
						LPAD(OGGE.SUFFISSO,5) SUFFISSO,
						NVL(RUOG.IMPORTO,0) IMPORTO,
						NVL(RUOG.ADDIZIONALE_ECA,0) + NVL(RUOG.MAGGIORAZIONE_ECA,0) ADD_MAGG_ECA,
						NVL(RUOG.ADDIZIONALE_PRO,0) ADDIZIONALE_PRO,
						NVL(RUOG.IVA,0) IVA,
						NVL(RUOG.MAGGIORAZIONE_TARES,0) MAGGIORAZIONE_TARES,
						NVL(RUOG.CONSISTENZA,0) CONSISTENZA,
						RUOG.TIPO_TARIFFA TIPO_TARIFFA,
						RUOG.CATEGORIA CATEGORIA,
						RUOG.OGGETTO OGGETTO,
						RUOG.OGGETTO_PRATICA OGGETTO_PRATICA,
						NVL(SGRAVI_RUOLO.IMPORTO_SGRAVIO,0) IMPORTO_SGRAVIO,
						NVL(RUOG.IMPORTO_LORDO,0) IMPORTO_LORDO,
						RUOLI.INVIO_CONSORZIO,
						RUOLI.SPECIE_RUOLO,
						NVL(SOGGETTI.STATO,0) STATO_SOGG,
						DECODE(DATI_GENERALI.FLAG_INTEGRAZIONE_GSD,'S',DECODE(SOGGETTI.TIPO_RESIDENTE,0,
							DECODE(SOGGETTI.FASCIA,1,'SI',3,'NI','NO'),'NO'),
			 				DECODE(SOGGETTI.TIPO_RESIDENTE,0,'SI','NO')) RESIDENTE,
						ANADEV.DESCRIZIONE STATO_DESCRIZIONE,
						SOGGETTI.DATA_ULT_EVE,
						DECODE(SOGGETTI.COD_VIA,NULL,SOGGETTI.DENOMINAZIONE_VIA,ARVI_SOGG.DENOM_UFF) INDIRIZZO_RES,
						SOGGETTI.NUM_CIV||DECODE(SOGGETTI.SUFFISSO,NULL,'','/'||SOGGETTI.SUFFISSO) NUM_CIVICO_RES,
						LPAD(SOGGETTI.CAP,5,'0') CAP_RES,
						COMU.DENOMINAZIONE COMUNE_RES,
						DECODE(SOGGETTI.FASCIA,2,DECODE(SOGGETTI.STATO,50,'',
							DECODE(LPAD(DATI_GENERALI.PRO_CLIENTE,3,'0') || LPAD(DATI_GENERALI.COM_CLIENTE,3,'0'),
			 					LPAD(SOGGETTI.COD_PRO_RES,3,'0') || LPAD(SOGGETTI.COD_COM_RES,3,'0'),'ERR','')),'') VERIFICA_COMUNE_RES,
						f_verifica_cap(SOGGETTI.COD_PRO_RES,SOGGETTI.COD_COM_RES,SOGGETTI.CAP) VERIFICA_CAP,
						TRANSLATE(SOGG_P.COGNOME_NOME,'/',' ') COGNOME_NOME_P,
						OGCO.FLAG_AB_PRINCIPALE,
						f_get_num_fam_cosu(OGCO.OGGETTO_PRATICA,OGCO.FLAG_AB_PRINCIPALE,RUOLI.ANNO_RUOLO,OGIM.OGGETTO_IMPOSTA) NUMERO_FAMILIARI,
						NVL(OGIM.IMPORTO_PV,0) IMPORTO_PV,
						NVL(OGIM.IMPORTO_PF,0) IMPORTO_PF,
						RUOG.GIORNI_RUOLO,
						RUOG.SEQUENZA,
						NVL(RUOG.IMPOSTA,0) IMPOSTA,
						RUOLI.ANNO_RUOLO,
						f_descrizione_titr(RUOLI.TIPO_TRIBUTO,RUOLI.ANNO_RUOLO) DESCR_TRIBUTO,
						f_recapito(SOGGETTI.NI,RUOLI.TIPO_TRIBUTO,3) PEC_MAIL,
						RUOLI.FLAG_CALCOLO_TARIFFA_BASE FLAG_TARIFFA_BASE,
						NVL(RUOG.IMPORTO_BASE,0) IMPORTO_BASE,
						DECODE(RUOG.ADDIZIONALE_ECA_BASE,NULL,
							DECODE(RUOG.MAGGIORAZIONE_ECA_BASE,NULL,TO_NUMBER(NULL),
								NVL(RUOG.ADDIZIONALE_ECA_BASE,0) + NVL(RUOG.MAGGIORAZIONE_ECA_BASE,0)),
			 					NVL(RUOG.ADDIZIONALE_ECA_BASE,0) + NVL(RUOG.MAGGIORAZIONE_ECA_BASE,0)) ADD_MAGG_ECA_BASE,
						NVL(RUOG.ADDIZIONALE_PRO_BASE,0) ADDIZIONALE_PRO_BASE,
						NVL(RUOG.IVA_BASE,0) IVA_BASE,
						NVL(SGRAVI_RUOLO.IMPORTO_SGRAVIO_BASE,0) IMPORTO_SGRAVIO_BASE,
						NVL(OGIM.IMPOSTA_BASE,0) IMPOSTA_BASE,
						NVL(OGIM.IMPORTO_PV_BASE,0) IMPORTO_PV_BASE,
						NVL(OGIM.IMPORTO_PF_BASE,0) IMPORTO_PF_BASE,
						NVL(OGIM.PERC_RIDUZIONE_PF,0) PERC_RIDUZIONE_PF,
						NVL(OGIM.PERC_RIDUZIONE_PV,0) PERC_RIDUZIONE_PV,
						NVL(OGIM.IMPORTO_RIDUZIONE_PF,0) RIDUZIONE_IMP_NETTA_PF,
						NVL(OGIM.IMPORTO_RIDUZIONE_PV,0) RIDUZIONE_IMP_NETTA_PV,
                        nvl(CORU.COMPENSAZIONE, 0) AS COMPENSAZIONE
                        ${selectPerExport}
					FROM 
						DATI_GENERALI,
						ARCHIVIO_VIE ARVI_OGGE,
						OGGETTI OGGE,
						SOGGETTI,
						CONTRIBUENTI,
						RUOLI,
						RUOLI_OGGETTO RUOG,
			 			(SELECT RUOLO,COD_FISCALE,SEQUENZA,SUM(IMPORTO) IMPORTO_SGRAVIO,SUM(IMPORTO_BASE) IMPORTO_SGRAVIO_BASE
			 			 FROM SGRAVI
			 			 WHERE SGRAVI.RUOLO IN ${ruoliId}
			 			 GROUP BY RUOLO,COD_FISCALE,SEQUENZA) SGRAVI_RUOLO,
						(SELECT COUNT(DISTINCT RUOLO) CONTA, COD_FISCALE
						 FROM RUOLI_CONTRIBUENTE RUCO
						 WHERE RUCO.RUOLO IN ${ruoliId}
						 GROUP BY COD_FISCALE) NR_RUOLI,
						ANADEV,
						ARCHIVIO_VIE ARVI_SOGG,
						AD4_COMUNI COMU,
						SOGGETTI SOGG_P,
						OGGETTI_CONTRIBUENTE OGCO,
						OGGETTI_IMPOSTA OGIM,
                        COMPENSAZIONI_RUOLO CORU
                        ${fromPerExport}
			 		WHERE
						ARVI_OGGE.COD_VIA (+) = OGGE.COD_VIA AND
						OGGE.OGGETTO (+) = RUOG.OGGETTO AND
						SOGGETTI.NI = CONTRIBUENTI.NI AND   
						CONTRIBUENTI.COD_FISCALE = RUOG.COD_FISCALE AND
						RUOG.RUOLO = SGRAVI_RUOLO.RUOLO (+) AND
						RUOG.COD_FISCALE = SGRAVI_RUOLO.COD_FISCALE (+) AND
						RUOG.SEQUENZA = SGRAVI_RUOLO.SEQUENZA (+) AND
						SOGGETTI.STATO = ANADEV.COD_EV (+) AND
						ARVI_SOGG.COD_VIA (+) = SOGGETTI.COD_VIA AND
						SOGGETTI.COD_COM_RES = COMU.COMUNE (+) AND
						SOGGETTI.COD_PRO_RES = COMU.PROVINCIA_STATO (+) AND
						SOGGETTI.NI_PRESSO = SOGG_P.NI (+) AND           
						RUOG.RUOLO = RUOLI.RUOLO AND
                        ${wherePerExport}
						OGIM.OGGETTO_IMPOSTA(+) = RUOG.OGGETTO_IMPOSTA AND
						OGCO.OGGETTO_PRATICA(+) = OGIM.OGGETTO_PRATICA AND
						NVL(OGCO.COD_FISCALE,CONTRIBUENTI.COD_FISCALE) = CONTRIBUENTI.COD_FISCALE AND
						CONTRIBUENTI.COD_FISCALE = NR_RUOLI.COD_FISCALE AND
						RUOG.RUOLO in ${ruoliId} and (nvl(ruoli.tipo_emissione,'X') in ('A', 'S', 'X') or
                       (nvl(ruoli.tipo_emissione,'X') = 'T' and
                        f_ruolo_totale_all(CONTRIBUENTI.COD_FISCALE, OGIM.ANNO, OGIM.TIPO_TRIBUTO, -1) in (ruoli.ruolo, -1)) or
                       (nvl(ruoli.tipo_emissione,'X') = 'T' and
                        f_ruolo_totale_all(CONTRIBUENTI.COD_FISCALE, OGIM.ANNO, OGIM.TIPO_TRIBUTO, -1) not in (2445,-1) and nr_ruoli.conta = 1))
                        and ogim.ruolo = coru.ruolo(+)
                        and ogim.oggetto_pratica = coru.oggetto_pratica(+)
                        and ogim.cod_fiscale = coru.cod_fiscale(+)
                        and ogim.anno = coru.anno(+)
			 			${extraFilter}
					ORDER BY
						RUOLI.TIPO_RUOLO ASC,
						SOGGETTI.COGNOME_NOME ASC,
						RUOG.COD_FISCALE ASC,
						OGGE.OGGETTO ASC
        """

        switch (listDeceduti)    // -1 -> Deceduti e Non Deceduti,	1 -> Solo Non Deceduti,	2 -> Solo Deceduti
        {
            default: break
            case -1:
                break
            case 1:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "STATO_SOGG <> 50"
                break
            case 2:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "STATO_SOGG = 50"
                break
        }

        postFilter += creaCondizioneHasPEC(hasPEC, postFilter)

        if (postFilter) {
            query = "SELECT * FROM (${query}) WHERE ${postFilter}"
        }

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            parameters.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        def listaUtenzeRuolo = []

        int totalCount = 0
        int pageCount = 0
        int pageStart = activePage * pageSize

        results.each {

            if ((totalCount >= pageStart) && (pageCount < pageSize)) {

                def ruoloUtenza = [:]

                TipoTributoDTO tipoTributo = TipoTributo.get(it['TIPO_TRIBUTO']).toDTO()

                ruoloUtenza.codUnivoco = it['RUOLO'].toString() + "_" + it['COD_FISCALE'] + "_" + it['SEQUENZA'].toString()

                ruoloUtenza.tipoRuolo = it['TIPO_RUOLO']
                ruoloUtenza.ruolo = it['RUOLO']
                ruoloUtenza.codiceTributo = it['CODICE_TRIBUTO']
                ruoloUtenza.sequenza = it['SEQUENZA']

                ruoloUtenza.anno = it['ANNO_RUOLO'].toLong()

                ruoloUtenza.tipoTributo = tipoTributo.tipoTributo
                ruoloUtenza.tipoTributoAttuale = tipoTributo.getTipoTributoAttuale((short) ruoloUtenza.anno)

                ruoloUtenza.codFiscale = it['COD_FISCALE']
                ruoloUtenza.ni = it['NI']
                ruoloUtenza.codContr = it['COD_CONTR']

                ruoloUtenza.cognomeNome = it['COGNOME_NOME']
                ruoloUtenza.cognomeNomeP = it['COGNOME_NOME_P']

                ruoloUtenza.descrTributo = it['DESCR_TRIBUTO']

                ruoloUtenza.tipoTariffa = it['TIPO_TARIFFA']

                ruoloUtenza.indOrd = it['IND_ORD']
                ruoloUtenza.indOgge = it['IND_OGGE']
                ruoloUtenza.numCiv = it['NUM_CIV']
                ruoloUtenza.suffisso = it['SUFFISSO']

                ruoloUtenza.categoria = it['CATEGORIA']
                ruoloUtenza.oggetto = it['OGGETTO']
                ruoloUtenza.oggettoPratica = it['OGGETTO_PRATICA']

                ruoloUtenza.abPrincipale = (it['FLAG_AB_PRINCIPALE'] == 'S') ? 'SI' : ''
                ruoloUtenza.abPrincipaleFlag = (it['FLAG_AB_PRINCIPALE'] == 'S')
                ruoloUtenza.numeroFamiliari = it['NUMERO_FAMILIARI']
                ruoloUtenza.giorniRuolo = it['GIORNI_RUOLO']

                ruoloUtenza.tariffaBase = it['FLAG_TARIFFA_BASE']

                ruoloUtenza.importoBase = it['IMPORTO_BASE']
                ruoloUtenza.impostaBase = it['IMPOSTA_BASE']
                ruoloUtenza.addMaggECABase = it['ADD_MAGG_ECA_BASE']
                ruoloUtenza.addProvBase = it['ADDIZIONALE_PRO_BASE']
                ruoloUtenza.ivaBase = it['IVA_BASE']
                ruoloUtenza.importoPVBase = it['IMPORTO_PV_BASE']
                ruoloUtenza.importoPFBase = it['IMPORTO_PF_BASE']
                ruoloUtenza.importoSgravioBase = it['IMPORTO_SGRAVIO_BASE']

                ruoloUtenza.importo = it['IMPORTO']
                ruoloUtenza.imposta = it['IMPOSTA']
                ruoloUtenza.addMaggEca = it['ADD_MAGG_ECA']
                ruoloUtenza.addProv = it['ADDIZIONALE_PRO']
                ruoloUtenza.iva = it['IVA']
                ruoloUtenza.importoPF = it['IMPORTO_PF']
                ruoloUtenza.importoPV = it['IMPORTO_PV']
                ruoloUtenza.sgravio = it['IMPORTO_SGRAVIO']

                ruoloUtenza.percRiduzionePF = it['PERC_RIDUZIONE_PF']
                ruoloUtenza.percRiduzionePV = it['PERC_RIDUZIONE_PV']
                ruoloUtenza.impRiduzionePF = it['RIDUZIONE_IMP_NETTA_PF']
                ruoloUtenza.impRiduzionePV = it['RIDUZIONE_IMP_NETTA_PV']

                ruoloUtenza.importoLordo = it['IMPORTO_LORDO']

                ruoloUtenza.maggiorazioneTares = it['MAGGIORAZIONE_TARES']
                ruoloUtenza.consistenza = it['CONSISTENZA']

                ruoloUtenza.residente = it['RESIDENTE']
                ruoloUtenza.residenteFlag = (it['RESIDENTE'] == 'SI')
                ruoloUtenza.statoDescrizione = it['STATO_DESCRIZIONE']

                ruoloUtenza.dataUltEvento = it['DATA_ULT_EVE']?.format("dd/MM/yyyy")

                ruoloUtenza.indirizzoRes = it['INDIRIZZO_RES']
                ruoloUtenza.civicoRes = it['NUM_CIVICO_RES']
                ruoloUtenza.comuneRes = it['COMUNE_RES']
                ruoloUtenza.capRes = it['CAP_RES']
                ruoloUtenza.comuneResErr = it['VERIFICA_COMUNE_RES']
                ruoloUtenza.capResErr = it['VERIFICA_CAP']

                ruoloUtenza.invioConsorzio = it['INVIO_CONSORZIO']?.format("dd/MM/yyyy")

                ruoloUtenza.decedutoFlag = (it['STATO_SOGG'] == 50)

                ruoloUtenza.mailPEC = it['PEC_MAIL']
                ruoloUtenza.mailPECFlag = (it['PEC_MAIL'] != null)

                ruoloUtenza.specieRuolo = it['SPECIE_RUOLO']
                ruoloUtenza.specie = it['SPECIE_RUOLO'] ? 'Coattivo' : 'Ordinario'
                ruoloUtenza.descrizioneSpecie = ruoloUtenza.specie ? 1 : 0

                ruoloUtenza.compensazione = it['COMPENSAZIONE']

                ruoloUtenza.desCategoria = it['DES_CATEGORIA']
                ruoloUtenza.desTariffa = it['DES_TARIFFA']

                listaUtenzeRuolo << ruoloUtenza

                pageCount++
            }

            totalCount++
        }

        return [totalCount: totalCount, records: listaUtenzeRuolo]
    }

    def getContribuentiRuolo(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        DecimalFormat importoFmt = new DecimalFormat("#,##0.00")

        def ruoliId = "(" + parametriRicerca?.ruoli?.join(",") + ",-1)"

        int listDeceduti = parametriRicerca?.listDeceduti ?: -1
        int versatoVersusDovuto = parametriRicerca?.versatoVersusDovuto ?: -1
        int hasPEC = parametriRicerca?.hasPEC ?: -1
        int hasVersamenti = parametriRicerca?.hasVersamenti ?: -1
        def soglia = parametriRicerca?.soglia ?: 1.0

        def parameters = [:]

        String extraFilter = ""
        String postFilter = ""
        String temp

        temp = (String) parametriRicerca?.codFiscale
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [codFiscale: temp + '%']
            extraFilter += "AND RUCO.COD_FISCALE LIKE (:codFiscale) "
        }
        temp = (String) parametriRicerca?.cognome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [cognome: temp + '%']
            extraFilter += "AND SOGG.COGNOME_RIC LIKE (:cognome) "
        }
        temp = (String) parametriRicerca?.nome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [nome: temp + '%']
            extraFilter += "AND SOGG.NOME_RIC LIKE (:nome) "
        }

        String query = """
				    SELECT RUCO.COD_FISCALE,
                       TRANSLATE(SOGG.COGNOME_NOME, '/', ' ') AS COGNOME_NOME,
                       MAX(SOGG.COGNOME) AS COGNOME,
                       MAX(SOGG.NOME) AS NOME,
                       0 AS CODICE_TRIBUTO,
                       RUOLI.ANNO_RUOLO,
                       MAX(CATA.FLAG_TARIFFA_PUNTUALE) AS FLAG_TARIFFA_PUNTUALE,
                       COUNT(OGIM.OGGETTO_IMPOSTA) AS UTENZE,
                       SUM(NVL(RUCO.IMPORTO, 0)) AS IMPORTO,
                       SUM(NVL(OGIM.ADDIZIONALE_ECA, 0)) AS ADDIZIONALE_ECA,
                       SUM(NVL(OGIM.MAGGIORAZIONE_ECA, 0)) AS MAGGIORAZIONE_ECA,
                       SUM(NVL(OGIM.ADDIZIONALE_PRO, 0)) AS ADDIZIONALE_PRO,
                       SUM(NVL(OGIM.IVA, 0)) AS IVA,
                       SUM(NVL(OGIM.IMPOSTA, 0)) AS IMPOSTA,
                       SUM(NVL(OGIM.IMPORTO_PV, 0)) AS IMPORTO_PV,
                       SUM(NVL(OGIM.IMPORTO_PF, 0)) AS IMPORTO_PF,
                       SUM(NVL(OGIM.MAGGIORAZIONE_TARES, 0)) AS MAGGIORAZIONE_TARES,
                       MAX(RUCO.SEQUENZA) AS SEQUENZA,
                       MAX(TIPO_CALCOLO) AS TIPO_CALCOLO,
                       MAX(NVL(SOGG.STATO, 0)) AS STATO_SOGG,
                       MAX(DECODE(DTGG.FLAG_INTEGRAZIONE_GSD,
                                  'S',
                                  DECODE(SOGG.TIPO_RESIDENTE,
                                         0,
                                         DECODE(SOGG.FASCIA, 1, 'SI', 3, 'NI', 'NO'),
                                         'NO'),
                                  decode(SOGG.TIPO_RESIDENTE, 0, 'SI', 'NO'))) AS RESIDENTE,
                       MAX(DECODE(SOGG.COD_VIA,
                                  null,
                                  SOGG.DENOMINAZIONE_VIA,
                                  ARVI.DENOM_UFF)) AS INDIRIZZO_RES,
                       MAX(SOGG.NUM_CIV ||
                           DECODE(SOGG.SUFFISSO, null, '', '/' || SOGG.SUFFISSO)) AS NUM_CIVICO_RES,
                       MAX(LPAD(SOGG.CAP, 5, '0')) AS CAP_RES,
                       MAX(COMU.DENOMINAZIONE) AS COMUNE_RES,
                       MAX(DECODE(SOGG.FASCIA,
                                  2,
                                  DECODE(SOGG.STATO,
                                         50,
                                         '',
                                         DECODE(LPAD(DTGG.PRO_CLIENTE, 3, '0') ||
                                                LPAD(DTGG.COM_CLIENTE, 3, '0'),
                                                LPAD(SOGG.COD_PRO_RES, 3, '0') ||
                                                LPAD(SOGG.COD_COM_RES, 3, '0'),
                                                'ERR',
                                                '')),
                                  '')) VERIFICA_COMUNE_RES,
                       MAX(f_verifica_cap(SOGG.COD_PRO_RES, SOGG.COD_COM_RES, SOGG.CAP)) VERIFICA_CAP,
                       MAX(TRANSLATE(SOGG_P.COGNOME_NOME, '/', ' ')) COGNOME_NOME_P,
                       MAX(ANADEV.DESCRIZIONE) STATO_DESCRIZIONE,
                       MAX(SOGG.DATA_ULT_EVE) AS DATA_ULT_EVE,
                       MAX(f_compensazione_ruolo(RUOLI.RUOLO, CONT.COD_FISCALE, NULL)) AS COMPENSAZIONE,
                       MAX(f_recapito(SOGG.NI, RUOLI.TIPO_TRIBUTO, 3)) AS PEC_MAIL,
                       MAX(DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'A',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONT.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  'S',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONT.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONT.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  0)) AS VERSAMENTI_V,
                       MAX(DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONT.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'VC'),
                                  0)) AS VERSAMENTI_VC,
                       MAX(DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONT.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'VS'),
                                  0)) AS VERSAMENTI_VS,
                       case
                         when (max(ruoli.tipo_emissione) = 'T' and max(nr_ruoli.conta) = 1 and
                              ruco.cod_fiscale = nr_ruoli.cod_fiscale) or
                              (f_ruolo_totale_all(ruco.COD_FISCALE,
                                              ruoli.ANNO_RUOLO,
                                              OGIM.TIPO_TRIBUTO,
                                              -1) in $ruoliId) then
                          max(ruoli.ruolo)
                         else
                          case
                            when (min(ruoli.tipo_emissione) in ('A', 'S') or
                                 max(ruoli.tipo_emissione) in ('A', 'S')) and
                                 max(nr_ruoli.conta) = 1 and
                                 ruco.cod_fiscale = nr_ruoli.cod_fiscale then
                             max(ruoli.ruolo)
                            else
                             null
                          end
                       end ruolo,
						max(ruoli.flag_calcolo_tariffa_base) flag_tariffa_base,
						sum(nvl(RUCO.IMPORTO_BASE,0)) importo_base,
						sum(decode(ogim.addizionale_eca_base,null,
							decode(ogim.maggiorazione_eca_base,null,to_number(null),
								nvl(OGIM.ADDIZIONALE_ECA_BASE,0) + nvl(OGIM.MAGGIORAZIONE_ECA_BASE,0)), 
									nvl(OGIM.ADDIZIONALE_ECA_BASE,0) + nvl(OGIM.MAGGIORAZIONE_ECA_BASE,0))) add_magg_eca_base,
						sum(nvl(OGIM.ADDIZIONALE_PRO_BASE,0)) addizionale_pro_base,
						sum(nvl(OGIM.IVA_BASE,0)) iva_base,
						sum(nvl(sgravi_ruolo.importo_sgravio,0)) SGRAVIO,
						sum(nvl(sgravi_ruolo.importo_sgravio_base,0)) IMPORTO_SGRAVIO_BASE,
						sum(nvl(ogim.imposta_base,0)) imposta_base,
						sum(nvl(ogim.importo_pf_base,0)) importo_pf_base,
						sum(nvl(ogim.importo_pv_base,0)) importo_pv_base,
						sum(nvl(ogim.importo_riduzione_pf,0)) riduzione_imp_netta_pf,
						sum(nvl(ogim.importo_riduzione_pv,0)) riduzione_imp_netta_pv,
						max(nvl(ruec.importo_ruolo,0)) as importo_ecc,
						max(nvl(ruec.imposta,0)) as imposta_ecc,
						max(nvl(ruec.add_pro,0)) as add_pro_ecc
                  FROM (select count(distinct ruolo) conta, cod_fiscale
                          from ruoli_contribuente ruco
                         where ruco.ruolo in $ruoliId
                         group by cod_fiscale) nr_ruoli,
                       DATI_GENERALI DTGG,
                       RUOLI,
                       RUOLI_CONTRIBUENTE RUCO,
                       CARICHI_TARSU CATA,
					   (SELECT RUOLO, COD_FISCALE,
					     SUM(IMPORTO_RUOLO) IMPORTO_RUOLO,
					     SUM(IMPOSTA) IMPOSTA,
					     SUM(NVL(ADDIZIONALE_PRO,0)) ADD_PRO
					      FROM RUOLI_ECCEDENZE
					     WHERE RUOLO in $ruoliId
					     GROUP BY RUOLO, COD_FISCALE
					   ) RUEC,
					   (SELECT RUOLO, COD_FISCALE, SEQUENZA,
					     SUM(IMPORTO) IMPORTO_SGRAVIO, SUM(IMPORTO_BASE) IMPORTO_SGRAVIO_BASE
					      FROM SGRAVI
						 WHERE RUOLO in $ruoliId
					     GROUP BY RUOLO, COD_FISCALE, SEQUENZA
					   ) SGRAVI_RUOLO,
                       OGGETTI_IMPOSTA OGIM,
                       CONTRIBUENTI CONT,
                       SOGGETTI SOGG,
                       SOGGETTI SOGG_P,
                       ANADEV,
                       ARCHIVIO_VIE ARVI,
                       AD4_COMUNI COMU
                 WHERE RUOLI.RUOLO = RUCO.RUOLO(+)
                   AND RUOLI.ANNO_RUOLO = CATA.ANNO(+)
                   AND RUCO.OGGETTO_IMPOSTA = OGIM.OGGETTO_IMPOSTA(+)
                   AND RUCO.COD_FISCALE = CONT.COD_FISCALE
                   AND nr_ruoli.cod_fiscale = ruco.cod_fiscale
                   AND RUCO.RUOLO = SGRAVI_RUOLO.RUOLO(+)
                   AND RUCO.COD_FISCALE = SGRAVI_RUOLO.COD_FISCALE (+)
                   AND RUCO.RUOLO = RUEC.RUOLO(+)
                   AND RUCO.COD_FISCALE = RUEC.COD_FISCALE (+)
                   AND RUCO.SEQUENZA = SGRAVI_RUOLO.SEQUENZA (+)
                   AND CONT.NI = SOGG.NI
                   AND SOGG.COD_VIA = ARVI.COD_VIA(+)
                   AND SOGG.STATO = ANADEV.COD_EV(+)
                   AND SOGG.NI_PRESSO = SOGG_P.NI(+)
                   AND SOGG.COD_COM_RES = COMU.COMUNE(+)
                   AND SOGG.COD_PRO_RES = COMU.PROVINCIA_STATO(+)
                   AND RUOLI.RUOLO in $ruoliId
                   and (nvl(ruoli.tipo_emissione,'X') in ('A', 'S', 'X') or
                       (nvl(ruoli.tipo_emissione,'X') = 'T' and
                        f_ruolo_totale_all(CONT.COD_FISCALE, OGIM.ANNO, OGIM.TIPO_TRIBUTO, -1) in (ruoli.ruolo, -1)) or
                       (nvl(ruoli.tipo_emissione,'X') = 'T' and
                        f_ruolo_totale_all(CONT.COD_FISCALE, OGIM.ANNO, OGIM.TIPO_TRIBUTO, -1) not in (ruoli.ruolo, -1) and nr_ruoli.conta = 1))
                       ${extraFilter}
                 GROUP BY OGIM.TIPO_TRIBUTO,
                          RUCO.COD_FISCALE,
                          nr_ruoli.cod_fiscale,
                          SOGG.COGNOME_NOME,
                          RUOLI.ANNO_RUOLO
                 ORDER BY RUOLI.ANNO_RUOLO  DESC,
                          SOGG.COGNOME_NOME ASC,
                          RUCO.COD_FISCALE  ASC,
                          CODICE_TRIBUTO    ASC
        """

        // -1 -> Default,1 -> Versato > Dovuto,	2 -> Dovuto > Versato,3 ->Versato = Dovuto
        switch (versatoVersusDovuto) {
            default: break
            case -1:
                break
            case 1: // da Rimborsare
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += " (VERSAMENTI_V + SGRAVIO + COMPENSAZIONE) > ((IMPORTO + IMPORTO_ECC) + ${soglia})"
                break
            case 2: // da Pagare
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += " (VERSAMENTI_V + SGRAVIO + COMPENSAZIONE) < ((IMPORTO + IMPORTO_ECC) - ${soglia})"
                break
            case 3: // Saldato
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += " (VERSAMENTI_V + SGRAVIO + COMPENSAZIONE)  between " + 
                                    "((IMPORTO + IMPORTO_ECC) - ${soglia}) AND ((IMPORTO + IMPORTO_ECC) + ${soglia})"
                break
        }

        // -1 -> Deceduti e Non Deceduti,	1 -> Solo Non Deceduti,	2 -> Solo Deceduti
        switch (listDeceduti) {
            default: break
            case -1:
                break
            case 1:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "STATO_SOGG <> 50"
                break
            case 2:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "STATO_SOGG = 50"
                break
        }

        // -1 -> Tutti,	10 -> Con Versamenti,	11 -> Con Versamenti spontanei,	12 -> Con Versamenti da compensazione,	20 -> Senza Versamenti
        switch (hasVersamenti) {
            default: break
            case -1:
                break
            case 10:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "(VERSAMENTI_V > 0 OR VERSAMENTI_VS > 0 OR VERSAMENTI_VC > 0)"
                break
            case 11:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "(VERSAMENTI_VS > 0)"
                break
            case 12:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "(VERSAMENTI_VC > 0)"
                break
            case 20:
                if (postFilter.length() > 0) {
                    postFilter += " AND "
                }
                postFilter += "(VERSAMENTI_V = 0 AND VERSAMENTI_VS = 0 AND VERSAMENTI_VC = 0)"
                break
        }

        postFilter += creaCondizioneHasPEC(hasPEC, postFilter)

        if (postFilter) {
            query = "SELECT * FROM (${query}) WHERE ${postFilter}"
        }

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            parameters.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        def listaRuoliRuolo = []

        int totalCount = 0
        int pageCount = 0
        int pageStart = activePage * pageSize

        results.each {

            if ((totalCount >= pageStart) && (pageCount < pageSize)) {

                def ruoloContribuente = [:]

                // TipoTributoDTO tipoTributo = TipoTributo.get(it['TIPO_TRIBUTO']).toDTO()

                ruoloContribuente.codUnivoco = it['RUOLO'].toString() + "_" + it['COD_FISCALE'] + "_" + it['SEQUENZA'].toString()

                ruoloContribuente.ruolo = it['RUOLO']
                ruoloContribuente.sequenza = it['SEQUENZA']

                ruoloContribuente.utenze = it['UTENZE']

                ruoloContribuente.anno = it['ANNO_RUOLO'].toLong()
                // ruoloContribuente.annoEmissione = it['ANNO_EMISSIONE'].toLong()
                ruoloContribuente.progrEmissione = it['PROGR_EMISSIONE']

                // ruoloContribuente.tipoTributo = tipoTributo.tipoTributo
                // ruoloContribuente.tipoTributoAttuale = tipoTributo.getTipoTributoAttuale((short) ruoloContribuente.anno)
                ruoloContribuente.tipoRuolo = it['TIPO_RUOLO']
                ruoloContribuente.tipoRuoloStr = it['TIPO_RUOLO'] == 1 ? 'P' : 'S'

                ruoloContribuente.codFiscale = it['COD_FISCALE']

                ruoloContribuente.cognomeNome = it['COGNOME_NOME']
                ruoloContribuente.cognome = it['COGNOME']
                ruoloContribuente.nome = it['NOME']
                ruoloContribuente.cognomeNomeP = it['COGNOME_NOME_P']

                ruoloContribuente.codiceTributo = it['CODICE_TRIBUTO']

                ruoloContribuente.importo = it['IMPORTO']
             // ruoloContribuente.importoLordo = it['IMPORTO_LORDO']
             // ruoloContribuente.importoLordoStr = it['IMPORTO_LORDO'] ? 'S' : 'N'

                ruoloContribuente.imposta = it['IMPOSTA']
                ruoloContribuente.addMaggEca = new BigDecimal(it['ADDIZIONALE_ECA'] ?: 0).add(new BigDecimal(it['MAGGIORAZIONE_ECA'] ?: 0))
                ruoloContribuente.addProv = it['ADDIZIONALE_PRO']
                ruoloContribuente.iva = it['IVA']
                ruoloContribuente.importoPF = it['IMPORTO_PF']
                ruoloContribuente.importoPV = it['IMPORTO_PV']
                ruoloContribuente.maggiorazioneTares = it['MAGGIORAZIONE_TARES']
                ruoloContribuente.residente = it['RESIDENTE']
                ruoloContribuente.residenteFlag = (it['RESIDENTE'] == 'SI')
                ruoloContribuente.statoDescrizione = it['STATO_DESCRIZIONE']
                ruoloContribuente.dataUltEvento = it['DATA_ULT_EVE']?.format("dd/MM/yyyy")

                ruoloContribuente.indirizzoRes = it['INDIRIZZO_RES']
                ruoloContribuente.civicoRes = it['NUM_CIVICO_RES']
                ruoloContribuente.comuneRes = it['COMUNE_RES']
                ruoloContribuente.capRes = it['CAP_RES']
                ruoloContribuente.comuneResErr = it['VERIFICA_COMUNE_RES']
                ruoloContribuente.capResErr = it['VERIFICA_CAP']

                ruoloContribuente.dataEmissione = it['DATA_EMISSIONE']?.format("dd/MM/yyyy")
                ruoloContribuente.invioConsorzio = it['INVIO_CONSORZIO']?.format("dd/MM/yyyy")

                ruoloContribuente.specieRuolo = it['SPECIE_RUOLO']
                ruoloContribuente.specie = it['SPECIE_RUOLO'] ? 'Coattivo' : 'Ordinario'
                ruoloContribuente.descrizioneSpecie = ruoloContribuente.specie ? 1 : 0

                ruoloContribuente.tipoEmissione = it['TIPO_EMISSIONE']
                ruoloContribuente.tipoCalcolo = it['TIPO_CALCOLO']

                ruoloContribuente.decedutoFlag = (it['STATO_SOGG'] == 50)
                ruoloContribuente.versato = it['VERSAMENTI_V']
                ruoloContribuente.versatoS = it['VERSAMENTI_VS']
                ruoloContribuente.versatoC = it['VERSAMENTI_VC']

                ruoloContribuente.mailPEC = it['PEC_MAIL']
                ruoloContribuente.mailPECFlag = (it['PEC_MAIL'] != null)

                ruoloContribuente.tariffaBase = it['FLAG_TARIFFA_BASE']

                ruoloContribuente.importoBase = it['IMPORTO_BASE']
                ruoloContribuente.impostaBase = it['IMPOSTA_BASE']
                ruoloContribuente.addMaggECABase = it['ADD_MAGG_ECA_BASE']
                ruoloContribuente.addProvBase = it['ADDIZIONALE_PRO_BASE']
                ruoloContribuente.ivaBase = it['IVA_BASE']
                ruoloContribuente.importoPVBase = it['IMPORTO_PV_BASE']
                ruoloContribuente.importoPFBase = it['IMPORTO_PF_BASE']
                ruoloContribuente.importoSgravioBase = it['IMPORTO_SGRAVIO_BASE']
                ruoloContribuente.impRiduzionePF = it['RIDUZIONE_IMP_NETTA_PF']
                ruoloContribuente.impRiduzionePV = it['RIDUZIONE_IMP_NETTA_PV']

                ruoloContribuente.flagTariffaPuntuale = it['FLAG_TARIFFA_PUNTUALE']

                ruoloContribuente.importoEcc = it['IMPORTO_ECC']
                ruoloContribuente.eccedenze = it['IMPOSTA_ECC']
                ruoloContribuente.addProvEcc = it['ADD_PRO_ECC']
                ruoloContribuente.addProvImp = it['ADDIZIONALE_PRO']

                // Erano funzioni groovy ma ci mettono un'eternità con molti contribuenti
                // Rimesso le ORALCE FUNCTION - > Da rivalutare alternative
                ruoloContribuente.sgravio = it['SGRAVIO']
                ruoloContribuente.compensazione = it['COMPENSAZIONE']

                switch (ruoloContribuente.tipoCalcolo) {
                    case 'N': ruoloContribuente.descrizioneCalcolo = 'Normalizzato'; break
                    case 'T': ruoloContribuente.descrizioneCalcolo = 'Tradizionale'; break
                    default: ruoloContribuente.descrizioneCalcolo = ''; break
                }
                switch (ruoloContribuente.tipoEmissione) {
                    case 'A': ruoloContribuente.descrizioneEmissione = 'Acconto'; break
                    case 'S': ruoloContribuente.descrizioneEmissione = 'Saldo'; break
                    case 'T': ruoloContribuente.descrizioneEmissione = 'Totale'; break
                    default: ruoloContribuente.descrizioneEmissione = ''; break
                }

                if(ruoloContribuente.flagTariffaPuntuale == 'S') {
                    ruoloContribuente.addProvTooltip = "Da Imposta: " + importoFmt.format((ruoloContribuente.addProv ?: 0)) + "\n" + 
                                                        "Da Eccedenze: " + importoFmt.format((ruoloContribuente.addProvEcc ?: 0))

                    ruoloContribuente.addProv = (ruoloContribuente.addProv ?: 0) + (ruoloContribuente.addProvEcc ?: 0)
                    ruoloContribuente.importo = (ruoloContribuente.importo ?: 0) + (ruoloContribuente.importoEcc ?: 0)
                }
                else {
                    ruoloContribuente.addProvTooltip = null
                };

                ruoloContribuente.dovuto = (ruoloContribuente.importo ?: 0) - (ruoloContribuente.sgravio ?: 0) - (ruoloContribuente.versato ?: 0) - (ruoloContribuente.compensazione ?: 0)

                listaRuoliRuolo << ruoloContribuente

                pageCount++
            }

            totalCount++
        }

        return [totalCount: totalCount, records: listaRuoliRuolo]
    }

    def getListaDiCaricoRuoli(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        DecimalFormat importoFmt = new DecimalFormat("#,##0.00")

        def filtri = [:]
        def tipoTributo = parametriRicerca?.tipoTributo ?: "-"

        def daAnno = parametriRicerca?.daAnno
        def aAnno = parametriRicerca?.aAnno
        def daAnnoEmissione = parametriRicerca?.daAnnoEmissione
        def aAnnoEmissione = parametriRicerca?.aAnnoEmissione
        def daProgEmissione = parametriRicerca?.daProgEmissione
        def aProgEmissione = parametriRicerca?.aProgEmissione
        def daDataEmissione = parametriRicerca?.daDataEmissione
        def aDataEmissione = parametriRicerca?.aDataEmissione
        def daDataInvio = parametriRicerca?.daDataInvio
        def aDataInvio = parametriRicerca?.aDataInvio
        def daNumeroRuolo = parametriRicerca?.daNumeroRuolo
        def aNumeroRuolo = parametriRicerca?.aNumeroRuolo
        def tipoRuolo = parametriRicerca?.tipoRuolo
        def specieRuolo = parametriRicerca?.specieRuolo
        def tipoEmissione = parametriRicerca?.tipoEmissione
        def codiceTributo = parametriRicerca?.codiceTributo
        def anno = parametriRicerca?.annoList

        filtri << ['tipoTributo': tipoTributo]

        String annoList = ''
        if (anno && !anno.empty) {
            anno.each {
                if (!annoList.empty) {
                    annoList += ", "
                }
                annoList += it.value.toString()
            }
        }

        String extraFilter = (annoList != '') ? " AND RUOLI.ANNO_RUOLO IN (${annoList}) " : ""

        if (daAnno != null) {
            filtri << ['daAnno': daAnno]
            extraFilter += " AND RUOLI.ANNO_RUOLO >= :daAnno "
        }
        if (aAnno != null) {
            filtri << ['aAnno': aAnno]
            extraFilter += " AND RUOLI.ANNO_RUOLO <= :aAnno "
        }
        if (daAnnoEmissione != null) {
            filtri << ['daAnnoEmissione': daAnnoEmissione]
            extraFilter += " AND RUOLI.ANNO_EMISSIONE >= :daAnnoEmissione "
        }
        if (aAnnoEmissione != null) {
            filtri << ['aAnnoEmissione': aAnnoEmissione]
            extraFilter += " AND RUOLI.ANNO_EMISSIONE <= :aAnnoEmissione "
        }
        if (daProgEmissione != null) {
            filtri << ['daProgEmissione': daProgEmissione]
            extraFilter += " AND RUOLI.PROGR_EMISSIONE >= :daProgEmissione "
        }
        if (aProgEmissione != null) {
            filtri << ['aProgEmissione': aProgEmissione]
            extraFilter += " AND RUOLI.PROGR_EMISSIONE <= :aProgEmissione "
        }
        if (daDataEmissione != null) {
            filtri << ['daDataEmissione': daDataEmissione.format('dd/MM/yyyy') ?: '01/01/1800']
            extraFilter += " AND RUOLI.DATA_EMISSIONE >= TO_DATE(:daDataEmissione, 'dd/mm/yyyy') "
        }
        if (aDataEmissione != null) {
            filtri << ['aDataEmissione': aDataEmissione.format('dd/MM/yyyy') ?: '01/01/1800']
            extraFilter += """ AND RUOLI.DATA_EMISSIONE <= TO_DATE(:aDataEmissione, 'dd/mm/yyyy') """
        }
        if (daDataInvio != null) {
            filtri << ['daDataInvio': daDataInvio.format('dd/MM/yyyy') ?: '01/01/1800']
            extraFilter += " AND RUOLI.INVIO_CONSORZIO >= TO_DATE(:daDataInvio, 'dd/mm/yyyy') "
        }
        if (aDataInvio != null) {
            filtri << ['aDataInvio': aDataInvio.format('dd/MM/yyyy') ?: '01/01/1800']
            extraFilter += " AND RUOLI.INVIO_CONSORZIO <= TO_DATE(:aDataInvio, 'dd/mm/yyyy') "
        }
        if (daNumeroRuolo != null) {
            filtri << ['daNumeroRuolo': daNumeroRuolo]
            extraFilter += " AND RUOLI.RUOLO >= :daNumeroRuolo "
        }
        if (aNumeroRuolo != null) {
            filtri << ['aNumeroRuolo': aNumeroRuolo]
            extraFilter += " AND RUOLI.RUOLO <= :aNumeroRuolo "
        }
        if (specieRuolo != null) {
            filtri << ['specieRuolo': specieRuolo]
            extraFilter += " AND RUOLI.SPECIE_RUOLO = :specieRuolo "
        }
        if (tipoRuolo != null) {
            filtri << ['tipoRuolo': tipoRuolo]
            extraFilter += " AND RUOLI.TIPO_RUOLO = :tipoRuolo "
        }
        if (tipoEmissione != null) {
            filtri << ['tipoEmissione': tipoEmissione]
            extraFilter += " AND RUOLI.TIPO_EMISSIONE = :tipoEmissione "
        }
        if (codiceTributo != null) {
            filtri << ['codiceTributo': codiceTributo]
            extraFilter += " AND RUOLI.TRIBUTO = :codiceTributo "
        }

        String query = """
				SELECT   RUOLI.TIPO_RUOLO,
				         RUOLI.ANNO_RUOLO,
				         RUOLI.ANNO_EMISSIONE,
				         RUOLI.PROGR_EMISSIONE,
				         RUOLI.DATA_EMISSIONE,
				         NVL(RUOLI.TRIBUTO,0) AS TRIBUTO,
				         RUOLI.IMPORTO,
				         RUOLI.ADD_MAGG_ECA,
				         RUOLI.ADD_PRO,
				         RUOLI.IVA,
				         RUOLI.MAGGIORAZIONE_TARES AS MAGG_TARES,
				         RUOLI.INVIO_CONSORZIO,   
				         RUOLI.RUOLO,
				         RUOLI.TIPO_TRIBUTO,
				         RUOLI.SGRAVIO,
				         RUOLI.RUTR_DESC,
				         RUOLI.SCADENZA_PRIMA_RATA,
				         RUOLI.SPECIE_RUOLO,
				         RUOLI.IMPORTO_LORDO,
				         RUOLI.RUOLO_MASTER,
				         RUOLI.IS_RUOLO_MASTER,
				         RUOLI.TIPO_CALCOLO,
				         RUOLI.TIPO_EMISSIONE,
				         F_COMPENSAZIONE_RUOLO(RUOLI.RUOLO,NULL,NULL) AS COMPENSAZIONE,
				         RUOLI.IMPOSTA,
				         RUOLI.ECCEDENZE,
				         RUOLI.ADD_PRO_IMP,
				         RUOLI.ADD_PRO_ECC,
				     --  RUOLI.PERC_ACCONTO,
				         NULL AS PERC_ACCONTO,
				         RUOLI.FLAG_CALCOLO_TARIFFA_BASE,
				         RUOLI.FLAG_TARIFFE_RUOLO,
				         RUOLI.FLAG_DEPAG,
				         DECODE(CATA.ANNO,NULL,'S',NULL) AS FLAG_ERRORE_CATA,
				         DECODE(RUOLI.TIPO_RUOLO,2,CATA.FLAG_TARIFFA_PUNTUALE,null) AS FLAG_TARIFFA_PUNTUALE
				FROM RUOLI_ELENCO RUOLI,
				         CARICHI_TARSU CATA
				WHERE ((RUOLI.IMPORTO <> 0 OR NVL(UPPER(F_INPA_VALORE('RUOLO_ZERO')),'N') = 'S') OR
				         NOT EXISTS (SELECT 1 FROM RUOLI_CONTRIBUENTE RUCO
				         WHERE RUCO.RUOLO = RUOLI.RUOLO))
				  AND RUOLI.TIPO_TRIBUTO = :tipoTributo
				  AND RUOLI.ANNO_RUOLO = CATA.ANNO (+)
				  ${extraFilter}
				ORDER BY TIPO_RUOLO ASC,
				         ANNO_RUOLO ASC,
				         ANNO_EMISSIONE ASC,
				         PROGR_EMISSIONE ASC,
				         TRIBUTO ASC,
				         DATA_EMISSIONE ASC,
				         INVIO_CONSORZIO ASC
        """

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        int totalCount = 0
        int pageCount = 0
        int pageStart = activePage * pageSize

        def records = []

        if (parametriRicerca?.ruoliSelezionati != null) {
            results = results.findAll { it.RUOLO in parametriRicerca.ruoliSelezionati.collect { it.key } }
        }

        results.each {

            if ((totalCount >= pageStart) && (pageCount < pageSize)) {

                def record = [:]
                record.tipoRuolo = it['TIPO_RUOLO']
                record.annoRuolo = it['ANNO_RUOLO']
                record.annoEmissione = it['ANNO_EMISSIONE']
                record.progrEmissione = it['PROGR_EMISSIONE']
                record.dataEmissione = it['DATA_EMISSIONE']
                record.tributo = it['TRIBUTO']
                record.importo = it['IMPORTO']
                record.addMaggEca = it['ADD_MAGG_ECA']
                record.addPro = it['ADD_PRO']
                record.iva = it['IVA']
                record.maggTares = it['MAGG_TARES']
                record.invioConsorzio = it['INVIO_CONSORZIO']
                record.invioConsorzioControllo = it['INVIO_CONSORZIO']
                record.ruolo = it['RUOLO']
                record.tipoTributo = it['TIPO_TRIBUTO']
                record.sgravio = it['SGRAVIO']
                record.rutrDesc = it['RUTR_DESC']
                record.scadenzaPrimaRata = it['SCADENZA_PRIMA_RATA']
                record.specieRuolo = it['SPECIE_RUOLO']
                record.importoLordo = it['IMPORTO_LORDO']
                record.ruoloMaster = it['RUOLO_MASTER']
                record.isRuoloMaster = it['IS_RUOLO_MASTER']
                record.tipoCalcolo = it['TIPO_CALCOLO']
                record.tipoEmissione = it['TIPO_EMISSIONE']
                record.compensazione = it['COMPENSAZIONE']
                record.imposta = it['IMPOSTA']
                record.percAcconto = it['PERC_ACCONTO']
                record.flagCalcoloTariffaBase = it['FLAG_CALCOLO_TARIFFA_BASE']
                record.flagTariffeRuolo = it['FLAG_TARIFFE_RUOLO']
                record.flagDePag = it['FLAG_DEPAG']

				record.eccedenze = it['ECCEDENZE']
				record.addProImp = it['ADD_PRO_IMP']
				record.addProEcc = it['ADD_PRO_ECC']

                record.flagErroreCaTa = it['FLAG_ERRORE_CATA']

                if(record.tipoRuolo == 2) { // SOLO supplettivo
                    record.flagTariffaPuntuale = it['FLAG_TARIFFA_PUNTUALE']
                }
                else {
                    record.flagTariffaPuntuale = null
                }

                switch (record.tipoRuolo) {
                    default: record.tipoRuoloDescr = ''; break
                    case 1: record.tipoRuoloDescr = 'P'; break
                    case 2: record.tipoRuoloDescr = 'S'; break
                }
                switch (record.tipoCalcolo) {
                    default: record.tipoCalcoloDescr = ''; break
                    case 'T': record.tipoCalcoloDescr = 'Tradizionale'; break
                    case 'N': record.tipoCalcoloDescr = 'Normalizzato'; break
                }
                switch (record.tipoEmissione) {
                    default: record.tipoEmissioneDescr = ''; break
                    case 'A': record.tipoEmissioneDescr = 'Acconto'; break
                    case 'S': record.tipoEmissioneDescr = 'Saldo'; break
                    case 'T': record.tipoEmissioneDescr = 'Totale'; break
                    case 'X': record.tipoEmissioneDescr = ''; break
                }

                if(record.flagTariffaPuntuale == 'S') {
                    record.addProvTooltip = "Da Imposta: " + importoFmt.format((record.addProImp ?: 0)) + "\n" + 
                                                        "Da Eccedenze: " + importoFmt.format((record.addProEcc ?: 0))
                }
                else {
                    record.addProvTooltip = null
                }

                record.selezionabile = true

                record.inviatoAConsorzio = record.invioConsorzio != null

                records << record

                pageCount++
            }

            totalCount++
        }

        return [totalCount: totalCount, records: records]
    }

    def getPraticheRuolo(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        def ruoliId = "(" + parametriRicerca?.ruoli?.join(",") + ",-1)"

        def filtri = [:]
        filtri << ["pAnno": parametriRicerca.anno]
        filtri << ["pTipoTributo": parametriRicerca.tipoTributo]

        def hasPEC = parametriRicerca?.hasPEC ?: -1
        def hasVersamenti = parametriRicerca?.hasVersamenti ?: -1

        def filtriRicerca = ""

        if (parametriRicerca?.cognome) {
            filtriRicerca += " AND SOGGETTI.COGNOME LIKE :pCognome "
            filtri << ["pCognome": parametriRicerca.cognome.toUpperCase()]
        }

        if (parametriRicerca?.nome) {
            filtriRicerca += " AND SOGGETTI.NOME LIKE :pNome "
            filtri << ["pNome": parametriRicerca.nome.toUpperCase()]
        }

        if (parametriRicerca?.codFiscale) {
            filtriRicerca += " AND SOGGETTI.COD_FISCALE LIKE :pCodFiscale "
            filtri << ["pCodFiscale": parametriRicerca.codFiscale.toUpperCase()]
        }

        if (parametriRicerca?.tipoPratica && parametriRicerca.tipoPratica != "T") {
            filtriRicerca += " AND PRATICHE_TRIBUTO.TIPO_PRATICA = :pTipoPratica "
            filtri << ["pTipoPratica": parametriRicerca.tipoPratica]
        }

        if (parametriRicerca?.numeroDa != null) {
            if (parametriRicerca.numeroDa.contains('%')) {
                filtriRicerca += " AND PRATICHE_TRIBUTO.NUMERO like :pNumeroDa "
                filtri << ['pNumeroDa': parametriRicerca.numeroDa]
            } else {
                filtriRicerca += " AND LPAD(PRATICHE_TRIBUTO.NUMERO, 15, ' ') >= :pNumeroDa "
                filtri << ['pNumeroDa': parametriRicerca.numeroDa.padLeft(15, " ")]
            }
        }

        if (parametriRicerca?.numeroA != null) {
            if (!parametriRicerca?.numeroDa || (parametriRicerca?.numeroDa && !parametriRicerca.numeroDa.contains('%'))) {
                filtriRicerca += " AND LPAD(PRATICHE_TRIBUTO.NUMERO, 15, ' ') <= :pNumeroA "
                filtri << ['pNumeroA': parametriRicerca.numeroA.padLeft(15, " ")]
            }
        }

        if (parametriRicerca?.dataNotificaDa) {
            filtri << ['pDataNotificaDa': parametriRicerca.dataNotificaDa]
            filtriRicerca += " AND PRATICHE_TRIBUTO.DATA_NOTIFICA >= :pDataNotificaDa "
        }

        if (parametriRicerca?.dataNotificaA) {
            filtri << ['pDataNotificaA': parametriRicerca.dataNotificaA]
            filtriRicerca += " AND PRATICHE_TRIBUTO.DATA_NOTIFICA <= :pDataNotificaA "
        }

        if (parametriRicerca?.dataEmissioneDa) {
            filtri << ['pDataEmissioneDa': parametriRicerca.dataEmissioneDa]
            filtriRicerca += " AND PRATICHE_TRIBUTO.DATA >= :pDataEmissioneDa "
        }

        if (parametriRicerca?.dataEmissioneA) {
            filtri << ['pDataEmissioneA': parametriRicerca.dataEmissioneA]
            filtriRicerca += " AND PRATICHE_TRIBUTO.DATA <= :pDataEmissioneA "
        }


        def query = """
                SELECT PRATICHE_TRIBUTO.PRATICA,
                       PRATICHE_TRIBUTO.TIPO_PRATICA,
                       PRATICHE_TRIBUTO.DATA_NOTIFICA,
                       PRATICHE_TRIBUTO.ANNO,
                       PRATICHE_TRIBUTO.NUMERO,
                       F_ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 891) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 892) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 893) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 894),
                               1) imp_sanz,
                       F_ROUND(PRATICHE_TRIBUTO.IMPORTO_RIDOTTO +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 891) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 892) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 893) +
                               F_SANZIONI_ADDIZIONALI(PRATICHE_TRIBUTO.PRATICA, 894),
                               1) importo_ridotto,
                       tot_vers.i_v TOTALE_VERSATO,
                       CONTRIBUENTI.NI,
                       SOGGETTI.COGNOME_NOME,
                       SANZIONI_PRATICA.RUOLO,
                       contribuenti.cod_fiscale,
                       f_recapito(SOGGETTI.NI, RUOLI.TIPO_TRIBUTO, 3) AS PEC_MAIL,
                       DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONTRIBUENTI.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'VS'),
                                  0) AS VERSAMENTI_VS,
                       DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'A',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONTRIBUENTI.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  'S',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONTRIBUENTI.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONTRIBUENTI.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'V'),
                                  0) AS VERSAMENTI_V,
                       DECODE(NVL(RUOLI.TIPO_EMISSIONE, 'X'),
                                  'T',
                                  f_tot_vers_cont_ruol(RUOLI.ANNO_RUOLO,
                                                       CONTRIBUENTI.COD_FISCALE,
                                                       RUOLI.TIPO_TRIBUTO,
                                                       null,
                                                       'VC'),
                                  0) AS VERSAMENTI_VC
                  FROM SOGGETTI,
                       DATI_GENERALI,
                       (select sum(vers.importo_versato) I_V90,
                               sum(decode(sign(nvl(trunc(vers.data_pagamento),
                                                   trunc(prtr.data_notifica)) -
                                               trunc(prtr.data_notifica) -
                                               f_ricalcolo_giorni(trunc(prtr.data_notifica),
                                                                  nvl(trunc(vers.data_pagamento),
                                                                      trunc(prtr.data_notifica)),
                                                                  prtr.tipo_tributo)),
                                          1,
                                          0,
                                          vers.importo_versato)) I_V60,
                               VERS.PRATICA PRAT,
                               VERS.COD_FISCALE CF
                          from versamenti VERS, PRATICHE_TRIBUTO PRTR
                         where nvl(trunc(VERS.DATA_PAGAMENTO), trunc(prtr.data_notifica)) -
                               trunc(PRTR.DATA_NOTIFICA) <=
                               f_ricalcolo_giorni(trunc(prtr.data_notifica),
                                                  nvl(trunc(vers.data_pagamento),
                                                      trunc(prtr.data_notifica)),
                                                  '90')
                           and VERS.PRATICA = PRTR.PRATICA
                         GROUP BY VERS.PRATICA, VERS.COD_FISCALE) vers,
                       (select sum(vers.importo_versato) I_V,
                               max(nvl(trunc(vers.data_pagamento), trunc(prtr.data_notifica))) D_P,
                               VERS.PRATICA PRAT,
                               VERS.COD_FISCALE CF
                          from versamenti VERS, PRATICHE_TRIBUTO PRTR
                         where VERS.PRATICA = PRTR.PRATICA
                         GROUP BY VERS.PRATICA, VERS.COD_FISCALE) tot_vers,
                       PRATICHE_TRIBUTO,
                       RAPPORTI_TRIBUTO,
                       CONTRIBUENTI,
                       RUOLI,
                       (select sapr.pratica, min(sapr.ruolo) ruolo
                          from sanzioni_pratica sapr
                         group by sapr.pratica) SANZIONI_PRATICA
                 WHERE PRATICHE_TRIBUTO.ANNO = :pAnno
                   and SANZIONI_PRATICA.RUOLO IN ${ruoliId}
                   and RUOLI.RUOLO = SANZIONI_PRATICA.RUOLO
                   and PRATICHE_TRIBUTO.TIPO_PRATICA IN ('A', 'L')
                   and PRATICHE_TRIBUTO.DATA_NOTIFICA is not NULL
                   and (PRATICHE_TRIBUTO.pratica_rif is null or
                       (PRATICHE_TRIBUTO.pratica_rif is not null and
                       substr(f_pratica(PRATICHE_TRIBUTO.pratica_rif), 1, 1) = 'G' and
                       nvl(substr(f_pratica(PRATICHE_TRIBUTO.pratica_rif), 3), 'D') not in
                       ('P', 'D')))
                   and SANZIONI_PRATICA.PRATICA = PRATICHE_TRIBUTO.PRATICA
                   and F_ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE, 1) > 0
                   and F_ROUND(PRATICHE_TRIBUTO.IMPORTO_RIDOTTO, 1) > 0
                   and CONTRIBUENTI.NI = SOGGETTI.NI
                   and PRATICHE_TRIBUTO.PRATICA = RAPPORTI_TRIBUTO.PRATICA
                   and RAPPORTI_TRIBUTO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE
                   and PRATICHE_TRIBUTO.TIPO_TRIBUTO || '' = :pTipoTributo
                   and vers.PRAT(+) = RAPPORTI_TRIBUTO.PRATICA
                   and vers.CF(+) = RAPPORTI_TRIBUTO.COD_FISCALE
                   and tot_vers.PRAT(+) = RAPPORTI_TRIBUTO.PRATICA
                   and tot_vers.CF(+) = RAPPORTI_TRIBUTO.COD_FISCALE
                   ${filtriRicerca}
                 order by 11 ASC, 10 ASC
		"""

        def postFilter = ""

        // -1 -> Tutti,	10 -> Con Versamenti,	11 -> Con Versamenti spontanei,	12 -> Con Versamenti da compensazione,	20 -> Senza Versamenti
        switch (hasVersamenti) {
            default: break
            case -1:
                break
            case 10:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "(VERSAMENTI_V > 0 OR VERSAMENTI_VS > 0 OR VERSAMENTI_VC > 0)"
                break
            case 11:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "(VERSAMENTI_VS > 0)"
                break
            case 12:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "(VERSAMENTI_VC > 0)"
                break
            case 20:
                if (postFilter.length() > 0) postFilter += " AND "
                postFilter += "(VERSAMENTI_V = 0 AND VERSAMENTI_VS = 0 AND VERSAMENTI_VC = 0)"
                break
        }


        postFilter += creaCondizioneHasPEC(hasPEC, postFilter)

        if (postFilter) {
            query = "SELECT * FROM (${query}) WHERE ${postFilter}"
        }

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        results.each {
            it.sanzioni = praticheSanzioneQuery(ruoliId, it.pratica)
            it.tooltipSanzioni = ""
            it.sanzioni.each { s ->
                it.tooltipSanzioni += "${s.sanzDesc} ${s.importo}\n"
            }
        }

        def colonneSanzioni = results*.sanzioni.flatten()
                .collect { [label: it.tributo, tooltiptext: it.tribDesc] }.unique()

        def pratiche = []

        String patternValuta = "\$euro\$ #,###.00"
        DecimalFormat valuta = new DecimalFormat(patternValuta)

        results.each { p ->

            def soggetto = PraticaTributo.createCriteria().list {
                createAlias("contribuente", "cont", CriteriaSpecification.INNER_JOIN)
                createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)

                eq('id', p.pratica as Long)
            }[0].contribuente.soggetto

            def cognomeNome = "${soggetto.cognome} ${soggetto.nome ?: ''}"


            def singolaPratica = [
                    [label: p.pratica, type: "number", cssClass: "destra", key: "pratica"],
                    [label: cognomeNome, type: "generic", cssClass: "", key: "cognomeNome"],
                    [label: p.codFiscale, type: "generic", cssClass: "", key: "codFiscale"],
                    [label: p.tipoPratica, type: "number", cssClass: "centro", key: "tipoPratica"],
                    [label: p.anno, type: "number", cssClass: "centro", key: "anno"],
                    [label: p.numero, type: "number", cssClass: "destra", key: "numero"],
                    [label: p.dataNotifica, type: "date", cssClass: "centro", key: "dataNotifica"],
                    [label: p.impSanz, type: "currency", cssClass: "destra", key: "impSanz"],
                    [label: p.importoRidotto, type: "currency", cssClass: "destra", key: "importoRidotto"],
                    [label: p.totaleVersato, type: "currency", cssClass: "destra", key: "totaleVersato"]
            ]

            colonneSanzioni.each { cs ->
                def sanzione =
                        p.sanzioni.findAll { s -> s.tributo == cs.label }
                                .collect { s -> [tributo: s.tributo, importoTotale: s.importoTotale] }
                                .unique()[0]

                def tooltipText = ""
                p.sanzioni.findAll { s -> s.tributo == cs.label }
                        .each { s1 ->
                            tooltipText += "${s1.sanzDesc} ${commonService.formattaValuta(s1.importo) ?: ''}\n"
                        }

                singolaPratica << [label      : sanzione?.importoTotale,
                                   type       : "currency",
                                   cssClass   : "destra",
                                   tooltipText: tooltipText,
                                   key        : cs.label]
            }

            singolaPratica << [label: p.ruolo, type: "number", cssClass: "destra", key: "ruolo"]

            pratiche << singolaPratica
        }

        return [colonneSanzioni: colonneSanzioni,
                pratiche       : pratiche]

    }

    private creaCondizioneHasPEC(def hasPEC, def postFilter) {

        def condizione = ""

        switch (hasPEC) {
            default: break
            case -1:
                break
            case 1:
                if (postFilter.length() > 0) {
                    condizione += " AND "
                }
                condizione += "PEC_MAIL IS NULL "
                break
            case 2:
                if (postFilter.length() > 0) {
                    condizione += " AND "
                }
                condizione += "PEC_MAIL IS NOT NULL "
                break
        }

        return condizione
    }

    // Legge Eccedenze del ruolo
    def getEccedenzeRuolo(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        def ruoliId = "(" + parametriRicerca?.ruoli?.join(",") + ",-1)"
        def codTributo = parametriRicerca?.tributo

        Boolean perExport = parametriRicerca.perExport ?: false

        def parameters = [:]

        String extraFilter = ""
        String temp

        if (codTributo) {
            parameters << [codTributo: codTributo]
            extraFilter += "AND RUEC.TRIBUTO = :codTributo "
        }

        temp = (String) parametriRicerca?.codFiscale
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [codFiscale: temp + '%']
            extraFilter += "AND RUEC.COD_FISCALE LIKE (:codFiscale) "
        }
        temp = (String) parametriRicerca?.cognome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [cognome: temp + '%']
            extraFilter += "AND SOGG.COGNOME_RIC LIKE (:cognome) "
        }
        temp = (String) parametriRicerca?.nome
        if ((temp != null) && (temp.size() > 0)) {
            temp = temp.toUpperCase()
            parameters << [nome: temp + '%']
            extraFilter += "AND SOGG.NOME_RIC LIKE (:nome) "
        }

        String query = """
            SELECT
              RUEC.ID_ECCEDENZA,
              RUOL.RUOLO,
              RUOL.ANNO_RUOLO,
              RUEC.COD_FISCALE,
              SOGG.NI,
              TRANSLATE(SOGG.COGNOME_NOME, '/', ' ') AS COGNOME_NOME,
              SOGG.COGNOME,
              SOGG.NOME,
              RUEC.TRIBUTO,
              RUEC.CATEGORIA,
              RUEC.SEQUENZA,
              RUEC.DAL,
              RUEC.AL,
              RUEC.FLAG_DOMESTICA,
              RUEC.NUMERO_FAMILIARI,
              RUEC.IMPOSTA,
              RUEC.ADDIZIONALE_PRO,
              RUEC.IMPORTO_RUOLO,
              RUEC.IMPORTO_MINIMI,
              RUEC.TOTALE_SVUOTAMENTI,
              RUEC.SUPERFICIE,
              RUEC.COSTO_UNITARIO,
              RUEC.COSTO_SVUOTAMENTO,
              RUEC.SVUOTAMENTI_SUPERFICIE,
              RUEC.COSTO_SUPERFICIE,
              RUEC.ECCEDENZA_SVUOTAMENTI,
              RUEC.UTENTE,
              RUEC.DATA_VARIAZIONE,
              RUEC.NOTE
            FROM
              RUOLI_ECCEDENZE  RUEC,
              RUOLI            RUOL,
              CONTRIBUENTI     CONT,
              SOGGETTI         SOGG
            WHERE
                RUEC.RUOLO = RUOL.RUOLO
            AND RUEC.RUOLO in $ruoliId
            AND RUEC.COD_FISCALE = CONT.COD_FISCALE
            AND CONT.NI = SOGG.NI
	            ${extraFilter}
            ORDER BY
              RUOL.ANNO_RUOLO   DESC,
              SOGG.COGNOME_NOME  ASC,
              RUEC.COD_FISCALE   ASC,
              RUEC.TRIBUTO       ASC,
              RUEC.CATEGORIA     ASC,
              RUEC.DAL           ASC,
              RUEC.AL            ASC
        """

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            parameters.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        def listaEccedenze = []

        int totalCount = 0
        int pageCount = 0
        int pageStart = activePage * pageSize

        results.each {

            if ((totalCount >= pageStart) && (pageCount < pageSize)) {

                def eccedenza = [:]

                eccedenza.codUnivoco = it['ID_ECCEDENZA'].toString()

                eccedenza.ruolo = it['RUOLO']
                eccedenza.tributo = it['TRIBUTO']
                eccedenza.categoria = it['CATEGORIA']
                eccedenza.sequenza = it['SEQUENZA']

                eccedenza.anno = it['ANNO_RUOLO'].toLong()

                eccedenza.dataDal = it['DAL']
                eccedenza.dataAl = it['AL']
                eccedenza.numeroFamiliari = it['NUMERO_FAMILIARI']
				
                eccedenza.ni = it['NI']
                eccedenza.codFiscale = it['COD_FISCALE']
                eccedenza.cognomeNome = it['COGNOME_NOME']
                eccedenza.cognome = it['COGNOME']
                eccedenza.nome = it['NOME']

                eccedenza.flagDomestica = (it['FLAG_DOMESTICA'] == 'S') ? true : false

                eccedenza.imposta = it['IMPOSTA']
                eccedenza.addProv = it['ADDIZIONALE_PRO']
                eccedenza.importoRuolo = it['IMPORTO_RUOLO']
                eccedenza.importoMinimi = it['IMPORTO_MINIMI']
				
                eccedenza.totaleSvuotamenti = it['TOTALE_SVUOTAMENTI']
                eccedenza.superficie = it['SUPERFICIE']
                eccedenza.costoUnitario = it['COSTO_UNITARIO']
                eccedenza.costoSvuotamento = it['COSTO_SVUOTAMENTO']
                eccedenza.svuotamentiSuperficie = it['SVUOTAMENTI_SUPERFICIE']
                eccedenza.costoSuperficie = it['COSTO_SUPERFICIE']
                eccedenza.eccedenzaSvuotamenti = it['ECCEDENZA_SVUOTAMENTI']

                eccedenza.note = it['NOTE']

                listaEccedenze << eccedenza

                pageCount++
            }

            totalCount++
        }

        return [totalCount: totalCount, records: listaEccedenze]
    }

    private def praticheSanzioneQuery(String ruoliId, def pratica) {

        def query = """
            SELECT DISTINCT decode(SANZIONI.TRIBUTO,
                               0,
                               OGGETTI_PRATICA.TRIBUTO,
                               SANZIONI.TRIBUTO) tributo,
                        SANZIONI_PRATICA.RUOLO,
                        RUOLI_CONTRIBUENTE.SEQUENZA,
                        RUOLI_CONTRIBUENTE.PRATICA,
                        RUOLI_CONTRIBUENTE.UTENTE,
                        RUOLI_CONTRIBUENTE.RUOLO,
                        RUOLI_CONTRIBUENTE.TRIBUTO,
                        SANZIONI_PRATICA.IMPORTO,
                        SANZIONI_PRATICA.IMPORTO_RUOLO,
                        RUOLI_CONTRIBUENTE.COD_FISCALE,
                        SANZIONI_PRATICA.COD_SANZIONE,
                        RUOLI_CONTRIBUENTE.IMPORTO as importo_Totale,
                        SANZIONI.FLAG_IMPOSTA,
                        SANZIONI.FLAG_INTERESSI,
                        SANZIONI_PRATICA.COD_SANZIONE || ' - ' ||
                        SANZIONI.DESCRIZIONE sanz_desc,
                        decode(SANZIONI.TRIBUTO,
                               0,
                               OGGETTI_PRATICA.TRIBUTO,
                               SANZIONI.TRIBUTO) || ' - ' ||
                        TIPI_TRIBUTO.DESCRIZIONE trib_desc,
                        RUOLI_CONTRIBUENTE.NOTE,
                        sanzioni_pratica.sequenza sapr_sequenza
          FROM SANZIONI_PRATICA,
               SANZIONI,
               RUOLI_CONTRIBUENTE,
               (select max(OGGETTI_PRATICA.TRIBUTO) tributo,
                       OGGETTI_PRATICA.PRATICA pratica
                  from OGGETTI_PRATICA
                 where OGGETTI_PRATICA.PRATICA = :pPratica
                 group by OGGETTI_PRATICA.PRATICA) OGGETTI_PRATICA,
               TIPI_TRIBUTO
         WHERE sanzioni_pratica.pratica = ruoli_contribuente.pratica(+)
           AND ruoli_contribuente.ruolo(+) = sanzioni_pratica.ruolo
           AND SANZIONI_PRATICA.COD_SANZIONE = SANZIONI.COD_SANZIONE
           AND SANZIONI_PRATICA.SEQUENZA_SANZ = SANZIONI.SEQUENZA
           AND SANZIONI.TIPO_TRIBUTO = SANZIONI_PRATICA.TIPO_TRIBUTO
           AND SANZIONI.TIPO_TRIBUTO = TIPI_TRIBUTO.TIPO_TRIBUTO
           AND OGGETTI_PRATICA.PRATICA(+) = SANZIONI_PRATICA.PRATICA
           AND SANZIONI_PRATICA.PRATICA = :pPratica
           AND (SANZIONI_PRATICA.RUOLO is NULL OR SANZIONI_PRATICA.RUOLO in ${ruoliId})
           AND (decode(SANZIONI.TRIBUTO,
                       0,
                       OGGETTI_PRATICA.TRIBUTO,
                       SANZIONI.TRIBUTO) = RUOLI_CONTRIBUENTE.TRIBUTO OR
               SANZIONI.TRIBUTO is not null AND RUOLI_CONTRIBUENTE.TRIBUTO is null)
        union
        select sanz.tributo tributo,
               decode(1, 2, 2, null) sapr_ruolo,
               decode(1, 2, 2, null) sequenza,
               decode(1, 2, 2, null) pratica,
               '' utente,
               decode(1, 2, 2, null) ruco_ruolo,
               decode(1, 2, 2, null) ruco_tributo,
               F_SANZIONI_ADDIZIONALI(:pPratica, sanz.cod_sanzione) importo,
               decode(1, 2, 2, null) importo_ruolo,
               '' cod_fiscale,
               sanz.cod_sanzione cod_sanzione,
               decode(1, 2, 2, null) importo_totale,
               sanz.flag_imposta flag_imposta,
               sanz.flag_interessi flag_interessi,
               sanz.COD_SANZIONE || ' - ' || sanz.DESCRIZIONE sanz_desc,
               SANZ.TRIBUTO || ' - ' || TITR.DESCRIZIONE trib_desc,
               '' note,
               decode(1, 2, 2, null) sapr_sequenza
          from sanzioni sanz, tipi_tributo titr, ruoli ruol
         where sanz.COD_SANZIONE in (891, 892, 893, 894)
           and sanz.TIPO_TRIBUTO = 'TARSU'
           and F_SANZIONI_ADDIZIONALI(:pPratica, sanz.cod_sanzione) > 0
           and titr.TIPO_TRIBUTO = 'TARSU'
           and ruol.ruolo in ${ruoliId}
           and nvl(ruol.importo_lordo, 'N') = 'S'
           and not exists (select 'x'
                  from ruoli_contribuente ruco1
                 where ruco1.ruolo in ${ruoliId}
                   and ruco1.PRATICA = :pPratica)
         ORDER BY 1 asc, 11 ASC
        """

        def results = sessionFactory.currentSession.createSQLQuery(query).with {

            setLong("pPratica", pratica as Long)
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

    def generaTrasmissione(List<Long> ruoli, Tracciato tipoTracciato) {
        def nomeFile = ""
        def nomeProcedure = "TRASMISSIONE_RUOLO"

        def sessione = sessionFactory.currentSession.createSQLQuery("select PARAM_SEQ.nextval from dual").list()[0]


        int progressivo = 1
        if (tipoTracciato == Tracciato.T290) {
            def mesi = [2: 1, 4: 2, 6: 3, 9: 4, 11: 5]
            def ruolo = Ruolo.get(ruoli[0])
            nomeFile = "${ruolo.tipoTributo.codEnte}${ruolo.annoEmissione}${mesi[ruolo.scadenzaPrimaRata.getAt(Calendar.MONTH)]}.001"
        } else {
            nomeProcedure += "_${tipoTracciato.code}"

            Sql sql = new Sql(dataSource)
            sql.call('{? = call F_GET_NOME_FILE_TRAS_RUOLI}'
                    , [Sql.VARCHAR]) { nomeFile = it }
            sql.close()
        }

        ruoli.each {
            Parametri param = new Parametri(
                    [sessione: sessione, nomeParametro: nomeProcedure, progressivo: progressivo++, valore: it]
            )

            param.save(flush: true, failOnError: true)
        }


        Sql sql = new Sql(dataSource)
        sql.call("{call ${nomeProcedure}(?, ?, ?)}"
                , [sessione, nomeProcedure, null])
        sql.close()


        def data = ""
        sessionFactory.currentSession.createSQLQuery("""
            SELECT wrkt.dati as dati  
                FROM wrk_trasmissione_ruolo wrkt,   
                     parametri para 
               WHERE ( wrkt.ruolo = to_number( para.valore ) ) AND  
                     ( para.sessione = :pSessione )
               ORDER BY wrkt.progressivo
    """).with {
            setParameter('pSessione', sessione)
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }.each {
            data += "${it.dati}\n"
        }

        ruoli.each {
            sessionFactory.currentSession.createSQLQuery("delete from wrk_trasmissione_ruolo trru where trru.ruolo = $it").executeUpdate()
        }


        return [nomeFile: nomeFile, data: data]

    }

    def eliminaPraticaDaRuolo(Long idPratica, Long idRuolo) {

        PraticaTributo prtr = PraticaTributo.get(idPratica)
        Ruolo ruolo = Ruolo.get(idRuolo)

        // Si recuperano i ruoli contribuente associati alla pratica ed al contribuente
        ruolo.ruoliContribuente.findAll {
            it.contribuente == prtr.contribuente &&
                    it.pratica == prtr
        }.each { rc ->
            // Si elimina il ruolo contribuente
            ruolo.ruoliContribuente.remove(rc)
            rc.delete(failOnError: true, flush: true)
        }

        // Si resettano le informazioni sulle sanzioni pratica
        SanzionePratica.findAllByRuoloAndPratica(
                ruolo,
                prtr
        ).each {
            it.importoRuolo = null
            it.ruolo = null

            it.save(flush: true, failOnError: true)
        }
    }

    def eliminaContribuenteDaRuolo(Long idRuolo, String codFiscale) {

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call eliminazione_ruolo(?, ?)}'
                    , [
                    idRuolo,
                    codFiscale
            ])

            // Eliminazione dovuto
            def ruolo = Ruolo.get(idRuolo)
            if (integrazioneDePagService.dePagAbilitato() && ruolo?.flagDePag == 'S') {
                integrazioneDePagService.eliminaDovutoRuolo(codFiscale, idRuolo)
            }
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def elencoRuoliAutomatici(def filtri = [:]) {

        return RuoliAutomatici.createCriteria().list {

            createAlias("ruolo", "ruol", CriteriaSpecification.INNER_JOIN)


            if (filtri?.ruolo) {
                eq('ruolo.id', filtri.ruolo.id)
            }

            if (filtri?.tipoRuolo && filtri.tipoRuolo.codice) {
                eq('ruol.tipoRuolo', filtri.tipoRuolo.codice)
            }

            if (filtri?.annoRuoloDa) {
                gte('ruol.annoRuolo', filtri?.annoRuoloDa as Short)
            }

            if (filtri?.annoRuoloA) {
                lte('ruol.annoRuolo', filtri?.annoRuoloA as Short)
            }

            if (filtri?.annoEmissioneDa) {
                gte('ruol.annoEmissione', filtri?.annoEmissioneDa as Short)
            }

            if (filtri?.annoEmissioneA) {
                lte('ruol.annoEmissione', filtri?.annoEmissioneA as Short)
            }

            if (filtri?.validitaDa) {
                gte('daData', filtri?.validitaDa)
            }

            if (filtri?.validitaA) {
                lte('aData', filtri?.validitaA)
            }

            order('daData')
        }.toDTO(["ruolo"])
    }

    def existsOverlappingRuoloAutomatico(RuoliAutomaticiDTO dto) {
        return RuoliAutomatici.createCriteria().count {

            eq('tipoTributo', dto.tipoTributo.toDomain())

            // Avoiding to involve current interesse when editing it
            if (dto.id != null) {
                ne('id', dto.id)
            }

            ge('aData', dto.daData)
            le('daData', dto.aData)
        } > 0
    }

    def salvaRuoloAutomatico(RuoliAutomaticiDTO dto) {

        RuoliAutomatici ruoloAutomatico = RuoliAutomatici.findByRuoloAndDaData(dto.ruolo.toDomain(), dto.daData)

        if ((ruoloAutomatico) && (ruoloAutomatico.id != (dto.id ?: 0))) {
            throw new Application20999Error("Esiste già un ruolo automatico per (ruolo, da) [${dto.ruolo.id}, ${dto.daData.format("dd/MM/yyyy")}]")
        }

        return dto.toDomain().save(failOnError: true, flush: true)
    }

    def findAllRuoliAutomatici(PraticaTributoDTO prtr) {

        def sql = """
			select ruol.*, ruol.ruolo as id
				  from ruoli ruol, ruoli_automatici ruau
				 where ruol.ruolo = ruau.ruolo
				   and ruol.invio_consorzio is null
				   and ruol.anno_ruolo >= :pAnno
				   and ruol.tipo_tributo = :pTipoTributo
				   and :pData between ruau.da_data and nvl(ruau.a_data, to_date('99991231', 'YYYYMMDD'))
				   order by TIPO_RUOLO ASC,
                            ANNO_RUOLO ASC,
                            ANNO_EMISSIONE ASC,
                            PROGR_EMISSIONE ASC,
                            DATA_EMISSIONE ASC,
                            INVIO_CONSORZIO ASC

		"""

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setShort('pAnno', prtr.anno)
            setString('pTipoTributo', prtr.tipoTributo.tipoTributo)
            setDate('pData', prtr.data)

            list()
        }
    }

    def verificaSelezioneAnnualitaRuoli(def selezione) {

        def ruoliId = selezione.isEmpty() ? "(-1)" : "(" + selezione?.join(",") + ")"

        def sql = """
			SELECT COUNT(DISTINCT RUOL.ANNO_RUOLO) SPECIE_RUOLO
			FROM RUOLI RUOL
			WHERE RUOL.RUOLO IN $ruoliId
		"""

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0].specieRuolo < 2
    }

    def verificaSelezioneMultiplaRuoli(def selezione) {

        def ruoliId = selezione.isEmpty() ? "(-1)" : "(" + selezione?.join(",") + ")"

        def sql = """
			SELECT COUNT(DISTINCT DECODE(RUOL.TIPO_EMISSIONE, 'A', 0, 'S', 0, 'T', 1)) TIPI_EMISSIONI
			FROM RUOLI RUOL
			WHERE RUOL.RUOLO IN $ruoliId
		"""

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0].tipiEmissioni < 2
    }

    def verificaSelezioneSpecieRuoli(def selezione) {

        def ruoliId = selezione.isEmpty() ? "(-1)" : "(" + selezione?.join(",") + ")"

        def sql = """
			SELECT COUNT(DISTINCT RUOL.SPECIE_RUOLO) SPECIE_RUOLO
			FROM RUOLI RUOL
			WHERE RUOL.RUOLO IN $ruoliId
		"""

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0].specieRuolo < 2
    }

    def verificaSelezioneRuoliTotali(String tipoTributo, def selezione) {

        String annualita = ""

        def ruoliId = selezione.isEmpty() ? "(-1)" : "(" + selezione?.join(",") + ")"

        def sql = """
			SELECT	COUNT(*) AS NUM_RUOLI, RUOL.ANNO_RUOLO 
			FROM	RUOLI RUOL
			WHERE	RUOL.TIPO_TRIBUTO = '${tipoTributo}' AND
					RUOL.TIPO_EMISSIONE = 'T' AND
					RUOL.ANNO_RUOLO in (
						SELECT ANNO_RUOLO FROM RUOLI WHERE TIPO_EMISSIONE = 'T' AND RUOLO IN ${ruoliId}
					) AND
					RUOL.RUOLO NOT IN ${ruoliId}
			GROUP BY RUOL.ANNO_RUOLO
			ORDER BY RUOL.ANNO_RUOLO
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        results.each {

            String anno = it.annoRuolo as String
            if (!annualita.empty) {
                annualita += ", "
            }
            annualita += anno
        }

        return annualita
    }


    def getMinutaDiRuolo(def ruolo, def ordinePrimo, def ordineSecondo) {

        def tributi = getTributiMinutaDiRuolo(ruolo.ruolo)
        def ordineDecedutiNonDeceduti = ""

        def filtri = [
                "p_ruolo": ruolo.ruolo,
                "p_trib1": tributi.trib1,
                "p_trib2": tributi.trib2,
                "p_trib3": tributi.trib3,
                "p_trib4": tributi.trib4,
                "p_trib5": tributi.trib5,
                "p_trib6": tributi.trib6
        ]

        if (ordineSecondo == "D") {
            ordineDecedutiNonDeceduti = " SOGGETTI.STATO = 50 AND "
        } else if (ordineSecondo == "ND") {
            ordineDecedutiNonDeceduti = " SOGGETTI.STATO != 50 AND "
        }

        def ordinamento = ""
        if (ordinePrimo == "A") {
            ordinamento = " COGNOME, NOME, COD_FISCALE, COD_CONTRIB, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (ordinePrimo == "CF") {
            ordinamento = " COD_FISCALE, COGNOME, NOME, COD_CONTRIB, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (ordinePrimo == "CC") {
            ordinamento = " COD_CONTRIB, COGNOME, NOME, COD_FISCALE, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (ordinePrimo == "I") {
            ordinamento = " INDIRIZZO_OG, NUM_CIV, SUFFISSO, COGNOME, NOME, COD_FISCALE, COD_CONTRIB "
        } else {
            throw new IllegalArgumentException("Ordinamento ${ordinamento} non riconosciuto")
        }


        def querySpecie0 = """
                Select * from (
                    SELECT CONTRIBUENTI.COD_FISCALE,
                             RUOLI.ANNO_RUOLO,   
                             RUOLI.RATE rate,   
                             RUOLI.SCADENZA_PRIMA_RATA scad_pr_rata,   
                             decode(RUOLI.RATE,0,'Unica Rata',to_char(RUOLI.RATE)||' rat'||
                                    decode(RUOLI.RATE,1,'a','e')||' dal '||
                                    to_char(RUOLI.SCADENZA_PRIMA_RATA,'dd/mm/yyyy')
                                   ) des_rata,
                             translate(SOGGETTI.COGNOME_NOME, '/', ' ') nominativo,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib1, RUOLI_OGGETTO.IMPORTO, null)) imp_trib1,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib2, RUOLI_OGGETTO.IMPORTO, null)) imp_trib2,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib3, RUOLI_OGGETTO.IMPORTO, null)) imp_trib3,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib4, RUOLI_OGGETTO.IMPORTO, null)) imp_trib4,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib5, RUOLI_OGGETTO.IMPORTO, null)) imp_trib5,   
                             sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib6, RUOLI_OGGETTO.IMPORTO, null)) imp_trib6,   
                             max(decode(RUOLI.TIPO_RUOLO,1, 'RUOLO PRINCIPALE', 'RUOLO SUPPLETIVO')) tipo_ruolo,   
                             OGGETTI.COD_VIA,   
                             OGGETTI.NUM_CIV,   
                             OGGETTI.SUFFISSO,   
                             OGGETTI.SCALA,   
                             OGGETTI.PIANO,   
                             OGGETTI.INTERNO,   
                             decode( CONTRIBUENTI.COD_CONTROLLO , NULL, to_char(CONTRIBUENTI.COD_CONTRIBUENTE), CONTRIBUENTI.COD_CONTRIBUENTE||'-'||CONTRIBUENTI.COD_CONTROLLO) cod_contrib,   
                             max(decode( OGGETTI.COD_VIA, NULL, OGGETTI.INDIRIZZO_LOCALITA, ARCHIVIO_VIE.DENOM_UFF)||decode(OGGETTI.NUM_CIV,NULL,'', ', '||OGGETTI.NUM_CIV )||decode(OGGETTI.SUFFISSO,NULL,'', '/'||OGGETTI.SUFFISSO ))  indirizzo_og,
                             SOGGETTI.COGNOME,    
                             SOGGETTI.NOME,         
                             max(COM3.DENOMINAZIONE||decode(PRO3.SIGLA,null,null,' '||PRO3.SIGLA)
                                )  comune_nas,
                             SOGGETTI.DATA_NAS data_nas,    
                             SOGGETTI.SESSO sesso,
                             max(decode(SOGGETTI.NI_PRESSO
                                       ,null,decode(SOGGETTI.COD_VIA
                                                   ,NULL,SOGGETTI.DENOMINAZIONE_VIA
                                                        ,ARV1.DENOM_UFF
                                                   )||
                                             decode(SOGGETTI.NUM_CIV,NULL,'', ', '||SOGGETTI.NUM_CIV )||
                                             decode(SOGGETTI.SUFFISSO,NULL,'', '/'||SOGGETTI.SUFFISSO )
                                            ,decode(SOG2.COD_VIA
                                                   ,NULL,SOG2.DENOMINAZIONE_VIA
                                                        ,ARV2.DENOM_UFF
                                                   )||
                                             decode(SOG2.NUM_CIV,NULL,'', ', '||SOG2.NUM_CIV )||
                                             decode(SOG2.SUFFISSO,NULL,'', '/'||SOG2.SUFFISSO )
                                       )
                                )  indirizzo_sog,
                             max(decode(SOGGETTI.NI_PRESSO
                                       ,null,COM.DENOMINAZIONE||decode(PRO.SIGLA
                                                                           ,null,null
                                                                                ,' '||PRO.SIGLA
                                                                           )
                                            ,COM2.DENOMINAZIONE||decode(PRO2.SIGLA
                                                                           ,null,null
                                                                                ,' '||PRO2.SIGLA
                                                                           )
                                       )
                                )  comune_sog,
                             OGGETTI.OGGETTO,
                             OGGETTI_PRATICA.CONSISTENZA,
                             nvl(SOGGETTI.STATO,0)    stato_sogg,
                             OGCO.FLAG_AB_PRINCIPALE,
                             F_GET_NUM_FAM_COSU(ogpr.oggetto_pratica, flag_ab_principale, RUOLI_OGGETTO.anno_ruolo, ogim.oggetto_imposta) NUMERO_FAMILIARI,
                          OGIM.IMPORTO_PV,
                          OGIM.IMPORTO_PF
                        FROM SOGGETTI, 
                            SOGGETTI  SOG2,  
                             CONTRIBUENTI, 
                             OGGETTI,   
                             ARCHIVIO_VIE, 
                             ARCHIVIO_VIE ARV1,   
                             ARCHIVIO_VIE ARV2,            
                             OGGETTI_PRATICA,   
                             RUOLI_OGGETTO, 
                              RUOLI,
                             AD4_COMUNI COM,   
                             AD4_PROVINCIE PRO,  
                             AD4_COMUNI COM2,   
                             AD4_COMUNI COM3,      
                             AD4_PROVINCIE PRO2,   
                             AD4_PROVINCIE PRO3,
                             OGGETTI_CONTRIBUENTE OGCO,
                             OGGETTI_IMPOSTA OGIM,
                             oggetti_pratica ogpr              
                       WHERE ( oggetti.cod_via = archivio_vie.cod_via (+)) and  
                             ( soggetti.cod_via = arv1.cod_via (+)) and  
                             ( sog2.cod_via = arv2.cod_via (+)) and  
                             ( COM.PROVINCIA_STATO (+) = SOGGETTI.COD_PRO_RES ) and   
                             ( COM.COMUNE          (+) = SOGGETTI.COD_COM_RES ) and   
                             ( PRO.PROVINCIA       (+) = COM.PROVINCIA_STATO ) and  
                             ( COM2.PROVINCIA_STATO (+) = SOG2.COD_PRO_RES ) and   
                             ( COM2.COMUNE (+) = SOG2.COD_COM_RES ) and   
                             ( PRO2.PROVINCIA (+) = COM2.PROVINCIA_STATO ) and   
                             ( COM3.PROVINCIA_STATO (+) = SOGGETTI.COD_PRO_NAS ) and   
                             ( COM3.COMUNE (+) = SOGGETTI.COD_COM_NAS ) and   
                             ( PRO3.PROVINCIA (+) = COM3.PROVINCIA_STATO ) and          
                             ( SOGGETTI.NI = CONTRIBUENTI.NI ) and  
                              ( SOG2.NI (+) = SOGGETTI.NI_PRESSO ) and 
                              ( RUOLI_OGGETTO.OGGETTO  = OGGETTI.OGGETTO (+)) and
                             ( RUOLI_OGGETTO.OGGETTO_PRATICA = OGGETTI_PRATICA.OGGETTO_PRATICA (+)) and
                             ( RUOLI_OGGETTO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE ) and  
                             ( RUOLI_OGGETTO.RUOLO = RUOLI.RUOLO ) and  
                             ( (RUOLI_OGGETTO.RUOLO = :p_ruolo ) ) and
                             ${ordineDecedutiNonDeceduti}
                              ogim.oggetto_imposta (+) = RUOLI_OGGETTO.oggetto_imposta and
                              ogco.oggetto_pratica (+) = ogim.oggetto_pratica and
                              ogco.cod_fiscale (+) = ogim.cod_fiscale and
                              ogpr.oggetto_pratica (+) = ogim.oggetto_pratica 
                    group by CONTRIBUENTI.COD_FISCALE,   
                             RUOLI.ANNO_RUOLO,
                           OGGETTI.OGGETTO ,  
                             RUOLI.RATE,   
                             RUOLI.SCADENZA_PRIMA_RATA,   
                             decode(RUOLI.RATE,0,'Unica Rata',to_char(RUOLI.RATE)||' rat'||
                                    decode(RUOLI.RATE,1,'a','e')||' dal '||
                                    to_char(RUOLI.SCADENZA_PRIMA_RATA,'dd/mm/yyyy')
                                   ),
                             SOGGETTI.COGNOME_NOME,
                             OGGETTI.COD_VIA,   
                             OGGETTI.NUM_CIV,   
                             OGGETTI.SUFFISSO,   
                             OGGETTI.SCALA,   
                             OGGETTI.PIANO,   
                             OGGETTI.INTERNO,   
                             CONTRIBUENTI.COD_CONTRIBUENTE,
                           CONTRIBUENTI.COD_CONTROLLO,
                           SOGGETTI.COGNOME,    
                           SOGGETTI.NOME,
                            SOGGETTI.DATA_NAS ,    
                             SOGGETTI.SESSO ,      
                             OGGETTI_PRATICA.CONSISTENZA,
                             nvl(SOGGETTI.STATO,0), 
                             OGCO.FLAG_AB_PRINCIPALE,
                             RUOLI_OGGETTO.oggetto_imposta,
                             RUOLI_OGGETTO.anno_ruolo,
                             F_GET_NUM_FAM_COSU(ogpr.oggetto_pratica, flag_ab_principale, RUOLI_OGGETTO.anno_ruolo, ogim.oggetto_imposta),
                          OGIM.IMPORTO_PV,
                          OGIM.IMPORTO_PF)
                    ORDER BY $ordinamento 

                   """


        def querySpecie1 = """
                        Select * from (
                                  SELECT CONTRIBUENTI.COD_FISCALE cod_fiscale,
                                         OGGETTI_PRATICA.OGGETTO_PRATICA oggetto_pratica,   
                                         max(RUOLI.ANNO_RUOLO) anno_ruolo,   
                                         max('RUOLO '||RUOLI.DESCRIZIONE) des_ruolo,
                                         max(RUOLI.RATE) rate,   
                                         max(RUOLI.SCADENZA_PRIMA_RATA) scad_pr_rata,   
                                         max(decode(RUOLI.RATE
                                                   ,0,'Unica Rata'
                                                     ,to_char(RUOLI.RATE)||' rat'||decode(RUOLI.RATE,1,'a','e')||
                                                      ' dal '||to_char(RUOLI.SCADENZA_PRIMA_RATA,'dd/mm/yyyy')
                                                   )
                                            ) des_rata,
                                         max(translate(SOGGETTI.COGNOME_NOME, '/', ' ')) nominativo,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib1, RUOLI_OGGETTO.IMPORTO, null)) imp_trib1,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib2, RUOLI_OGGETTO.IMPORTO, null)) imp_trib2,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib3, RUOLI_OGGETTO.IMPORTO, null)) imp_trib3,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib4, RUOLI_OGGETTO.IMPORTO, null)) imp_trib4,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib5, RUOLI_OGGETTO.IMPORTO, null)) imp_trib5,   
                                         sum(decode(RUOLI_OGGETTO.TRIBUTO, :p_trib6, RUOLI_OGGETTO.IMPORTO, null)) imp_trib6,   
                                         max(decode(RUOLI.TIPO_RUOLO,1, 'RUOLO PRINCIPALE', 'RUOLO SUPPLETIVO')) tipo_ruolo,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.COD_VIA
                                                        ,SOG2.COD_VIA
                                                   )
                                            ) cod_via,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.NUM_CIV
                                                        ,SOG2.NUM_CIV
                                                   )
                                            ) num_civ,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.SUFFISSO
                                                        ,SOG2.SUFFISSO
                                                   )
                                            ) suffisso,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.SCALA
                                                        ,SOG2.SCALA
                                                   )
                                            ) scala,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.PIANO
                                                        ,SOG2.PIANO
                                                   )
                                            ) piano,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,SOGGETTI.INTERNO
                                                        ,SOG2.INTERNO
                                                   )
                                            ) interno,   
                                         max(decode( CONTRIBUENTI.COD_CONTROLLO , NULL, to_char(CONTRIBUENTI.COD_CONTRIBUENTE), CONTRIBUENTI.COD_CONTRIBUENTE||'-'||CONTRIBUENTI.COD_CONTROLLO)) cod_contrib,   
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,decode(SOGGETTI.COD_VIA
                                                               ,NULL,SOGGETTI.DENOMINAZIONE_VIA
                                                                    ,ARVI.DENOM_UFF
                                                               )||
                                                         decode(SOGGETTI.NUM_CIV,NULL,'', ', '||SOGGETTI.NUM_CIV )||
                                                         decode(SOGGETTI.SUFFISSO,NULL,'', '/'||SOGGETTI.SUFFISSO )
                                                        ,decode(SOG2.COD_VIA
                                                               ,NULL,SOG2.DENOMINAZIONE_VIA
                                                                    ,ARV2.DENOM_UFF
                                                               )||
                                                         decode(SOG2.NUM_CIV,NULL,'', ', '||SOG2.NUM_CIV )||
                                                         decode(SOG2.SUFFISSO,NULL,'', '/'||SOG2.SUFFISSO )
                                                   )
                                            )  indirizzo_sog,
                                         max(decode(SOGGETTI.NI_PRESSO
                                                   ,null,COMU.DENOMINAZIONE||decode(PROV.SIGLA
                                                                                       ,null,null
                                                                                            ,' '||PROV.SIGLA
                                                                                       )
                                                        ,COM2.DENOMINAZIONE||decode(PRO2.SIGLA
                                                                                       ,null,null
                                                                                            ,' '||PRO2.SIGLA
                                                                                       )
                                                   )
                                            )  comune_sog,
                                         max(COM3.DENOMINAZIONE||decode(PRO3.SIGLA,null,null,' '||PRO3.SIGLA)
                                            )  comune_nas,
                                         max(SOGGETTI.COGNOME) cognome,    
                                         max(SOGGETTI.NOME) nome,
                                         max(SOGGETTI.DATA_NAS) data_nas,    
                                         max(SOGGETTI.SESSO) sesso,
                                         max(OGGETTI.OGGETTO) oggetto,
                                         max(decode(OGGETTI.COD_VIA
                                                   ,NULL,OGGETTI.INDIRIZZO_LOCALITA
                                                        ,AROG.DENOM_UFF
                                                   )||
                                             decode(OGGETTI.NUM_CIV
                                                   ,null,''
                                                        ,', '||OGGETTI.NUM_CIV
                                                   )||
                                             decode(OGGETTI.SUFFISSO
                                                   ,null,''
                                                        ,'/'||OGGETTI.SUFFISSO
                                                   )
                                            )  indirizzo,
                                         max(OGGETTI_PRATICA.CONSISTENZA) consistenza,
                                         max(PRATICHE_TRIBUTO.ANNO) anno_pratica,
                                         max(decode(PRATICHE_TRIBUTO.TIPO_PRATICA,null,null,
                                                    decode(PRATICHE_TRIBUTO.TIPO_PRATICA,'D','Den. ','I','Inf. ','L','Liq. ',
                                                           'V','Rav. ','A','Acc. ',null
                                                          )||decode(PRATICHE_TRIBUTO.NUMERO,null,null,
                                                                    PRATICHE_TRIBUTO.NUMERO||' '
                                                                   )||decode(PRATICHE_TRIBUTO.DATA,null,null,
                                                                             'del '||to_char(PRATICHE_TRIBUTO.DATA,'dd/mm/yyyy')
                                                                            )
                                                   )
                                            ) estremi_pratica,
                                         max(f_data_decorrenza(PRATICHE_TRIBUTO.tipo_tributo, RUOLI.specie_ruolo, PRATICHE_TRIBUTO.data, PRATICHE_TRIBUTO.data_notifica, 1)) data_dec_int,   
                                         max(f_omesso_tardivo(PRATICHE_TRIBUTO.PRATICA)) tardivo_omesso,   
                                         max(RUOLI_OGGETTO.NOTE) note,
                                         max(nvl(SOGGETTI.STATO,0))    stato_sogg   
                                    FROM SOGGETTI SOGGETTI,   
                                         SOGGETTI SOG2,   
                                         CONTRIBUENTI, 
                                         OGGETTI,   
                                         ARCHIVIO_VIE AROG,   
                                         ARCHIVIO_VIE ARVI,   
                                         ARCHIVIO_VIE ARV2,   
                                         AD4_COMUNI COMU,   
                                         AD4_COMUNI COM2,   
                                         AD4_COMUNI COM3,   
                                         AD4_PROVINCIE PROV,   
                                         AD4_PROVINCIE PRO2,   
                                         AD4_PROVINCIE PRO3,   
                                         OGGETTI_PRATICA,   
                                         PRATICHE_TRIBUTO,    
                                         RUOLI_OGGETTO, 
                                         RUOLI   
                                   WHERE ( SOGGETTI.cod_via = arvi.cod_via (+)) and  
                                         ( sog2.cod_via = arv2.cod_via (+)) and  
                                         ( oggetti.cod_via = arog.cod_via (+)) and  
                                         ( COMU.PROVINCIA_STATO (+) = SOGGETTI.COD_PRO_RES ) and   
                                         ( COMU.COMUNE (+) = SOGGETTI.COD_COM_RES ) and   
                                         ( PROV.PROVINCIA (+) = COMU.PROVINCIA_STATO ) and   
                                         ( COM2.PROVINCIA_STATO (+) = SOG2.COD_PRO_RES ) and   
                                         ( COM2.COMUNE (+) = SOG2.COD_COM_RES ) and   
                                         ( PRO2.PROVINCIA (+) = COM2.PROVINCIA_STATO ) and   
                                         ( COM3.PROVINCIA_STATO (+) = SOGGETTI.COD_PRO_NAS ) and   
                                         ( COM3.COMUNE (+) = SOGGETTI.COD_COM_NAS ) and   
                                         ( PRO3.PROVINCIA (+) = COM3.PROVINCIA_STATO ) and   
                                         ( SOGGETTI.NI = CONTRIBUENTI.NI ) and  
                                         ( SOG2.NI (+) = SOGGETTI.NI_PRESSO ) and
                                         ${ordineDecedutiNonDeceduti}   
                                         ( RUOLI_OGGETTO.OGGETTO  = OGGETTI.OGGETTO (+)) and
                                         ( RUOLI_OGGETTO.OGGETTO_PRATICA = OGGETTI_PRATICA.OGGETTO_PRATICA (+)) and
                                         ( RUOLI_OGGETTO.PRATICA = PRATICHE_TRIBUTO.PRATICA (+)) and
                                         ( RUOLI_OGGETTO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE ) and  
                                         ( RUOLI_OGGETTO.RUOLO = RUOLI.RUOLO ) and  
                                         ( (RUOLI_OGGETTO.RUOLO = :p_ruolo ) )   
                                group by CONTRIBUENTI.COD_FISCALE,   
                                         PRATICHE_TRIBUTO.PRATICA,   
                                         OGGETTI_PRATICA.OGGETTO_PRATICA
                                )
                                    ORDER BY $ordinamento 
                            """

        def results = sessionFactory.currentSession.createSQLQuery(ruolo.specieRuolo == 0 ? querySpecie0 : querySpecie1).with {


            filtri.each { k, v ->
                setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        results.each {
            it.indirizzoSoggCompleto = (it.indirizzoSog ?: "") + " " + (it.comuneSog ?: "")

            if (it.sesso?.trim()) {
                it.infoNascita = (it.sesso == 'F' ? 'Femmina nata a ' : 'Maschio nato a ') + (it.comuneNas ?: '') +
                        ' il ' + it.dataNas?.format("dd/MM/yyyy")
            }

            it.infoNascita = it.infoNascita ?: ''
        }

        return results
    }

    def getTributiMinutaDiRuolo(def numeroRuolo) {

        def tributi = [:]

        Sql sql = new Sql(dataSource)
        sql.call('{call INTESTAZIONE_MINUTA_RUOLO(?,?,?,?,?,?,?)}',
                [
                        numeroRuolo,
                        Sql.VARCHAR,
                        Sql.VARCHAR,
                        Sql.VARCHAR,
                        Sql.VARCHAR,
                        Sql.VARCHAR,
                        Sql.VARCHAR
                ]) { trib1, trib2, trib3, trib4, trib5, trib6 ->
            tributi.trib1 = trib1 ?: ""
            tributi.trib2 = trib2 ?: ""
            tributi.trib3 = trib3 ?: ""
            tributi.trib4 = trib4 ?: ""
            tributi.trib5 = trib5 ?: ""
            tributi.trib6 = trib6 ?: ""
        }

        return tributi
    }

    def getRiepilogoPerCategoria(def ruolo) {


        if (ruolo.ruolo == null || ruolo.annoRuolo == null) {
            return []
        }

        def filtri = [
                "p_ruolo": ruolo.ruolo,
                "p_anno" : ruolo.annoRuolo
        ]

        def querySpecie0 = """
                             SELECT count(*) quantita,   
                                         sum(RUOLI_OGGETTO.IMPORTO) imp,
                                         decode(ruoli.tipo_calcolo,'T',to_number(null),
                                                sum(NVL(ruoli_oggetto.addizionale_eca,0) +
                                                    NVL(ruoli_oggetto.maggiorazione_eca,0) +
                                                    NVL(ruoli_oggetto.addizionale_pro,0) +
                                                    NVL(ruoli_oggetto.iva,0) +
                                                    NVL(ruoli_oggetto.maggiorazione_tares,0))) imp_add,   
                                         sum(RUOLI_OGGETTO.CONSISTENZA) cons,   
                                         TARIFFE.DESCRIZIONE,   
                                         max(RUOLI_OGGETTO.TRIBUTO) trib,  
                                         max(cotr.descrizione) "tribDescr", 
                                         max(RUOLI_OGGETTO.CATEGORIA) cate,   
                                         max(RUOLI_OGGETTO.TIPO_TARIFFA) tari,   
                                         max(:p_ruolo) ruolo,   
                                         CATEGORIE.DESCRIZIONE cate_desc,   
                                         decode(ruoli.tipo_calcolo,'T',max(TARIFFE.TARIFFA),to_number(null)) tariffa,   
                                         sum(OGGETTI_IMPOSTA.IMPORTO_PV) imp_pv,   
                                         sum(OGGETTI_IMPOSTA.IMPORTO_PF) imp_pf,
                                         ruoli.tipo_calcolo  
                                    FROM RUOLI_OGGETTO,   
                                         TARIFFE,   
                                         CATEGORIE,   
                                         OGGETTI_IMPOSTA,
                                         RUOLI,
                                         codici_tributo cotr  
                                   WHERE ( ruoli_oggetto.tributo = tariffe.tributo (+)) and  
                                         ( ruoli_oggetto.categoria = tariffe.categoria (+)) and  
                                         ( ruoli_oggetto.tipo_tariffa = tariffe.tipo_tariffa (+)) and  
                                         ( ruoli_oggetto.tributo = categorie.tributo (+)) and  
                                         ( ruoli_oggetto.categoria = categorie.categoria (+)) and  
                                         ( RUOLI_OGGETTO.OGGETTO_IMPOSTA = OGGETTI_IMPOSTA.OGGETTO_IMPOSTA ) and  
                                         ( RUOLI_OGGETTO.RUOLO = :p_ruolo ) AND  
                                         ( TARIFFE.ANNO (+) = :p_anno ) AND
                                         ( ruoli_oggetto.ruolo = ruoli.ruolo )
                                         and cotr.tipo_tributo = ruoli.tipo_tributo
                                         and cotr.tributo = RUOLI_OGGETTO.TRIBUTO
                                GROUP BY RUOLI_OGGETTO.TRIBUTO,   
                                         RUOLI_OGGETTO.CATEGORIA,   
                                         RUOLI_OGGETTO.TIPO_TARIFFA,   
                                         CATEGORIE.DESCRIZIONE,   
                                         TARIFFE.DESCRIZIONE,
                                         RUOLI.TIPO_CALCOLO   

                           """

        def querySpecie1 = """
                                   SELECT count(*) quantita,   
                                             sum(RUOLI_OGGETTO.IMPORTO) imp,   
                                             sum(NVL(ruoli_oggetto.addizionale_eca,0) +
                                                 NVL(ruoli_oggetto.maggiorazione_eca,0) +
                                                 NVL(ruoli_oggetto.addizionale_pro,0) +
                                                 NVL(ruoli_oggetto.iva,0) +
                                                 NVL(ruoli_oggetto.maggiorazione_tares,0)) imp_add,
                                             sum(RUOLI_OGGETTO.CONSISTENZA) cons,   
                                             TARIFFE.DESCRIZIONE,   
                                             max(RUOLI_OGGETTO.TRIBUTO) trib,   
                                             max(RUOLI_OGGETTO.CATEGORIA) cate,   
                                             max(RUOLI_OGGETTO.TIPO_TARIFFA) tari,   
                                             max(:p_ruolo) ruolo,   
                                             max(:p_anno) anno,
                                             CATEGORIE.DESCRIZIONE,   
                                             max(TARIFFE.TARIFFA) tariffa,   
                                             sum(OGGETTI_IMPOSTA.IMPORTO_PV) imp_pv,   
                                             sum(OGGETTI_IMPOSTA.IMPORTO_PF) imp_pf,
                                             nvl(sum(RUOLI_OGGETTO.IMPORTO_BASE),0) imp_base, 
                                             sum(NVL(ruoli_oggetto.addizionale_eca_base,0) +
                                                 NVL(ruoli_oggetto.maggiorazione_eca_base,0) +
                                                 NVL(ruoli_oggetto.addizionale_pro_base,0) +
                                                 NVL(ruoli_oggetto.iva_base,0)) imp_add_base,  
                                             nvl(sum(OGGETTI_IMPOSTA.IMPORTO_PV_BASE),0) imp_pv_base,   
                                             nvl(sum(OGGETTI_IMPOSTA.IMPORTO_PF_BASE),0) imp_pf_base
                                        FROM RUOLI_OGGETTO,   
                                             TARIFFE,   
                                             CATEGORIE,   
                                             OGGETTI_IMPOSTA  
                                       WHERE ( ruoli_oggetto.tributo = tariffe.tributo (+)) and  
                                             ( ruoli_oggetto.categoria = tariffe.categoria (+)) and  
                                             ( ruoli_oggetto.tipo_tariffa = tariffe.tipo_tariffa (+)) and  
                                             ( ruoli_oggetto.tributo = categorie.tributo (+)) and  
                                             ( ruoli_oggetto.categoria = categorie.categoria (+)) and  
                                             ( RUOLI_OGGETTO.OGGETTO_IMPOSTA = OGGETTI_IMPOSTA.OGGETTO_IMPOSTA ) and  
                                             ( ( RUOLI_OGGETTO.RUOLO = :p_ruolo ) AND  
                                             ( TARIFFE.ANNO (+) = :p_anno ) )   
                                    GROUP BY RUOLI_OGGETTO.TRIBUTO,   
                                             RUOLI_OGGETTO.CATEGORIA,   
                                             RUOLI_OGGETTO.TIPO_TARIFFA,   
                                             CATEGORIE.DESCRIZIONE,   
                                             TARIFFE.DESCRIZIONE   

                           """

        def results = sessionFactory.currentSession.createSQLQuery(ruolo.specieRuolo == 0 ? querySpecie0 : querySpecie1).with {


            filtri.each { k, v ->
                setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

    def getTributiRicercaMinutaCategoria(def tipoTributo) {

        def filtri = [:]

        filtri << ["p_tipoTributo": tipoTributo]

        def query = """
                       select tributo, tributo||' - '||descrizione as descrizione
                        from codici_tributo
                        where tipo_tributo like :p_tipoTributo
                        order by 1
                  """

        return sessionFactory.currentSession.createSQLQuery(query).with {


            filtri.each { k, v ->
                setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

    }

    def getCategoriaRicercaMinutaCategoria(def tipoTributo, def tributo) {

        def filtri = [:]

        filtri << ["p_tipoTributo": tipoTributo]
        filtri << ["p_tributo": tributo]

        def query = """
                       select categorie.categoria, categorie.categoria||' - '||categorie.descrizione as descrizione
                        from categorie,
                        tipi_tributo,
                        codici_tributo
                        where categorie.tributo = codici_tributo.tributo
                        and  tipi_tributo.tipo_tributo = codici_tributo.tipo_tributo
                        and  :p_tributo  in (-1, categorie.tributo )
                        and  tipi_tributo.tipo_tributo like :p_tipoTributo
                        order by 1 asc
                  """

        return sessionFactory.currentSession.createSQLQuery(query).with {


            filtri.each { k, v ->
                setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

    }

    def getMinutaPerCategoria(def ruolo, def parametri) {

        def filtri = [:]

        def filtroDecedutiNonDeceduti = ""
        if (parametri.filtro == "D") {
            filtroDecedutiNonDeceduti = " AND SOGG.STATO = 50 "
        } else if (parametri.filtro == "ND") {
            filtroDecedutiNonDeceduti = " AND SOGG.STATO != 50 "
        }

        def ordinamentoStr = ""
        if (parametri.ordinamento == "A") {
            ordinamentoStr = " COGNOME, NOME, COD_FISCALE, COD_CONTRIB, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (parametri.ordinamento == "CF") {
            ordinamentoStr = " COD_FISCALE, COGNOME, NOME, COD_CONTRIB, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (parametri.ordinamento == "CC") {
            ordinamentoStr = " COD_CONTRIB, COGNOME, NOME, COD_FISCALE, INDIRIZZO_OG, NUM_CIV, SUFFISSO "
        } else if (parametri.ordinamento == "I") {
            ordinamentoStr = " INDIRIZZO_OG, NUM_CIV, SUFFISSO, COGNOME, NOME, COD_FISCALE, COD_CONTRIB "
        } else {
            throw new IllegalArgumentException("Ordinamento ${ordinamento} non riconosciuto")
        }

        filtri << ["p_tributo": parametri.tributo]
        filtri << ["p_categoriaDa": parametri?.categoriaDa ?: 1]
        filtri << ["p_categoriaA": parametri?.categoriaA ?: 999999]
        filtri << ["p_ruolo": ruolo]

        def query = """
            select * from (
                    SELECT CONT.COD_FISCALE,
                             RUOG.ANNO_RUOLO,   
                             RUOL.RATE rate,   
                             RUOL.SCADENZA_PRIMA_RATA scad_pr_rata,   
                             translate(SOGG.COGNOME_NOME, '/', ' ') nominativo,   
                             decode(RUOL.TIPO_RUOLO,1, 'RUOLO PRINCIPALE', 'RUOLO SUPPLETIVO') tipo_ruolo,   
                               RUOG.TRIBUTO,
                             COTR.TRIBUTO||' - '||COTR.DESCRIZIONE_RUOLO COTR_DESCR,
                             RUOG.CATEGORIA,
                             decode(CATE.CATEGORIA,null,'',CATE.CATEGORIA||' - '||CATE.DESCRIZIONE) CATE_DESCR,
                             RUOG.TIPO_TARIFFA,
                             decode(TARI.TIPO_TARIFFA,null,'',TARI.TIPO_TARIFFA||' - '||TARI.DESCRIZIONE) TARI_DESCR,
                             RUOG.CONSISTENZA,
                             OGGE.COD_VIA,   
                             OGGE.NUM_CIV,   
                             OGGE.SUFFISSO,   
                             OGGE.SCALA,   
                             OGGE.PIANO,   
                             OGGE.INTERNO,   
                             DECODE(CONT.COD_CONTRIBUENTE,NULL,NULL,lpad(CONT.COD_CONTRIBUENTE||DECODE(CONT.COD_CONTROLLO,NULL,NULL,'-'
                                ||lpad(CONT.COD_CONTROLLO,2)),11)) cod_contrib,   
                             decode( OGGE.COD_VIA, NULL, OGGE.INDIRIZZO_LOCALITA, ARVI.DENOM_UFF||decode(OGGE.NUM_CIV,NULL,'', ', '
                                ||OGGE.NUM_CIV )||decode(OGGE.SUFFISSO,NULL,'', '/'||OGGE.SUFFISSO ))  indirizzo_og,
                             SOGG.COGNOME,    
                             SOGG.NOME,
                             OGGE.OGGETTO,
                             NVL(RUOG.IMPORTO, 0) IMPORTO,
                             decode( OGGE.COD_VIA, NULL, OGGE.INDIRIZZO_LOCALITA, ARVI.DENOM_UFF)  indirizzo,
                             nvl(SOGG.STATO,0)    stato_sogg,
                             OGCO.FLAG_AB_PRINCIPALE,
                             F_GET_NUM_FAM_COSU(ogpr.oggetto_pratica, ogco.flag_ab_principale, ruog.anno_ruolo, ogim.oggetto_imposta) NUMERO_FAMILIARI,
                             NVL(OGIM.IMPORTO_PV, 0) IMPORTO_PV,
                             NVL(OGIM.IMPORTO_PF, 0) IMPORTO_PF
                        FROM TARIFFE TARI,
                             CATEGORIE CATE,
                             CODICI_TRIBUTO COTR,
                             SOGGETTI SOGG,   
                             CONTRIBUENTI CONT, 
                             OGGETTI OGGE,   
                             ARCHIVIO_VIE ARVI,   
                             RUOLI_OGGETTO RUOG, 
                             RUOLI RUOL,
                             OGGETTI_CONTRIBUENTE OGCO,
                             OGGETTI_IMPOSTA OGIM,
                             oggetti_pratica ogpr
                       WHERE TARI.TIPO_TARIFFA   (+) = RUOG.TIPO_TARIFFA
                         and TARI.CATEGORIA      (+) = RUOG.CATEGORIA
                         and TARI.TRIBUTO      (+) = RUOG.TRIBUTO
                         and TARI.ANNO         (+) = RUOG.ANNO_RUOLO
                         and CATE.CATEGORIA      (+) = RUOG.CATEGORIA
                         and CATE.TRIBUTO      (+) = RUOG.TRIBUTO
                         and COTR.TRIBUTO      (+) = RUOG.TRIBUTO
                         and OGGE.cod_via = ARVI.cod_via (+)  
                         and SOGG.NI = CONT.NI  
                         and RUOG.OGGETTO = OGGE.OGGETTO
                         and RUOG.COD_FISCALE = CONT.COD_FISCALE  
                         and RUOG.RUOLO = RUOL.RUOLO  
                         and ogim.oggetto_imposta = ruog.oggetto_imposta 
                         and ogco.oggetto_pratica = ogim.oggetto_pratica 
                         and ogco.cod_fiscale = CONT.cod_fiscale 
                         and ogpr.oggetto_pratica = ogim.oggetto_pratica
                         ${filtroDecedutiNonDeceduti} 
                         AND RUOG.TRIBUTO = :p_tributo
                         AND RUOG.RUOLO = :p_ruolo
                         AND nvl(RUOG.CATEGORIA, 0) between :p_categoriaDa and :p_categoriaA
                         ) order by $ordinamentoStr
                    """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {


            filtri.each { k, v ->
                setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }


        return result

    }
}

