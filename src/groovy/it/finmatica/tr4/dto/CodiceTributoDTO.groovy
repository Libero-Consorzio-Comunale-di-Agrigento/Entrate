package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CodiceTributo

class CodiceTributoDTO implements DTO<CodiceTributo> {
    private static final long serialVersionUID = 1L

    String codEntrata
    Integer contoCorrente
    String descrizione
    String descrizioneCc
    String descrizioneRuolo
    String flagCalcoloInteressi
    String flagRuolo
    String flagStampaCc
    TipoTributoDTO tipoTributo
    TipoTributoDTO tipoTributoPrec
    String gruppoTributo
    Long id

    Set<CategoriaDTO> categorie


    CodiceTributo getDomainObject() {
        return CodiceTributo.get(this.id)
    }

    CodiceTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    void addToCategorie(CategoriaDTO categoria) {
        if (this.categorie == null)
            this.categorie = new HashSet<CategoriaDTO>()
        this.categorie.add(categoria)
        categoria.codiceTributo = this
    }

    void removeFromCategorie(CategoriaDTO categoria) {
        if (this.categorie == null)
            this.categorie = new HashSet<CategoriaDTO>()
        this.categorie.remove(categoria)
        categoria.codiceTributo = null
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
