package it.finmatica.tr4.bonificaDati

import grails.transaction.Transactional
import it.finmatica.tr4.ArchivioVie
import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.anomalie.AnomaliaParametro
import it.finmatica.tr4.anomalie.AnomaliaPratica
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.Query
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer

@Transactional
class GestioneAnomalieService {

    private static Log log = LogFactory.getLog(GestioneAnomalieService)

    def sessionFactory

    String sqlCatastoFab = """
            SELECT DISTINCT TO_NUMBER(FAB.CONTATORE) AS IDFABBRICATO,
                            TO_NUMBER(FAB.CONTATORE) AS IDIMMOBILE,
                            FAB.INDIRIZZO AS INDIRIZZO,
                            FAB.INDIRIZZO ||
                            DECODE(FAB.NUM_CIV,
                                   NULL,
                                   '',
                                   ', ' || REPLACE(LTRIM(REPLACE(FAB.NUM_CIV, '0', ' ')),
                                                   ' ',
                                                   '0')) ||
                            DECODE(FAB.SCALA,
                                   NULL,
                                   '',
                                   ' Sc:' ||
                                   REPLACE(LTRIM(REPLACE(FAB.SCALA, '0', ' ')), ' ', '0')) ||
                            DECODE(FAB.PIANO,
                                   NULL,
                                   '',
                                   ' P:' ||
                                   REPLACE(LTRIM(REPLACE(FAB.PIANO, '0', ' ')), ' ', '0')) ||
                            DECODE(FAB.INTERNO,
                                   NULL,
                                   '',
                                   ' In:' || REPLACE(LTRIM(REPLACE(FAB.INTERNO, '0', ' ')),
                                                     ' ',
                                                     '0')) AS INDIRIZZOCOMPLETO,
                            FAB.NUM_CIV AS CIVICO,
                            FAB.SCALA AS SCALA,
                            FAB.INTERNO AS INTERNO,
                            FAB.PIANO AS PIANO,
                            FAB.CATEGORIA AS CATEGORIACATASTO,
                            FAB.CLASSE AS CLASSECATASTO,
                            FAB.SEZIONE AS SEZIONE,
                            FAB.FOGLIO AS FOGLIO,
                            FAB.NUMERO AS NUMERO,
                            FAB.SUBALTERNO AS SUBALTERNO,
                            FAB.ZONA AS ZONA,
                            FAB.PARTITA AS PARTITA,
                            TO_NUMBER(FAB.CONSISTENZA) AS CONSISTENZA,
                            TO_NUMBER(FAB.RENDITA_EURO) AS RENDITA,
                            TO_NUMBER(FAB.SUPERFICIE) AS SUPERFICIE,
                            FAB.NOTE AS ANNOTAZIONE,
                            FAB.DATA_EFFICACIA AS DATAEFFICACIAINIZIO,
                            LPAD(NVL(FAB.NUM_CIV, '0'), 6, '0') AS CIVICOSORT,
                            LPAD(NVL(FAB.SEZIONE, ' '), 3, ' ') ||
                            LPAD(NVL(FAB.FOGLIO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.NUMERO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.SUBALTERNO, ' '), 4, ' ') ||
                            LPAD(NVL(FAB.ZONA, ' '), 3, '') AS ESTREMICATASTALISORT,
                            'F' AS TIPOOGGETTO
              FROM IMMOBILI_CATASTO_URBANO FAB
             WHERE 1 = 1
						"""


    String sqlCatastoTer = """
                    select distinct to_number(fab.id_immobile) as idimmobile,
                        to_number(fab.id_immobile) as idFabbricato,
                        fab.indirizzo as indirizzo,
                        fab.indirizzo ||
                        decode(fab.num_civ,
                               null,
                               '',
                               ', ' || replace(ltrim(replace(fab.num_civ, '0', ' ')),
                                               ' ',
                                               '0')) as indirizzocompleto,
                        fab.num_civ as civico,
                        null as scala,
                        null as interno,
                        null as piano,
                        null as categoriacatasto,
                        fab.classe as classecatasto,
                        fab.sezione as sezione,
                        fab.foglio as foglio,
                        fab.numero as numero,
                        fab.subalterno as subalterno,
                        '' as zona,
                        fab.partita as partita,
                        0 as consistenza,
                        0 as rendita,
                        to_number(fab.reddito_dominicale_euro) as redditodominicale,
                        to_number(fab.reddito_agrario_euro) as redditoagrario,
                        0 as superficie,
                        '' as annotazione,
                        fab.data_efficacia as dataefficaciainizio,
                        lpad(nvl(fab.num_civ, '0'), 6, '0') as civicosort,
                        lpad(nvl(fab.sezione, ' '), 3, ' ') ||
                        lpad(nvl(fab.foglio, ' '), 5, ' ') ||
                        lpad(nvl(fab.numero, ' '), 5, ' ') ||
                        lpad(nvl(fab.subalterno, ' '), 4, ' ') || '' as estremicatastalisort,
                        'T' as tipooggetto
          from immobili_catasto_terreni fab
         where 1 = 1
						"""

    ControlloAnomalieService controlloAnomalieService

