package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cunonfis;

import java.util.Map;

public class CunonfisDTO implements it.finmatica.dto.DTO<Cunonfis> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codFiscale;
    String codTitolo;
    String codice;
    String denominatore;
    String denominazione;
    String denominazioneRic;
    String desTitolo;
    String numeratore;
    Integer partita;
    String sede;


    public Cunonfis getDomainObject () {
        return Cunonfis.createCriteria().get {
            eq('codice', this.codice)
            eq('partita', this.partita)
            eq('denominazione', this.denominazione)
            eq('sede', this.sede)
            eq('codFiscale', this.codFiscale)
            eq('codTitolo', this.codTitolo)
            eq('numeratore', this.numeratore)
            eq('denominatore', this.denominatore)
            eq('desTitolo', this.desTitolo)
            eq('denominazioneRic', this.denominazioneRic)
        }
    }
    public Cunonfis toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
