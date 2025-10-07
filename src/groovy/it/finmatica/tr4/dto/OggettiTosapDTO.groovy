package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiTosap;

import java.util.Date;
import java.util.Map;

public class OggettiTosapDTO implements it.finmatica.dto.DTO<OggettiTosap> {
    private static final long serialVersionUID = 1L;

    Long id;
    BigDecimal aChilometro;
    Short anno;
    Short categoria;
    Short codComOcc;
    String codFiscale;
    Short codProOcc;
    BigDecimal consistenza;
    BigDecimal daChilometro;
    Date data;
    Date dataCessazione;
    Date dataConcessione;
    Date dataDecorrenza;
    Date fineConcessione;
    String indirizzoOcc;
    Date inizioConcessione;
    BigDecimal larghezza;
    String lato;
    Integer numConcessione;
    Long oggetto;
    Long oggettoPratica;
    Long oggettoPraticaRif;
    Long pratica;
    BigDecimal profondita;
    String tipoPratica;
    Byte tipoTariffa;
    Short tributo;


    public OggettiTosap getDomainObject () {
        return OggettiTosap.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('oggettoPraticaRif', this.oggettoPraticaRif)
            eq('dataDecorrenza', this.dataDecorrenza)
            eq('dataCessazione', this.dataCessazione)
            eq('tributo', this.tributo)
            eq('categoria', this.categoria)
            eq('tipoTariffa', this.tipoTariffa)
            eq('consistenza', this.consistenza)
            eq('numConcessione', this.numConcessione)
            eq('dataConcessione', this.dataConcessione)
            eq('inizioConcessione', this.inizioConcessione)
            eq('fineConcessione', this.fineConcessione)
            eq('larghezza', this.larghezza)
            eq('profondita', this.profondita)
            eq('codProOcc', this.codProOcc)
            eq('codComOcc', this.codComOcc)
            eq('indirizzoOcc', this.indirizzoOcc)
            eq('daChilometro', this.daChilometro)
            eq('aChilometro', this.aChilometro)
            eq('lato', this.lato)
            eq('pratica', this.pratica)
            eq('tipoPratica', this.tipoPratica)
            eq('data', this.data)
            eq('oggetto', this.oggetto)
        }
    }
    public OggettiTosap toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
