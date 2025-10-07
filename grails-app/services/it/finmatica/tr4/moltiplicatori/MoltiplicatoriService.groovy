package it.finmatica.tr4.moltiplicatori

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Moltiplicatore

class MoltiplicatoriService {

    def getListaMoltiplicatori(def filtro = [:]) {

        def parametri = [
                pDa              : (filtro.da ?: 0) as BigDecimal,
                pA               : (filtro.a ?: 9999.99) as BigDecimal,
                pCategoriaCatasto: filtro.categoriaCatasto ? "${filtro.categoriaCatasto}" : "%",
                pDescrizione     : filtro.descrizione ? "${filtro.descrizione}" : "%"]

        if (filtro.anno) {
            parametri.pAnno = filtro.anno as Short
        }

        String query = """SELECT molt
        FROM
            Moltiplicatore as molt
        INNER JOIN
            molt.categoriaCatasto as caca
        WHERE
            ${parametri.pAnno ? 'molt.anno = :pAnno and' : ''}
            lower(caca.categoriaCatasto) like lower(:pCategoriaCatasto) and
            lower(caca.descrizione) like lower(:pDescrizione) and
            molt.moltiplicatore >= :pDa and
            molt.moltiplicatore <= :pA
        ORDER BY
            molt.anno desc,
            caca.categoriaCatasto
            """

        return Moltiplicatore.executeQuery(query, parametri).findAll()
    }

    def getCountMoltiplicatoriByAnno(def anno) {
        def parametri = [pAnno: anno as Short]

        String query = """SELECT count(*)
        FROM
            Moltiplicatore as molt
        WHERE
            molt.anno = :pAnno"""

        return Moltiplicatore.executeQuery(query, parametri)[0]
    }

    def getCategorieCatasto() {
        return CategoriaCatasto.findAll()
                .sort { it.categoriaCatasto }
    }

    def existsMoltiplicatore(def moltiplicatore) {
        return Moltiplicatore.findByAnnoAndCategoriaCatasto(moltiplicatore.anno, moltiplicatore.categoriaCatasto) != null
    }

    def salvaMoltiplicatore(def moltiplicatore) {
        moltiplicatore.save(failOnError: true, flush: true)
    }

    def eliminaMoltiplicatore(def moltiplicatore) {
        moltiplicatore.delete(failOnError: true, flush: true)
    }

    def getListaAnniDuplicaDaAnno() {

        return Moltiplicatore.findAll()
                .collect {
                    it.anno
                }
                .unique()
                .sort { -it }
    }

    def getMoltiplicatoriDaAnno(def anno) {
        return Moltiplicatore.findAllByAnno(anno)
    }

}
