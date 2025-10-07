package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO 

public class OggettoDTO implements DTO<Oggetto> {
    private static final long serialVersionUID = 1L

    Long id
    Short annoCatasto
    ArchivioVieDTO archivioVie
    Byte are
    CategoriaCatastoDTO categoriaCatasto
    Byte centiare
    SortedSet<CivicoOggettoDTO> civiciOggetto
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
    TreeSet<NotificaOggettoDTO> notificheOggetto
    Integer numCiv
    String numero
	String numeroPadded
    SortedSet<OggettoPraticaDTO> oggettiPratica
    String partita
	String partitaPadded
    SortedSet<PartizioneOggettoDTO> partizioniOggetto
    String piano
    Integer progrPartita
    String protocolloCatasto
    String qualita
    SortedSet<RiferimentoOggettoDTO> riferimentiOggetto
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
    SortedSet<UtilizzoOggettoDTO> utilizziOggetto
    BigDecimal vani
    String zona
	String zonaPadded
    BigDecimal idImmobile
    SortedSet<CodiceRfidDTO> codiciRfid

    BigDecimal latitudine
    BigDecimal longitudine
	BigDecimal aLatitudine
	BigDecimal aLongitudine

    public void addToCiviciOggetto (CivicoOggettoDTO civicoOggetto) {
        if (this.civiciOggetto == null)
            this.civiciOggetto = new TreeSet<CivicoOggettoDTO>()
        this.civiciOggetto.add (civicoOggetto)
        civicoOggetto.oggetto = this
    }

    public void removeFromCiviciOggetto (CivicoOggettoDTO civicoOggetto) {
        if (this.civiciOggetto == null)
            this.civiciOggetto = new TreeSet<CivicoOggettoDTO>()
        this.civiciOggetto.remove (civicoOggetto)
        civicoOggetto.oggetto = null
    }
	
    public void addToNotificheOggetto (NotificaOggettoDTO notificaOggetto) {
        if (this.notificheOggetto == null)
            this.notificheOggetto = new TreeSet<NotificaOggettoDTO>()
        this.notificheOggetto.add (notificaOggetto)
        notificaOggetto.oggetto = this
    }

    public void removeFromNotificheOggetto (NotificaOggettoDTO notificaOggetto) {
        if (this.notificheOggetto == null)
            this.notificheOggetto = new TreeSet<NotificaOggettoDTO>()
        this.notificheOggetto.remove (notificaOggetto)
        notificaOggetto.oggetto = null
    }
    public void addToOggettiPratica (OggettoPraticaDTO oggettoPratica) {
        if (this.oggettiPratica == null)
            this.oggettiPratica = new TreeSet<OggettoPraticaDTO>()
        this.oggettiPratica.add (oggettoPratica)
        oggettoPratica.oggetto = this
    }

    public void removeFromOggettiPratica (OggettoPraticaDTO oggettoPratica) {
        if (this.oggettiPratica == null)
            this.oggettiPratica = new TreeSet<OggettoPraticaDTO>()
        this.oggettiPratica.remove (oggettoPratica)
        oggettoPratica.oggetto = null
    }
    public void addToPartizioniOggetto (PartizioneOggettoDTO partizioneOggetto) {
        if (this.partizioniOggetto == null)
            this.partizioniOggetto = new TreeSet<PartizioneOggettoDTO>()
        this.partizioniOggetto.add (partizioneOggetto)
        partizioneOggetto.oggetto = this
    }

    public void removeFromPartizioniOggetto (PartizioneOggettoDTO partizioneOggetto) {
        if (this.partizioniOggetto == null)
            this.partizioniOggetto = new TreeSet<PartizioneOggettoDTO>()
        this.partizioniOggetto.remove (partizioneOggetto)
        partizioneOggetto.oggetto = null
    }
    public void addToRiferimentiOggetto (RiferimentoOggettoDTO riferimentoOggetto) {
        if (this.riferimentiOggetto == null)
            this.riferimentiOggetto = new TreeSet<RiferimentoOggettoDTO>()
        this.riferimentiOggetto.add (riferimentoOggetto)
        riferimentoOggetto.oggetto = this
    }

    public void removeFromRiferimentiOggetto (RiferimentoOggettoDTO riferimentoOggetto) {
        if (this.riferimentiOggetto == null)
            this.riferimentiOggetto = new TreeSet<RiferimentoOggettoDTO>()
        this.riferimentiOggetto.remove (riferimentoOggetto)
        riferimentoOggetto.oggetto = null
    }
    public void addToUtilizziOggetto (UtilizzoOggettoDTO utilizzoOggetto) {
        if (this.utilizziOggetto == null)
            this.utilizziOggetto = new TreeSet<UtilizzoOggettoDTO>()
        this.utilizziOggetto.add (utilizzoOggetto)
        utilizzoOggetto.oggetto = this
    }

    public void removeFromUtilizziOggetto (UtilizzoOggettoDTO utilizzoOggetto) {
        if (this.utilizziOggetto == null)
            this.utilizziOggetto = new TreeSet<UtilizzoOggettoDTO>()
        this.utilizziOggetto.remove (utilizzoOggetto)
        utilizzoOggetto.oggetto = null
    }

    public void addToCodiciRfid(CodiceRfidDTO codiceRfid) {
        if (this.codiciRfid == null)
            this.codiciRfid = new TreeSet<CodiceRfidDTO>()
        this.codiciRfid.add(codiceRfid)
        codiceRfid.oggetto = this
    }

    public void removeFromCodiciRfid(CodiceRfidDTO codiceRfid) {
        if (this.codiciRfid == null)
            this.codiciRfid = new TreeSet<CodiceRfidDTO>()
        this.codiciRfid.remove(codiceRfid)
        codiceRfid.oggetto = null
    }

    public Oggetto getDomainObject () {
        return Oggetto.get(this.id)
    }
    public Oggetto toDomain(Map overrides = [:]) {
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

    public String getIndirizzoCompleto() {
        String indirizzoCompleto = archivioVie? archivioVie?.denomUff : indirizzoLocalita ?: ""
        if (!indirizzoCompleto.isEmpty()) {
            indirizzoCompleto += (numCiv ? ", $numCiv" : "") + (suffisso ? "/$suffisso" : "")  + (scala ? " Sc: $scala" : "") + (piano ? " P: $piano" : "") + (interno ? " Int: $interno" : "")
        }
        return indirizzoCompleto
    }
	
	public List<OggettoContribuenteDTO> getOggettiContribuente() {
		return oggettiPratica.oggettiContribuente.flatten()
	}
	
	public List<RuoloContribuenteDTO> getRuoliOggetto() {
		return oggettiPratica.oggettiContribuente.ruoliOggetto.flatten()
	}
	
}
