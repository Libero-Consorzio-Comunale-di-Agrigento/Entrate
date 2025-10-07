package it.finmatica.tr4.stradario

import it.finmatica.tr4.DenominazioneVia
import transform.AliasToEntityCamelCaseMapResultTransformer

class StradarioService {

    def sessionFactory

    def getListaVie(def pageSize, def activePage, def ordinamento, def filtri, def wholeList) {

        def parametri = [:]


        def ordinamentoQuery = ""

        if (ordinamento == "cod") {
            ordinamentoQuery = " ORDER BY ARVI.COD_VIA ASC "
        } else {
            ordinamentoQuery = " ORDER BY ARVI.DENOM_ORD ASC "
        }

        def filtriQuery = ""

        if (filtri?.codiceDa != null) {
            if (filtriQuery.length() == 0) {
                filtriQuery += " WHERE "
            } else {
                filtriQuery += " AND "
            }

            filtriQuery += " ARVI.COD_VIA >= :p_cod_via_da "
            parametri << ["p_cod_via_da": filtri.codiceDa]
        }

        if (filtri?.codiceA != null) {
            if (filtriQuery.length() == 0) {
                filtriQuery += " WHERE "
            } else {
                filtriQuery += " AND "
            }

            filtriQuery += " ARVI.COD_VIA <= :p_cod_via_a "
            parametri << ["p_cod_via_a": filtri.codiceA]
        }

        if (filtri?.denomUff) {
            if (filtriQuery.length() == 0) {
                filtriQuery += " WHERE "
            } else {
                filtriQuery += " AND "
            }

            filtriQuery += " ARVI.DENOM_UFF LIKE :p_denom_uff "
            parametri << ["p_denom_uff": filtri.denomUff.toUpperCase()]
        }

        if (filtri?.denomOrd) {
            if (filtriQuery.length() == 0) {
                filtriQuery += " WHERE "
            } else {
                filtriQuery += " AND "
            }

            filtriQuery += " ARVI.DENOM_ORD LIKE :p_denom_ord "
            parametri << ["p_denom_ord": filtri.denomOrd.toUpperCase()]
        }

        def query = """
                           SELECT ARVI.COD_VIA, 
                                  ARVI.DENOM_UFF, 
                                  ARVI.DENOM_ORD,
                                  COUNT(*) over() "totale"
                           FROM ARCHIVIO_VIE ARVI
                           ${filtriQuery}
                           ${ordinamentoQuery}
                           """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            if (!wholeList) {
                setFirstResult(activePage * pageSize)
                setMaxResults(pageSize)
            }

            list()
        }
    }


    def getListaDenominazioni(def codVia, def filtri) {

        def parametri = [:]
        parametri << ["p_cod_via": codVia]


        def filtriQuery = ""


        if (filtri?.daProgrVia) {
            filtriQuery += " AND DENOMINAZIONI_VIA.PROGR_VIA >= :p_da_progr_via "
            parametri << ["p_da_progr_via": filtri.daProgrVia]
        }

        if (filtri?.aProgrVia) {
            filtriQuery += " AND DENOMINAZIONI_VIA.PROGR_VIA <= :p_a_progr_via "
            parametri << ["p_a_progr_via": filtri.aProgrVia]
        }

        if (filtri?.descNominativo) {
            filtriQuery += " AND DENOMINAZIONI_VIA.DESCRIZIONE LIKE :p_desc_nom "
            parametri << ["p_desc_nom": filtri.descNominativo.toUpperCase()]
        }

        def query = """
                            SELECT DENOMINAZIONI_VIA.PROGR_VIA,
                                   DENOMINAZIONI_VIA.DESCRIZIONE,
                                   DENOMINAZIONI_VIA.COD_VIA
                              FROM DENOMINAZIONI_VIA
                             WHERE (DENOMINAZIONI_VIA.COD_VIA = :p_cod_via)
                             ${filtriQuery}
                             ORDER BY DENOMINAZIONI_VIA.PROGR_VIA ASC
                           """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def existDenominazione(def codVia, def progrVia) {

        def result = DenominazioneVia.createCriteria().get {
            eq("progrVia", progrVia as Integer)
            eq("archivioVie.id", codVia as Long)
        }

        return result != null
    }

    def getDenominazione(def codVia, def progrVia) {

        return DenominazioneVia.createCriteria().get {
            eq("progrVia", progrVia as Integer)
            eq("archivioVie.id", codVia as Long)
        }

    }

    def salvaDenominazione(def denominazione) {
        denominazione.save(failOnError: true, flush: true)
    }

    def eliminaDenominazione(def denominazione) {
        denominazione.delete(failOnError: true, flush: true)
    }

}
