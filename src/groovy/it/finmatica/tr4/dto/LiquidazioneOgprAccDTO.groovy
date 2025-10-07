package it.finmatica.tr4.dto;

import it.finmatica.tr4.LiquidazioneOgprAcc;

import java.util.Date;
import java.util.Map;

public class LiquidazioneOgprAccDTO implements it.finmatica.dto.DTO<LiquidazioneOgprAcc> {
    private static final long serialVersionUID = 1L;

    Long id;
    String categoriaCatastoLiq;
    String classeCatastoLiq;
    String codFiscale;
    Date dataLiq;
    BigDecimal detrazioneLiq;
    String flagRiduzioneLiq;
    Byte mesiEsclusioneLiq;
    Byte mesiPossessoLiq;
    Byte mesiRiduzioneLiq;
    Long oggettoPraticaDic;
    Long oggettoPraticaLiq;
    BigDecimal percPossessoLiq;
    Long praticaAcc;
    Byte tipoAliquotaLiq;
    Byte tipoOggettoLiq;
    BigDecimal valoreLiq;


    public LiquidazioneOgprAcc getDomainObject () {
        return LiquidazioneOgprAcc.createCriteria().get {
            eq('oggettoPraticaLiq', this.oggettoPraticaLiq)
            eq('valoreLiq', this.valoreLiq)
            eq('categoriaCatastoLiq', this.categoriaCatastoLiq)
            eq('classeCatastoLiq', this.classeCatastoLiq)
            eq('tipoOggettoLiq', this.tipoOggettoLiq)
            eq('percPossessoLiq', this.percPossessoLiq)
            eq('mesiPossessoLiq', this.mesiPossessoLiq)
            eq('mesiEsclusioneLiq', this.mesiEsclusioneLiq)
            eq('flagRiduzioneLiq', this.flagRiduzioneLiq)
            eq('mesiRiduzioneLiq', this.mesiRiduzioneLiq)
            eq('detrazioneLiq', this.detrazioneLiq)
            eq('tipoAliquotaLiq', this.tipoAliquotaLiq)
            eq('oggettoPraticaDic', this.oggettoPraticaDic)
            eq('codFiscale', this.codFiscale)
            eq('praticaAcc', this.praticaAcc)
            eq('dataLiq', this.dataLiq)
        }
    }
    public LiquidazioneOgprAcc toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
