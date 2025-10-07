package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.dto.pratiche.RapportoTributoDTO

class ContribuenteDTO implements it.finmatica.dto.DTO<Contribuente> {
	private static final long serialVersionUID = 1L

	String id
	String codAttivita
	Integer codContribuente
	Byte codControllo
	String codFiscale
	Set<ContattoContribuenteDTO> contattiContribuente
	Set<DocumentoContribuenteDTO> documentiContribuente
	So4AmministrazioneDTO ente
	String note
	Set<OggettoContribuenteDTO> oggettiContribuente
	Set<RuoloContribuenteDTO> ruoliContribuente
	SoggettoDTO soggetto
	SortedSet<VersamentoDTO> versamenti
	SortedSet<PraticaTributoDTO> pratiche
	SortedSet<RapportoTributoDTO> rapportiTributo
	Set<ContribuenteCcSoggettoDTO> contribuentiCcSoggetti

	void addToContattiContribuente(ContattoContribuenteDTO contattoContribuente) {
		if (this.contattiContribuente == null)
			this.contattiContribuente = new HashSet<ContattoContribuenteDTO>()
		this.contattiContribuente.add(contattoContribuente)
		contattoContribuente.contribuente = this
	}

	void removeFromContattiContribuente(ContattoContribuenteDTO contattoContribuente) {
		if (this.contattiContribuente == null)
			this.contattiContribuente = new HashSet<ContattoContribuenteDTO>()
		this.contattiContribuente.remove(contattoContribuente)
		contattoContribuente.contribuente = null
	}

	void addToDocumentiContribuente(DocumentoContribuenteDTO documentoContribuente) {
		if (this.documentiContribuente == null)
			this.documentiContribuente = new HashSet<DocumentoContribuenteDTO>()
		this.documentiContribuente.add(documentoContribuente)
		documentoContribuente.contribuente = this
	}

	void removeFromDocumentiContribuente(DocumentoContribuenteDTO documentoContribuente) {
		if (this.documentiContribuente == null)
			this.documentiContribuente = new HashSet<DocumentoContribuenteDTO>()
		this.documentiContribuente.remove(documentoContribuente)
		documentoContribuente.contribuente = null
	}

	void addToOggettiContribuente(OggettoContribuenteDTO oggettoContribuente) {
		if (this.oggettiContribuente == null)
			this.oggettiContribuente = new HashSet<OggettoContribuenteDTO>()
		this.oggettiContribuente.add(oggettoContribuente)
		oggettoContribuente.contribuente = this
	}

	void removeFromOggettiContribuente(OggettoContribuenteDTO oggettoContribuente) {
		if (this.oggettiContribuente == null)
			this.oggettiContribuente = new HashSet<OggettoContribuenteDTO>()
		this.oggettiContribuente.remove(oggettoContribuente)
		oggettoContribuente.contribuente = null
	}

