package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cufisica;

import java.util.Map;

public class CufisicaDTO implements it.finmatica.dto.DTO<Cufisica> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codFiscale;
    String codTitolo;
    String codice;
    String cognome;
    String cognomeNomeRic;
    String dataNascita;
    String denominatore;
    String desTitolo;
    String indSupplementari;
    String luogoNascita;
    String nome;
    String numeratore;
    Integer partita;
    Boolean sesso;


    public Cufisica getDomainObject () {
        return Cufisica.createCriteria().get {
            eq('codice', this.codice)
            eq('partita', this.partita)
            eq('cognome', this.cognome)
            eq('nome', this.nome)
            eq('indSupplementari', this.indSupplementari)
            eq('codTitolo', this.codTitolo)
            eq('numeratore', this.numeratore)
            eq('denominatore', this.denominatore)
            eq('desTitolo', this.desTitolo)
            eq('sesso', this.sesso)
            eq('dataNascita', this.dataNascita)
            eq('luogoNascita', this.luogoNascita)
            eq('codFiscale', this.codFiscale)
            eq('cognomeNomeRic', this.cognomeNomeRic)
        }
    }
    public Cufisica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
