package it.finmatica.tr4.dto.datiesterni;

import java.util.Set;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.dto.VersamentoDTO;
import it.finmatica.tr4.dto.pratiche.FamiliarePraticaDTO;

public class TitoloDocumentoDTO implements it.finmatica.dto.DTO<TitoloDocumento> {
    private static final long serialVersionUID = 1L;

    String 	descrizione
    String 	estensioneMulti
    String 	estensioneMulti2
    String 	tipoCaricamento
    Long 	id

	String nomeBean
	String nomeMetodo
	
	Set<ParametroImportDTO> parametriImport
		
    public TitoloDocumento getDomainObject () {
        return TitoloDocumento.get(this.id)
    }
    public TitoloDocumento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
	
	public void addToParametriImport (ParametroImportDTO parametroImport) {
		if (this.parametriImport == null)
			this.parametriImport = new HashSet<ParametroImportDTO>()
		this.parametriImport.add (parametroImport);
		parametroImport.titoloDocumento = this
	}
	
	public void removeFromParametriImport (ParametroImportDTO parametroImport) {
		if (this.parametriImport == null)
			this.parametriImport = new HashSet<ParametroImportDTO>()
		this.parametriImport.remove (parametroImport);
		parametroImport.titoloDocumento = null
	}
	
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
