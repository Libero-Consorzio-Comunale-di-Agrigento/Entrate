package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.ParametriExport

class ParametriExportDTO implements DTO<ParametriExport>, Comparable<ParametriExportDTO> {
    private static final long serialVersionUID = 1L

    Long id
    TipiExportDTO tipoExport
    Byte parametroExport
    String nomeParametro
    String tipoParametro
    String formatoParametro
    String ultimoValore
    String flagObbligatorio
    String valorePredefinito
    Byte ordinamento
    String flagNonVisibile
    String querySelezione


    ParametriExport getDomainObject() {
        return ParametriExport.createCriteria().get {
            eq('tipoExport.id', this.tipoExport.id)
            eq('parametroExport', this.parametroExport)
        }
    }

    ParametriExport toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as ParametriExport
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    @Override
    int compareTo(ParametriExportDTO o) {
        this.tipoExport.id <=> o?.tipoExport?.id ?:
                this.parametroExport <=> o?.parametroExport
    }
}
