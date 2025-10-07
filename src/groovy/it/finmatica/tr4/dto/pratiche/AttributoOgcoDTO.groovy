package it.finmatica.tr4.dto.pratiche;

import it.finmatica.ad4.dizionari.Ad4Comune;
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.commons.TipoEsitoNota
import it.finmatica.tr4.commons.TipoRegime
import it.finmatica.tr4.dto.CodiceDirittoDTO
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.datiesterni.DocumentoCaricatoDTO
import it.finmatica.tr4.pratiche.AttributoOgco

public class AttributoOgcoDTO implements it.finmatica.dto.DTO<AttributoOgco> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer codAtto;
    CodiceDirittoDTO codDiritto;
    String codEsito;
    ContribuenteDTO contribuente
    String codFiscaleRogante;
    Date dataRegAtti;
    Date dataValiditaAtto;
    Date lastUpdated;
    DocumentoCaricatoDTO documentoId;
    TipoEsitoNota esitoNota;
    String note;
    String numeroNota;
    String numeroRepertorio;
    OggettoPraticaDTO oggettoPratica;
    TipoRegime regime;
    String rogante;
    String sedeRogante;
    Ad4UtenteDTO	utente;
	OggettoContribuenteDTO oggettoContribuente
	Ad4ComuneDTO ad4Comune
	
    public AttributoOgco getDomainObject () {
        return AttributoOgco.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('oggettoPratica.id', this.oggettoPratica.id)
        }
    }
    public AttributoOgco toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
