package it.finmatica.tr4.dto;

import it.finmatica.tr4.OggettiTasi;

import java.util.Date;
import java.util.Map;

public class OggettiTasiDTO implements it.finmatica.dto.DTO<OggettiTasi> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String categoriaCatasto;
    String classeCatasto;
    String codFiscale;
    Date data;
    BigDecimal detrazione;
    String estremiTitolo;
    String flagAbPrincipale;
    String flagAlRidotta;
    String flagEsclusione;
    String flagFirma;
    String flagPossesso;
    String flagRiduzione;
    Byte fonte;
    String immStorico;
    Byte mesiAliquotaRidotta;
    Byte mesiEsclusione;
    Byte mesiPossesso;
    Byte mesiRiduzione;
    Short modello;
    String numOrdine;
    Long oggetto;
    Long oggettoPratica;
    Long oggettoPraticaRif;
    BigDecimal percPossesso;
    Long pratica;
    String tipoPratica;
    String titolo;
    BigDecimal valore;


    public OggettiTasi getDomainObject () {
        return OggettiTasi.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('anno', this.anno)
            eq('oggettoPratica', this.oggettoPratica)
            eq('percPossesso', this.percPossesso)
            eq('mesiPossesso', this.mesiPossesso)
            eq('mesiEsclusione', this.mesiEsclusione)
            eq('mesiRiduzione', this.mesiRiduzione)
            eq('detrazione', this.detrazione)
            eq('mesiAliquotaRidotta', this.mesiAliquotaRidotta)
            eq('flagPossesso', this.flagPossesso)
            eq('flagEsclusione', this.flagEsclusione)
            eq('flagRiduzione', this.flagRiduzione)
            eq('flagAbPrincipale', this.flagAbPrincipale)
            eq('flagAlRidotta', this.flagAlRidotta)
            eq('numOrdine', this.numOrdine)
            eq('immStorico', this.immStorico)
            eq('categoriaCatasto', this.categoriaCatasto)
            eq('classeCatasto', this.classeCatasto)
            eq('valore', this.valore)
            eq('titolo', this.titolo)
            eq('estremiTitolo', this.estremiTitolo)
            eq('flagFirma', this.flagFirma)
            eq('modello', this.modello)
            eq('fonte', this.fonte)
            eq('oggettoPraticaRif', this.oggettoPraticaRif)
            eq('pratica', this.pratica)
            eq('tipoPratica', this.tipoPratica)
            eq('data', this.data)
            eq('oggetto', this.oggetto)
        }
    }
    public OggettiTasi toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
