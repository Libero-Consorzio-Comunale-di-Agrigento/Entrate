package it.finmatica.tr4.contribuenti

import it.finmatica.tr4.contribuenti.f24query.*
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.transform.AliasToEntityMapResultTransformer

class F24ViolazioniService {

    def sessionFactory

    def f24ViolazioneDettaglio(Long pratica, Boolean ridotto) {

        // Recupero del tributo
        String sql = f24Query(pratica)

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def prtr = PraticaTributo.get(pratica)

        def dettagli = sqlQuery.with {
            setParameter('pPratica', pratica)
            if (prtr?.tipoPratica != 'V') {
                setParameter('pImportoRidotto', ridotto ? 'S' : 'N')
            }

            if (prtr?.tipoTributo?.tipoTributo in ['TARSU', 'ICP', 'TOSAP']) {
                setParameter('pCodFiscale', prtr?.contribuente?.codFiscale)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        return !dettagli.empty ? dettagli : null

    }

    private String f24Query(Long pratica) {

        String f24ViolazioniSQL = ""

        PraticaTributo praticaTributo = PraticaTributo.get(pratica)

        String whereAnno = ""
        String codSanzioni = ""

        if (praticaTributo.tipoPratica == 'V') {
            if (praticaTributo.tipoTributo.tipoTributo == 'ICI') {
                f24ViolazioniSQL = F24RavvICIQuery.query()
            } else if (praticaTributo.tipoTributo.tipoTributo == 'TASI') {
                f24ViolazioniSQL = F24RavvTASIQuery.query()
            } else if (praticaTributo.tipoTributo.tipoTributo == 'TARSU') {
                f24ViolazioniSQL = F24RavvTARSUQuery.query()
            }
        } else if (praticaTributo.tipoTributo.tipoTributo.equals("ICI")) {
            if (praticaTributo.anno < 2012) {
                whereAnno = " < "
                codSanzioni = "1,0,21,0,24,0,31,0,101,0,121,0,124,0,131,0,98,0,99,0,198,0,199,0,"
            } else if (praticaTributo.anno >= 2012) {
                whereAnno = " >= "
                codSanzioni = "98,0,99,0,198,0,199,0,"
            }

            f24ViolazioniSQL = F24ViolazioniICIQuery.query()

        } else if (praticaTributo.tipoTributo.tipoTributo == "TASI") {
            f24ViolazioniSQL = F24ViolazioniTASIQuery.query()
        } else if (praticaTributo.tipoTributo.tipoTributo == "TARSU") {
            f24ViolazioniSQL = F24ViolazioniTARSUQuery.query()
        } else if (praticaTributo.tipoTributo.tipoTributo == "ICP") {
            f24ViolazioniSQL = F24ViolazioniTribMinQuery.query("ICP")
        } else if (praticaTributo.tipoTributo.tipoTributo == "TOSAP") {
            f24ViolazioniSQL = F24ViolazioniTribMinQuery.query("TOSAP")
        } else {
            throw new RuntimeException("F24 non supportato per il modello scelto.")
        }

        return f24ViolazioniSQL

    }
}
