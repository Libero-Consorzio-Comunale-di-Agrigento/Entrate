package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiContTerreni;

import java.util.Map;

public class SigaiContTerreniDTO implements it.finmatica.dto.DTO<SigaiContTerreni> {
    private static final long serialVersionUID = 1L;

    Long id;
    String cfContitolare;
    String dataSit;
    String fiscale;
    String flagCf;
    String invio;
    String istatCom;
    String numOrdine;
    String partCatast;
    String perQPoss;
    String progMod;
    String progressivo;
    String recoModificato;


    public SigaiContTerreni getDomainObject () {
        return SigaiContTerreni.createCriteria().get {
            eq('istatCom', this.istatCom)
            eq('fiscale', this.fiscale)
            eq('dataSit', this.dataSit)
            eq('flagCf', this.flagCf)
            eq('progMod', this.progMod)
            eq('numOrdine', this.numOrdine)
            eq('partCatast', this.partCatast)
            eq('cfContitolare', this.cfContitolare)
            eq('perQPoss', this.perQPoss)
            eq('progressivo', this.progressivo)
            eq('invio', this.invio)
            eq('recoModificato', this.recoModificato)
        }
    }
    public SigaiContTerreni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
