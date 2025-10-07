package it.finmatica.as4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.ad4.dto.dizionari.Ad4ProvinciaDTO
import it.finmatica.ad4.dto.dizionari.Ad4StatoDTO
import it.finmatica.as4.As4SoggettoCorrente
import it.finmatica.dto.DtoToEntityUtils

public class As4SoggettoCorrenteDTO implements it.finmatica.dto.DTO<As4SoggettoCorrente> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    String capDomicilio;
    String capResidenza;
    String cittadinanza;
    String codiceFiscale;
    String codiceFiscaleEstero;
    String cognome;
    String competenza;
    String competenzaEsclusiva;
    Ad4ComuneDTO comuneDomicilio;
    Ad4ComuneDTO comuneNascita;
    Ad4ComuneDTO comuneResidenza;
    Date dal;
    Date dataAggiornamento;
    Date dataNascita;
    String denominazione;
    String faxDomicilio;
    String faxResidenza;
    String indirizzoDomicilio;
    String indirizzoResidenza;
    String indirizzoWeb;
    String luogoNascita;
    String nome;
    String note;
    String partitaIva;
    String presso;
    Ad4ProvinciaDTO provinciaDomicilio;
    Ad4ProvinciaDTO provinciaNascita;
    Ad4ProvinciaDTO provinciaResidenza;
    String sesso;
    Ad4StatoDTO statoDomicilio;
    Ad4StatoDTO statoNascita;
    Ad4StatoDTO statoResidenza;
    String telefonoDomicilio;
    String telefonoResidenza;
    As4TipoSoggettoDTO tipoSoggetto;
    Ad4UtenteDTO utenteAd4;
    Ad4UtenteDTO utenteAggiornamento;


    public As4SoggettoCorrente getDomainObject () {
        return As4SoggettoCorrente.get(this.id)
    }
    public As4SoggettoCorrente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