    def getOggettiDaAchivio(def indirizzo, Integer numCiv, String categoria) {

        if (indirizzo == null && numCiv == null) {
            return [lista: [], filtro: new FiltroRicercaOggetto()]
        }

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto();

        def elenco = Oggetto.createCriteria().list() {
            createAlias("archivioVie", "via", CriteriaSpecification.INNER_JOIN)
            if (indirizzo instanceof String) {
                createAlias("via.denominazioniVia", "denom", CriteriaSpecification.INNER_JOIN)
            }
            createAlias("tipoOggetto", "tipoOggetto", CriteriaSpecification.INNER_JOIN)
            projections {
                groupProperty("id")                                    // 0
                groupProperty("tipoOggetto.tipoOggetto")                // 1
                groupProperty("indirizzoLocalita")                        // 2
                groupProperty("via.denomUff")                            // 3
                groupProperty("numCiv")                                    // 4
                groupProperty("categoriaCatasto.categoriaCatasto")        // 5
                groupProperty("sezione")                                // 6
                groupProperty("foglio")                                    // 7
                groupProperty("numero")                                    // 8
                groupProperty("subalterno")                                // 9
                groupProperty("partita")                                // 10
                groupProperty("zona")                                    // 11
                groupProperty("protocolloCatasto")                        // 12
                groupProperty("annoCatasto")                            // 13
                groupProperty("classeCatasto")                            // 14
                groupProperty("suffisso")                                // 15
                groupProperty("scala")                                    // 16
                groupProperty("piano")                                    // 17
                groupProperty("interno")                                // 18
            }
            if (indirizzo instanceof String) {
                fro.indirizzo = indirizzo
                sqlRestriction(" lower('" + indirizzo + "') like lower('%'||denom2_.descrizione||'%')")
            } else {
                def nomeIndirizzo = ArchivioVie.get(indirizzo)?.denomUff
                if (nomeIndirizzo) {
                    fro.indirizzo = nomeIndirizzo
                    eq("via.id", indirizzo)
                }
            }

            if (numCiv) {
                fro.numCiv = numCiv
                eq("numCiv", numCiv)
            }
            if (categoria) {
                fro.categoriaCatasto = CategoriaCatasto.get(categoria).toDTO()
                eq("categoriaCatasto.categoriaCatasto", categoria)
            }
            isNotNull("foglio")
            isNotNull("numero")
            isNotNull("subalterno")
        }.collect() { row ->
            [
                    idOggetto              : row[0]
                    , tipoOggetto          : row[1]
                    , indirizzoLocalita    : row[2]
                    , indirizzoDenomUff    : row[3]
                    , numCiv               : row[4]
                    , categoriaCatasto     : row[5]
                    , sezione              : row[6]
                    , foglio               : row[7]
                    , numero               : row[8]
                    , subalterno           : row[9]
                    , partita              : row[10]
                    , zona                 : row[11]
                    , protocolloCatasto    : row[12]
                    , annoCatasto          : row[13]
                    , classeCatasto        : row[14]
                    , indirizzoCompleto    : (row[3] != null ? row[3] : (row[2] != null ? row[2] : '')) +
                    (row[4] != null ? ", " + row[4] : "") +    // Numero civico
                    (row[15] != null ? "/" + row[15] : "") +    // Suffisso
                    (row[16] != null ? " Sc:" + row[16] : "") +    // Scala
                    (row[17] != null ? " P:" + row[17] : "") +    // Piano
                    (row[18] != null ? " In:" + row[18] : "")    // Interno
                    , indirizzoCompletoSort: (row[3] != null ? row[3] : row[2]) + (row[4] != null ? ", " + (row[4] + "").padLeft(6, '0') : "0".padLeft(6, '0'))
                    , estremiCatastoSort   : (row[6] != null ? row[6].padLeft(3, '0') : " ".padLeft(3, '0')) +
                    (row[7] != null ? row[7].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[8] != null ? row[8].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[9] != null ? row[9].padLeft(4, '0') : " ".padLeft(4, '0')) +
                    (row[10] != null ? row[10].padLeft(3, '0') : " ".padLeft(3, '0'))
            ]
        }.sort { it.indirizzoCompletoSort }

        return [lista: elenco, filtro: fro]
    }

    def getOggettiDaCatasto(String indirizzo, Integer numCiv, String categoria) {

        indirizzo = indirizzo?.replace("'", "''")

        if (indirizzo == null && numCiv == null) {
            return [lista: [], filtro: new FiltroRicercaOggetto()]
        }

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto();

        String sql =
                sqlCatasto + """
                                AND FAB.FOGLIO IS NOT NULL
                                AND FAB.NUMERO IS NOT NULL
                                AND FAB.SUBALTERNO IS NOT NULL
                               """

        if (indirizzo) {
            fro.indirizzo = indirizzo
            sql += """ AND (FAB.INDIRIZZO IS NOT NULL AND
                        LOWER('$indirizzo') LIKE '%' || LOWER(FAB.INDIRIZZO) || '%') """
        }

        if (numCiv != null) {
            fro.numCiv = numCiv
            sql += """ AND LTRIM(RTRIM(FAB.NUM_CIV)) = '$numCiv' """
        }

        if (categoria) {
            fro.categoriaCatasto = CategoriaCatasto.get(categoria).toDTO()
            sql += """ AND FAB.CATEGORIA = '$categoria' """
        }

        sql += """
				ORDER BY ESTREMICATASTALISORT
		"""

        def lista = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return [lista: lista, filtro: fro]
    }

