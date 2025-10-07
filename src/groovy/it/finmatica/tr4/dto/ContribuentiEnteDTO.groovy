package it.finmatica.tr4.dto;

import it.finmatica.tr4.ContribuentiEnte;

import java.util.Date;
import java.util.Map;

public class ContribuentiEnteDTO implements it.finmatica.dto.DTO<ContribuentiEnte> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer codContribuente;
    Byte codControllo;
    String codFiscale;
    String codFiscaleRap;
    String codSesso;
    String cognomeNome;
    String comune;
    String comuneEnte;
    String comuneNascita;
    String comuneRap;
    Date dataNascita;
    String dataOdierna;
    String indirizzo;
    String indirizzoRap;
    Long ni;
    String presso;
    String provinciaEnte;
    String rappresentante;
    String sesso;
    String siglaEnte;
    String telefono;


    public ContribuentiEnte getDomainObject () {
        return ContribuentiEnte.createCriteria().get {
            eq('comuneEnte', this.comuneEnte)
            eq('siglaEnte', this.siglaEnte)
            eq('provinciaEnte', this.provinciaEnte)
            eq('cognomeNome', this.cognomeNome)
            eq('ni', this.ni)
            eq('codSesso', this.codSesso)
            eq('sesso', this.sesso)
            eq('codContribuente', this.codContribuente)
            eq('codControllo', this.codControllo)
            eq('codFiscale', this.codFiscale)
            eq('presso', this.presso)
            eq('indirizzo', this.indirizzo)
            eq('comune', this.comune)
            eq('telefono', this.telefono)
            eq('dataNascita', this.dataNascita)
            eq('comuneNascita', this.comuneNascita)
            eq('rappresentante', this.rappresentante)
            eq('codFiscaleRap', this.codFiscaleRap)
            eq('indirizzoRap', this.indirizzoRap)
            eq('comuneRap', this.comuneRap)
            eq('dataOdierna', this.dataOdierna)
        }
    }
    public ContribuentiEnte toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
