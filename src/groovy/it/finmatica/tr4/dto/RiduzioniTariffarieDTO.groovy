package it.finmatica.tr4.dto;

import it.finmatica.tr4.RiduzioniTariffarie;

import java.util.Map;

public class RiduzioniTariffarieDTO implements it.finmatica.dto.DTO<RiduzioniTariffarie> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Short categoria;
    String descCategoria;
    String descTariffa;
    String descTributo;
    String riduzione;
    BigDecimal tariffa;
    BigDecimal tariffaBase;
    Byte tipoTariffa;
    String tipoTributo;
    Short tributo;


    public RiduzioniTariffarie getDomainObject () {
        return RiduzioniTariffarie.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('tributo', this.tributo)
            eq('descTributo', this.descTributo)
            eq('categoria', this.categoria)
            eq('descCategoria', this.descCategoria)
            eq('tipoTariffa', this.tipoTariffa)
            eq('descTariffa', this.descTariffa)
            eq('anno', this.anno)
            eq('tariffa', this.tariffa)
            eq('tariffaBase', this.tariffaBase)
            eq('riduzione', this.riduzione)
        }
    }
    public RiduzioniTariffarie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
