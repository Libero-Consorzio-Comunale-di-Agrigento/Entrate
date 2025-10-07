package it.finmatica.tr4.bonificaDati.versamenti

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.AnciVer
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.WrkVersamenti
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.criterion.CriteriaSpecification

import java.sql.Date

@Transactional
class BonificaVersamentiService {

    private final static def ID_OPERAZIONE_DA_VERSAMENTO_ANOMALO_LENGTH = 18

    def dataSource
    def sessionFactory
    CommonService commonService

    def getAnomalie(def incasso, def tipoAnomalia, def anno, def tipoTributo, def idDoc) {
        int rowNum = 0
        if (incasso == 'ANCI') {
            return AnciVer.createCriteria().list() {

                projections {
                    count('progrRecord') //0
                    sum('importoVersato') //1
                    max('importoVersato') //2

                    groupProperty('tipoAnomalia') //3
                    groupProperty('annoFiscale') // 4

                    order('annoFiscale')
                }


                if (tipoAnomalia) {
                    eq('tipoAnomalia', (byte) tipoAnomalia.tipoAnomalia)
                }

                if (anno) {
                    eq('annoFiscale', anno)
                }
            }.collect { row ->
                [
                        numVersamenti: row[0],
                        totaleVersato: row[1] / 100,
                        maxVersamento: row[2] / 100,
                        tipoAnomalia : row[3],
                        anomaliaDesc : row[3] + ' - ' + TipoAnomalia.findByTipoAnomalia(row[3]).descrizione,
                        anno         : row[4],
                        visible      : true,
                        selected     : false,
                        rowNum       : rowNum++
                ]
            }
        } else {
            // Se non sono selezionati causali si retituisce una lista vuota
            if (tipoAnomalia.isEmpty()) {
                return []
            }

            return WrkVersamenti.createCriteria().list() {
                projections {
                    count('id') // 0
                    sum('importoVersato') //1
                    max('importoVersato') //2

                    groupProperty('causale') //3
                    groupProperty('tipoTributo') //4
                    groupProperty('anno') //5

                    order('anno')
                    order('tipoTributo.tipoTributo')
                    order('causale.causale')
                }

                if (tipoTributo) {
                    eq('tipoTributo.tipoTributo', tipoTributo)
                }

                if (tipoAnomalia) {
                    'in'('causale', tipoAnomalia)
                }

                if (anno) {
                    eq('anno', anno)
                }

                if (idDoc) {
                    eq('documentoId', idDoc)
                }
            }.collect { row ->
                [
                        numVersamenti : row[0],
                        totaleVersato : row[1],
                        maxVersamento : row[2],
                        tipoAnomalia  : row[3],
                        anomaliaDesc  : row[3].causale + ' - ' + row[3].descrizione,
                        anno          : row[5],
                        visible       : true,
                        selected      : false,
                        tributoAttuale: row[4].getTipoTributoAttuale(row[5]),
                        rowNum        : rowNum++,
                        tipoTributo   : row[4].tipoTributo
                ]

            }
        }
    }

