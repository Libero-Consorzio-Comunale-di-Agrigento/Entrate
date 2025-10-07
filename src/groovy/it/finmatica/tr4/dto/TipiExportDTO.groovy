package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipiExport

public class TipiExportDTO implements DTO<TipiExport> {
    private static final long serialVersionUID = 1L

    Long id
    BigDecimal annoTrasAnci
    String descrizione
    String estensioneNomeFile
    String flagStandard
    String nomeFile
    String nomeProcedura
    Integer ordinamento
    String prefissoNomeFile
    String suffissoNomeFile
    String tabellaTemporanea
    String tipoTributo
    String windowControllo
    String windowStampa
    String flagClob
    SortedSet<ParametriExportDTO> parametriExport

    void addToParametriExport(ParametriExportDTO parametroExport) {
        if (this.parametriExport == null)
            this.parametriExport = new TreeSet<ParametriExportDTO>()
        this.parametriExport.add(parametroExport)
        parametroExport.tipoExport = this
    }

    void removeFromParametriExport(ParametriExportDTO parametroExport) {
        if (this.parametriExport == null)
            this.parametriExport = new TreeSet<ParametriExportDTO>()
        this.parametriExport.remove(parametroExport)
        parametroExport.tipoExport = null
    }

    public TipiExport getDomainObject() {
        return TipiExport.get(this.id)
    }

    public TipiExport toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
