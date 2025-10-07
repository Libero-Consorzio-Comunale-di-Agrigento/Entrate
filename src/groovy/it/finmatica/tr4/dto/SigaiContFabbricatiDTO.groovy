package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiContFabbricati;

import java.util.Map;

public class SigaiContFabbricatiDTO implements it.finmatica.dto.DTO<SigaiContFabbricati> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abitPrin;
    String annoDeAcc;
    String dataSit;
    String fiscCont;
    String fiscale;
    String flagPossesso;
    String flagcf;
    String foglio;
    String impoDetrazAbPr;
    String invio;
    String istatCom;
    String numOrd;
    String numero;
    String percPoss;
    String progMod;
    String progressivo;
    String protocollo;
    String recoModificato;
    String sezione;
    String subalterno;


    public SigaiContFabbricati getDomainObject () {
        return SigaiContFabbricati.createCriteria().get {
            eq('fiscale', this.fiscale)
            eq('dataSit', this.dataSit)
            eq('progMod', this.progMod)
            eq('numOrd', this.numOrd)
            eq('istatCom', this.istatCom)
            eq('sezione', this.sezione)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('protocollo', this.protocollo)
            eq('annoDeAcc', this.annoDeAcc)
            eq('fiscCont', this.fiscCont)
            eq('flagcf', this.flagcf)
            eq('percPoss', this.percPoss)
            eq('abitPrin', this.abitPrin)
            eq('progressivo', this.progressivo)
            eq('invio', this.invio)
            eq('impoDetrazAbPr', this.impoDetrazAbPr)
            eq('flagPossesso', this.flagPossesso)
            eq('recoModificato', this.recoModificato)
        }
    }
    public SigaiContFabbricati toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
