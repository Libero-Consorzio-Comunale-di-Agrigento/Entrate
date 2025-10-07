package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.OggettoOgim
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO

public class OggettoOgimDTO implements it.finmatica.dto.DTO<OggettoOgim> {
    private static final long serialVersionUID = 1L;

    BigDecimal aliquota;
    BigDecimal aliquotaErariale;
    BigDecimal aliquotaStd;
    short anno;
    ContribuenteDTO	contribuente;
    Byte mesiPossesso;
    Boolean mesiPossesso1sem;
    OggettoPraticaDTO oggettoPratica;
    Short sequenza;
    TipoAliquotaDTO tipoAliquota;


    public OggettoOgim getDomainObject () {
        return OggettoOgim.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica.id', this.oggettoPratica.id)
            eq('sequenza', this.sequenza)
        }
    }
    public OggettoOgim toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
