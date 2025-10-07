package it.finmatica.tr4.dto;

import it.finmatica.tr4.Sottocategorie;

import java.util.Map;

public class SottocategorieDTO implements it.finmatica.dto.DTO<Sottocategorie> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short categoria;
    String descrizione;
    Short sottocategoria;
    Short tributo;


    public Sottocategorie getDomainObject () {
        return Sottocategorie.createCriteria().get {
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
            eq('sottocategoria', this.sottocategoria)
            eq('descrizione', this.descrizione)
        }
    }
    public Sottocategorie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
