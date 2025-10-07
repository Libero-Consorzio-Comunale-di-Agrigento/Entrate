package it.finmatica.tr4.contribuenti

import it.finmatica.tr4.contribuenti.f24query.F24ImpostaQuery
import org.hibernate.transform.AliasToEntityMapResultTransformer

class F24ImposteService {

    def sessionFactory

    def f24ImpostaDettaglio(short anno, String tipoTributo, String codFiscale, String tipoVersamento, String dovutoVersato) {

        String sql = F24ImpostaQuery.query(tipoTributo)

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def dettagli = sqlQuery.with {
            setParameter('p_anno', anno)
            setParameter('p_tipo_tributo', tipoTributo)
            setParameter('p_cod_fiscale', codFiscale)
            setParameter('p_tipo_versamento', tipoVersamento)
            setParameter('p_dovuto_versato', dovutoVersato)

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        return !dettagli.empty ? dettagli : null

    }
}
