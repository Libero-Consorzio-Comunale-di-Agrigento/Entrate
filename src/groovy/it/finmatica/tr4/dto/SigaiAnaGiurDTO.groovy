package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiAnaGiur;

import java.util.Map;

public class SigaiAnaGiurDTO implements it.finmatica.dto.DTO<SigaiAnaGiur> {
    private static final long serialVersionUID = 1L;

    Long id;
    String apprBil;
    String caaf;
    String capDomFi;
    String capFiscDenunc;
    String capRapLeg;
    String capSedeLeg;
    String caricaDenunc;
    String centroServizio;
    String codiceCari;
    String cognomeRapLeg;
    String comFiscDenunc;
    String comNasRapLe;
    String comuReRaLe;
    String comuneDomFi;
    String comuneSedeLeg;
    String dataCarica;
    String dataNasRapLe;
    String dataVariaz;
    String dataVariazDf;
    String denomDenunc;
    String denominaz;
    String domFiscDenunc;
    String eventiEcc;
    String fiSocIn;
    String fiscDenunc;
    String fiscRapLeg;
    String fiscale;
    String flag;
    String flagCf;
    String flagCfSIn;
    String flagRapLeg;
    String free;
    String indDomFi;
    String indRapLeg;
    String indSedeLeg;
    String istatCom;
    String istatComSl;
    String istatNasRapLe;
    String istatReRaLe;
    String modello;
    String naturaGiu;
    String nomeRapLeg;
    String presenta;
    String progMod;
    String progressivo;
    String provDomFi;
    String provReRaLe;
    String provSedeLeg;
    String prvFiscDenunc;
    String prvNasRapLe;
    String ragioneSoc;
    String recoModificato;
    String sessoRapLeg;
    String sigla;
    String situaz;
    String stato;
    String telDichiarante;
    String telPrefDichiar;
    String terBil;
    String uiidd;


    public SigaiAnaGiur getDomainObject () {
        return SigaiAnaGiur.createCriteria().get {
            eq('uiidd', this.uiidd)
            eq('centroServizio', this.centroServizio)
            eq('presenta', this.presenta)
            eq('fiscale', this.fiscale)
            eq('modello', this.modello)
            eq('progMod', this.progMod)
            eq('flagCf', this.flagCf)
            eq('sigla', this.sigla)
            eq('ragioneSoc', this.ragioneSoc)
            eq('flag', this.flag)
            eq('apprBil', this.apprBil)
            eq('terBil', this.terBil)
            eq('dataVariaz', this.dataVariaz)
            eq('comuneSedeLeg', this.comuneSedeLeg)
            eq('istatComSl', this.istatComSl)
            eq('provSedeLeg', this.provSedeLeg)
            eq('capSedeLeg', this.capSedeLeg)
            eq('indSedeLeg', this.indSedeLeg)
            eq('dataVariazDf', this.dataVariazDf)
            eq('comuneDomFi', this.comuneDomFi)
            eq('istatCom', this.istatCom)
            eq('provDomFi', this.provDomFi)
            eq('capDomFi', this.capDomFi)
            eq('indDomFi', this.indDomFi)
            eq('stato', this.stato)
            eq('naturaGiu', this.naturaGiu)
            eq('situaz', this.situaz)
            eq('fiSocIn', this.fiSocIn)
            eq('flagCfSIn', this.flagCfSIn)
            eq('eventiEcc', this.eventiEcc)
            eq('fiscRapLeg', this.fiscRapLeg)
            eq('flagRapLeg', this.flagRapLeg)
            eq('cognomeRapLeg', this.cognomeRapLeg)
            eq('nomeRapLeg', this.nomeRapLeg)
            eq('sessoRapLeg', this.sessoRapLeg)
            eq('dataNasRapLe', this.dataNasRapLe)
            eq('comNasRapLe', this.comNasRapLe)
            eq('istatNasRapLe', this.istatNasRapLe)
            eq('prvNasRapLe', this.prvNasRapLe)
            eq('denominaz', this.denominaz)
            eq('codiceCari', this.codiceCari)
            eq('dataCarica', this.dataCarica)
            eq('comuReRaLe', this.comuReRaLe)
            eq('istatReRaLe', this.istatReRaLe)
            eq('provReRaLe', this.provReRaLe)
            eq('indRapLeg', this.indRapLeg)
            eq('capRapLeg', this.capRapLeg)
            eq('caaf', this.caaf)
            eq('recoModificato', this.recoModificato)
            eq('fiscDenunc', this.fiscDenunc)
            eq('free', this.free)
            eq('denomDenunc', this.denomDenunc)
            eq('domFiscDenunc', this.domFiscDenunc)
            eq('capFiscDenunc', this.capFiscDenunc)
            eq('comFiscDenunc', this.comFiscDenunc)
            eq('prvFiscDenunc', this.prvFiscDenunc)
            eq('caricaDenunc', this.caricaDenunc)
            eq('telPrefDichiar', this.telPrefDichiar)
            eq('telDichiarante', this.telDichiarante)
            eq('progressivo', this.progressivo)
        }
    }
    public SigaiAnaGiur toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
