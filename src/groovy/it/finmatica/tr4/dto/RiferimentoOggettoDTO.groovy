package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.RiferimentoOggetto;

import java.util.Date;
import java.util.Map;

public class RiferimentoOggettoDTO implements it.finmatica.dto.DTO<RiferimentoOggetto>, Comparable<RiferimentoOggettoDTO> {
    private static final long serialVersionUID = 1L;

    Short aAnno;
    Short annoRendita;
    CategoriaCatastoDTO categoriaCatasto;
    String classeCatasto;
    Short daAnno;
    Date dataReg;
    Date dataRegAtti;
    Date lastUpdated;
    Date fineValidita;
    Date inizioValidita;
    String note;
    OggettoDTO oggetto;
    BigDecimal rendita;
    Ad4UtenteDTO	utente;

    def uuid = UUID.randomUUID().toString().replace('-', '')

    public RiferimentoOggetto getDomainObject () {
        return RiferimentoOggetto.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('inizioValidita', this.inizioValidita)
        }
    }
    public RiferimentoOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	@Override
	public int compareTo(RiferimentoOggettoDTO ro) {
		oggetto?.id		<=> (ro.oggetto?.id)?:
		inizioValidita	<=> ro.inizioValidita
	}

}