    def aggiornaEstremiCatasto(OggettoDTO oggDTO, boolean aggiornaDenunce = false) {
        Oggetto oggetto = oggDTO.getDomainObject()

        oggetto.sezione = oggDTO.sezione
        oggetto.foglio = oggDTO.foglio
        oggetto.numero = oggDTO.numero
        oggetto.subalterno = oggDTO.subalterno
        oggetto.partita = oggDTO.partita

        oggetto.archivioVie = oggDTO?.archivioVie?.getDomainObject()
        oggetto.numCiv = oggDTO?.numCiv
        oggetto.suffisso = oggDTO?.suffisso
        oggetto.scala = oggDTO?.scala
        oggetto.piano = oggDTO?.piano
        oggetto.interno = oggDTO?.interno
        oggetto.categoriaCatasto = oggDTO?.categoriaCatasto?.getDomainObject()

        oggetto.save(failOnError: true, flush: true)

        if (aggiornaDenunce) {

            def parametri = [:]
            parametri.pCategoriaCatasto = oggDTO.categoriaCatasto.categoriaCatasto
            parametri.pOggetto = oggDTO.id

            Query sqlUpdateCat =
                    sessionFactory.currentSession
                            .createSQLQuery """
                                                UPDATE OGGETTI_PRATICA
                                                   SET CATEGORIA_CATASTO = ?
                                                 WHERE OGGETTI_PRATICA.OGGETTO = ?
                                                   AND EXISTS
                                                 (SELECT 1
                                                          FROM PRATICHE_TRIBUTO
                                                         WHERE PRATICHE_TRIBUTO.PRATICA = OGGETTI_PRATICA.PRATICA
                                                           AND PRATICHE_TRIBUTO.TIPO_PRATICA = 'D')
                                                 """
            sqlUpdateCat.setString(0, oggDTO.categoriaCatasto.categoriaCatasto)
            sqlUpdateCat.setLong(1, oggDTO.id)
            sqlUpdateCat.executeUpdate()
        }

        return oggetto.toDTO()
    }

    def getOggettiDaAchivioEstremiUguali(OggettoDTO oggetto) {

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto();

        def elenco = Oggetto.createCriteria().list() {
            createAlias("archivioVie", "via", CriteriaSpecification.LEFT_JOIN)
            createAlias("via.denominazioniVia", "denom", CriteriaSpecification.LEFT_JOIN)
            createAlias("tipoOggetto", "tipoOggetto", CriteriaSpecification.INNER_JOIN)
            projections {
                groupProperty("id")                                    // 0
                groupProperty("tipoOggetto.tipoOggetto")            // 1
                groupProperty("indirizzoLocalita")                    // 2
                groupProperty("via.denomUff")                        // 3
                groupProperty("numCiv")                                // 4
                groupProperty("categoriaCatasto.categoriaCatasto")    // 5
                groupProperty("sezione")                            // 6
                groupProperty("foglio")                                // 7
                groupProperty("numero")                                // 8
                groupProperty("subalterno")                            // 9
                groupProperty("partita")                            // 10
                groupProperty("zona")                                // 11
                groupProperty("protocolloCatasto")                    // 12
                groupProperty("annoCatasto")                        // 13
                groupProperty("classeCatasto")                        // 14
                groupProperty("suffisso")                            // 15
                groupProperty("scala")                                // 16
                groupProperty("piano")                                // 17
                groupProperty("interno")                            // 18
            }

            ne("id", oggetto.id)

            if (oggetto.sezione != null) {
                fro.sezione = oggetto.sezione
                eq("sezione", oggetto.sezione)
            }

            if (oggetto.foglio != null) {
                fro.foglio = oggetto.foglio
                eq("foglio", oggetto.foglio)
            }

            if (oggetto.numero != null) {
                fro.numero = oggetto.numero
                eq("numero", oggetto.numero)
            }

            if (oggetto.subalterno != null) {
                fro.subalterno = oggetto.subalterno
                eq("subalterno", oggetto.subalterno)
            }

            if (oggetto.partita != null) {
                fro.partita = oggetto.partita
                eq("partita", oggetto.partita)
            }

            if (oggetto.zona != null) {
                fro.zona = oggetto.zona
                eq("zona", oggetto.zona)
            }

            if (oggetto.protocolloCatasto != null) {
                fro.protocolloCatasto = oggetto.protocolloCatasto
                eq("protocolloCatasto", oggetto.protocolloCatasto)
            }

            if (oggetto.annoCatasto != null) {
                fro.annoCatasto = (Short) oggetto.annoCatasto
                eq("annoCatasto", (Short) oggetto.annoCatasto)
            }

            if (oggetto.archivioVie?.id != null) {
                fro.indirizzo = oggetto.archivioVie.denomUff
                eq("via.id", oggetto.archivioVie.id)
            } else if (oggetto.indirizzoLocalita) {
                fro.indirizzo = oggetto.indirizzoLocalita
                sqlRestriction(" lower('" + oggetto.indirizzoLocalita + "') like lower(denom2_.descrizione||'%')")
            }

            if (oggetto.numCiv != null) {
                eq("numCiv", oggetto.numCiv)
            }
            if (oggetto.categoriaCatasto) {
                eq("categoriaCatasto.categoriaCatasto", oggetto.categoriaCatasto.categoriaCatasto)
            }
            or {
                isNotNull("sezione")
                isNotNull("foglio")
                isNotNull("numero")
                isNotNull("subalterno")
                isNotNull("partita")
                isNotNull("zona")
                isNotNull("protocolloCatasto")
                isNotNull("annoCatasto")
            }
        }.collect() { row ->
            [
                    idOggetto              : row[0]
                    , tipoOggetto          : row[1]
                    , indirizzoLocalita    : row[2]
                    , indirizzoDenomUff    : row[3]
                    , numCiv               : row[4]
                    , categoriaCatasto     : row[5]
                    , sezione              : row[6]
                    , foglio               : row[7]
                    , numero               : row[8]
                    , subalterno           : row[9]
                    , partita              : row[10]
                    , zona                 : row[11]
                    , protocolloCatasto    : row[12]
                    , annoCatasto          : row[13]
                    , classeCatasto        : row[14]
                    , indirizzoCompleto    : (row[3] != null ? row[3] : (row[2] != null ? row[2] : '')) +
                    (row[4] != null ? ", " + row[4] : "") +    // Numero civico
                    (row[15] != null ? "/" + row[15] : "") +    // Suffisso
                    (row[16] != null ? " Sc:" + row[16] : "") +    // Scala
                    (row[17] != null ? " P:" + row[17] : "") +    // Piano
                    (row[18] != null ? " In:" + row[18] : "")    // Interno
                    , indirizzoCompletoSort: (row[3] != null ? row[3] : row[2]) + (row[4] != null ? ", " + (row[4] + "").padLeft(6, '0') : "0".padLeft(6, '0'))
                    , estremiCatastoSort   : (row[6] != null ? row[6].padLeft(3, '0') : " ".padLeft(3, '0')) +
                    (row[7] != null ? row[7].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[8] != null ? row[8].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[9] != null ? row[9].padLeft(4, '0') : " ".padLeft(4, '0')) +
                    (row[10] != null ? row[10].padLeft(3, '0') : " ".padLeft(3, '0'))
            ]
        }.sort { it.estremiCatastoSort }
        return [lista: elenco, filtro: fro]
    }

