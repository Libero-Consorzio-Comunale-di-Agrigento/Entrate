package it.finmatica.tr4.dto.pratiche

import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.StoPraticaTributo

class StoPraticaTributoDTO implements DTO<StoPraticaTributo>, Comparable<StoPraticaTributoDTO> {

	private static final long serialVersionUID = 1L

	Long id
	short anno
	String codFiscaleDen
	Ad4ComuneTr4DTO comuneDenunciante
	ContribuenteDTO contribuente
	Date data
	Date dataNotifica
	Date lastUpdated
	String denunciante
	So4AmministrazioneDTO ente
	boolean flagAdesione
	boolean flagAnnullamento
	boolean flagDenuncia
	BigDecimal importoRidotto
	BigDecimal importoRidotto2
	BigDecimal importoTotale
	BigDecimal impostaDovutaTotale
	BigDecimal impostaTotale
	String indirizzoDen
	String motivo
	String note
	Set<NotificaOggettoDTO> notificheOggetto
	String numero
	String numeroPadded
	SortedSet<StoOggettoPraticaDTO> oggettiPratica
	String partitaIvaDen
	StoPraticaTributoDTO praticaTributoRif
	Set<StoRapportoTributoDTO> rapportiTributo
	TipoAttoDTO tipoAtto
	TipoCaricaDTO tipoCarica
	TipoEventoDenuncia tipoEvento
	String tipoPratica
	TipoStatoDTO tipoStato
	TipoTributoDTO tipoTributo
	String tipoCalcolo
	BigDecimal versatoPreRate
	Date dataRateazione
	BigDecimal mora
	Short numRata
	String tipologiaRate
	BigDecimal importoRate
	BigDecimal aliquotaRate
	String utente

	def rate

	StoPraticaTributo getDomainObject() {
		return StoPraticaTributo.get(this.id)
	}

	StoPraticaTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	int compareTo(StoPraticaTributoDTO obj) {
		obj.anno <=> anno ?: id <=> obj.id
	}

	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
}
