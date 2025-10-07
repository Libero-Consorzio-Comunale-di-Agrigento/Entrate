package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.AliquotaCategoria

public class AliquotaCategoriaDTO implements DTO<AliquotaCategoria> {
    private static final long serialVersionUID = 1L

    BigDecimal aliquota
    BigDecimal aliquotaBase
    short anno
    CategoriaCatastoDTO categoriaCatasto
    String note
    TipoAliquotaDTO tipoAliquota
    
    def uuid = UUID.randomUUID().toString().replace('-', '')

    public AliquotaCategoria getDomainObject() {
        return AliquotaCategoria.createCriteria().get {
            eq('anno', this.anno)
            eq('tipoAliquota', this.tipoAliquota)
            eq('categoriaCatasto', this.categoriaCatasto)
        }
    }

    public AliquotaCategoria toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
