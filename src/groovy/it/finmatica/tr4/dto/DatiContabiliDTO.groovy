package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.commons.*
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.DatiContabili

class DatiContabiliDTO implements DTO<DatiContabili> {
    private static final long serialVersionUID = 1L

    Long id
    TipoTributoDTO tipoTributo
    Short anno
    String tipoImposta
    String tipoPratica
    Date emissioneDal
    Date emissioneAl
    Date ripartizioneDal
    Date ripartizioneAl
    CodiceTributoDTO tributo
    //CodiceF24DTO codTributoF24
    String codTributoF24
    String descrizioneTitr
    TipoStatoDTO statoPratica
    Short annoAcc
    Integer numeroAcc
    TipoOccupazione tipoOccupazione
    String codEnteComunale

    //Set<CodiceF24DTO> codTributoF24

    // Not in DB
    String desEnteComunale

    public DatiContabili getDomainObject () {
        return DatiContabili.createCriteria().get {
            eq('id', Long.parseLong(this?.id?.toString()))
        }
    }

    public DatiContabili toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
