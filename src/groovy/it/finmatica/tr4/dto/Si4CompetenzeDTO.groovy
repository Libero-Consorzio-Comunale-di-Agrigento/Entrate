package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.Ad4Tr4UtenteDTO
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Si4Competenze

class Si4CompetenzeDTO implements DTO<Si4Competenze> {
    private static final long serialVersionUID = 1L

    Long id
    String accesso
    Date al
    Date dal
    Date dataAggiornamento
    String oggetto
    String ruolo
    Si4AbilitazioniDTO si4Abilitazioni
    Ad4UtenteDTO utente
    Ad4Tr4UtenteDTO utenteTr4
    Ad4UtenteDTO utenteAggiornamento

    def tipoOggettoDesc
    def descrizioneTributo

    Si4Competenze getDomainObject() {
        return Si4Competenze.get(this.id)
    }

    Si4Competenze toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