    def getDettagliAnomalie(def incasso, def tipoAnomAnno, def params = [:], def filtri, def sortBy) {

        int rowNum = 0

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        def dettagli
        def listaDettagli

        if (incasso == 'ANCI') {
            dettagli = AnciVer.createCriteria().list(params) {

                createAlias("contribuente", "cont",
                        (filtri?.soloSoggetti) ? CriteriaSpecification.INNER_JOIN : CriteriaSpecification.LEFT_JOIN)

                projections {
                    property('tipoAnomalia') // 0
                    property('codFiscale')// 1
                    property('dataVersamento', 'dataPagamento')// 2
                    property('importoVersato')// 3
                    property('flagRavvedimento')// 4
                    property('annoFiscale', 'anno')// 5
                    property('progrRecord') // 6
                    property('flagOk') // 7
                    property('flagContribuente') // 8
                    property('sanzioneRavvedimento') // 9
                    property('cont.soggetto.id') // 10
                }
                eq('tipoAnomalia', tipoAnomAnno.tipoAnomalia)
                eq('annoFiscale', tipoAnomAnno.anno)

                if (filtri.codiceFiscale) {
                    ilike('codFiscale', filtri.codiceFiscale)
                }
                if (filtri.importoVersatoDa) {
                    gte('importoVersato', filtri.importVersatoDa)
                }
                if (filtri.importoVersatoA) {
                    lte('importoVersato', filtri.importVersatoA)
                }
                if (filtri.dataPagamentoDa) {
                    gte('dataVersamento', filtri.dataPagamentoDa)
                }
                if (filtri.dataPagamentoA) {
                    lte('dataVersamento', filtri.dataPagamentoA)
                }
                if (filtri.annoDa) {
                    gte('annoFiscale', filtri.annoDa as Short)
                }
                if (filtri.annoA) {
                    lte('annoFiscale', filtri.annoA as Short)
                }

                if (sortBy) {
                    order(sortBy.property, sortBy.direction)
                } else {
                    order('codFiscale')
                    order('importoVersato')
                    order('dataVersamento')
                }
            }

            listaDettagli = dettagli.collect { row ->

                def sogg = Soggetto.findByCodFiscaleOrId(row[1], row[10]) ?: Soggetto.findByPartitaIvaOrId(row[1], row[10])

                [
                        rowNum              : rowNum++,
                        tipoAnomalia        : row[0],
                        codFiscale          : row[1],
                        cognomeNome         : '', // Per compatibilità con F24 dove è definito
                        dataPagamento       : row[2],
                        importoVersato      : row[3] / 100,
                        flagRavvedimento    : row[4],
                        codFiscaleSogg      : sogg?.codFiscale ?: sogg?.partitaIva,
                        cognomeNomeSogg     : sogg?.cognomeNome?.replace('/', ' '),
                        anno                : row[5],
                        annoOrig            : row[5],
                        id                  : [annoFiscale: row[5],
                                               progrRecord: row[6]],
                        flagOk              : row[7] == 'S',
                        flagCont            : row[8] == 'S',
                        sanzioneRavvedimento: row[9],
                        progressivo         : row[6],
                        tipoTributo         : null
                ]
            }
        } else {
            dettagli = WrkVersamenti.createCriteria().list(params) {

                createAlias("contribuente", "cont", CriteriaSpecification.LEFT_JOIN)

                if (filtri?.soloSoggetti) {
                    sqlRestriction("exists (select 1 from soggetti sogg where {alias}.cod_fiscale = nvl(sogg.cod_fiscale, sogg.partita_iva))")
                }

                projections {
                    property('causale', 'tipoAnomalia') // 0
                    property('codFiscale')// 1
                    property('dataPagamento')// 2
                    property('importoVersato')// 3
                    property('sanzioneRavvedimento')// 4
                    property('cognomeNome')// 5
                    property('anno')// 6
                    property('tipoTributo') //7
                    property('id') // 8
                    property('flagOk') // 9
                    property('flagContribuente') // 10
                    property('cont.soggetto.id') // 11
                }

                if (!tipoAnomAnno.isEmpty()) {
                    or {
                        tipoAnomAnno.each { ta ->
                            and {
                                eq('anno', ta.anno)
                                'in'('causale', [ta.tipoAnomalia])
                            }
                        }
                    }
                }

                if (filtri.tipiTributo) {
                    'in'('tipoTributo.tipoTributo', filtri.tipiTributo)
                }

                if (filtri.cognomeNome) {
                    ilike('cognomeNome', filtri.cognomeNome)
                }
                if (filtri.codiceFiscale) {
                    ilike('codFiscale', filtri.codiceFiscale)
                }
                if (filtri.importoVersatoDa) {
                    gte('importoVersato', filtri.importoVersatoDa)
                }
                if (filtri.importoVersatoA) {
                    lte('importoVersato', filtri.importoVersatoA)
                }
                if (filtri.dataPagamentoDa) {
                    gte('dataPagamento', filtri.dataPagamentoDa)
                }
                if (filtri.dataPagamentoA) {
                    lte('dataPagamento', filtri.dataPagamentoA)
                }
                if (filtri.dataRegistrazioneDa) {
                    lte('dataReg', filtri.dataRegistrazioneDa)
                }
                if (filtri.dataRegistrazioneA) {
                    lte('dataReg', filtri.dataRegistrazioneA)
                }
                if (filtri.annoDa) {
                    gte('anno', filtri.annoDa as Short)
                }
                if (filtri.annoA) {
                    lte('anno', filtri.annoA as Short)
                }
                if (filtri.ruolo) {
                    eq('ruolo', filtri.ruolo as Long)
                }
                if (filtri.tipoVersamento != null) {
                    eq('tipoVersamento', filtri.tipoVersamento)
                }
                if (filtri.documentoId != null && !(filtri.documentoId instanceof String)) {
                    eq('documentoId', filtri.documentoId as Long)
                }

                if (sortBy) {
                    order(sortBy.property, sortBy.direction)
                    order('progressivo', 'Asc')
                } else {
                    order('anno')
                    order('tipoTributo')
                    order('causale')
                    order('cognomeNome')
                    order('codFiscale')
                    order('importoVersato')
                    order('dataPagamento')
                }
            }

            listaDettagli = dettagli.collect { row ->

                def sogg = Soggetto.findByCodFiscaleOrId(row[1], row[11]) ?: Soggetto.findByPartitaIvaOrId(row[1], row[11])
                def causale = row[0]

                [
                        rowNum              : rowNum++,
                        tipoAnomalia        : causale?.causale,
                        codFiscale          : row[1],
                        cognomeNome         : row[5]?.replace('/', ' '),
                        dataPagamento       : row[2],
                        importoVersato      : row[3],
                        flagRavvedimento    : causale?.causale in ['50100', '50109', '50150', '50180', '50190'],
                        codFiscaleSogg      : sogg?.codFiscale ?: sogg?.partitaIva,
                        cognomeNomeSogg     : sogg?.cognomeNome?.replace('/', ' '),
                        anno                : row[6],
                        annoOrig            : row[6],
                        tributoAttuale      : row[7].toDTO().getTipoTributoAttuale(row[6]),
                        id                  : row[8],
                        flagOk              : row[9] == 'S',
                        tipoTributo         : row[7].tipoTributo,
                        flagCont            : row[10] == 'S',
                        sanzioneRavvedimento: row[4],
                        progressivo         : row[8],
                        descrizioneAnomalia : causale?.descrizione,
                ]
            }
        }

        return [
                record      : listaDettagli,
                numeroRecord: dettagli.totalCount
        ]
    }

