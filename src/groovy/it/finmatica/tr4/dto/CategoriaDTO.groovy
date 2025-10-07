package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO;
import it.finmatica.tr4.Categoria;

import java.util.Map;
import java.util.Set;

public class CategoriaDTO implements it.finmatica.dto.DTO<Categoria> {
    private static final long serialVersionUID = 1L;
	Long  id
    Short categoria;
    Short categoriaRif;
    String descrizione;
    String descrizionePrec;
    So4AmministrazioneDTO ente;
    String flagDomestica;
    String flagGiorni;
	Boolean	flagNoDepag;
    CodiceTributoDTO codiceTributo
	
	Set<TariffaDTO> tariffe

    public Categoria getDomainObject () {
        return Categoria.get(this.id)
    }
    public Categoria toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

	public void addToTariffe (TariffaDTO tariffa) {
		if (this.tariffe == null)
			this.tariffe = new HashSet<TariffaDTO>()
		this.tariffe.add (tariffa);
		tariffe.categoria = this
	}
	
	public void removeFromTariffe (TariffaDTO tariffa) {
		if (this.tariffe == null)
			this.tariffe = new HashSet<TariffaDTO>()
		this.tariffe.remove (tariffa);
		tariffe.categoria = null
	}
	
	
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
