package it.finmatica.tr4.dto;

import it.finmatica.tr4.TipoUtilizzo;
import it.finmatica.dto.DtoToEntityUtils

import java.util.Map;
import java.util.Set;

public class TipoUtilizzoDTO implements it.finmatica.dto.DTO<TipoUtilizzo> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id

	Set<UtilizzoTributoDTO> utilizziTributo;
	
    public TipoUtilizzo getDomainObject () {
        return TipoUtilizzo.get(this.id)
    }
    public TipoUtilizzo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


	public void addToUtilizzoTributo (UtilizzoTributoDTO utilizzoTributo) {
		if (this.utilizziTributo == null)
			this.utilizziTributo = new HashSet<UtilizzoTributoDTO>()
		this.utilizziTributo.add (utilizzoTributo);
		utilizzoTributo.tipoUtilizzo = this
	}

	public void removeFromUtilizzoTributo (UtilizzoTributoDTO utilizzoTributo) {
		if (this.utilizziTributo == null)
			this.utilizziTributo = new HashSet<UtilizzoTributoDTO>()
		this.utilizziTributo.remove (utilizzoTributo);
		utilizzoTributo.tipoUtilizzo = null
	}
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
