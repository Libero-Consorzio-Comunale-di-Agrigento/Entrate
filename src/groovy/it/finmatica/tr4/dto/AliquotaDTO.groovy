package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Aliquota

public class AliquotaDTO implements it.finmatica.dto.DTO<Aliquota> {
    private static final long serialVersionUID = 1L

    Long id
    TipoAliquotaDTO tipoAliquota
    Short anno
    BigDecimal aliquota
    String flagAbPrincipale
    String flagPertinenze
    BigDecimal aliquotaBase
    BigDecimal aliquotaErariale
    BigDecimal aliquotaStd
    BigDecimal percSaldo
    BigDecimal percOccupante
    String flagRiduzione
    BigDecimal riduzioneImposta
    String note
    Date scadenzaMiniImu
    String flagFabbricatiMerce

    public Aliquota getDomainObject () {
        return Aliquota.createCriteria().get {
            eq('tipoAliquota.tipoTributo.tipoTributo', this?.tipoAliquota?.tipoTributo?.tipoTributo)
            eq('anno', this?.anno)
            eq('tipoAliquota.tipoAliquota', this?.tipoAliquota?.tipoAliquota)
        }
    }
    public Aliquota toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
