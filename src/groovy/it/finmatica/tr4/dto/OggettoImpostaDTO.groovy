package it.finmatica.tr4.dto

import grails.util.Holders
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.OggettoImposta
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO

class OggettoImpostaDTO implements DTO<OggettoImposta> {
    private static final long serialVersionUID = 1L

    Long id
    BigDecimal addizionaleEca
    BigDecimal addizionalePro
    BigDecimal aliquota
    BigDecimal aliquotaErariale
    BigDecimal aliquotaIva
    BigDecimal aliquotaStd
    Short anno
    Date lastUpdated
    BigDecimal detrazione
    BigDecimal detrazioneAcconto
    BigDecimal detrazioneFigli
    BigDecimal detrazioneFigliAcconto
    BigDecimal detrazioneImponibile
    BigDecimal detrazioneImponibileAcconto
    BigDecimal detrazioneImponibileD
    BigDecimal detrazioneImponibileDAcc
    BigDecimal detrazioneRimanenteCain
    BigDecimal detrazioneRimanenteCainAcc
    BigDecimal detrazioneStd
    String dettaglioOgim
    BigDecimal fattura
    boolean flagCalcolo
    BigDecimal imponibile
    BigDecimal imponibileD
    BigDecimal importoPf
    BigDecimal importoPv
    BigDecimal importoRuolo
    BigDecimal importoVersato
    BigDecimal imposta
    BigDecimal impostaAcconto
    BigDecimal impostaAccontoPrePerc
    BigDecimal impostaAliquota
    BigDecimal impostaDovuta
    BigDecimal impostaDovutaAcconto
    BigDecimal impostaDovutaMini
    BigDecimal impostaDovutaStd
    BigDecimal impostaErariale
    BigDecimal impostaErarialeAcconto
    BigDecimal impostaErarialeDovuta
    BigDecimal impostaErarialeDovutaAcc
    BigDecimal impostaMini
    BigDecimal impostaPrePerc
    BigDecimal impostaStd
    BigDecimal iva
    BigDecimal maggiorazioneEca
    BigDecimal maggiorazioneTares
    BigDecimal detrazionePrec
    BigDecimal aliquotaPrec
    BigDecimal aliquotaErarPrec
    Short mesiAffitto
    Short mesiPossesso
    String note
    Long numBollettino
    BigDecimal percentuale
    RuoloDTO ruolo
    TipoTributoDTO tipoTributo
    String tipoRapporto
    String utente

    BigDecimal aliquotaAcconto

    Short tipoTariffaBase
    BigDecimal impostaBase
    BigDecimal addizionaleEcaBase
    BigDecimal maggiorazioneEcaBase
    BigDecimal addizionaleProBase
    BigDecimal ivaBase
    BigDecimal importoPfBase
    BigDecimal importoPvBase
    BigDecimal importoRuoloBase
    String dettaglioOgimBase
    BigDecimal percRiduzionePf
    BigDecimal percRiduzionePv
    BigDecimal importoRiduzionePf
    BigDecimal importoRiduzionePv
    Short daMesePossesso
    BigDecimal impostaPeriodo

    TipoAliquotaDTO tipoAliquota
    TipoAliquotaDTO tipoAliquotaPrec
    OggettoContribuenteDTO oggettoContribuente

    SortedSet<RuoloContribuenteDTO> ruoliContribuente
    Set<FamiliareOgimDTO> familiariOgim
    Set<RataImpostaDTO> rateImposta
    Set<VersamentoDTO> versamenti

    def presentiAliquote
    def presentiDetrazioni

    OggettoImposta getDomainObject() {
        return OggettoImposta.get(this.id)
    }

    OggettoImposta toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    void addToRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
        if (this.ruoliContribuente == null)
            this.ruoliContribuente = new TreeSet<RuoloContribuenteDTO>()
        this.ruoliContribuente.add(ruoloContribuente)
        ruoloContribuente.oggettoImposta = this
    }

    void addToVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.add(versamento)
        versamento.oggettoImposta = this
    }

    void addToRateImposta(RataImpostaDTO rataImposta) {
        if (this.rateImposta == null)
            this.rateImposta = new HashSet<RataImpostaDTO>()
        this.rateImposta.add(rataImposta)
        rataImposta.oggettoImposta = this
    }

    void removeFromRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
        if (this.ruoliContribuente == null)
            this.ruoliContribuente = new TreeSet<RuoloContribuenteDTO>()
        this.ruoliContribuente.remove(ruoloContribuente)
        ruoloContribuente.oggettoImposta = null
    }

    void addToFamiliariOgim(FamiliareOgimDTO familiareOgim) {
        if (this.familiariOgim == null)
            this.familiariOgim = new HashSet<FamiliareOgimDTO>()
        this.familiariOgim.add(familiareOgim)
        familiareOgim.oggettoImposta = this
    }

    void removeFromRuoliContribuente(FamiliareOgimDTO familiareOgim) {
        if (this.familiariOgim == null)
            this.familiariOgim = new HashSet<FamiliareOgimDTO>()
        this.familiariOgim.remove(familiareOgim)
        familiareOgim.oggettoImposta = null
    }

    void removeFromVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.remove(versamento)
        versamento.oggettoImposta = null
    }

    void removeFromRateImposta(RataImpostaDTO rataImposta) {
        if (this.rateImposta == null)
            this.rateImposta = new HashSet<RataImpostaDTO>()
        this.rateImposta.remove(rataImposta)
        rataImposta.oggettoImposta = null
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    /***********************************************************************
     * SOLO PER CALCOLO INDIVIDUALE
     * Se tipoOggetto 3 o 55
     * calcola il valore a partire dalla rendita,
     * altrimenti restituisce null
     * @return valore a partire dalla rendita
     ********************************************************************** */
    BigDecimal getValoreDaRendita() {
        OggettoPraticaDTO ogpr = this.oggettoContribuente.oggettoPratica
        CommonService commonService = (CommonService) Holders.getApplicationContext().getBean('commonService')
        return commonService.valoreDaRendita(ogpr?.valore, ogpr?.tipoOggetto
                , anno, ogpr?.categoriaCatasto, ogpr?.immStorico)
    }

    boolean selezionato = false

}
