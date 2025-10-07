package it.finmatica.tr4.dto;

import it.finmatica.tr4.Catele;

import java.util.Map;

public class CateleDTO implements it.finmatica.dto.DTO<Catele> {
    private static final long serialVersionUID = 1L;

    Long id;
    Byte anno;
    Integer capFornitura;
    Integer capRec;
    String codAtt;
    String codAttNew;
    String codAzienda;
    String codComAmm;
    String codComune;
    Boolean codFisPro;
    Boolean codFisUt;
    String codFiscale;
    String codFiscalePro;
    String codUtente;
    String comNasPro;
    String comuneNas;
    String dataNas;
    String dataNasPro;
    Boolean datiImm;
    String denominazione;
    String denominazionePro;
    Boolean dup;
    String filRec;
    Boolean flagCodFisPro;
    Boolean flagCodFisUte;
    String foglio;
    String indRec;
    String indirizzo;
    Boolean infQuest;
    String interno;
    String locRec;
    String localitaFornitura;
    String nomRec;
    String numero;
    String partitaIva;
    String piano;
    String protocollo;
    String provinciaPro;
    String provinciaUte;
    Boolean rurale;
    String scala;
    String sesso;
    String sessoPro;
    String sezione;
    String subalterno;
    Integer supImmobile;
    Boolean superficieImm;
    Boolean utenza;
    String utilizzato;


    public Catele getDomainObject () {
        return Catele.createCriteria().get {
            eq('codComune', this.codComune)
            eq('codAzienda', this.codAzienda)
            eq('codUtente', this.codUtente)
            eq('codFiscale', this.codFiscale)
            eq('denominazione', this.denominazione)
            eq('sesso', this.sesso)
            eq('dataNas', this.dataNas)
            eq('comuneNas', this.comuneNas)
            eq('provinciaUte', this.provinciaUte)
            eq('sezione', this.sezione)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('protocollo', this.protocollo)
            eq('anno', this.anno)
            eq('indirizzo', this.indirizzo)
            eq('scala', this.scala)
            eq('piano', this.piano)
            eq('interno', this.interno)
            eq('capFornitura', this.capFornitura)
            eq('utilizzato', this.utilizzato)
            eq('localitaFornitura', this.localitaFornitura)
            eq('supImmobile', this.supImmobile)
            eq('rurale', this.rurale)
            eq('codComAmm', this.codComAmm)
            eq('codFiscalePro', this.codFiscalePro)
            eq('denominazionePro', this.denominazionePro)
            eq('sessoPro', this.sessoPro)
            eq('dataNasPro', this.dataNasPro)
            eq('comNasPro', this.comNasPro)
            eq('provinciaPro', this.provinciaPro)
            eq('utenza', this.utenza)
            eq('nomRec', this.nomRec)
            eq('indRec', this.indRec)
            eq('capRec', this.capRec)
            eq('filRec', this.filRec)
            eq('locRec', this.locRec)
            eq('flagCodFisUte', this.flagCodFisUte)
            eq('flagCodFisPro', this.flagCodFisPro)
            eq('dup', this.dup)
            eq('codFisUt', this.codFisUt)
            eq('datiImm', this.datiImm)
            eq('superficieImm', this.superficieImm)
            eq('codFisPro', this.codFisPro)
            eq('infQuest', this.infQuest)
            eq('codAtt', this.codAtt)
            eq('codAttNew', this.codAttNew)
            eq('partitaIva', this.partitaIva)
        }
    }
    public Catele toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