    def getOggettiDaCatastoEstremiUguali(OggettoDTO oggetto) {

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto();

        if (oggetto.tipoOggetto != null) {
            if (oggetto.tipoOggetto.tipoOggetto in [1L, 2L]) {
                fro.tipoOggettoCatasto = 'T'
            } else if (oggetto.tipoOggetto.tipoOggetto == 3) {
                fro.tipoOggettoCatasto = 'F'
            }
        }

        String sql = fro.tipoOggettoCatasto == 'F' ? sqlCatastoFab : sqlCatastoTer


        if (oggetto?.archivioVie?.id ? oggetto.archivioVie.denomUff : oggetto.indirizzoLocalita) {
            fro.indirizzo = oggetto?.archivioVie?.id ? oggetto.archivioVie.denomUff : oggetto.indirizzoLocalita
            sql += """ AND (FAB.INDIRIZZO IS NOT NULL AND
                        LOWER('$fro.indirizzo') LIKE '%' || LOWER(FAB.INDIRIZZO) || '%') """
        }

        if (oggetto.categoriaCatasto) {
            fro.categoriaCatasto = CategoriaCatasto.get(oggetto.categoriaCatasto.categoriaCatasto).toDTO()
            sql += """ AND LOWER(FAB.CATEGORIA) LIKE LOWER('%$fro.categoriaCatasto.categoriaCatasto%') """
        }
        if (oggetto.sezione != null) {
            fro.sezione = oggetto.sezione
            sql += """ AND FAB.SEZIONE = '$fro.sezione'"""
        }

        if (oggetto.foglio != null) {
            fro.foglio = oggetto.foglio
            sql += """ AND FAB.FOGLIO = '$fro.foglio'"""
        }

        if (oggetto.numero) {
            fro.numero = oggetto.numero
            sql += """ AND FAB.NUMERO = '$fro.numero'"""
        }

        if (oggetto.subalterno != null) {
            fro.subalterno = oggetto.subalterno
            sql += """ AND FAB.SUBALTERNO = '$fro.subalterno'"""
        }

        if (oggetto.partita != null) {
            fro.partita = oggetto.partita
            sql += """ AND FAB.PARTITA = '$fro.partita'"""
        }

        if (oggetto.zona != null) {
            fro.zona = oggetto.zona
            sql += """ AND FAB.ZONA = '$fro.zona'"""
        }

        if (oggetto.numCiv != null) {
            fro.numCiv = oggetto.numCiv
            sql += """ AND FAB.NUM_CIV = '$fro.numCiv' """
        }

        sql += """
				ORDER BY ESTREMICATASTALISORT
		"""

        def lista = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return [lista: lista, filtro: fro]
    }