    def getWrkVersamenti(def filtri, def tipoAnomAnno, def sortBy) {
        WrkVersamenti.createCriteria().list() {

            if (!tipoAnomAnno.isEmpty()) {
                or {
                    tipoAnomAnno.each { ta ->
                        and {
                            eq('anno', ta.anno)
                            'in'('causale', [ta.tipoAnomalia])
                        }
                    }
                }
            }

            // Codice fiscale
            if (filtri.codiceFiscale) {
                ilike('codFiscale', filtri.codiceFiscale)
            }
            // Importo Da
            if (filtri.importoVersatoDa) {
                gte('importoVersato', filtri.importoVersatoDa)
            }
            // Importo Da
            if (filtri.importoVersatoA) {
                lte('importoVersato', filtri.importoVersatoA)
            }
            // Importo Da
            if (filtri.dataPagamentoDa) {
                gte('dataPagamento', filtri.dataPagamentoDa)
            }
            // Importo Da
            if (filtri.dataPagamentoA) {
                lte('dataPagamento', filtri.dataPagamentoA)
            }
            // Tipi Tributo
            if (filtri.tipiTributo) {
                'in'('tipoTributo.tipoTributo', filtri.tipiTributo)
            }

            if (sortBy) {
                order(sortBy.property, sortBy.direction)
            } else {
                order('anno')
                order('tipoTributo')
                order('causale')
                order('cognomeNome')
                order('codFiscale')
                order('importoVersato')
                order('dataPagamento')
            }
        }
    }

