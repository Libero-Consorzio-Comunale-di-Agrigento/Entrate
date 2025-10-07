package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

import java.math.RoundingMode

public class OggettoContribuenteDTO implements DTO<OggettoContribuente> {
    private static final long serialVersionUID = 1L

    Long id
    Short anno
    ContribuenteDTO contribuente
    Date dataCessazione
    Date dataDecorrenza
    Date lastUpdated
    BigDecimal detrazione
    Date fineOccupazione
    boolean flagAbPrincipale
    boolean flagAlRidotta
    boolean flagEsclusione
    boolean flagPossesso
    boolean flagRiduzione
    boolean flagPuntoRaccolta
    Date inizioOccupazione
    Short mesiAliquotaRidotta
    Short mesiEsclusione
    Short mesiOccupato
    Short mesiOccupato1sem
    Short mesiPossesso
    Short mesiPossesso1sem
    Short mesiRiduzione
    String note
    OggettoPraticaDTO oggettoPratica
    BigDecimal percDetrazione
    BigDecimal percPossesso
    Integer progressivoSudv
    Long successione
    String tipoRapporto
    String tipoRapportoK
    String utente
	Short daMesePossesso
    Date dataEvento

    Set<DetrazioneOgcoDTO> detrazioniOgco
    Set<AliquotaOgcoDTO> aliquoteOgco
    Set<OggettoImpostaDTO> oggettiImposta
    Set<AttributoOgcoDTO> attributiOgco
    //Set<AnomaliaPraticaDTO> anomaliePratiche

    OggettoPraticaDTO oggettoPraticaId

    public OggettoContribuente getDomainObject() {
        return OggettoContribuente.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('oggettoPratica.id', this.oggettoPratica.id)
        }
    }

    public OggettoContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    public void addToDetrazioniOgco(DetrazioneOgcoDTO detrazioneOgco) {
        if (this.detrazioniOgco == null)
            this.detrazioniOgco = new HashSet<DetrazioneOgcoDTO>()
        this.detrazioniOgco.add(detrazioneOgco)
        detrazioneOgco.oggettoContribuente = this
    }

    public void removeFromDetrazioniOgco(DetrazioneOgcoDTO detrazioneOgco) {
        if (this.detrazioniOgco == null)
            this.detrazioniOgco = new HashSet<DetrazioneOgcoDTO>()
        this.detrazioniOgco.remove(detrazioneOgco)
        detrazioneOgco.oggettoContribuente = null
    }

    public void addToAliquoteOgco(AliquotaOgcoDTO aliquotaOgco) {
        if (this.aliquoteOgco == null)
            this.aliquoteOgco = new HashSet<AliquotaOgcoDTO>()
        this.aliquoteOgco.add(aliquotaOgco)
        aliquotaOgco.oggettoContribuente = this
    }

    public void removeFromAliquoteOgco(AliquotaOgcoDTO aliquotaOgco) {
        if (this.aliquoteOgco == null)
            this.aliquoteOgco = new HashSet<AliquotaOgcoDTO>()
        this.aliquoteOgco.remove(aliquotaOgco)
        aliquotaOgco.oggettoContribuente = null
    }

    public void addToOggettiImposta(OggettoImpostaDTO oggettoImposta) {
        if (this.oggettiImposta == null)
            this.oggettiImposta = new HashSet<OggettoImpostaDTO>()
        this.oggettiImposta.add(oggettoImposta)
        oggettoImposta.oggettoContribuente = this
    }

    public void removeFromOggettiImposta(OggettoImpostaDTO oggettoImposta) {
        if (this.oggettiImposta == null)
            this.oggettiImposta = new HashSet<OggettoImpostaDTO>()
        this.oggettiImposta.remove(oggettoImposta)
        oggettoImposta.oggettoContribuente = null
    }

    public void addToAttributiOgco(AttributoOgcoDTO attributoOgco) {
        if (this.attributiOgco == null)
            this.attributiOgco = new HashSet<AttributoOgcoDTO>()
        this.attributiOgco.add(attributoOgco)
        attributoOgco?.oggettoContribuente = this
    }

    public void removeFromAttributiOgco(AttributoOgcoDTO attributoOgco) {
        if (this.attributiOgco == null)
            this.attributiOgco = new HashSet<AttributoOgcoDTO>()
        this.attributiOgco.remove(attributoOgco)
        attributoOgco.oggettoContribuente = null
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
        if(contribuente)
          builder.append contribuente?.codFiscale, other.contribuente?.codFiscale
        builder.append oggettoPratica.id, other.oggettoPratica.id
        builder.isEquals()
    }

    public SortedSet<RuoloContribuenteDTO> getRuoliOggetto() {
        new TreeSet<RuoloContribuenteDTO>(oggettiImposta?.ruoliContribuente?.flatten())
    }

    public BigDecimal getImpostaLorda() {
        oggettiImposta?.flatten()?.sum {
            it.imposta.setScale(2, RoundingMode.HALF_UP) +
                    it.addizionaleEca.setScale(2, RoundingMode.HALF_UP) +
                    it.maggiorazioneEca.setScale(2, RoundingMode.HALF_UP) +
                    it.addizionalePro.setScale(2, RoundingMode.HALF_UP) +
                    it.iva.setScale(2, RoundingMode.HALF_UP)
        }
    }

    public BigDecimal getMaggiorazioneTares() {
        oggettiImposta?.flatten()?.sum { it.maggiorazioneTares }
    }

    public void setAttributoOgco(AttributoOgcoDTO attributoOgco) {
        addToAttributiOgco(attributoOgco)
    }

    public AttributoOgcoDTO getAttributoOgco() {
        (attributiOgco && !attributiOgco.isEmpty()) ? attributiOgco[0] : null
    }

    OggettoImpostaDTO getSingoloOggettoImposta(){
        return oggettiImposta[0]
    }
}