    def getOggettiDaAchivioEstremiParziali(OggettoDTO oggetto) {

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto();

        def elenco = Oggetto.createCriteria().list() {
            createAlias("archivioVie", "via", CriteriaSpecification.LEFT_JOIN)
            createAlias("via.denominazioniVia", "denom", CriteriaSpecification.LEFT_JOIN)
            createAlias("tipoOggetto", "tipoOggetto", CriteriaSpecification.INNER_JOIN)
            projections {
                groupProperty("id")
                groupProperty("tipoOggetto.tipoOggetto")
                groupProperty("indirizzoLocalita")
                groupProperty("via.denomUff")
                groupProperty("numCiv")
                groupProperty("categoriaCatasto.categoriaCatasto")
                groupProperty("sezione")
                groupProperty("foglio")
                groupProperty("numero")
                groupProperty("subalterno")
                groupProperty("partita")
                groupProperty("zona")
                groupProperty("protocolloCatasto")
                groupProperty("annoCatasto")
                groupProperty("classeCatasto")
                groupProperty("suffisso")                                // 15
                groupProperty("scala")                                    // 16
                groupProperty("piano")                                    // 17
                groupProperty("interno")                                // 18
            }

            if (oggetto.sezione != null) {
                fro.sezione = oggetto.sezione
                eq("sezione", oggetto.sezione)
            }

            if (oggetto.foglio != null) {
                fro.foglio = oggetto.foglio
                eq("foglio", oggetto.foglio)
            }

            if (oggetto.numero != null) {
                fro.numero = oggetto.numero
                eq("numero", oggetto.numero)
            }

            if (oggetto.subalterno != null) {
                fro.subalterno = oggetto.subalterno
                eq("subalterno", oggetto.subalterno
                )
            }

            if (oggetto.partita != null) {
                fro.partita = oggetto.partita
                eq("partita", oggetto.partita)
            }

            if (oggetto.zona != null) {
                fro.zona = oggetto.zona
                eq("zona", oggetto.zona)
            }

            if (oggetto.protocolloCatasto != null) {
                fro.protocolloCatasto = oggetto.protocolloCatasto
                eq("protocolloCatasto", oggetto.protocolloCatasto)
            }

            if (oggetto.annoCatasto != null) {
                fro.annoCatasto = (Short) oggetto.annoCatasto
                eq("annoCatasto", (Short) oggetto.annoCatasto)
            }

            if (oggetto.archivioVie?.id != null) {
                fro.indirizzo = (oggetto.archivioVie.denomUff - ~/([^\s]+)/).trim()
                eq("via.id", oggetto.archivioVie.id)
            } else if (oggetto.indirizzoLocalita != null) {
                fro.indirizzo = ggetto.indirizzoLocalita
                ilike("denom.descrizione", oggetto.indirizzoLocalita)
            }

            if (oggetto.numCiv != null) {
                fro.numCiv = oggetto.numCiv
                eq("numCiv", oggetto.numCiv)
            }

            ne("id", oggetto.id)
            if (oggetto.categoriaCatasto) {
                eq("categoriaCatasto.categoriaCatasto", oggetto.categoriaCatasto.categoriaCatasto)
            }
            or {
                isNotNull("sezione")
                isNotNull("foglio")
                isNotNull("numero")
                isNotNull("subalterno")
                isNotNull("partita")
                isNotNull("zona")
                isNotNull("protocolloCatasto")
                isNotNull("annoCatasto")
            }
        }.collect() { row ->
            [
                    idOggetto           : row[0]
                    , tipoOggetto       : row[1]
                    , indirizzoLocalita : row[2]
                    , indirizzoDenomUff : row[3]
                    , numCiv            : row[4]
                    , categoriaCatasto  : row[5]
                    , sezione           : row[6]
                    , foglio            : row[7]
                    , numero            : row[8]
                    , subalterno        : row[9]
                    , partita           : row[10]
                    , zona              : row[11]
                    , protocolloCatasto : row[12]
                    , annoCatasto       : row[13]
                    , classeCatasto     : row[14]
                    , indirizzoCompleto : (row[3] != null ? row[3] : (row[2] != null ? row[2] : '')) +
                    (row[4] != null ? ", " + row[4] : "") +    // Numero civico
                    (row[15] != null ? "/" + row[15] : "") +    // Suffisso
                    (row[16] != null ? " Sc:" + row[16] : "") +    // Scala
                    (row[17] != null ? " P:" + row[17] : "") +    // Piano
                    (row[18] != null ? " In:" + row[18] : "")    // Interno
                    , estremiCatastoSort: (row[6] != null ? row[6].padLeft(3, '0') : " ".padLeft(3, '0')) +
                    (row[7] != null ? row[7].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[8] != null ? row[8].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[9] != null ? row[9].padLeft(4, '0') : " ".padLeft(4, '0')) +
                    (row[10] != null ? row[10].padLeft(3, '0') : " ".padLeft(3, '0'))
            ]
        }.sort { it.estremiCatastoSort }

        return [lista: elenco, filtro: fro]
    }

