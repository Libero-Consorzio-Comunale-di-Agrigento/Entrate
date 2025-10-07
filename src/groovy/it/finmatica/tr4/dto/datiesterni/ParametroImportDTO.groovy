package it.finmatica.tr4.dto.datiesterni;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.datiesterni.ParametroImport

public class ParametroImportDTO implements it.finmatica.dto.DTO<ParametroImport> {
	private static final long serialVersionUID = 1L;
	
	Long 	id
	String nomeParametro                
	String labelParametro
	String componente                   
                                    
	So4AmministrazioneDTO 	ente            
	Ad4UtenteDTO			utente          
    TitoloDocumentoDTO 		titoloDocumento
	Short					sequenza
	
	
    public ParametroImport getDomainObject () {
        return ParametroImport.get(this.id)
    }
    public ParametroImport toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