	void addToRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
		if (this.ruoliContribuente == null)
			this.ruoliContribuente = new HashSet<RuoloContribuenteDTO>()
		this.ruoliContribuente.add(ruoloContribuente)
		ruoloContribuente.contribuente = this
	}

	void removeFromRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
		if (this.ruoliContribuente == null)
			this.ruoliContribuente = new HashSet<RuoloContribuenteDTO>()
		this.ruoliContribuente.remove(ruoloContribuente)
		ruoloContribuente.contribuente = null
	}

	void addToVersamenti(VersamentoDTO versamento) {
		if (this.versamenti == null)
			this.versamenti = new TreeSet<VersamentoDTO>()
		this.versamenti.add(versamento)
		versamento.contribuente = this
	}

	void removeFromVersamenti(VersamentoDTO versamento) {
		if (this.versamenti == null)
			this.versamenti = new TreeSet<VersamentoDTO>()
		this.versamenti.remove(versamento)
		versamento.contribuente = null
	}

	void addToPratiche(PraticaTributoDTO pratica) {
		if (this.pratiche == null)
			this.pratiche = new TreeSet<PraticaTributoDTO>()
		this.pratiche.add(pratica)
		pratica.contribuente = this
	}

	void removeFromPratiche(PraticaTributoDTO pratica) {
		if (this.pratiche == null)
			this.pratiche = new TreeSet<PraticaTributoDTO>()
		this.pratiche.remove(pratica)
		pratica.contribuente = null
	}

	void addToRapportiTributo(RapportoTributoDTO rapportoTributo) {
		if (this.rapportiTributo == null)
			this.rapportiTributo = new TreeSet<PraticaTributoDTO>()
		this.rapportiTributo.add(rapportoTributo)
		rapportoTributo.contribuente = this
	}

	void removeFromRapportiTributo(RapportoTributoDTO rapportoTributo) {
		if (this.rapportiTributo == null)
			this.rapportiTributo = new TreeSet<PraticaTributoDTO>()
		this.rapportiTributo.remove(rapportoTributo)
		rapportoTributo.contribuente = null
	}

	Contribuente getDomainObject() {
		return Contribuente.createCriteria().get {
			eq("codFiscale", this.codFiscale)
		}
	}

	Contribuente toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	SortedSet<RapportoTributoDTO> getPraticheImu() {
		return rapportiTributo.findAll {
			it.pratica.tipoTributo.tipoTributo == "ICI"
		}
	}

	SortedSet<RapportoTributoDTO> getPraticheTasi() {
		return rapportiTributo.findAll {
			it.pratica.tipoTributo.tipoTributo == "TASI"
		}
	}

	SortedSet<RapportoTributoDTO> getPraticheTari() {
		return rapportiTributo.findAll {
			it.pratica.tipoTributo.tipoTributo == "TARSU"
		}
	}

	SortedSet<RapportoTributoDTO> getPraticheCuni() {
		return rapportiTributo.findAll {
			it.pratica.tipoTributo.tipoTributo == "CUNI"
		}
	}

	Set<VersamentoDTO> getVersamentiImu() {
		return versamenti.findAll {
			it.tipoTributo.tipoTributo == "ICI"
		}
	}

	Set<VersamentoDTO> getVersamentiTasi() {
		return versamenti.findAll {
			it.tipoTributo.tipoTributo == "TASI"
		}
	}

	Set<VersamentoDTO> getVersamentiTari() {
		return versamenti.findAll {
			it.tipoTributo.tipoTributo == "TARSU"
		}
	}

	Set<VersamentoDTO> getVersamentiCuni() {
		return versamenti.findAll {
			it.tipoTributo.tipoTributo == "CUNI"
		}
	}

	/*
     * Rdmine #15707
     * La precedente costruzione sporcava il DTO creando problemi di inconsistenza nel caso in cui un oggetto appartenesse a tributi diversi.
     * Si crea un nuovo DTO così che ogni tributo abbia il suo a parità di oggetto.
     */

	List<OggettoDTO> getOggettiImu() {
		def oggettiPratica = praticheImu.pratica.oggettiPratica.flatten().groupBy { it.oggetto }
		def l = []
		for (def oggettoPratica : oggettiPratica) {
			def newOp = [:]
			newOp.key = oggettoPratica.key.getDomainObject().toDTO()
			newOp.value = oggettoPratica.value
			newOp.key.oggettiPratica = new TreeSet<OggettoPraticaDTO>(newOp.value)
			l << newOp.key
		}
		return l
	}

	List<OggettoDTO> getOggettiTasi() {
		def oggettiPratica = praticheTasi.pratica.oggettiPratica.flatten().groupBy { it.oggetto }
		def l = []
		for (def oggettoPratica : oggettiPratica) {
			def newOp = [:]
			newOp.key = oggettoPratica.key.getDomainObject().toDTO()
			newOp.value = oggettoPratica.value
			newOp.key.oggettiPratica = new TreeSet<OggettoPraticaDTO>(newOp.value)
			l << newOp.key
		}
		return l
	}

	List<OggettoDTO> getOggettiTari() {
		def oggettiPratica = praticheTari.pratica.oggettiPratica.flatten().groupBy { it.oggetto }
		def l = []
		for (def oggettoPratica : oggettiPratica) {
			def newOp = [:]
			newOp.key = oggettoPratica.key.getDomainObject().toDTO()
			newOp.value = oggettoPratica.value
			newOp.key.oggettiPratica = new TreeSet<OggettoPraticaDTO>(newOp.value)
			l << newOp.key
		}
		return l
	}

	List<OggettoDTO> getOggettiCuni() {
		def oggettiPratica = praticheCuni.pratica.oggettiPratica.flatten().groupBy { it.oggetto }
		def l = []
		for (def oggettoPratica : oggettiPratica) {
			def newOp = [:]
			newOp.key = oggettoPratica.key.getDomainObject().toDTO()
			newOp.value = oggettoPratica.value
			newOp.key.oggettiPratica = new TreeSet<OggettoPraticaDTO>(newOp.value)
			l << newOp.key
		}
		return l
	}

}
