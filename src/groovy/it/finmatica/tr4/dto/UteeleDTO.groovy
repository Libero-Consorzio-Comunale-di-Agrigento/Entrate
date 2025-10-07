package it.finmatica.tr4.dto;

import it.finmatica.tr4.Uteele;

import java.util.Map;

public class UteeleDTO implements it.finmatica.dto.DTO<Uteele> {
    private static final long serialVersionUID = 1L;

    Long id;
    String cap;
    String capRecapito;
    String codAttivita;
    String codContratto;
    String codFiscale;
    String consumo;
    String dataAllacciamento;
    String dataContratto;
    Integer ente;
    String indirizzoRecapito;
    String localita;
    String localitaRecapito;
    String nomeVia;
    String nominativo;
    String nominativoRecapito;
    BigDecimal potenza;
    String semestre;
    String statoUtenza;
    String tipoUtente;
    String tipoUtenza;
    String tipoVia;
    String utenza;


    public Uteele getDomainObject () {
        return Uteele.createCriteria().get {
            eq('utenza', this.utenza)
            eq('ente', this.ente)
            eq('tipoUtente', this.tipoUtente)
            eq('nominativo', this.nominativo)
            eq('codFiscale', this.codFiscale)
            eq('tipoVia', this.tipoVia)
            eq('nomeVia', this.nomeVia)
            eq('localita', this.localita)
            eq('cap', this.cap)
            eq('tipoUtenza', this.tipoUtenza)
            eq('statoUtenza', this.statoUtenza)
            eq('codAttivita', this.codAttivita)
            eq('potenza', this.potenza)
            eq('consumo', this.consumo)
            eq('dataAllacciamento', this.dataAllacciamento)
            eq('dataContratto', this.dataContratto)
            eq('codContratto', this.codContratto)
            eq('nominativoRecapito', this.nominativoRecapito)
            eq('indirizzoRecapito', this.indirizzoRecapito)
            eq('localitaRecapito', this.localitaRecapito)
            eq('capRecapito', this.capRecapito)
            eq('semestre', this.semestre)
        }
    }
    public Uteele toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
