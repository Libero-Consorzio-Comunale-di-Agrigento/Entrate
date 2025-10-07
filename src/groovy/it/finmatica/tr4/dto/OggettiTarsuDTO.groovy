package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiTarsu;

import java.util.Date;
import java.util.Map;

public class OggettiTarsuDTO implements it.finmatica.dto.DTO<OggettiTarsu> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Short categoria;
    String categoriaCatasto;
    String classeCatasto;
    String codFiscale;
    BigDecimal consistenza;
    Date data;
    Date dataCessazione;
    Date dataDecorrenza;
    Date fineOccupazione;
    Date inizioOccupazione;
    Long oggetto;
    Long oggettoPratica;
    Long oggettoPraticaRif;
    Long pratica;
    String tipoPratica;
    Byte tipoTariffa;
    Short tributo;


    public OggettiTarsu getDomainObject () {
        return OggettiTarsu.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('categoriaCatasto', this.categoriaCatasto)
            eq('classeCatasto', this.classeCatasto)
            eq('oggettoPraticaRif', this.oggettoPraticaRif)
            eq('inizioOccupazione', this.inizioOccupazione)
            eq('fineOccupazione', this.fineOccupazione)
            eq('dataDecorrenza', this.dataDecorrenza)
            eq('dataCessazione', this.dataCessazione)
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
            eq('tipoTariffa', this.tipoTariffa)
            eq('consistenza', this.consistenza)
            eq('pratica', this.pratica)
            eq('tipoPratica', this.tipoPratica)
            eq('data', this.data)
            eq('oggetto', this.oggetto)
        }
    }
    public OggettiTarsu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
