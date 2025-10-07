package it.finmatica.tr4.dto.pratiche

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.pratiche.StoOggettoContribuente
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

public class StoOggettoContribuenteDTO implements it.finmatica.dto.DTO<StoOggettoContribuente> {

	private static final long serialVersionUID = 1L;

	Long id;
	Short anno;
	ContribuenteDTO contribuente;
	Date dataCessazione;
	Date dataDecorrenza;
	Date lastUpdated;
	BigDecimal detrazione;
	Date fineOccupazione;
	boolean flagAbPrincipale;
	boolean flagAlRidotta;
	boolean flagEsclusione;
	boolean flagPossesso;
	boolean flagRiduzione;
	Date inizioOccupazione;
	Short mesiAliquotaRidotta;
	Short mesiEsclusione;
	Short mesiOccupato
	Short mesiOccupato1sem
	Short mesiPossesso;
	Short mesiPossesso1sem;
	Short mesiRiduzione;
	String note;
	StoOggettoPraticaDTO oggettoPratica;
	BigDecimal percDetrazione
	BigDecimal percPossesso;
	Integer progressivoSudv;
	Long successione;
	String tipoRapporto;
	String tipoRapportoK;
	Ad4UtenteDTO utente;
	Short daMesePossesso
	Date dataEvento

	StoOggettoPraticaDTO oggettoPraticaId

	def detrazioniOgco
	def attributiOgco
	def aliquoteOgco
	def attributoOgco

	public StoOggettoContribuente getDomainObject() {
		return StoOggettoContribuente.createCriteria().get {
			eq('contribuente.codFiscale', this.contribuente.codFiscale)
			eq('oggettoPratica.id', this.oggettoPratica.id)
		}
	}
	public StoOggettoContribuente toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente?.codFiscale
		builder.append oggettoPratica?.id
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.append oggettoPratica.id, other.oggettoPratica.id
		builder.isEquals()
	}
}
