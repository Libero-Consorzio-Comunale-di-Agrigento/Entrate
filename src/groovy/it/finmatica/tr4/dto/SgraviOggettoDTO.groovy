package it.finmatica.tr4.dto;

import it.finmatica.tr4.SgraviOggetto;

import java.util.Date;
import java.util.Map;

public class SgraviOggettoDTO implements it.finmatica.dto.DTO<SgraviOggetto> {
    private static final long serialVersionUID = 1L;

//  Long id;
	RuoloContribuenteDTO ruoloContribuente
    Byte aMeseRuco;
    Byte aMeseSgra;
    BigDecimal addizionaleEca;
    BigDecimal addizionalePro;
    String codFiscale;
    Byte daMeseRuco;
    Byte daMeseSgra;
    Date dataElenco;
    Short giorniRuolo;
    Short giorniSgravio;
    BigDecimal importo;
    BigDecimal importoLordo;
    BigDecimal imposta;
    BigDecimal iva;
    BigDecimal maggiorazioneEca;
    BigDecimal maggiorazioneTares;
    Byte motivoSgravio;
    BigDecimal nettoSgravi;
    Short numeroElenco;
    RuoloDTO ruolo;
    Byte semestri;
    Short sequenza;
    Short sequenzaSgravio;
    String tipoSgravio;


    public SgraviOggetto getDomainObject () {
        return SgraviOggetto.createCriteria().get {
//          eq('ruolo', this.ruolo)
//          eq('codFiscale', this.codFiscale)
//          eq('sequenza', this.sequenza)
			eq('ruolo', this.ruolo)
			eq('ruoloContribuente.contribuente.codFiscale', this.ruoloContribuente.contribuente.codFiscale)
			eq('sequenza', this.sequenza)
            eq('sequenzaSgravio', this.sequenzaSgravio)
            eq('motivoSgravio', this.motivoSgravio)
            eq('numeroElenco', this.numeroElenco)
            eq('dataElenco', this.dataElenco)
            eq('importo', this.importo)
            eq('nettoSgravi', this.nettoSgravi)
            eq('semestri', this.semestri)
            eq('addizionaleEca', this.addizionaleEca)
            eq('maggiorazioneEca', this.maggiorazioneEca)
            eq('addizionalePro', this.addizionalePro)
            eq('iva', this.iva)
            eq('maggiorazioneTares', this.maggiorazioneTares)
            eq('importoLordo', this.importoLordo)
            eq('imposta', this.imposta)
            eq('daMeseRuco', this.daMeseRuco)
            eq('aMeseRuco', this.aMeseRuco)
            eq('daMeseSgra', this.daMeseSgra)
            eq('aMeseSgra', this.aMeseSgra)
            eq('tipoSgravio', this.tipoSgravio)
            eq('giorniRuolo', this.giorniRuolo)
            eq('giorniSgravio', this.giorniSgravio)
        }
    }
    public SgraviOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
