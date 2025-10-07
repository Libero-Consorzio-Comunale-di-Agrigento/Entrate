package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.EredeSoggetto

public class EredeSoggettoDTO implements DTO<EredeSoggetto> {
    private static final long serialVersionUID = 1L;

    Date lastUpdated
    SoggettoDTO soggetto
    SoggettoDTO soggettoErede
    String note
	Short numeroOrdine
    Ad4UtenteDTO	utente
	SoggettoDTO soggettoEredeId

    def uuid = UUID.randomUUID().toString().replace('-', '')

    public EredeSoggetto getDomainObject () {
        return EredeSoggetto.createCriteria().get {
            eq('soggetto.id', this.soggetto.id)
            eq('soggettoErede.id', this.soggettoErede.id)
        }
    }
    public EredeSoggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