    def getPratica(def codFiscale, def identificativoOperazione, def dataPagamento, def tipoTributo) {
        def pratica = null

        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_f24_pratica(?,?, ?, ?)}', [Sql.INTEGER,
                                                         codFiscale,
                                                         identificativoOperazione,
                                                         dataPagamento,
                                                         tipoTributo]) {
            idPratica ->
                pratica = PraticaTributo.findById(idPratica)
        }

        return pratica
    }

    def getPratiche(def filtri, int pageSize, int activePage, def sortBy = null) {

        int rowNum = 0

        def params = [:]
        params.max = pageSize
        params.offset = activePage * params.max

        def lista = PraticaTributo.createCriteria().list(params) {

            createAlias("rate", "rate", CriteriaSpecification.LEFT_JOIN)

            projections {
                groupProperty('tipoTributo') // 0
                groupProperty('anno') // 1
                groupProperty('tipoPratica') // 2
                groupProperty('tipoEvento') // 3
                groupProperty('data') // 4
                groupProperty('numero') // 5
                groupProperty('tipoStato') // 6
                groupProperty('tipoAtto') // 7
                groupProperty('dataNotifica') // 8
                groupProperty('id') // 9
                max("rate.rata")
            }

            eq('contribuente.codFiscale', filtri.codFiscale)
            isNotNull('numero')
            'in'('tipoPratica', ['A', 'L'])
            isNull('praticaTributoRif')

            if (!sortBy) {
                order("tipoTributo.tipoTributo", "asc")
                order("tipoPratica", "asc")
                order("anno", "desc")
                order("data", "desc")
            } else {
                order(sortBy.property, sortBy.direction)
            }
        }

        def elencoPratiche = lista.collect { row ->
            [
                    tipoTributo : row[0]?.toDTO(),
                    anno        : row[1],
                    tipoPratica : row[2],
                    tipoEvento  : row[3],
                    data        : row[4],
                    numero      : row[5],
                    tipoStato   : row[6]?.toDTO(),
                    tipoAtto    : row[7]?.toDTO(),
                    dataNotifica: row[8],
                    pratica     : row[9],
                    maxRata     : row[10],
                    rowNum      : rowNum++

            ]
        }

        return [
                record      : elencoPratiche,
                numeroRecord: lista.totalCount
        ]
    }

    def getPraticheRavv(def filtri, int pageSize, int activePage, def sortBy = null) {

        int rowNum = 0

        def params = [:]
        params.max = pageSize
        params.offset = activePage * params.max

        def lista = PraticaTributo.createCriteria().list(params) {
            projections {
                property('tipoTributo') // 0
                property('anno') // 1
                property('data') // 2
                property('numero') // 3
                property('tipoStato') // 4
                property('id') // 5
            }

            eq('contribuente.codFiscale', filtri.codFiscale)
            eq('tipoPratica', 'V')

            if (!sortBy) {
                order("tipoTributo.tipoTributo", "asc")
                order("anno", "desc")
                order("data", "desc")
            } else {
                order(sortBy.property, sortBy.direction)
            }
        }

        def elencoPratiche = lista.collect { row ->
            [
                    tipoTributo: row[0]?.toDTO(),
                    anno       : row[1],
                    data       : row[2],
                    numero     : row[3],
                    tipoStato  : row[4]?.toDTO(),
                    pratica    : row[5],
                    rowNum     : rowNum++

            ]
        }

        return [
                record      : elencoPratiche,
                numeroRecord: lista.totalCount
        ]
    }

    def generaIdentificativoOperazione(def pratica) {
        String identificativoOperazione = ""

        switch (pratica.tipoPratica) {
            case 'L':
                identificativoOperazione += 'LIQ'
                break
            case 'A':
                identificativoOperazione += 'ACC'
                break
            case 'V':
                identificativoOperazione += 'RAV'
                break
            default:
                throw new IllegalArgumentException("""Tipo pratica '${pratica.tipoPratica}' non supportato.""")
        }

        switch (pratica.tipoEvento.id) {
            case 'T':
            case 'A':
                identificativoOperazione += pratica.tipoEvento.id
                break
            default:
                identificativoOperazione += 'P'
        }

        identificativoOperazione += pratica.anno
        identificativoOperazione += (pratica.id + '').padLeft(10, '0')

        return identificativoOperazione
    }

    def cambiaStato(def incasso, def anom) {
        anom.flagOk = !anom.flagOk

        def vers

        if (incasso == 'ANCI') {
            vers = AnciVer.findByProgrRecordAndAnnoFiscale(anom.id.progrRecord, anom.id.annoFiscale)
        } else {
            vers = WrkVersamenti.get(anom.id)
        }

        vers.flagOk = anom.flagOk ? 'S' : null
        vers.save(flush: true, failOnError: true)

    }

    def numeraPratiche(def tipoTributo, def tipoPratica,
                       def ni, def codFiscale,
                       def daAnno, def adAnno,
                       def daData, def aData) {
        Sql sql = new Sql(dataSource)
        sql.call('{call numera_pratiche(?, ?, ?, ?, ?, ?, ?, ?)}'
                , [
                tipoTributo, tipoPratica,
                ni, codFiscale,
                daAnno, adAnno,
                daData, aData
        ])
    }

    def caricaArchivi(def incasso, def tipoTributo = null, String codFiscale = null) {

        Sql sql = new Sql(dataSource)

        if (incasso == 'ANCI') {
            sql.call('{call carica_versamenti_ici(?)}'
                    , [null])
        } else {

            try {

                if (tipoTributo in ['TRASV', 'ICIAP']) {
                    return "Nessuna procedura di caricamento prevista per (tipoTributo, incasso) = (${tipoTributo}, ${incasso})".toString()
                }

                if (tipoTributo == 'TARSU') {
                    tipoTributo = 'TARES'
                } else if (tipoTributo in ['CUNI', 'ICP', 'TOSAP']) {
                    tipoTributo = 'TRMI'
                }

                sql.call("""{call carica_versamenti_${tipoTributo}_f24(?, ?, ?)}"""
                        , [null, codFiscale, Sql.VARCHAR])
            } catch (Exception e) {
                e.printStackTrace()
                if (e.message.indexOf('ORA-20999:') > 0) {
                    return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                } else {
                    return e.message
                }

            }
        }

        return ''

    }

    def aggiornaVersamentoCheck(def versamento) {

        try {

            if (!versamento.anno) {
                throw new RuntimeException("ORA-20999: Indicare l'anno.\n")
            }

            checkCodiceIdentificativo(versamento.identificativoOperazione)

            Sql sql = new Sql(dataSource)
            sql.call('{call WRK_VERSAMENTI_DI (?, ?, ?, ?, ?)}'
                    , [
                    versamento.dataPagamento ? new Date(versamento.dataPagamento.time) : null,
                    versamento.importoVersato,
                    versamento.identificativoOperazione?.size() == ID_OPERAZIONE_DA_VERSAMENTO_ANOMALO_LENGTH ?
                            versamento.identificativoOperazione?.substring(10, 18)?.toLong() : null,
                    versamento.rata,
                    versamento.tipoVersamento
            ])

        } catch (Exception e) {
            commonService.serviceException(e)
        }

    }

    def checkCodiceIdentificativo(String codiceIdentificativo) {

        if (codiceIdentificativo == null ||
                codiceIdentificativo.isEmpty()) {
            return
        }

        if (codiceIdentificativo.length() < 18 ||
                !codiceIdentificativo.substring(8, 18).isNumber()) {
            throw new RuntimeException("ORA-20999: Codice identificativo: Formato non valido.\n")
        }

    }

    def aggiornaVersamento(def versamento) {

        def soggetto = Soggetto.findByCodFiscale(versamento.codFiscale)
        def contribuente = Contribuente.findByCodFiscale(versamento.codFiscale) ?:
                Contribuente.findBySoggetto(soggetto) ?: new Contribuente([
                        codFiscale: versamento.codFiscale, soggetto: soggetto
                ])

        if (contribuente && soggetto) {
            versamento.contribuente = contribuente
        }

        if (!(versamento instanceof AnciVer)) {
            sessionFactory.currentSession.createSQLQuery("UPDATE WRK_VERSAMENTI WRVE SET WRVE.COD_FISCALE = ? WHERE WRVE.PROGRESSIVO = ?")
                    .setString(0, versamento.codFiscale)
                    .setInteger(1, versamento.progressivo as Integer)
                    .executeUpdate()
        }

        versamento.save(flush: true, failOnError: true)

        // AnnoFiscale è in chiave Hibernate non lo sa modificare, si deve procedere manualmente.
        if (versamento instanceof AnciVer && versamento.annoFiscaleModificato) {
            AnciVer.executeUpdate("""update AnciVer 
                                                set annoFiscale = ${versamento.annoFiscaleModificato}
                                                where annoFiscale =  ${versamento.annoFiscale}
                                                   and progrRecord = ${versamento.progrRecord}
                                                """)
        }

    }

    def aggiornaDataNotifica(def prtr) {
        prtr.save(flush: true, failOnError: true)
    }

    def aggiornaDataNotificaCheck(def prtr) {
        try {

            Sql sql = new Sql(dataSource)
            sql.call('{call PRATICHE_TRIBUTO_DI(?, ?, ?, ?, ?, ?, ?)}'
                    , [
                    prtr.id,
                    prtr.tipoPratica,
                    prtr.data?.time ? new Date(prtr.data.time) : null,
                    prtr.dataNotifica?.time ? new Date(prtr.dataNotifica?.time) : null,
                    'N', '', 'WEB'
            ])

            return ''

        } catch (Exception e) {

            e.printStackTrace()
            return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
        }
    }

    def eliminaVersamento(def tipoIncasso, def versamento) {
        if (tipoIncasso == 'ANCI') {
            versamento = AnciVer.findByAnnoFiscaleAndProgrRecord(versamento.id.annoFiscale, versamento.id.progrRecord)
        } else {
            versamento = WrkVersamenti.findByProgressivo(new BigDecimal(versamento.id))
        }

        versamento.delete(failOnError: true, flush: true)
    }

    def versamentiToXlsx(def filtriDettaglio, def tipoAnomAnom, def sortDettagliBy = null) {

        def versamenti = []
        def campi = [:]
        def primaRiga = true

        getWrkVersamenti(filtriDettaglio, tipoAnomAnom, sortDettagliBy).toDTO(['causale']).each {

            def versamento = [:]
            it.properties.each {

                if (primaRiga && !(it.key in ['class', 'domainObject'])) {

                    if (it.key == 'lastUpdated') {
                        campi << [dataVariazione: 'dataVariazione']
                    } else {
                        campi << [(it.key): it.key]
                    }
                }

                switch (it.key) {
                    case ['class', 'domainObject']:
                        break
                    case 'contribuente':
                        versamento[it.key] = it.value?.codFiscale
                        break
                    case 'causale':
                        versamento[it.key] = it.value.descrizione
                        break
                    case 'tipoTributo':
                        versamento[it.key] = it.value.tipoTributoAttuale
                        break
                    case 'lastUpdated':
                        versamento['dataVariazione'] = it.value
                        break
                    default:
                        versamento[it.key] = it.value
                }
            }
            primaRiga = false
            versamenti << versamento
        }

        campi.sort()

        return [versamenti: versamenti, campi: campi]
    }

    boolean verificaIdOperazione(String idOperazione) {
        return (ID_OPERAZIONE_DA_VERSAMENTO_ANOMALO_LENGTH == idOperazione?.size()
                && idOperazione[4..7].isNumber()
                && idOperazione[8..9].isNumber()
                && idOperazione[10..17].isNumber())
    }

    def verificaDatiIdOperazione(def idOperazione, def anno, def rata) {

        if (!idOperazione?.trim()) {
            return ""
        }

        if (!((idOperazione?.size() ?: 0) in [0, ID_OPERAZIONE_DA_VERSAMENTO_ANOMALO_LENGTH]
                && idOperazione[4..7].isNumber()
                && idOperazione[8..9].isNumber()
                && idOperazione[10..17].isNumber())) {
            return "Formato Id. Operazione non valido"
        }

        if (!(idOperazione[0..2] in ['LIQ', 'ACC', 'RAV'])) {
            return "Tipo pratica ${idOperazione[0..2]} non supportato"
        }

        def rataIdOp = idOperazione[8..9].toInteger()
        if (rataIdOp != 0 && (rataIdOp != (rata ?: 0))) {
            return "Rata ${rataIdOp} non corrisponde alla rata ${rata ?: ''} della pratica"
        }

        def annoIdOp = idOperazione[4..7].toInteger()
        if (annoIdOp != 0 && (annoIdOp != (anno ?: 0))) {
            return "Anno ${annoIdOp} non corrisponde all'anno ${anno ?: ''} della pratica"
        }

        return ""
    }
}
