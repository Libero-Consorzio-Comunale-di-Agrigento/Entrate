package it.finmatica.tr4.archiviovie

import it.finmatica.tr4.ArchivioVie

import org.hibernate.criterion.CriteriaSpecification



class ArchivioVieService {

    def listaVie(String filtro, int pageSize, int activePage) {
		def listaVie = ArchivioVie.createCriteria().list(max:pageSize, offset: pageSize * activePage) {
			if (filtro != null && !filtro.isEmpty()){
				denominazioniVia {
					ilike("descrizione", "%" + filtro + "%")
				}
			}
			order("denomOrd", "asc")
			setResultTransformer(CriteriaSpecification.DISTINCT_ROOT_ENTITY)
		}
		
		return [lista: listaVie.list.toDTO(), totale: listaVie.totalCount]
    }
}
