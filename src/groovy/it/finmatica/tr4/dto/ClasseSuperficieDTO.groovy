package it.finmatica.tr4.dto;

import it.finmatica.tr4.ClasseSuperficie;

import java.util.Map;

public class ClasseSuperficieDTO implements it.finmatica.dto.DTO<ClasseSuperficie> {
    private static final long serialVersionUID = 1L;

    Long id;
    ScaglioneRedditoDTO anno;
    Integer classe;
    BigDecimal imposta;
    SettoreAttivitaDTO settore;


    public ClasseSuperficie getDomainObject () {
        return ClasseSuperficie.createCriteria().get {
            eq('anno.anno', this.anno.anno)
            eq('settore.settore', this.settore.settore)
            eq('classe', this.classe)
        }
    }
    public ClasseSuperficie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
