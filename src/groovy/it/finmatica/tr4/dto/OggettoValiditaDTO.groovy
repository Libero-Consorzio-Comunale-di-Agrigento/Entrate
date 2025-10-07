package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.OggettoValidita
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class OggettoValiditaDTO implements it.finmatica.dto.DTO<OggettoValidita> {
	private static final long serialVersionUID = 1L

	ContribuenteDTO contribuente
	OggettoDTO oggetto
	OggettoPraticaDTO oggettoPratica
	OggettoPraticaDTO oggettoPraticaRif
	OggettoPraticaDTO oggettoPraticaRifAp
	PraticaTributoDTO pratica
	TipoStatoDTO tipoStato
	TipoTributoDTO tipoTributo
	Date al
	Short anno
    Date dal
    Date data
    boolean flagAbPrincipale
    boolean flagDenuncia
    String numero
    
    String tipoEvento
    String tipoOccupazione
    String tipoPratica

	BigDecimal 	percPossesso
	Short 		mesiPossesso
	Short 		mesiEsclusione
	Short 		mesiRiduzione
	boolean 	flagPossesso
	boolean 	flagEsclusione
	boolean 	flagRiduzione
	BigDecimal 	valore
	boolean		flagProvvisorio
	TipoOggettoDTO tipoOggetto
	BigDecimal detrazione


	OggettoValidita getDomainObject() {
		return OggettoValidita.createCriteria().get {
			eq('contribuente.codFiscale', this.contribuente.codFiscale)
			eq('oggettoPratica.id', this.oggettoPratica.id)
		}
	}

	OggettoValidita toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
