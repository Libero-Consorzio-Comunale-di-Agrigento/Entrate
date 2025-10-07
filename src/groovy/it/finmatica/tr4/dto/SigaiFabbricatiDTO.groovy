package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiFabbricati;

import java.util.Map;

public class SigaiFabbricatiDTO implements it.finmatica.dto.DTO<SigaiFabbricati> {
    private static final long serialVersionUID = 1L;

    Long id;
    String abitPrinc;
    String annoDeAcc;
    String annoFiscale;
    String cap;
    String caratteristica;
    String catCatastale;
    String classe;
    String comune;
    String datScIlorRedd;
    String dataSit;
    String dePianoEnRedd;
    String detrazPrinc;
    String esclusoEsente;
    String fiscDichCong;
    String fiscale;
    String flagValProv;
    String flagcF;
    String foglio;
    String giorniPossRedd;
    String idenRendValore;
    String immStorico;
    String imponIlor;
    String imponIrpefRedd;
    String indirizzo;
    String invio;
    String istatCom;
    String mesiApplRidu;
    String mesiEscEsenzi;
    String mesiPoss;
    String numOrd;
    String numero;
    String percPoss;
    String percPossRedd;
    String persona;
    String possesso;
    String progMod;
    String progressivo;
    String protocollo;
    String prov;
    String recoModificato;
    String redditoEffRedd;
    String relazione;
    String rendita;
    String renditaRedd;
    String riduzione;
    String riduzione2;
    String sezione;
    String soggIci;
    String soggIsiRedd;
    String subalterno;
    String tdich;
    String tipoImm;
    String titoloRedd;
    String utilizzoRedd;


    public SigaiFabbricati getDomainObject () {
        return SigaiFabbricati.createCriteria().get {
            eq('fiscale', this.fiscale)
            eq('persona', this.persona)
            eq('dataSit', this.dataSit)
            eq('tdich', this.tdich)
            eq('progMod', this.progMod)
            eq('numOrd', this.numOrd)
            eq('caratteristica', this.caratteristica)
            eq('comune', this.comune)
            eq('istatCom', this.istatCom)
            eq('prov', this.prov)
            eq('cap', this.cap)
            eq('indirizzo', this.indirizzo)
            eq('sezione', this.sezione)
            eq('foglio', this.foglio)
            eq('numero', this.numero)
            eq('subalterno', this.subalterno)
            eq('protocollo', this.protocollo)
            eq('annoDeAcc', this.annoDeAcc)
            eq('catCatastale', this.catCatastale)
            eq('classe', this.classe)
            eq('immStorico', this.immStorico)
            eq('idenRendValore', this.idenRendValore)
            eq('flagValProv', this.flagValProv)
            eq('tipoImm', this.tipoImm)
            eq('soggIci', this.soggIci)
            eq('detrazPrinc', this.detrazPrinc)
            eq('riduzione', this.riduzione)
            eq('rendita', this.rendita)
            eq('percPoss', this.percPoss)
            eq('mesiPoss', this.mesiPoss)
            eq('mesiEscEsenzi', this.mesiEscEsenzi)
            eq('mesiApplRidu', this.mesiApplRidu)
            eq('possesso', this.possesso)
            eq('esclusoEsente', this.esclusoEsente)
            eq('riduzione2', this.riduzione2)
            eq('abitPrinc', this.abitPrinc)
            eq('fiscDichCong', this.fiscDichCong)
            eq('flagcF', this.flagcF)
            eq('renditaRedd', this.renditaRedd)
            eq('giorniPossRedd', this.giorniPossRedd)
            eq('percPossRedd', this.percPossRedd)
            eq('redditoEffRedd', this.redditoEffRedd)
            eq('utilizzoRedd', this.utilizzoRedd)
            eq('dePianoEnRedd', this.dePianoEnRedd)
            eq('datScIlorRedd', this.datScIlorRedd)
            eq('imponIrpefRedd', this.imponIrpefRedd)
            eq('titoloRedd', this.titoloRedd)
            eq('soggIsiRedd', this.soggIsiRedd)
            eq('imponIlor', this.imponIlor)
            eq('progressivo', this.progressivo)
            eq('recoModificato', this.recoModificato)
            eq('invio', this.invio)
            eq('relazione', this.relazione)
            eq('annoFiscale', this.annoFiscale)
        }
    }
    public SigaiFabbricati toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