    def getOggettiDaCatastoEstremiParziali(OggettoDTO oggetto) {

        FiltroRicercaOggetto fro = new FiltroRicercaOggetto()

        if (oggetto.tipoOggetto != null) {
            if (oggetto.tipoOggetto.tipoOggetto in [1L, 2L]) {
                fro.tipoOggettoCatasto = 'T'
            } else if (oggetto.tipoOggetto.tipoOggetto == 3) {
                fro.tipoOggettoCatasto = 'F'
            }
        }

        String sql = fro.tipoOggettoCatasto == 'F' ? sqlCatastoFab : sqlCatastoTer


        if (oggetto.categoriaCatasto) {
            fro.categoriaCatasto = CategoriaCatasto.get(oggetto.categoriaCatasto.categoriaCatasto).toDTO()
            sql += """ AND LOWER(FAB.CATEGORIA) LIKE LOWER('%$fro.categoriaCatasto.categoriaCatasto%') """
        }
        if (oggetto?.archivioVie?.id ? oggetto.archivioVie.denomUff : oggetto.indirizzoLocalita) {
            // Si rimuove il toponimo
            fro.indirizzo = oggetto?.archivioVie?.id ? (oggetto.archivioVie.denomUff - ~/([^\s]+)/).trim() : oggetto.indirizzoLocalita
            sql += """ AND (FAB.INDIRIZZO IS NOT NULL AND
                        LOWER('$fro.indirizzo') LIKE '%' || LOWER(FAB.INDIRIZZO) || '%') """
        }
        if (oggetto.sezione != null) {
            fro.sezione = oggetto.sezione
            sql += """ AND FAB.SEZIONE = '$fro.sezione'"""
        }

        if (oggetto.foglio != null) {
            fro.foglio = oggetto.foglio
            sql += """ AND FAB.FOGLIO = '$fro.foglio'"""
        }

        if (oggetto.numero) {
            fro.numero = oggetto.numero
            sql += """ AND FAB.NUMERO = '$fro.numero'"""
        }

        if (oggetto.subalterno != null) {
            fro.subalterno = oggetto.subalterno
            sql += """ AND FAB.SUBALTERNO = '$fro.subalterno'"""
        }

        if (oggetto.partita != null) {
            fro.partita = oggetto.partita
            sql += """ AND FAB.PARTITA = '$fro.partita'"""
        }

        if (oggetto.zona != null) {
            fro.zona = oggetto.zona
            sql += """ AND FAB.ZONA = '$fro.zona'"""
        }

        if (oggetto.numCiv != null) {
            fro.numCiv = oggetto.numCiv
            sql += """ AND FAB.NUM_CIV = '$fro.numCiv' """
        }

        sql += """
				ORDER BY ESTREMICATASTALISORT
		"""

        def lista = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return [lista: lista, filtro: fro]
    }

    /**
     * Dati il tipo di anomalia, l'anno dell'anomalia e l'oggetto cerca gli ogco
     * validi in quell'anno che non sono anomali per quel tipo anomalia.
     */
    List<OggettoContribuenteDTO> getOgcoNonAnomali(short tipoAnomalia, short anno, Long idOggetto, String tipoTributo, String categorie) {
        def lista = []
        def parametriQuery = [:]
        List tipiOggetto = OggettiCache.OGGETTI_TRIBUTO.valore.findAll {
            it.tipoTributo.tipoTributo == tipoTributo
        }?.tipoOggetto.tipoOggetto
        parametriQuery.pTipoAnomalia = tipoAnomalia
        parametriQuery.pAnno = anno
        parametriQuery.pIdOggetto = idOggetto
        parametriQuery.pTipoTributo = tipoTributo
        parametriQuery.pTipiOggetto = tipiOggetto
        parametriQuery.pCategorie = categorie?.split(",")
        String sql = """ SELECT ogco
					       FROM OggettoContribuente as ogco
                          INNER JOIN FETCH ogco.oggettoPratica as ogpr
                          INNER JOIN FETCH ogpr.oggetto as ogge
					      INNER JOIN FETCH ogpr.pratica as prtr
					      INNER JOIN FETCH ogco.contribuente as cont
					      INNER JOIN FETCH cont.soggetto as sogg
					"""
        String whereComuni = """ 
                        ogpr.oggetto.id = :pIdOggetto
                    AND prtr.tipoTributo.tipoTributo = :pTipoTributo
                    AND prtr.tipoPratica = 'D'
					AND ogco.tipoRapporto = 'D'
					AND ogpr.valore is not null
					AND COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto) 
									IN (:pTipiOggetto)
					AND COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto) 
									IN (:pCategorie)AND NOT EXISTS (SELECT 1
									FROM AnomaliaPratica as anpr
									INNER JOIN anpr.anomalia as anom
									INNER JOIN anom.anomaliaParametro as anpa
									INNER JOIN anpr.oggettoContribuente as ogco2
									WHERE anpa.tipoAnomalia.tipoAnomalia = :pTipoAnomalia
                                    AND anpa.anno = :pAnno
									AND anpa.flagImposta = 'S'
									AND anom.oggetto.id = ogpr.oggetto.id
									AND ogco2.oggettoPratica.id = ogpr.id
                                    AND ogco2.contribuente.codFiscale = cont.codFiscale
									AND anpr.flagOk = 'N')    """

        String sqlOgCo = """
					$sql
					WHERE $whereComuni
                    AND (ogco.anno||ogco.tipoRapporto||'S') =
			          (
			            SELECT MAX(concat(ogco1.anno,ogco1.tipoRapporto,ogco1.flagPossesso))
						FROM OggettoContribuente as ogco1
							INNER JOIN ogco1.oggettoPratica as ogpr1
					   		INNER JOIN ogpr1.pratica as prtr1
					   		INNER JOIN ogco1.contribuente as cont1
						WHERE     prtr1.tipoPratica = 'D'
                      	AND prtr1.anno <= :pAnno
                      	AND prtr1.tipoTributo.tipoTributo = prtr.tipoTributo.tipoTributo
                      	AND ogpr1.oggetto.id = ogpr.oggetto.id
                      	AND ogco1.tipoRapporto.tipoRapporto = 'D'
                      	AND cont1.codFiscale = cont.codFiscale
						AND COALESCE(ogpr1.categoriaCatasto, ogge.categoriaCatasto) = COALESCE(ogpr.categoriaCatasto, ogge.categoriaCatasto)
						AND COALESCE(ogpr1.tipoOggetto, ogge.tipoOggetto) = COALESCE(ogpr.tipoOggetto, ogge.tipoOggetto))
						)
					"""
        lista = OggettoContribuente.executeQuery(sqlOgCo, parametriQuery).toDTO()
        List listaPratiche = new ArrayList()
        lista.each { listaPratiche << it.oggettoPratica.pratica.id }

        String sqlOgIm = """
					$sql
					INNER JOIN FETCH ogco.oggettiImposta AS ogim
					WHERE $whereComuni
                    AND ogim.anno = :pAnno
					AND ogim.flagCalcolo = 'S'
					"""

        if (listaPratiche) {
            sqlOgIm += "AND prtr.id not in :pListaPratiche"
            parametriQuery.pListaPratiche = listaPratiche
        }

        lista += OggettoContribuente.executeQuery(sqlOgIm, parametriQuery).toDTO()
        return lista
    }

