package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiAnaFis;

import java.util.Map;

public class SigaiAnaFisDTO implements it.finmatica.dto.DTO<SigaiAnaFis> {
    private static final long serialVersionUID = 1L;

    Long id;
    String caParDomFi;
    String capDomFi;
    String capFiscDenunc;
    String capRes;
    String caricaDenunc;
    String codStaCiv;
    String cognome;
    String comDoFi;
    String comFiscDenunc;
    String comuneNascita;
    String comuneRes;
    String dataNascita;
    String denomDenunc;
    String domFiscDenunc;
    String eventiEcc;
    String fallimento;
    String fiscConiuge;
    String fiscDenunc;
    String fiscale;
    String free;
    String indirDomFi;
    String indirizzoRes;
    String istatComFi;
    String istatComRes;
    String modello;
    String nome;
    String presDichCong;
    String presenta;
    String proDomFi;
    String progMod;
    String progressivo;
    String prvFiscDenunc;
    String prvNascita;
    String prvRes;
    String recoModificato;
    String sesso;
    String tdich;
    String telDichiarante;
    String telPrefDichiar;
    String titStudio;


    public SigaiAnaFis getDomainObject () {
        return SigaiAnaFis.createCriteria().get {
            eq('tdich', this.tdich)
            eq('fiscale', this.fiscale)
            eq('presenta', this.presenta)
            eq('modello', this.modello)
            eq('progMod', this.progMod)
            eq('cognome', this.cognome)
            eq('nome', this.nome)
            eq('sesso', this.sesso)
            eq('dataNascita', this.dataNascita)
            eq('prvNascita', this.prvNascita)
            eq('comuneNascita', this.comuneNascita)
            eq('comuneRes', this.comuneRes)
            eq('istatComRes', this.istatComRes)
            eq('prvRes', this.prvRes)
            eq('capRes', this.capRes)
            eq('indirizzoRes', this.indirizzoRes)
            eq('codStaCiv', this.codStaCiv)
            eq('titStudio', this.titStudio)
            eq('fallimento', this.fallimento)
            eq('eventiEcc', this.eventiEcc)
            eq('caParDomFi', this.caParDomFi)
            eq('comDoFi', this.comDoFi)
            eq('istatComFi', this.istatComFi)
            eq('proDomFi', this.proDomFi)
            eq('indirDomFi', this.indirDomFi)
            eq('capDomFi', this.capDomFi)
            eq('presDichCong', this.presDichCong)
            eq('fiscConiuge', this.fiscConiuge)
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
    public SigaiAnaFis toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
