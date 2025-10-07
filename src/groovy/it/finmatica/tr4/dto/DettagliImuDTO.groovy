package it.finmatica.tr4.dto;

import it.finmatica.tr4.DettagliImu;

import java.util.Map;

public class DettagliImuDTO implements it.finmatica.dto.DTO<DettagliImu> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal abComu;
    BigDecimal abComuAcc;
    BigDecimal altriComu;
    BigDecimal altriComuAcc;
    BigDecimal altriErar;
    BigDecimal altriErarAcc;
    Short anno;
    BigDecimal areeComu;
    BigDecimal areeComuAcc;
    BigDecimal areeErar;
    BigDecimal areeErarAcc;
    String codFiscale;
    String cognomeNome;
    BigDecimal detrComu;
    BigDecimal detrComuAcc;
    BigDecimal fabbDComu;
    BigDecimal fabbDComuAcc;
    BigDecimal fabbDErar;
    BigDecimal fabbDErarAcc;
    BigDecimal impostaComu;
    BigDecimal impostaComuAcc;
    BigDecimal impostaErar;
    BigDecimal impostaErarAcc;
    BigDecimal nFabAb;
    BigDecimal nFabAltri;
    BigDecimal nFabFabbD;
    BigDecimal nFabRurali;
    BigDecimal ruraliComu;
    BigDecimal ruraliComuAcc;
    BigDecimal terreniComu;
    BigDecimal terreniComuAcc;
    BigDecimal terreniErar;
    BigDecimal terreniErarAcc;
    BigDecimal versAbPrinc;
    BigDecimal versAbPrincAcc;
    BigDecimal versAltriComu;
    BigDecimal versAltriComuAcc;
    BigDecimal versAltriErar;
    BigDecimal versAltriErarAcc;
    BigDecimal versAreeComu;
    BigDecimal versAreeComuAcc;
    BigDecimal versAreeErar;
    BigDecimal versAreeErarAcc;
    BigDecimal versFabDComu;
    BigDecimal versFabDComuAcc;
    BigDecimal versFabDErar;
    BigDecimal versFabDErarAcc;
    BigDecimal versRurali;
    BigDecimal versRuraliAcc;
    BigDecimal versTerreniComu;
    BigDecimal versTerreniComuAcc;
    BigDecimal versTerreniErar;
    BigDecimal versTerreniErarAcc;
    BigDecimal versamentiComu;
    BigDecimal versamentiComuAcc;
    BigDecimal versamentiErar;
    BigDecimal versamentiErarAcc;


    public DettagliImu getDomainObject () {
        return DettagliImu.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('cognomeNome', this.cognomeNome)
            eq('anno', this.anno)
            eq('abComu', this.abComu)
            eq('abComuAcc', this.abComuAcc)
            eq('nFabAb', this.nFabAb)
            eq('detrComu', this.detrComu)
            eq('detrComuAcc', this.detrComuAcc)
            eq('ruraliComu', this.ruraliComu)
            eq('ruraliComuAcc', this.ruraliComuAcc)
            eq('nFabRurali', this.nFabRurali)
            eq('terreniComu', this.terreniComu)
            eq('terreniComuAcc', this.terreniComuAcc)
            eq('terreniErar', this.terreniErar)
            eq('terreniErarAcc', this.terreniErarAcc)
            eq('areeComu', this.areeComu)
            eq('areeComuAcc', this.areeComuAcc)
            eq('areeErar', this.areeErar)
            eq('areeErarAcc', this.areeErarAcc)
            eq('fabbDComu', this.fabbDComu)
            eq('fabbDComuAcc', this.fabbDComuAcc)
            eq('fabbDErar', this.fabbDErar)
            eq('fabbDErarAcc', this.fabbDErarAcc)
            eq('nFabFabbD', this.nFabFabbD)
            eq('altriComu', this.altriComu)
            eq('altriComuAcc', this.altriComuAcc)
            eq('altriErar', this.altriErar)
            eq('altriErarAcc', this.altriErarAcc)
            eq('nFabAltri', this.nFabAltri)
            eq('versAbPrinc', this.versAbPrinc)
            eq('versAbPrincAcc', this.versAbPrincAcc)
            eq('versRurali', this.versRurali)
            eq('versRuraliAcc', this.versRuraliAcc)
            eq('versAltriComu', this.versAltriComu)
            eq('versAltriComuAcc', this.versAltriComuAcc)
            eq('versAltriErar', this.versAltriErar)
            eq('versAltriErarAcc', this.versAltriErarAcc)
            eq('versTerreniComu', this.versTerreniComu)
            eq('versTerreniComuAcc', this.versTerreniComuAcc)
            eq('versTerreniErar', this.versTerreniErar)
            eq('versTerreniErarAcc', this.versTerreniErarAcc)
            eq('versAreeComu', this.versAreeComu)
            eq('versAreeComuAcc', this.versAreeComuAcc)
            eq('versAreeErar', this.versAreeErar)
            eq('versAreeErarAcc', this.versAreeErarAcc)
            eq('versFabDComu', this.versFabDComu)
            eq('versFabDComuAcc', this.versFabDComuAcc)
            eq('versFabDErar', this.versFabDErar)
            eq('versFabDErarAcc', this.versFabDErarAcc)
            eq('impostaComu', this.impostaComu)
            eq('impostaComuAcc', this.impostaComuAcc)
            eq('impostaErar', this.impostaErar)
            eq('impostaErarAcc', this.impostaErarAcc)
            eq('versamentiComu', this.versamentiComu)
            eq('versamentiComuAcc', this.versamentiComuAcc)
            eq('versamentiErar', this.versamentiErar)
            eq('versamentiErarAcc', this.versamentiErarAcc)
        }
    }
    public DettagliImu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
