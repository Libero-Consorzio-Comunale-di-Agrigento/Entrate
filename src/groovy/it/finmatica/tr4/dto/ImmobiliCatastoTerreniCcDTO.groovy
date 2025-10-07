package it.finmatica.tr4.dto;

import it.finmatica.tr4.ImmobiliCatastoTerreniCc;

import java.util.Date;
import java.util.Map;

public class ImmobiliCatastoTerreniCcDTO implements it.finmatica.dto.DTO<ImmobiliCatastoTerreniCc> {
    private static final long serialVersionUID = 1L;

    Long id;
    String annoNota;
    String annoNota1;
    String annotazione;
    String are;
    String centiare;
    String classe;
    Date dataEfficacia;
    Date dataEfficacia1;
    Date dataIscrizione;
    Date dataIscrizione1;
    String denominatore;
    String edificialita;
    String ettari;
    String flagDeduzioni;
    String flagPorzione;
    String flagReddito;
    String foglio;
    String foglioRic;
    Integer idImmobile;
    Integer idSoggetto;
    String indirizzo;
    String indirizzoRic;
    String numCiv;
    String numeratore;
    String numero;
    String numeroNota;
    String numeroNota1;
    String numeroRic;
    String partita;
    String partitaTerreno;
    String progressivoNota;
    String progressivoNota1;
    String qualita;
    String redditoAgrarioEuro;
    String redditoAgrarioLire;
    String redditoDominicaleEuro;
    String redditoDominicaleLire;
    String subalterno;
    String subalternoRic;
    String tipoNota;
    String tipoNota1;


    public ImmobiliCatastoTerreniCc getDomainObject () {
        return ImmobiliCatastoTerreniCc.createCriteria().get {
            eq('idImmobile', this.idImmobile)
            eq('idSoggetto', this.idSoggetto)
            eq('indirizzo', this.indirizzo)
            eq('numCiv', this.numCiv)
            eq('partita', this.partita)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('edificialita', this.edificialita)
            eq('qualita', this.qualita)
            eq('classe', this.classe)
            eq('ettari', this.ettari)
            eq('are', this.are)
            eq('centiare', this.centiare)
            eq('numeratore', this.numeratore)
            eq('denominatore', this.denominatore)
            eq('flagReddito', this.flagReddito)
            eq('flagPorzione', this.flagPorzione)
            eq('flagDeduzioni', this.flagDeduzioni)
            eq('redditoDominicaleLire', this.redditoDominicaleLire)
            eq('redditoAgrarioLire', this.redditoAgrarioLire)
            eq('redditoDominicaleEuro', this.redditoDominicaleEuro)
            eq('redditoAgrarioEuro', this.redditoAgrarioEuro)
            eq('dataEfficacia', this.dataEfficacia)
            eq('dataIscrizione', this.dataIscrizione)
            eq('tipoNota', this.tipoNota)
            eq('numeroNota', this.numeroNota)
            eq('progressivoNota', this.progressivoNota)
            eq('annoNota', this.annoNota)
            eq('dataEfficacia1', this.dataEfficacia1)
            eq('dataIscrizione1', this.dataIscrizione1)
            eq('tipoNota1', this.tipoNota1)
            eq('numeroNota1', this.numeroNota1)
            eq('progressivoNota1', this.progressivoNota1)
            eq('annoNota1', this.annoNota1)
            eq('partitaTerreno', this.partitaTerreno)
            eq('annotazione', this.annotazione)
            eq('foglioRic', this.foglioRic)
            eq('numeroRic', this.numeroRic)
            eq('subalternoRic', this.subalternoRic)
            eq('indirizzoRic', this.indirizzoRic)
        }
    }
    public ImmobiliCatastoTerreniCc toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
