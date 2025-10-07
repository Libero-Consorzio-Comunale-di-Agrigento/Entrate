package it.finmatica.so4.dto.struttura;

import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.ad4.dto.dizionari.Ad4ProvinciaDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.struttura.So4AOO

public class So4AOODTO implements it.finmatica.dto.DTO<So4AOO> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abbreviazione;
    Date al;
    So4AmministrazioneDTO amministrazione;
    String cap;
    String codice;
    Ad4ComuneDTO comune;
    Date dal;
    String descrizione;
    String fax;
    String indirizzo;
    Long progr_aoo;
    Ad4ProvinciaDTO provincia;
    String telefono;


    public So4AOO getDomainObject () {
        return So4AOO.createCriteria().get {
            eq('progr_aoo', this.progr_aoo)
            eq('dal', this.dal)
        }
    }
    public So4AOO toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
