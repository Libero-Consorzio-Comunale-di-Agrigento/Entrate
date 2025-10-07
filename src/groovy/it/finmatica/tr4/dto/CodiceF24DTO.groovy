package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CodiceF24

public class CodiceF24DTO implements DTO<CodiceF24> {
    private static final long serialVersionUID = 1L

    def static tipiCodice = [
            "": "",
            I : "Interessi",
            S : "Sanzioni",
            C : "Imposte"
    ]

    def static tipiRateazione = [
            ""  : "",
            "0" : "Non compilare",
            FFFF: "Opzionale",
            NNRR: "Obbligatorio"
    ]

    String tributo
    String descrizione
    String rateazione
    TipoTributoDTO tipoTributo
    String descrizioneTitr
    String tipoCodice
    String flagStampaRateazione

    //DatiContabiliDTO datiContabili

    public CodiceF24 getDomainObject() {
        return CodiceF24.createCriteria().get {
            eq('tipoTributo.tipoTributo', this?.tipoTributo?.tipoTributo)
            eq('tributo', this?.tributo)
            eq('descrizioneTitr', this?.descrizioneTitr)
        }
    }

    public CodiceF24 toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


    def getRateazioneDescrizione() {
        return tipiRateazione[rateazione]
    }

    def getTipoCodiceDescrizione() {
        return tipiCodice[tipoCodice]
    }

}

