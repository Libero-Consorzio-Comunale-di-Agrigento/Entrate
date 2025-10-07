package it.finmatica.tr4.dto

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.RiferimentoOggettoBk

public class RiferimentoOggettoBkDTO implements it.finmatica.dto.DTO<RiferimentoOggettoBk>, Comparable<RiferimentoOggettoBkDTO> {
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
    Short sequenza;
    String note;
    OggettoDTO oggetto;
    BigDecimal rendita;
    Ad4UtenteDTO utente;
    Ad4UtenteDTO utenteRiog;
    Date dataVariazioneRiog;


    public RiferimentoOggettoBk getDomainObject () {
        return RiferimentoOggettoBk.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('inizioValidita', this.inizioValidita)
            eq('sequenza', this.sequenza)
        }
    }
    public RiferimentoOggettoBk toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	@Override
	public int compareTo(RiferimentoOggettoBkDTO ro) {
		oggetto?.id		<=> (ro.oggetto?.id)?:
		inizioValidita	<=> ro.inizioValidita
        sequenza 	    <=> ro.sequenza
	}

}
