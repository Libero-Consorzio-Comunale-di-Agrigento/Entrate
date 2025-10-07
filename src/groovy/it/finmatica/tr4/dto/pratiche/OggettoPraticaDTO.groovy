package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.OggettoPratica

class OggettoPraticaDTO implements DTO<OggettoPratica>, Comparable<OggettoPraticaDTO> {
    private static final long serialVersionUID = 1L

    OggettoPraticaRenditaDTO oggettoPraticaRendita
    Long id
    BigDecimal aChilometro
    AssenzaEstremiCatasto assenzaEstremiCatasto
    CategoriaCatastoDTO categoriaCatasto
    String classeCatasto
    Short codComOcc
    Short codProOcc
    BigDecimal consistenza
    BigDecimal consistenzaReale
    BigDecimal coperta
    Set<CostoStoricoDTO> costiStorici
    BigDecimal daChilometro
    Date dataAnagrafeTributaria
    Date dataConcessione
    Date lastUpdated
    DestinazioneUso destinazioneUso
    String estremiTitolo
    Date fineConcessione
    boolean flagProvvisorio
    boolean flagValoreRivalutato
    boolean flagFirma
    boolean flagUipPrincipale
    boolean flagDomicilioFiscale
    boolean flagContenzioso
    FonteDTO fonte
    boolean immStorico
    BigDecimal impostaBase
    BigDecimal impostaDovuta
    String indirizzoOcc
    Date inizioConcessione
    BigDecimal larghezza
    String lato
    BigDecimal locale
    Short modello
    NaturaOccupazione naturaOccupazione
    String note
    Integer numConcessione
    String numOrdine
    Short numeroFamiliari
    OggettoDTO oggetto
    OggettoPraticaDTO oggettoPraticaRif
    OggettoPraticaDTO oggettoPraticaRifAp
    OggettoPraticaDTO oggettoPraticaRifV
    Set<PartizioneOggettoPraticaDTO> partizioniOggettoPratica
    PraticaTributoDTO pratica
    BigDecimal profondita
    String qualita
    Integer quantita
    BigDecimal reddito
    BigDecimal scoperta
    TariffaDTO tariffa
    TipoOccupazione tipoOccupazione
    TipoOggettoDTO tipoOggetto
    Short tipoQualita
    String titolo
    TitoloOccupazione titoloOccupazione
    String utente
    BigDecimal valore
    Short anno
    CodiceTributoDTO codiceTributo
    Short tipoTariffa
    CategoriaDTO categoria
    Short tipoCategoria

    String flagDatiMetrici
    BigDecimal percRiduzioneSup
    
	boolean flagNullaOsta
	
    Set<OggettoContribuenteDTO> oggettiContribuente
    Set<OggettoOgimDTO> oggettiOgim

    void addToCostiStorici(CostoStoricoDTO costoStorico) {
        if (this.costiStorici == null)
            this.costiStorici = new HashSet<CostoStoricoDTO>()
        this.costiStorici.add(costoStorico)
        costoStorico.oggettoPratica = this
    }

    void removeFromCostiStorici(CostoStoricoDTO costoStorico) {
        if (this.costiStorici == null)
            this.costiStorici = new HashSet<CostoStoricoDTO>()
        this.costiStorici.remove(costoStorico)
        costoStorico.oggettoPratica = null
    }

    void addToPartizioniOggettoPratica(PartizioneOggettoPraticaDTO partizioneOggettoPratica) {
        if (this.partizioniOggettoPratica == null)
            this.partizioniOggettoPratica = new HashSet<PartizioneOggettoPraticaDTO>()
        this.partizioniOggettoPratica.add(partizioneOggettoPratica)
        partizioneOggettoPratica.oggettoPratica = this
    }

    void removeFromPartizioniOggettoPratica(PartizioneOggettoPraticaDTO partizioneOggettoPratica) {
        if (this.partizioniOggettoPratica == null)
            this.partizioniOggettoPratica = new HashSet<PartizioneOggettoPraticaDTO>()
        this.partizioniOggettoPratica.remove(partizioneOggettoPratica)
        partizioneOggettoPratica.oggettoPratica = null
    }

    void addToOggettiContribuente(OggettoContribuenteDTO oggettoContribuente) {
        if (this.oggettiContribuente == null)
            this.oggettiContribuente = new HashSet<OggettoContribuenteDTO>()
        this.oggettiContribuente.add(oggettoContribuente)
        oggettoContribuente.oggettoPratica = this
    }

    void removeFromOggettiContribuente(OggettoContribuenteDTO oggettoContribuente) {
        if (this.oggettiContribuente == null)
            this.oggettiContribuente = new HashSet<OggettoContribuenteDTO>()
        this.oggettiContribuente.remove(oggettoContribuente)
        oggettoContribuente.oggettoPratica = null
    }

    OggettoPratica getDomainObject() {
        return OggettoPratica.get(this.id)
    }

    OggettoPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    BigDecimal getRenditaDaRiferimenti() {
        return getDomainObject()?.getRenditaDaRiferimenti()
    }

    BigDecimal getValoreRivalutato() {
        return getDomainObject()?.getValoreRivalutato()
    }

    OggettoContribuenteDTO getSingoloOggettoContribuente(){
        return oggettiContribuente[0]
    }

    int compareTo(OggettoPraticaDTO obj) {
        obj.numOrdine <=> numOrdine ?: obj.id <=> id
    }
}
