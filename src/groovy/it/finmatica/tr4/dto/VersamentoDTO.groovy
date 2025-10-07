package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Versamento
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

class VersamentoDTO implements DTO<Versamento>, Comparable<VersamentoDTO> {
    private static final long serialVersionUID = 1L

    def uuid = UUID.randomUUID().toString().replace('-', '')

    Long id
    BigDecimal abPrincipale
    BigDecimal altriComune
    BigDecimal altriErariale
    BigDecimal altriFabbricati
    BigDecimal fabbricatiMerce
    Short anno
    BigDecimal areeComune
    BigDecimal areeErariale
    BigDecimal areeFabbricabili
    String causale
    ContribuenteDTO contribuente
    Date dataPagamento
    Date dataProvvedimento
    Date dataReg
    Date dataSentenza
    Date lastUpdated
    String descrizione
    BigDecimal detrazione
    String estremiProvvedimento
    String estremiSentenza
    Short fabbricati
    BigDecimal fabbricatiD
    BigDecimal fabbricatiDComune
    BigDecimal fabbricatiDErariale
    Long fattura
    FonteDTO fonte
    BigDecimal importoVersato
    Long imposta
    Long interessi
    BigDecimal maggiorazioneTares
    String note
    Long numBollettino
    Short numFabbricatiAb
    Short numFabbricatiAltri
    Short numFabbricatiMerce
    Short numFabbricatiAree
    Short numFabbricatiD
    Short numFabbricatiRurali
    Short numFabbricatiTerreni
    OggettoImpostaDTO oggettoImposta
    Long ogprOgim
    PraticaTributoDTO pratica
    Long progrAnci
    Integer provvedimento
    Short rata
    RataImpostaDTO rataImposta
    RuoloDTO ruolo
    BigDecimal rurali
    BigDecimal ruraliComune
    BigDecimal ruraliErariale
    BigDecimal sanzioni1
    BigDecimal sanzioni2
    Short sequenza
    BigDecimal speseMora
    BigDecimal speseSpedizione
    BigDecimal terreniAgricoli
    BigDecimal terreniComune
    BigDecimal terreniErariale
    TipoTributoDTO tipoTributo
    String tipoVersamento
    String ufficioPt
    Long idCompensazione
    String utente
    Long documentoId
	
	String servizio
	String idback

    BigDecimal addizionalePro
    BigDecimal sanzioniAddPro
    BigDecimal interessiAddPro

    // Proprietà non salvate in DB
    boolean nuovo = false
    boolean eliminato = false

    Versamento getDomainObject() {
        return Versamento.createCriteria().get {
            eq('contribuente.codFiscale', this.contribuente.codFiscale)
            eq('anno', this.anno)
            eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
            eq('sequenza', this.sequenza)
        }
    }

    Versamento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    String getDescrizioneTributo() {
        tipoTributo.getTipoTributoAttuale(anno)
    }

    @Override
    int compareTo(VersamentoDTO vers) {
        contribuente.codFiscale <=> vers.contribuente.codFiscale ?:
                tipoTributo.tipoTributo <=> vers.tipoTributo.tipoTributo ?:
                        vers.anno <=> anno ?:
                                vers.dataPagamento <=> dataPagamento ?:
                                        vers.tipoVersamento <=> tipoVersamento ?:
                                                vers.pratica?.id <=> pratica?.id ?:
                                                        rata <=> vers.rata ?:
                                                                sequenza <=> vers.sequenza
    }

    BigDecimal getTotaleDaVersare() {

        BigDecimal totale

        String tipoTributo = tipoTributo?.tipoTributo ?: '-'

        switch (tipoTributo) {
            case ['CUNI', 'ICP', 'TOSAP']:
                totale = (imposta ?: 0) + (sanzioni1 ?: 0) + (interessi ?: 0) + (speseSpedizione ?: 0) + (speseMora ?: 0)
                break
            case 'TARSU':
                totale = (imposta ?: 0) + (sanzioni1 ?: 0) + (interessi ?: 0) +
                        (addizionalePro ?: 0) + (sanzioniAddPro ?: 0) + (interessiAddPro ?: 0) +
                        (speseSpedizione ?: 0) + (speseMora ?: 0)
                break
            default:
                totale = (terreniAgricoli ?: 0) + (areeFabbricabili ?: 0) + (abPrincipale ?: 0) + (altriFabbricati ?: 0) +
                        (rurali ?: 0) + (fabbricatiD ?: 0) + (fabbricatiMerce ?: 0)
                break
        }

        return totale
    }

    Short getTotaleFabbricati() {
        return (numFabbricatiAb ?: 0) + (numFabbricatiAltri ?: 0) + (numFabbricatiMerce ?: 0) + (numFabbricatiAree ?: 0) +
                (numFabbricatiD ?: 0) + (numFabbricatiRurali ?: 0) + (numFabbricatiTerreni ?: 0)
    }
}
