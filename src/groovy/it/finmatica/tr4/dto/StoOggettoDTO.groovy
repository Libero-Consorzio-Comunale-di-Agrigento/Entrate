package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.StoOggetto
import it.finmatica.tr4.dto.pratiche.StoOggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.StoOggettoPraticaDTO

public class StoOggettoDTO implements it.finmatica.dto.DTO<StoOggetto> {

	private static final long serialVersionUID = 1L

	Long id
	Short annoCatasto
	ArchivioVieDTO archivioVie
	Byte are
	CategoriaCatastoDTO categoriaCatasto
	Byte centiare
	SortedSet<StoCivicoOggettoDTO> civiciOggetto
	String classeCatasto
	String codEcografico
	BigDecimal consistenza
	Date dataCessazione
	Date lastUpdated
	String descrizione
	EdificioDTO edificio
	So4AmministrazioneDTO ente
	String estremiCatasto
	Integer ettari
	String flagCostruitoEnte
	String flagSostituito
	String foglio
	String foglioPadded
	FonteDTO fonte
	String indirizzoLocalita
	Short interno
	String note
	def notificheOggetto
	Integer numCiv
	String numero
	String numeroPadded
	SortedSet<StoOggettoPraticaDTO> oggettiPratica
	String partita
	String partitaPadded
	def partizioniOggetto
	String piano
	Integer progrPartita
	String protocolloCatasto
	String qualita
	def riferimentiOggetto
	String scala
	String sezione
	String sezionePadded
	String subalterno
	String subalternoPadded
	String suffisso
	BigDecimal superficie
	TipoOggettoDTO tipoOggetto
	TipoQualitaDTO tipoQualita
	TipoUsoDTO tipoUso
	Ad4UtenteDTO	utente
	def utilizziOggetto
	BigDecimal vani
	String zona
	String zonaPadded
	BigDecimal idImmobile
	

	public void addToCiviciOggetto (StoCivicoOggettoDTO civicoOggetto) {
		if (this.civiciOggetto == null)
			this.civiciOggetto = new TreeSet<CivicoOggettoDTO>()
		this.civiciOggetto.add (civicoOggetto)
		civicoOggetto.oggetto = this
	}
	public void removeFromCiviciOggetto(StoCivicoOggettoDTO civicoOggetto) {
		if (this.civiciOggetto == null)
			this.civiciOggetto = new TreeSet<CivicoOggettoDTO>()
		this.civiciOggetto.remove (civicoOggetto)
		civicoOggetto.oggetto = null
	}
	
	public void addToOggettiPratica (StoOggettoPraticaDTO oggettoPratica) {
		if (this.oggettiPratica == null)
			this.oggettiPratica = new TreeSet<StoOggettoPraticaDTO>()
		this.oggettiPratica.add (oggettoPratica)
		oggettoPratica.oggetto = this
	}
	public void removeFromOggettiPratica (StoOggettoPraticaDTO oggettoPratica) {
		if (this.oggettiPratica == null)
			this.oggettiPratica = new TreeSet<StoOggettoPraticaDTO>()
		this.oggettiPratica.remove (oggettoPratica)
		oggettoPratica.oggetto = null
	}
	

	public StoOggetto getDomainObject () {
		return StoOggetto.get(this.id)
	}
	public StoOggetto toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	public String getIndirizzo() {
		String indirizzoCompleto = archivioVie? archivioVie?.denomUff : indirizzoLocalita ?: ""
		if (!indirizzoCompleto.isEmpty()) {
			indirizzoCompleto += (numCiv ? ", $numCiv" : "") + (suffisso ? "/$suffisso" : "") + (interno ? " int. $interno" : "")
		}
		return indirizzoCompleto
	}
	
	public List<StoOggettoContribuenteDTO> getOggettiContribuente() {
		return oggettiPratica.oggettiContribuente.flatten()
	}

}
