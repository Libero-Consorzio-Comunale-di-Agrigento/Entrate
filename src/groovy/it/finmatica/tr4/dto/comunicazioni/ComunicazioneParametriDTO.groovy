package it.finmatica.tr4.dto.comunicazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.comunicazioni.ComunicazioneParametri

public class ComunicazioneParametriDTO implements DTO<ComunicazioneParametri> {
    private static final long serialVersionUID = 1L;

    String tipoTributo
    String tipoComunicazione
    String descrizione
    String flagFirma
    String flagProtocollo
    String flagPec
    String tipoDocumento
    String titoloDocumento
    String pkgVariabili
    String tipoComunicazionePND
    String variabiliClob


    public ComunicazioneParametri getDomainObject() {
        return ComunicazioneParametri.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('tipoComunicazione', this.tipoComunicazione)
        }
    }

    public ComunicazioneParametri toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as ComunicazioneParametri
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
