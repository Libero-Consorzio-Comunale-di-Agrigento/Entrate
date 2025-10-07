package it.finmatica.tr4.dto;

import it.finmatica.tr4.AnomalieContitolari;

import java.util.Map;

public class AnomalieContitolariDTO implements it.finmatica.dto.DTO<AnomalieContitolari> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String codFiscale;
    String comune;
    BigDecimal detrazione;
    String flagAbPrincipale;
    String flagAlRidotta;
    String flagEsclusione;
    String flagPossesso;
    String flagRiduzione;
    String indirizzo;
    Byte mesiAliquotaRidotta;
    Byte mesiPossesso;
    String numOrdine;
    BigDecimal percPossesso;
    Long pratica;
    String siglaProvincia;


    public AnomalieContitolari getDomainObject () {
        return AnomalieContitolari.get(this.id)
    }
    public AnomalieContitolari toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
