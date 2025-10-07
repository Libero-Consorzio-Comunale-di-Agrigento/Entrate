package it.finmatica.tr4.dto;

import it.finmatica.tr4.Etichette;

import java.util.Map;

public class EtichetteDTO implements it.finmatica.dto.DTO<Etichette> {
    private static final long serialVersionUID = 1L;

    BigDecimal altezza;
    Boolean colonne;
    String descrizione;
    Byte etichetta;
    BigDecimal larghezza;
    String modulo;
    String note;
    String orientamento;
    Short righe;
    BigDecimal sinistra;
    BigDecimal sopra;
    BigDecimal spazioTraColonne;
    BigDecimal spazioTraRighe;


    public Etichette getDomainObject () {
        return Etichette.get(this.etichetta)
    }
    public Etichette toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
