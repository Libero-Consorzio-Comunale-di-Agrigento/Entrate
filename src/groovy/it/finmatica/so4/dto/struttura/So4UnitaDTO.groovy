package it.finmatica.so4.dto.struttura;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.struttura.So4Unita

public class So4UnitaDTO implements it.finmatica.dto.DTO<So4Unita> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date al;
    So4AmministrazioneDTO amministrazione;
    Boolean assegnazioneComponenti;
    String centroCosto;
    Boolean centroResponsabilita;
    String codice;
    String codiceAoo;
    Date dal;
    String descrizione;
    String etichetta;
    So4OtticaDTO ottica;
    Long progr;
    Long progrPadre;
    Integer revisione;
    Integer revisioneCessazione;
    Boolean seGiuridico;
    Integer sequenza;
    So4SuddivisioneStrutturaDTO suddivisione;
    String tagMail;
    String tipoUnita;
    String tipologia;
    Ad4UtenteDTO utenteAd4;


    public So4Unita getDomainObject () {
        return So4Unita.createCriteria().get {
            eq('progr', this.progr)
            eq('dal', this.dal)
            eq('ottica.codice', this.ottica.codice)
        }
    }
    public So4Unita toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
