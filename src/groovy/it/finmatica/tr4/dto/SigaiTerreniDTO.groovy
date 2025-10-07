package it.finmatica.tr4.dto;

import it.finmatica.tr4.SigaiTerreni;

import java.util.Map;

public class SigaiTerreniDTO implements it.finmatica.dto.DTO<SigaiTerreni> {
    private static final long serialVersionUID = 1L;

    Long id;
    String annoFiscale;
    String areaFab;
    String centServ;
    String centroCons;
    String comune;
    String condDir;
    String dataSit;
    String dedIlor;
    String esenzione;
    String fDichCong;
    String fiscale;
    String indirizzo;
    String invio;
    String istatCom;
    String mesiApplRidu;
    String mesiEscEsenzi;
    String mesiPoss;
    String numOrdTerr;
    String partitaCat;
    String perPoss;
    String persona;
    String possesso;
    String progMod;
    String progressivo;
    String prov;
    String proviidd;
    String qtRedAgrIlor;
    String qtRedAgrIrpef;
    String qtRedDomIlor;
    String qtRedDomIrpef;
    String recoModificato;
    String reddNom;
    String relazione;
    String riduzione;
    String soggIci;
    String tdich;
    String titolo;
    String totReddAgr;
    String totReddDom;
    String uffIidd;
    String valoreIsi;


    public SigaiTerreni getDomainObject () {
        return SigaiTerreni.createCriteria().get {
            eq('fiscale', this.fiscale)
            eq('persona', this.persona)
            eq('dataSit', this.dataSit)
            eq('centroCons', this.centroCons)
            eq('proviidd', this.proviidd)
            eq('uffIidd', this.uffIidd)
            eq('centServ', this.centServ)
            eq('tdich', this.tdich)
            eq('progMod', this.progMod)
            eq('comune', this.comune)
            eq('istatCom', this.istatCom)
            eq('prov', this.prov)
            eq('numOrdTerr', this.numOrdTerr)
            eq('partitaCat', this.partitaCat)
            eq('soggIci', this.soggIci)
            eq('condDir', this.condDir)
            eq('areaFab', this.areaFab)
            eq('reddNom', this.reddNom)
            eq('perPoss', this.perPoss)
            eq('fDichCong', this.fDichCong)
            eq('totReddDom', this.totReddDom)
            eq('qtRedDomIrpef', this.qtRedDomIrpef)
            eq('qtRedDomIlor', this.qtRedDomIlor)
            eq('valoreIsi', this.valoreIsi)
            eq('titolo', this.titolo)
            eq('totReddAgr', this.totReddAgr)
            eq('qtRedAgrIrpef', this.qtRedAgrIrpef)
            eq('qtRedAgrIlor', this.qtRedAgrIlor)
            eq('dedIlor', this.dedIlor)
            eq('progressivo', this.progressivo)
            eq('recoModificato', this.recoModificato)
            eq('invio', this.invio)
            eq('relazione', this.relazione)
            eq('annoFiscale', this.annoFiscale)
            eq('mesiPoss', this.mesiPoss)
            eq('mesiEscEsenzi', this.mesiEscEsenzi)
            eq('mesiApplRidu', this.mesiApplRidu)
            eq('possesso', this.possesso)
            eq('esenzione', this.esenzione)
            eq('riduzione', this.riduzione)
            eq('indirizzo', this.indirizzo)
        }
    }
    public SigaiTerreni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
