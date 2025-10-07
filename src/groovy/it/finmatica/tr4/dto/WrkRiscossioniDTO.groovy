package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkRiscossioni;

import java.util.Date;
import java.util.Map;

public class WrkRiscossioniDTO implements it.finmatica.dto.DTO<WrkRiscossioni> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Integer codAbi;
    Integer codCab;
    String codControlloCc;
    String codFiscale;
    String cognomeNome;
    String contoCorrente;
    Date dataPagamento;
    Date dataScadenza;
    BigDecimal importoTotale;
    BigDecimal importoVersato;
    Boolean rata;
    Long ruolo;
    String tipoTributo;


    public WrkRiscossioni getDomainObject () {
        return WrkRiscossioni.createCriteria().get {
            eq('ruolo', this.ruolo)
            eq('codFiscale', this.codFiscale)
            eq('tipoTributo', this.tipoTributo)
            eq('anno', this.anno)
            eq('rata', this.rata)
        }
    }
    public WrkRiscossioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
