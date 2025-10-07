package it.finmatica.tr4.tipoOggetto

import grails.transaction.Transactional
import it.finmatica.tr4.OggettoTributo
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.dto.OggettoTributoDTO
import it.finmatica.tr4.dto.TipoOggettoDTO

@Transactional
class TipoOggettoService {

	Collection<TipoOggettoDTO> getAll() {

		return TipoOggetto.getAll().toDTO()
	}

}
