package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.Ruolo

class RuoloDTO implements DTO<Ruolo> {
    private static final long serialVersionUID = 1L

    Long id
    Short aAnnoRuolo
    Short annoEmissione
    Short annoRuolo
    Short codSede
    String cognomeResp
    Date dataDenuncia
    Date dataEmissione
    Date dataFineInteressi
    Date lastUpdated
    String descrizione
    So4AmministrazioneDTO ente
    boolean importoLordo
    Date invioConsorzio
    String nomeResp
    String note
    Set<OggettoImpostaDTO> oggettiImposta
    Short progrEmissione
    Short rate
    Set<RuoloContribuenteDTO> ruoliContribuente
    Set<RuoloEccedenzaDTO> ruoliEccedenze
    RuoloDTO ruoloMaster
    RuoloDTO ruoloRif
    Date scadenzaPrimaRata
    Date scadenzaRata2
    Date scadenzaRata3
    Date scadenzaRata4
    boolean specieRuolo
    String statoRuolo
    String tipoCalcolo
    String tipoEmissione
    int tipoRuolo
    TipoTributoDTO tipoTributo
    Ad4UtenteDTO utente
    Set<VersamentoDTO> versamenti
    BigDecimal percAcconto
    String flagCalcoloTariffaBase
    String flagTariffeRuolo
    Date scadenzaAvviso1
    Date scadenzaAvviso2
    Date scadenzaAvviso3
    Date scadenzaAvviso4
	Date scadenzaRataUnica
	Date scadenzaAvvisoUnico
    String flagDePag
    String flagIscrittiAltroRuolo
    String flagEliminaDepag

    Date terminePagamento
    Short progrInvio

    void addToOggettiImposta(OggettoImpostaDTO oggettoImposta) {
        if (this.oggettiImposta == null)
            this.oggettiImposta = new HashSet<OggettoImpostaDTO>()
        this.oggettiImposta.add(oggettoImposta)
        oggettoImposta.ruolo = this
    }

    void removeFromOggettiImposta(OggettoImpostaDTO oggettoImposta) {
        if (this.oggettiImposta == null)
            this.oggettiImposta = new HashSet<OggettoImpostaDTO>()
        this.oggettiImposta.remove(oggettoImposta)
        oggettoImposta.ruolo = null
    }

    void addToRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
        if (this.ruoliContribuente == null)
            this.ruoliContribuente = new HashSet<RuoloContribuenteDTO>()
        this.ruoliContribuente.add(ruoloContribuente)
        ruoloContribuente.ruolo = this
    }

    void removeFromRuoliContribuente(RuoloContribuenteDTO ruoloContribuente) {
        if (this.ruoliContribuente == null)
            this.ruoliContribuente = new HashSet<RuoloContribuenteDTO>()
        this.ruoliContribuente.remove(ruoloContribuente)
        ruoloContribuente.ruolo = null
    }

    void addToruoliEccedenze(RuoloEccedenzaDTO ruoloEccedenza) {
        if (this.ruoliEccedenze == null)
            this.ruoliEccedenze = new HashSet<RuoloEccedenzaDTO>()
        this.ruoliEccedenze.add(ruoloEccedenza)
        ruoloEccedenza.ruolo = this
    }

    void removeFromruoliEccedenze(RuoloEccedenzaDTO ruoloEccedenza) {
        if (this.ruoliEccedenze == null)
            this.ruoliEccedenze = new HashSet<RuoloEccedenzaDTO>()
        this.ruoliEccedenze.remove(ruoloEccedenza)
        ruoloEccedenza.ruolo = null
    }

    void addToVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.add(versamento)
        versamento.ruolo = this
    }

    void removeFromVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.remove(versamento)
        versamento.ruolo = null
    }

    Ruolo getDomainObject() {
        return Ruolo.get(this.id)
    }

    Ruolo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