    /**
     * Dati il tipo di anomalia, l'anno dell'anomalia e l'oggetto cerca gli ogco
     * validi in quell'anno che sono anomali per quel tipo anomalia.
     */
    List<OggettoContribuenteDTO> getOgcoAnomali(AnomaliaPraticaDTO ap, String tipoTributo, String flagImposta) {
        def lista = []
        def parametriQuery = [:]
        List tipiOggetto = OggettiCache.OGGETTI_TRIBUTO.valore.findAll {
            it.tipoTributo.tipoTributo == tipoTributo
        }?.tipoOggetto.tipoOggetto
        parametriQuery.pAnno = ap.anomalia.anomaliaParametro.anno
        parametriQuery.pIdOggetto = ap.anomalia.oggetto.id
        parametriQuery.pTipoTributo = tipoTributo
        parametriQuery.pAnomaliaPraticaId = ap.id
        parametriQuery.pAnomaliaId = ap.anomalia.id
        parametriQuery.pTipiOggetto = tipiOggetto
        parametriQuery.pFlagImposta = flagImposta

        String sql = """
					SELECT ogco
					FROM OggettoContribuente as ogco
                       INNER JOIN FETCH ogco.oggettoPratica as ogpr
                       INNER JOIN FETCH ogpr.oggetto as ogge
					   INNER JOIN FETCH ogpr.pratica as prtr
					   INNER JOIN FETCH ogco.contribuente as cont
					   INNER JOIN FETCH cont.soggetto as sogg  """
        String whereComuni = """
					WHERE ogpr.oggetto.id = :pIdOggetto
                    AND prtr.tipoTributo.tipoTributo = :pTipoTributo
                    AND prtr.tipoPratica = 'D'
					AND ogco.tipoRapporto = 'D'
					AND ogpr.valore is not null
					AND COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto) 
									IN (:pTipiOggetto)
					AND EXISTS (SELECT 1
									FROM AnomaliaPratica as anpr
									INNER JOIN anpr.anomalia as anom
									INNER JOIN anom.anomaliaParametro as anpa
									INNER JOIN anpr.oggettoContribuente as ogco2
									WHERE anom.id = :pAnomaliaId
                                    AND anpr.id <> :pAnomaliaPraticaId
									AND ogco2.oggettoPratica.id = ogpr.id
                                    AND ogco2.contribuente.codFiscale = cont.codFiscale
									AND anpa.flagImposta = :pFlagImposta)
					"""
        if (flagImposta == "S") {
            sql = """ 
					$sql
					INNER JOIN FETCH ogco.oggettiImposta as ogim
					$whereComuni
					AND ogim.anno = :pAnno
					AND ogim.flagCalcolo = 'S'	
                  """
        } else {
            sql = """
					$sql
					$whereComuni
					AND (ogco.anno||ogco.tipoRapporto) =
			          (
			            SELECT MAX(concat(ogco1.anno,ogco1.tipoRapporto))
						FROM OggettoContribuente as ogco1
							INNER JOIN ogco1.oggettoPratica as ogpr1
					   		INNER JOIN ogpr1.pratica as prtr1
					   		INNER JOIN ogco1.contribuente as cont1
						WHERE     prtr1.tipoPratica = 'D'
                      	AND prtr1.anno <= :pAnno
                      	AND prtr1.tipoTributo.tipoTributo = prtr.tipoTributo.tipoTributo
                      	AND ogpr1.oggetto.id = ogpr.oggetto.id
                      	AND ogco1.tipoRapporto.tipoRapporto = 'D'
                      	AND cont1.codFiscale = cont.codFiscale
						AND COALESCE(ogpr1.categoriaCatasto, ogge.categoriaCatasto) = COALESCE(ogpr.categoriaCatasto, ogge.categoriaCatasto)
						AND COALESCE(ogpr1.tipoOggetto, ogge.tipoOggetto) = COALESCE(ogpr.tipoOggetto, ogge.tipoOggetto))
						)
                  """
        }
        lista = OggettoContribuente.executeQuery(sql, parametriQuery).toDTO()
        return lista
    }

