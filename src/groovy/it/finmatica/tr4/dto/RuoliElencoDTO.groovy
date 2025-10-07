package it.finmatica.tr4.dto;

import it.finmatica.tr4.RuoliElenco;

import java.util.Date;
import java.util.Map;

public class RuoliElencoDTO implements it.finmatica.dto.DTO<RuoliElenco> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal addMaggEca;
    BigDecimal addPro;
    Short annoEmissione;
    Short annoRuolo;
    Date dataEmissione;
    BigDecimal importo;
    String importoLordo;
    BigDecimal imposta;
    Date invioConsorzio;
    String isRuoloMaster;
    BigDecimal iva;
    BigDecimal maggiorazioneTares;
    Byte progrEmissione;
    Long ruolo;
    Long ruoloMaster;
    String rutrDesc;
    Date scadenzaPrimaRata;
    BigDecimal sgravio;
    Boolean specieRuolo;
    String tipoCalcolo;
    String tipoEmissione;
    Boolean tipoRuolo;
    String tipoTributo;
    Short tributo;


    public RuoliElenco getDomainObject () {
        return RuoliElenco.createCriteria().get {
            eq('tipoRuolo', this.tipoRuolo)
            eq('annoRuolo', this.annoRuolo)
            eq('annoEmissione', this.annoEmissione)
            eq('progrEmissione', this.progrEmissione)
            eq('dataEmissione', this.dataEmissione)
            eq('tributo', this.tributo)
            eq('importo', this.importo)
            eq('imposta', this.imposta)
            eq('addMaggEca', this.addMaggEca)
            eq('addPro', this.addPro)
            eq('iva', this.iva)
            eq('maggiorazioneTares', this.maggiorazioneTares)
            eq('invioConsorzio', this.invioConsorzio)
            eq('ruolo', this.ruolo)
            eq('tipoTributo', this.tipoTributo)
            eq('sgravio', this.sgravio)
            eq('rutrDesc', this.rutrDesc)
            eq('scadenzaPrimaRata', this.scadenzaPrimaRata)
            eq('specieRuolo', this.specieRuolo)
            eq('importoLordo', this.importoLordo)
            eq('ruoloMaster', this.ruoloMaster)
            eq('isRuoloMaster', this.isRuoloMaster)
            eq('tipoCalcolo', this.tipoCalcolo)
            eq('tipoEmissione', this.tipoEmissione)
        }
    }
    public RuoliElenco toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
