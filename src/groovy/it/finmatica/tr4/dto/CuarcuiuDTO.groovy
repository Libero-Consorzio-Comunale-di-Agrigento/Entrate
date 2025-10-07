package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cuarcuiu;

import java.util.Map;

public class CuarcuiuDTO implements it.finmatica.dto.DTO<Cuarcuiu> {
    private static final long serialVersionUID = 1L;

    Long id;
    String categoria1;
    Byte categoria2;
    String categoriaRic;
    String classe;
    String codice;
    BigDecimal consistenza;
    Integer contatore;
    String dataEfficacia;
    String dataIscrizione;
    String descrizione;
    String flag;
    String foglio;
    String foglioRic;
    String numero;
    String numeroRic;
    String partita;
    Long rendita;
    String sezione;
    String sezioneRic;
    String subalterno;
    String subalternoRic;
    String zona;
    String zonaRic;


    public Cuarcuiu getDomainObject () {
        return Cuarcuiu.createCriteria().get {
            eq('codice', this.codice)
            eq('partita', this.partita)
            eq('sezione', this.sezione)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('zona', this.zona)
            eq('categoria1', this.categoria1)
            eq('categoria2', this.categoria2)
            eq('classe', this.classe)
            eq('consistenza', this.consistenza)
            eq('rendita', this.rendita)
            eq('descrizione', this.descrizione)
            eq('contatore', this.contatore)
            eq('flag', this.flag)
            eq('dataEfficacia', this.dataEfficacia)
            eq('dataIscrizione', this.dataIscrizione)
            eq('categoriaRic', this.categoriaRic)
            eq('sezioneRic', this.sezioneRic)
            eq('foglioRic', this.foglioRic)
            eq('numeroRic', this.numeroRic)
            eq('subalternoRic', this.subalternoRic)
            eq('zonaRic', this.zonaRic)
        }
    }
    public Cuarcuiu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
