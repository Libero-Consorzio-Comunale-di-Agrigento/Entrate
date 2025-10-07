package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.AnciVer

public class AnciVerDTO implements it.finmatica.dto.DTO<AnciVer> {
    private static final long serialVersionUID = 1L;

    Long id;
    Long abPrincipale;
    String accontoSaldo;
    Long altriFabbricati;
    Short annoFiscale;
    Short annoImposta;
    Long areeFabbricabili;
    Integer cap;
    String codCatasto;
    String codFiscale;
    String comune;
    Short concessione;
    Date dataProvvedimento;
    Integer dataReg;
    Date dataVersamento;
    Integer detrazione;
    Integer detrazioneEffettiva;
    String ente;
    Short fabbricati;
    String flagCompetenzaVer;
    String flagContribuente;
    String flagExRurali;
    Boolean flagIdentificazione;
    String flagQuadratura;
    Boolean flagRavvedimento;
    String flagSquadratura;
    String flagZero;
    Byte fonte;
    Long importoVersato;
    Long imposta;
    Long impostaCalcolata;
    Long interessi;
    Integer numProvvedimento;
    Long progrQuietanza;
    Integer progrRecord;
    String quietanza;
    String sanzioneRavvedimento;
    Long sanzioni1;
    Long sanzioni2;
    Long terreniAgricoli;
    Byte tipoAnomalia;
    String tipoRecord;
    Integer tipoVersamento;
    String flagOk
    ContribuenteDTO contribuente

    public AnciVer getDomainObject() {
        return AnciVer.createCriteria().get {
            eq('progrRecord', this.progrRecord)
            eq('annoFiscale', this.annoFiscale)
        }
    }

    public AnciVer toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
