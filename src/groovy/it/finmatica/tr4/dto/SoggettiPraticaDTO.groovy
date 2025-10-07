package it.finmatica.tr4.dto;

import it.finmatica.tr4.SoggettiPratica;

import java.util.Date;
import java.util.Map;

public class SoggettiPraticaDTO implements it.finmatica.dto.DTO<SoggettiPratica> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    Integer codContribuente;
    Byte codControllo;
    String codFiscale;
    String codFiscaleErede;
    String codFiscaleRap;
    String codSesso;
    String cognomeNome;
    String cognomeNomeErede;
    String comune;
    String comuneEnte;
    String comuneErede;
    String comuneNascita;
    String comuneRap;
    Date dataNascita;
    String dataNotifica;
    String dataOdierna;
    String dataPratica;
    Character datiDb1;
    Character datiDb2;
    String indirizzo;
    String indirizzoErede;
    String indirizzoRap;
    String motivoPratica;
    Long ni;
    String notePratica;
    String numero;
    Long pratica;
    String presso;
    String provinciaEnte;
    String rappresentante;
    String sesso;
    String siglaEnte;
    String telefono;
    String tipoEvento;
    String tipoPratica;
    String tipoRapporto;
    String tipoTributo;


    public SoggettiPratica getDomainObject () {
        return SoggettiPratica.createCriteria().get {
            eq('comuneEnte', this.comuneEnte)
            eq('siglaEnte', this.siglaEnte)
            eq('provinciaEnte', this.provinciaEnte)
            eq('cognomeNome', this.cognomeNome)
            eq('ni', this.ni)
            eq('codSesso', this.codSesso)
            eq('sesso', this.sesso)
            eq('codContribuente', this.codContribuente)
            eq('codControllo', this.codControllo)
            eq('codFiscale', this.codFiscale)
            eq('presso', this.presso)
            eq('indirizzo', this.indirizzo)
            eq('comune', this.comune)
            eq('telefono', this.telefono)
            eq('dataNascita', this.dataNascita)
            eq('comuneNascita', this.comuneNascita)
            eq('rappresentante', this.rappresentante)
            eq('codFiscaleRap', this.codFiscaleRap)
            eq('indirizzoRap', this.indirizzoRap)
            eq('comuneRap', this.comuneRap)
            eq('pratica', this.pratica)
            eq('tipoTributo', this.tipoTributo)
            eq('tipoPratica', this.tipoPratica)
            eq('tipoEvento', this.tipoEvento)
            eq('anno', this.anno)
            eq('numero', this.numero)
            eq('tipoRapporto', this.tipoRapporto)
            eq('dataPratica', this.dataPratica)
            eq('dataNotifica', this.dataNotifica)
            eq('dataOdierna', this.dataOdierna)
            eq('cognomeNomeErede', this.cognomeNomeErede)
            eq('codFiscaleErede', this.codFiscaleErede)
            eq('indirizzoErede', this.indirizzoErede)
            eq('comuneErede', this.comuneErede)
            eq('notePratica', this.notePratica)
            eq('motivoPratica', this.motivoPratica)
            eq('datiDb1', this.datiDb1)
            eq('datiDb2', this.datiDb2)
        }
    }
    public SoggettiPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
