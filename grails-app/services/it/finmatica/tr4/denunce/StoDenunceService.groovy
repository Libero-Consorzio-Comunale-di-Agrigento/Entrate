package it.finmatica.tr4.denunce

import grails.orm.PagedResultList
import grails.plugins.springsecurity.SpringSecurityService
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.dto.pratiche.StoOggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.StoOggettoPraticaDTO
import it.finmatica.tr4.pratiche.*

import org.hibernate.criterion.*
import org.hibernate.transform.AliasToEntityMapResultTransformer

@Transactional
class StoDenunceService {

	/**
	 * Ritorna gli oggetti di una denuncia storica
	 * @param idPratica
	 * @param codFiscale
	 * @return
	 */
	@NotTransactional
	def oggettiDenuncia(long idPratica, String codFiscale) {
		String query = """
                    SELECT ogco 
		            FROM StoOggettoContribuente ogco
						  INNER JOIN FETCH ogco.contribuente cont
						  INNER JOIN FETCH ogco.oggettoPratica ogpr
						  LEFT JOIN FETCH ogpr.categoriaCatasto caca
						  LEFT JOIN FETCH ogpr.tipoOggetto tiog
						  INNER JOIN FETCH ogpr.oggetto ogg
						  LEFT JOIN FETCH ogg.archivioVie
				   WHERE
					   ogpr.pratica.id = :idPratica
					   AND ogco.tipoRapporto in ('A', 'D')
					   AND ogco.contribuente.codFiscale = :codFiscale
					ORDER BY LPAD(ogco.oggettoPratica.numOrdine, 2, '0')
		"""
		def lista = StoOggettoContribuente.executeQuery(query, [codFiscale: codFiscale, idPratica: idPratica]).toDTO()
	}
	
	@NotTransactional
	def contitolariOggetto(Long idOggPratica) {
		String query = """
                    SELECT ogco 
		            FROM StoOggettoContribuente ogco
						  INNER JOIN FETCH ogco.contribuente cont
						  INNER JOIN FETCH cont.soggetto sogg
						  INNER JOIN FETCH ogco.oggettoPratica ogpr
						  INNER JOIN FETCH ogpr.oggetto ogg
						  LEFT JOIN FETCH ogg.archivioVie
				   WHERE
				       ogpr.id = :idOggPratica
				   AND ogco.tipoRapporto in ('C')
		"""
		def lista = StoOggettoContribuente.executeQuery(query, [idOggPratica: idOggPratica]).toDTO()
	}
}
