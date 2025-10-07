package it.finmatica.tr4.dto;

import it.finmatica.tr4.TotaliPraticaView;

import java.util.Map;

public class TotaliPraticaViewDTO implements it.finmatica.dto.DTO<TotaliPraticaView> {
    private static final long serialVersionUID = 1L;

    Long id;
    Long pratica;
    BigDecimal totaleImposta;
    BigDecimal totaleInteressi;
    BigDecimal totalePenePecuniarie;
    BigDecimal totaleSoprattasse;
    BigDecimal totaleVersato;


    public TotaliPraticaView getDomainObject () {
        return TotaliPraticaView.createCriteria().get {
            eq('pratica', this.pratica)
            eq('totaleImposta', this.totaleImposta)
            eq('totaleSoprattasse', this.totaleSoprattasse)
            eq('totalePenePecuniarie', this.totalePenePecuniarie)
            eq('totaleInteressi', this.totaleInteressi)
            eq('totaleVersato', this.totaleVersato)
        }
    }
    public TotaliPraticaView toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
