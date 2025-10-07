package it.finmatica.tr4.dto.pratiche

import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.PraticaTributo

class PraticaTributoDTO implements DTO<PraticaTributo>, Comparable<PraticaTributoDTO> {
    private static final long serialVersionUID = 1L

    Long id
    short anno
    String codFiscaleDen
    Ad4ComuneTr4DTO comuneDenunciante
    ContribuenteDTO contribuente
    Date data
    Date dataNotifica
    TipoNotificaDTO tipoNotifica
    Date lastUpdated
    String denunciante
    So4AmministrazioneDTO ente
    Set<FamiliarePraticaDTO> familiariPratica
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
    SortedSet<OggettoPraticaDTO> oggettiPratica
    String partitaIvaDen
    PraticaTributoDTO praticaTributoRif
    Set<RapportoTributoDTO> rapportiTributo
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
    String tipoRavvedimento
    String utente
    String flagDePag
    Long documentoId
    String calcoloRate
    boolean flagIntRateSoloEvasa
    String tipoViolazione
    Date dataScadenza
    boolean flagRateOneri
    Date scadenzaPrimaRata
    Date dataRiferimentoRavvedimento

    Set<WebCalcoloIndividualeDTO> webCalcoliIndividuale
    Set<ContattoContribuenteDTO> contattiContribuente

    Set<VersamentoDTO> versamenti
    Set<SanzionePraticaDTO> sanzioniPratica
    Set<IterPraticaDTO> iter
    Set<RuoloContribuenteDTO> ruoliContribuente
    Set<DebitoRavvedimentoDTO> debitiRavvedimento

    def rate

    void addToSanzioniPratica(SanzionePraticaDTO sanzionePratica) {
        if (this.sanzioniPratica == null)
            this.sanzioniPratica = new HashSet<SanzionePraticaDTO>()
        this.sanzioniPratica.add(sanzionePratica)
        sanzionePratica.id = this
    }

    void removeFromSanzioniPratica(SanzionePraticaDTO sanzionePratica) {
        if (this.sanzioniPratica == null)
            this.sanzioniPratica = new HashSet<SanzionePraticaDTO>()
        this.sanzioniPratica.remove(sanzionePratica)
        sanzionePratica.id = null
    }

    void addToFamiliariPratica(FamiliarePraticaDTO familiarePratica) {
        if (this.familiariPratica == null)
            this.familiariPratica = new HashSet<FamiliarePraticaDTO>()
        this.familiariPratica.add(familiarePratica)
        familiarePratica.pratica = this
    }

    void removeFromFamiliariPratica(FamiliarePraticaDTO familiarePratica) {
        if (this.familiariPratica == null)
            this.familiariPratica = new HashSet<FamiliarePraticaDTO>()
        this.familiariPratica.remove(familiarePratica)
        familiarePratica.pratica = null
    }

    void addToNotificheOggetto(NotificaOggettoDTO notificaOggetto) {
        if (this.notificheOggetto == null)
            this.notificheOggetto = new HashSet<NotificaOggettoDTO>()
        this.notificheOggetto.add(notificaOggetto)
        notificaOggetto.pratica = this
    }

    void removeFromNotificheOggetto(NotificaOggettoDTO notificaOggetto) {
        if (this.notificheOggetto == null)
            this.notificheOggetto = new HashSet<NotificaOggettoDTO>()
        this.notificheOggetto.remove(notificaOggetto)
        notificaOggetto.pratica = null
    }

    void addToOggettiPratica(OggettoPraticaDTO oggettoPratica) {
        if (this.oggettiPratica == null)
            this.oggettiPratica = new TreeSet<OggettoPraticaDTO>()
        this.oggettiPratica.add(oggettoPratica)
        oggettoPratica.pratica = this
    }

    void removeFromOggettiPratica(OggettoPraticaDTO oggettoPratica) {
        if (this.oggettiPratica == null)
            this.oggettiPratica = new TreeSet<OggettoPraticaDTO>()
        this.oggettiPratica.remove(oggettoPratica)
        oggettoPratica.pratica = null
    }

    void addToRapportiTributo(RapportoTributoDTO rapportoTributo) {
        if (this.rapportiTributo == null)
            this.rapportiTributo = new HashSet<RapportoTributoDTO>()
        this.rapportiTributo.add(rapportoTributo)
        rapportoTributo.pratica = this
    }

    void removeFromRapportiTributo(RapportoTributoDTO rapportoTributo) {
        if (this.rapportiTributo == null)
            this.rapportiTributo = new HashSet<RapportoTributoDTO>()
        this.rapportiTributo.remove(rapportoTributo)
        rapportoTributo.pratica = null
    }

    void addToVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.add(versamento)
        versamento.pratica = this
    }

    void removeFromVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.remove(versamento)
        versamento.pratica = null
    }

    void addToContattiContribuente(ContattoContribuenteDTO contattoContribuente) {
        if (this.contattiContribuente == null)
            this.contattiContribuente = new HashSet<ContattoContribuenteDTO>()
        this.contattiContribuente.add(contattoContribuente)
        contattoContribuente.pratica = this
    }

    void removeFromContattiContribuente(ContattoContribuenteDTO contattoContribuente) {
        if (this.contattiContribuente == null)
            this.contattiContribuente = new HashSet<ContattoContribuenteDTO>()
        this.contattiContribuente.remove(contattoContribuente)
        contattoContribuente.pratica = null
    }

    void addToWebCalcoliIndividuale(WebCalcoloIndividualeDTO webCalcoloIndividuale) {
        if (this.webCalcoliIndividuale == null)
            this.webCalcoliIndividuale = new HashSet<WebCalcoloIndividualeDTO>()
        this.webCalcoliIndividuale.add(webCalcoloIndividuale)
        webCalcoloIndividuale.pratica = this
    }

    void removeFromWebCalcoliIndividuale(WebCalcoloIndividualeDTO webCalcoloIndividuale) {
        if (this.webCalcoliIndividuale == null)
            this.webCalcoliIndividuale = new HashSet<WebCalcoloIndividualeDTO>()
        this.webCalcoliIndividuale.remove(webCalcoloIndividuale)
        webCalcoloIndividuale.pratica = null
    }

    PraticaTributo getDomainObject() {
        return PraticaTributo.get(this.id)
    }

    PraticaTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    Set<OggettoContribuenteDTO> getOggettiContribuente() {
        oggettiPratica.oggettiContribuente.flatten()
    }

    int compareTo(PraticaTributoDTO obj) {
        obj.anno <=> anno ?: id <=> obj.id
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    void setWebCalcoloIndividuale(WebCalcoloIndividualeDTO webCalcoloIndividuale) {
        addToWebCalcoliIndividuale(webCalcoloIndividuale)
    }

    WebCalcoloIndividualeDTO getWebCalcoloIndividuale() {
        (webCalcoliIndividuale?.empty) ? null : webCalcoliIndividuale?.getAt(0)
    }

    void setContattoContribuente(ContattoContribuenteDTO contattoContribuente) {
        addToContattiContribuente(contattoContribuente)
    }

    ContattoContribuenteDTO getContattoContribuente() {
        (contattiContribuente?.empty) ? null : contattiContribuente?.getAt(0)
    }

    def getPratica() {
        return id
    }

//	public Ad4ComuneDTO getComuneDenunciante() {
//		getDomainObject().getAd4ComuneDenunciante()?.toDTO()
//	}
//	
//	public void setComuneDenunciante(Ad4ComuneDTO com) {
//		this.codComDen = com?.comune
//		this.codProDen = com?.provincia?.id
//	}
}
