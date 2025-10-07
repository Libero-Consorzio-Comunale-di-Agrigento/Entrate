package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.StoricoSoggetti;

import java.util.Date;
import java.util.Map;

public class StoricoSoggettiDTO implements it.finmatica.dto.DTO<StoricoSoggetti> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    Integer cap;
    Short codComNas;
    Short codComRap;
    Short codComRes;
    Long codFam;
    String codFiscale;
    String codFiscaleRap;
    Short codProNas;
    Short codProRap;
    Short codProRes;
    Integer codVia;
    String cognome;
    String cognomeNome;
    Date dal;
    Date dataNas;
    Date lastUpdated;
    String denominazioneVia;
    Byte fascia;
    FonteDTO fonte;
    String indirizzoRap;
    Byte interno;
    String intestatarioFam;
    Long niPresso;
    String nome;
    String note;
    Integer numCiv;
    String partitaIva;
    String piano;
    String rapportoPar;
    String rappresentante;
    String scala;
    Byte sequenzaPar;
    String sesso;
    SoggettoDTO soggetto;
    Byte stato;
    String suffisso;
    String tipo;
    Short tipoCarica;
    Ad4UtenteDTO	utente;


    public StoricoSoggetti getDomainObject () {
        return StoricoSoggetti.createCriteria().get {
            eq('soggetto.id', this.soggetto.id)
            eq('dal', this.dal)
        }
    }
    public StoricoSoggetti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
