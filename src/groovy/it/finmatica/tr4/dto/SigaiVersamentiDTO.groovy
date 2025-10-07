package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiVersamenti;

import java.util.Map;

public class SigaiVersamentiDTO implements it.finmatica.dto.DTO<SigaiVersamenti> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abitPrincip;
    String altriFabbric;
    String annoFiscaleImm;
    String areeFabbrica;
    String capImmobile;
    String comuneImmob;
    String concessione;
    String dataVersame;
    String exRurale;
    String fiscale;
    String flagAcconto;
    String flagSaldo;
    String impDetAbPr;
    String impTerrAgr;
    String invio;
    String istatCom;
    String numFabbricati;
    String progressivo;
    String recoModificato;
    String totaleImp;


    public SigaiVersamenti getDomainObject () {
        return SigaiVersamenti.createCriteria().get {
            eq('concessione', this.concessione)
            eq('fiscale', this.fiscale)
            eq('dataVersame', this.dataVersame)
            eq('comuneImmob', this.comuneImmob)
            eq('istatCom', this.istatCom)
            eq('capImmobile', this.capImmobile)
            eq('numFabbricati', this.numFabbricati)
            eq('annoFiscaleImm', this.annoFiscaleImm)
            eq('flagAcconto', this.flagAcconto)
            eq('flagSaldo', this.flagSaldo)
            eq('impTerrAgr', this.impTerrAgr)
            eq('areeFabbrica', this.areeFabbrica)
            eq('abitPrincip', this.abitPrincip)
            eq('altriFabbric', this.altriFabbric)
            eq('impDetAbPr', this.impDetAbPr)
            eq('totaleImp', this.totaleImp)
            eq('progressivo', this.progressivo)
            eq('invio', this.invio)
            eq('exRurale', this.exRurale)
            eq('recoModificato', this.recoModificato)
        }
    }
    public SigaiVersamenti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
