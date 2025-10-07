package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.DatoGenerale

public class DatoGeneraleDTO implements DTO<DatoGenerale> {
    private static final long serialVersionUID = 1L

    Long chiave;
    Ad4ComuneTr4DTO comuneCliente

    String flagIntegrazioneGsd
    String flagIntegrazioneTrb
    Byte faseEuro
    BigDecimal cambioEuro
    String codComuneRuolo
    String flagCatastoCu
    String flagProvincia
    Integer codAbi
    Integer codCab
    String codAzienda
    String flagAccTotale
    String flagCompetenze
    String tipoComune
    String area


    public DatoGenerale getDomainObject () {
        return DatoGenerale.get(this.chiave)
    }
    public DatoGenerale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
