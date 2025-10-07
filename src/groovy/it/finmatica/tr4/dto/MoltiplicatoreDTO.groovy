package it.finmatica.tr4.dto;

import it.finmatica.tr4.Moltiplicatore;

import java.util.Map;

public class MoltiplicatoreDTO implements it.finmatica.dto.DTO<Moltiplicatore> {
    private static final long serialVersionUID = 1L;

    //Long id;
    Short anno;
    CategoriaCatastoDTO categoriaCatasto;
    BigDecimal moltiplicatore;


    public Moltiplicatore getDomainObject () {
        return Moltiplicatore.createCriteria().get {
            eq('anno', this.anno)
            eq('categoriaCatasto.categoriaCatasto', this.categoriaCatasto.categoriaCatasto)
        }
    }
    public Moltiplicatore toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
