package it.finmatica.ad4

import grails.transaction.Transactional
import it.finmatica.ad4.dizionari.Ad4Comune

import org.hibernate.FetchMode

@Transactional
class Ad4ComuniService {

    /// Crea lista comuni per BandBoxComuni
    def listaComuni(String filtro, int pageSize, int activePage) {
		def listaComuni = Ad4Comune.createCriteria().list(max:pageSize, offset: pageSize * activePage) {
			ilike("denominazione", (filtro ?: '') + "%")
			order("denominazione", "asc")
			fetchMode("provincia", FetchMode.JOIN)
			fetchMode("stato", FetchMode.JOIN)
		}

		return [lista: listaComuni.list.toDTO(), totale: listaComuni.totalCount]
    }

    /// Crea lista comuni per BandBoxComuniFAE
    def listaComuniFAE(String filtro, Long provinciaStato, Long progrDoc, int pageSize, int activePage) {

		def listaComuni = Ad4Comune.createCriteria().list(max:pageSize, offset: pageSize * activePage) {
			fetchMode("provincia", FetchMode.JOIN)
			fetchMode("stato", FetchMode.JOIN)

			ilike("denominazione", (filtro ?: '') + "%")

			/// L'OR su {alias}Denominazioen = '.' serve per avere la riga vuota che consente un 'Annulla Selezione''
			if(provinciaStato) {
				sqlRestriction("(({alias}.provincia = " + (provinciaStato as String) + ") or " +
								"({alias}.denominazione = '.'))"
				)
			}

			if(progrDoc) {
				if(progrDoc == -1) {
					sqlRestriction("(nvl({alias}.sigla_cfis,{alias}.denominazione) IN " +
									 "(SELECT DISTINCT COD_ENTE_COMUNALE " +
									  "FROM FORNITURE_AE " +
									  "union " +
									  "select '.' from dual" +
									 ")" +
								   ")"
					)
				}
				else {
					sqlRestriction("(nvl({alias}.sigla_cfis,{alias}.denominazione) IN " +
									 "(SELECT DISTINCT COD_ENTE_COMUNALE " +
									   "FROM FORNITURE_AE " +
									   "WHERE DOCUMENTO_ID = " + (progrDoc as String) +
									  "union " +
									  "select '.' from dual" +
									 ")" +
								   ")"
					)
				}
			}

			order("denominazione", "asc")
		}

		return [lista: listaComuni.list.toDTO(), totale: listaComuni.totalCount]
    }
}
