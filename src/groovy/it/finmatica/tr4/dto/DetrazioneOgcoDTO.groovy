package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.DetrazioneOgco
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO

public class DetrazioneOgcoDTO implements it.finmatica.dto.DTO<DetrazioneOgco> {
    private static final long serialVersionUID = 1L;
    Short anno;
	Integer motDetrazione
	OggettoContribuenteDTO oggettoContribuente
	MotivoDetrazioneDTO motivoDetrazione
    BigDecimal detrazione;
    BigDecimal detrazioneAcconto;
	TipoTributoDTO tipoTributo
    String note;

    def uuid = UUID.randomUUID().toString().replace('-', '')
    boolean esistente = true
    boolean modificato = false
    boolean nuovo = false
    boolean annoCambiato = false
    Short annoPrecedente = null

    public DetrazioneOgco getDomainObject () {
		return DetrazioneOgco.createCriteria().get {
			eq('oggettoContribuente.contribuente.codFiscale', this.oggettoContribuente.contribuente.codFiscale)
            eq('oggettoContribuente.oggettoPratica.id', this.oggettoContribuente.oggettoPratica.id)
            eq('anno', this.anno)
        }
    }
    public DetrazioneOgco toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
