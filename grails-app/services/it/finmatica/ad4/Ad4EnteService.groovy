package it.finmatica.ad4

import grails.transaction.Transactional
import it.finmatica.tr4.commons.CommonService;

@Transactional
class Ad4EnteService {
	
	def sessionFactory
	CommonService commonService
	
	String getEnte() {
		
		String queryEnte = 
						"""
							SELECT ADEN.DESCRIZIONE
								FROM AD4_ISTANZE ADIS, AD4_ENTI ADEN
							WHERE ADIS.ENTE = ADEN.ENTE
								AND  upper(adis.istanza) = upper('${commonService.getIstanza()}')
							"""
		(sessionFactory.currentSession.createSQLQuery(queryEnte).list())?sessionFactory.currentSession.createSQLQuery(queryEnte).list().get(0):''
	}

}