    /**
     * Dati il l'anno dell'anomalia e l'oggetto cerca gli ogco
     * validi in quell'anno che hanno il tipo oggetto uguale a quello dell'oggetto
     * in tabella OGGETTI (cioè dove il tipo oggetto non è stato modificato rispetto all'ufficiale).
     * @param anno
     * @param idOggetto
     * @param tipoTributo
     * @return
     */
    List<OggettoContribuenteDTO> getTiogNonAnomali(short anno, Long idOggetto, String tipoTributo, String flagImposta) {
        def lista = []
        def parametriQuery = [:]
        parametriQuery.pAnno = anno
        parametriQuery.pIdOggetto = idOggetto
        parametriQuery.pTipoTributo = tipoTributo

        String sql = """
					SELECT ogco
					FROM OggettoContribuente as ogco
                       INNER JOIN ogco.oggettoPratica as ogpr
                       INNER JOIN ogpr.oggetto as ogge
					   INNER JOIN ogpr.pratica as prtr
					   INNER JOIN ogco.contribuente as cont
					"""
        String whereComuni = """
					ogpr.oggetto.id = :pIdOggetto
                    AND prtr.tipoTributo.tipoTributo = :pTipoTributo
                    AND prtr.tipoPratica = 'D'
					AND ogco.tipoRapporto.tipoRapporto = 'D'
					AND ogpr.tipoOggetto.tipoOggetto = ogge.tipoOggetto.tipoOggetto   """

        if (flagImposta == "S") {
            sql = """
				$sql
				INNER JOIN FETCH ogco.oggettiImposta AS ogim
				WHERE $whereComuni
		        AND ogim.anno = :pAnno
				AND ogim.flagCalcolo = 'S'					                
				"""
        } else {
            sql = """
				$sql
				WHERE $whereComuni 
				AND (ogco.anno||ogco.tipoRapporto||'S') =
			          (
			            SELECT MAX(concat(ogco1.anno,ogco1.tipoRapporto,ogco1.flagPossesso))
						FROM OggettoContribuente as ogco1
							INNER JOIN ogco1.oggettoPratica as ogpr1
					   		INNER JOIN ogpr1.pratica as prtr1
					   		INNER JOIN ogco1.contribuente as cont1
						WHERE     prtr1.tipoPratica = 'D'
                      	AND prtr1.anno <= :pAnno
                      	AND prtr1.tipoTributo.tipoTributo = prtr.tipoTributo.tipoTributo
                      	AND ogpr1.oggetto.id = ogpr.oggetto.id
                      	AND ogco1.tipoRapporto.tipoRapporto = 'D')	"""
        }
        lista = OggettoContribuente.executeQuery(sql, parametriQuery).toDTO(["oggettoPratica", "oggettoPratica.oggetto", "oggettoPratica.oggetto.archivioVie", "oggettoPratica.pratica", "contribuente", "contribuente.soggetto"])
        return lista
    }

    def anomalieAssociateAdOgCo(OggettoContribuente ogco) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pOgco = ogco

        String sql = """
				SELECT new Map(
					anpa.tipoAnomalia.id as idTipoAnomalia,
					anpa.tipoAnomalia.descrizione as descrizione,
					anpa.flagImposta as flagImposta,
					anpa.anno as anno,
					anpa.tipoTributo.tipoTributo as tipoTributo
				)
				FROM
					AnomaliaParametro anpa
				INNER JOIN
					anpa.anomalie anom
				INNER JOIN
					anom.anomaliePratiche anpr 
				WHERE
					anpr.oggettoContribuente = :pOgco
				ORDER BY
					anpa.tipoAnomalia.id,
					anpa.anno
				"""

        lista = AnomaliaParametro.executeQuery(sql, parametriQuery)
        return lista
    }

    def eliminaAnomaliePratica(OggettoContribuente ogco) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pOgco = ogco


        String sql = """
				SELECT anpr
				FROM
					AnomaliaPratica anpr
				INNER JOIN anpr.anomalia anom
				INNER JOIN anom.anomaliaParametro
				WHERE
					anpr.oggettoContribuente = :pOgco
					
				"""

        lista = AnomaliaPratica.executeQuery(sql, parametriQuery)

        // Eliminazione delle AnomaliaPratica associate
        lista.each {


            log.info "---------------------------------------------------------------------"
            // Se è l'unica AnomaliaPratica associata all'Anomalia si elimina direttamente quest'ultima
            if (it.anomalia.anomaliePratiche.count == 1) {

                // Si eliminano eventuali riferimenti
                it.anomalia.anomaliePratiche.each {
                    AnomaliaPratica.findAllByAnomaliaPraticaRif(it).each {
                        it.anomaliaPraticaRif = null
                    }
                }

                it.anomalia.delete(failOnError: true, flush: true)
                log.info "eliminazione anomalia"
            } else {

                // Si eliminano eventuali riferimenti
                it.anomalia.anomaliePratiche.each {
                    AnomaliaPratica.findAllByAnomaliaPraticaRif(it).each {
                        it.anomaliaPraticaRif = null
                    }
                }

                // Si elimina la sola AnomaliaPratica
                it.anomalia.anomaliePratiche.removeAll { ap -> ap.id == it.id }
                it.delete(failOnError: true, flush: true)
                log.info "eliminazione anomalia pratica"
            }
            log.info "Ricalcolo delle rendite..."
            // Ricalcolo delle rendite
            controlloAnomalieService.calcolaRendite(it.anomalia.anomaliaParametro.id, it.anomalia.id)
            log.info "---------------------------------------------------------------------"
        }
    }
}
