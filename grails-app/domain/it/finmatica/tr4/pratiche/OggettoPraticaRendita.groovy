package it.finmatica.tr4.pratiche

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.Categoria
import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.ClasseSuperficie
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.CostoStorico
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.OggettoOgim
import it.finmatica.tr4.PartizioneOggettoPratica
import it.finmatica.tr4.RiferimentoOggetto
import it.finmatica.tr4.Tariffa
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.commons.AssenzaEstremiCatasto
import it.finmatica.tr4.commons.DestinazioneUso
import it.finmatica.tr4.commons.NaturaOccupazione
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.commons.TitoloOccupazione
import it.finmatica.tr4.dto.MoltiplicatoreDTO
import it.finmatica.tr4.dto.RivalutazioneRenditaDTO
import it.finmatica.tr4.tipi.SiNoType

class OggettoPraticaRendita  {
	
	BigDecimal 	rendita
	
	static mapping = {
		id 					column: 'oggetto_pratica', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "OGGETTI_PRATICA_NR"]
		rendita				updateable: false, insertable: false
		table 'web_oggetti_pratica_rendita'
		version false
	}
	
	
	static constraints = {
	}
	
}
