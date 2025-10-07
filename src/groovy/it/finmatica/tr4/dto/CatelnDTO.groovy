package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cateln;

import java.util.Map;

public class CatelnDTO implements it.finmatica.dto.DTO<Cateln> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer capFor;
    Integer capRec;
    String codAmm;
    String codAttivita;
    String codAzienda;
    String codCatastale;
    Short codComFor;
    String codFiscale;
    Boolean codIntestatario;
    Byte codProFor;
    Long codUtente;
    String cognomeNome;
    String indirizzoFor;
    String indirizzoRec;
    String internoFor;
    String localitaFor;
    String localitaRec;
    String nominativoRec;
    String pianoFor;
    String scalaFor;
    Boolean tipoUtenza;


    public Cateln getDomainObject () {
        return Cateln.createCriteria().get {
            eq('codAzienda', this.codAzienda)
            eq('codUtente', this.codUtente)
            eq('tipoUtenza', this.tipoUtenza)
            eq('codIntestatario', this.codIntestatario)
            eq('cognomeNome', this.cognomeNome)
            eq('codFiscale', this.codFiscale)
            eq('indirizzoFor', this.indirizzoFor)
            eq('scalaFor', this.scalaFor)
            eq('pianoFor', this.pianoFor)
            eq('internoFor', this.internoFor)
            eq('capFor', this.capFor)
            eq('localitaFor', this.localitaFor)
            eq('codProFor', this.codProFor)
            eq('codComFor', this.codComFor)
            eq('codCatastale', this.codCatastale)
            eq('codAmm', this.codAmm)
            eq('nominativoRec', this.nominativoRec)
            eq('indirizzoRec', this.indirizzoRec)
            eq('capRec', this.capRec)
            eq('localitaRec', this.localitaRec)
            eq('codAttivita', this.codAttivita)
        }
    }
    public Cateln toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
