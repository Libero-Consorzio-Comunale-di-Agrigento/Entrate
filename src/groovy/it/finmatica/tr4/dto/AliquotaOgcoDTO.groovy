package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.AliquotaOgco;
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO;

import java.util.Date;
import java.util.Map;

public class AliquotaOgcoDTO implements it.finmatica.dto.DTO<AliquotaOgco> {
    private static final long serialVersionUID = 1L;

    Long id;
	OggettoContribuenteDTO oggettoContribuente
    Date al;
    Date dal;
    String note;
    TipoAliquotaDTO tipoAliquota

    // Proprietà non salvate in DB
    def uuid = UUID.randomUUID().toString().replace('-', '')
    boolean esistente = true
    boolean modificato = false
    boolean nuovo = false
    boolean dataDalCambiata = false
    Date dataDalPrecedente = null

    public AliquotaOgco getDomainObject () {
		// println this.oggettoContribuente.contribuente.codFiscale
		// println this.oggettoContribuente.oggettoPratica.id
        return AliquotaOgco.createCriteria().get {
            eq('oggettoContribuente.contribuente.codFiscale', this.oggettoContribuente.contribuente.codFiscale)
            eq('oggettoContribuente.oggettoPratica.id', this.oggettoContribuente.oggettoPratica.id)
            eq('dal', this.dal)
        }
    }
    public AliquotaOgco toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
