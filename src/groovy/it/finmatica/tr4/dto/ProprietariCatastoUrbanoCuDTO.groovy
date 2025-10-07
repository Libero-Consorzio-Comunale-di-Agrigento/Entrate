package it.finmatica.tr4.dto;

import it.finmatica.tr4.ProprietariCatastoUrbanoCu;

import java.util.Date;
import java.util.Map;

public class ProprietariCatastoUrbanoCuDTO implements it.finmatica.dto.DTO<ProprietariCatastoUrbanoCu> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codFiscale;
    String codFiscaleRic;
    String codTitolo;
    String cognomeNome;
    String cognomeNomeRic;
    Date dataNas;
    String denominatore;
    String desComNas;
    String desComSede;
    String desTitolo;
    Integer idImmobile;
    Integer idSoggetto;
    Integer idSoggettoRic;
    String numeratore;
    String partita;
    String siglaProNas;
    String siglaProSede;
    Character tipoImmobile;


    public ProprietariCatastoUrbanoCu getDomainObject () {
        return ProprietariCatastoUrbanoCu.createCriteria().get {
            eq('idImmobile', this.idImmobile)
            eq('idSoggetto', this.idSoggetto)
            eq('cognomeNome', this.cognomeNome)
            eq('desComSede', this.desComSede)
            eq('siglaProSede', this.siglaProSede)
            eq('codTitolo', this.codTitolo)
            eq('numeratore', this.numeratore)
            eq('denominatore', this.denominatore)
            eq('desTitolo', this.desTitolo)
            eq('dataNas', this.dataNas)
            eq('desComNas', this.desComNas)
            eq('siglaProNas', this.siglaProNas)
            eq('codFiscale', this.codFiscale)
            eq('tipoImmobile', this.tipoImmobile)
            eq('partita', this.partita)
            eq('cognomeNomeRic', this.cognomeNomeRic)
            eq('codFiscaleRic', this.codFiscaleRic)
            eq('idSoggettoRic', this.idSoggettoRic)
        }
    }
    public ProprietariCatastoUrbanoCu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
