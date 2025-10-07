package it.finmatica.tr4.categorie

import it.finmatica.tr4.Categoria
import it.finmatica.tr4.dto.CategoriaDTO

class CategorieService {

    Collection<CategoriaDTO> getByCriteria(def criteria = [:]) {
        return Categoria.createCriteria().list {
            if (criteria.codiceTributo) {
                eq("codiceTributo.id", criteria.codiceTributo) // Relativo a CODICI_TRIBUTO
            }
            order("categoria", "asc")
        }.toDTO()
    }

}
