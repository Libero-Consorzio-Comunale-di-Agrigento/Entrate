package it.finmatica.tr4.dto;

import it.finmatica.tr4.ImmobiliCatastoUrbanoCu;

import java.util.Date;
import java.util.Map;

public class ImmobiliCatastoUrbanoCuDTO implements it.finmatica.dto.DTO<ImmobiliCatastoUrbanoCu> {
    private static final long serialVersionUID = 1L;

    Long id;
    String categoria;
    String categoriaRic;
    String classe;
    String codTitolo;
    String consistenza;
    BigDecimal contatore;
    Date dataEfficacia;
    Date dataIscrizione;
    String denominatore;
    String desTitolo;
    String descrizione;
    String edificio;
    String estremiCatasto;
    String foglio;
    String foglioRic;
    String indirizzo;
    String indirizzoRic;
    String interno;
    String lotto;
    String numCiv;
    String numeratore;
    String numero;
    String numeroRic;
    String partita;
    String partitaRic;
    String partitaTitolarita;
    String piano;
    BigDecimal proprietario;
    String rendita;
    String scala;
    String sezione;
    String sezioneRic;
    String subalterno;
    String subalternoRic;
    Character tipoImmobile;
    String zona;
    String zonaRic;


    public ImmobiliCatastoUrbanoCu getDomainObject () {
        return ImmobiliCatastoUrbanoCu.createCriteria().get {
            eq('contatore', this.contatore)
            eq('proprietario', this.proprietario)
            eq('indirizzo', this.indirizzo)
            eq('numCiv', this.numCiv)
            eq('lotto', this.lotto)
            eq('edificio', this.edificio)
            eq('scala', this.scala)
            eq('interno', this.interno)
            eq('piano', this.piano)
            eq('numeratore', this.numeratore)
            eq('denominatore', this.denominatore)
            eq('codTitolo', this.codTitolo)
            eq('desTitolo', this.desTitolo)
            eq('tipoImmobile', this.tipoImmobile)
            eq('partitaTitolarita', this.partitaTitolarita)
            eq('partita', this.partita)
            eq('sezione', this.sezione)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('zona', this.zona)
            eq('categoria', this.categoria)
            eq('classe', this.classe)
            eq('consistenza', this.consistenza)
            eq('rendita', this.rendita)
            eq('descrizione', this.descrizione)
            eq('dataEfficacia', this.dataEfficacia)
            eq('dataIscrizione', this.dataIscrizione)
            eq('estremiCatasto', this.estremiCatasto)
            eq('sezioneRic', this.sezioneRic)
            eq('foglioRic', this.foglioRic)
            eq('numeroRic', this.numeroRic)
            eq('subalternoRic', this.subalternoRic)
            eq('indirizzoRic', this.indirizzoRic)
            eq('zonaRic', this.zonaRic)
            eq('categoriaRic', this.categoriaRic)
            eq('partitaRic', this.partitaRic)
        }
    }
    public ImmobiliCatastoUrbanoCu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
