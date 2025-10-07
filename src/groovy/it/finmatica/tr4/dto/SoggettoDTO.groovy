package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.DatoGenerale
import it.finmatica.tr4.Soggetto

class SoggettoDTO implements DTO<Soggetto> {
    private static final long serialVersionUID = 1L

    Long id
    ArchivioVieDTO archivioVie
    Integer cap
    Long codFam
    String codFiscale
    String codFiscaleRap
    Integer codProf
    String cognome
    String cognomeNome
    Ad4ComuneTr4DTO comuneEvento
    Ad4ComuneTr4DTO comuneNascita
    Ad4ComuneTr4DTO comuneRap
    Ad4ComuneTr4DTO comuneResidenza
    Date dataNas
    Date dataUltEve
    Date lastUpdated
    String denominazioneVia
    So4AmministrazioneDTO ente
    Set<FamiliareSoggettoDTO> familiariSoggetto
    Integer fascia
    boolean flagCfCalcolato
    boolean flagEsenzione
    FonteDTO fonte
    String gruppoUtente
    String indirizzoRap
    Integer interno
    String intestatarioFam
    Long matricola
    SoggettoDTO soggettoPresso
    String nome
    String note
    Integer numCiv
    String partitaIva
    Byte pensionato
    String piano
    String rapportoPar
    String rappresentante
    String scala
    Byte sequenzaPar
    String sesso
    AnadevDTO stato
    Set<StoricoSoggettiDTO> storicoSoggetto
    String suffisso
    String tipo
    TipoCaricaDTO tipoCarica
    boolean tipoResidente = true
    Ad4UtenteDTO utente
    String zipcode
    String nomeRic
    String cognomeRic

    Set<EredeSoggettoDTO> erediSoggetto
    Set<RecapitoSoggettoDTO> recapitiSoggetto
    Set<ContribuenteDTO> contribuenti = []

    void addToFamiliariSoggetto(FamiliareSoggettoDTO familiareSoggetto) {
        if (this.familiariSoggetto == null)
            this.familiariSoggetto = new HashSet<FamiliareSoggettoDTO>()
        this.familiariSoggetto.add(familiareSoggetto)
        familiareSoggetto.soggetto = this
    }

    void removeFromFamiliariSoggetto(FamiliareSoggettoDTO familiareSoggetto) {
        if (this.familiariSoggetto == null)
            this.familiariSoggetto = new HashSet<FamiliareSoggettoDTO>()
        this.familiariSoggetto.remove(familiareSoggetto)
        familiareSoggetto.soggetto = null
    }

    void addToStoricoSoggetto(StoricoSoggettiDTO storicoSoggetti) {
        if (this.storicoSoggetto == null)
            this.storicoSoggetto = new HashSet<StoricoSoggettiDTO>()
        this.storicoSoggetto.add(storicoSoggetti)
        storicoSoggetti.soggetto = this
    }

    void removeFromStoricoSoggetto(StoricoSoggettiDTO storicoSoggetti) {
        if (this.storicoSoggetto == null)
            this.storicoSoggetto = new HashSet<StoricoSoggettiDTO>()
        this.storicoSoggetto.remove(storicoSoggetti)
        storicoSoggetti.soggetto = null
    }

    void addToErediSoggetto(EredeSoggettoDTO eredeSoggetto) {
        if (this.erediSoggetto == null)
            this.erediSoggetto = new HashSet<EredeSoggettoDTO>()
        this.erediSoggetto.add(eredeSoggetto)
        eredeSoggetto.soggetto = this
    }

    void removeFromErediSoggetto(EredeSoggettoDTO eredeSoggetto) {
        if (this.erediSoggetto == null)
            this.erediSoggetto = new HashSet<EredeSoggettoDTO>()
        this.erediSoggetto.remove(eredeSoggetto)
        eredeSoggetto.soggetto = null
    }

    void addToRecapitiSoggetto(RecapitoSoggettoDTO recapitoSoggetto) {
        if (this.recapitiSoggetto == null)
            this.recapitiSoggetto = new HashSet<RecapitoSoggettoDTO>()
        this.recapitiSoggetto.add(recapitoSoggetto)
        recapitoSoggetto.soggetto = this
    }

    void removeFromRecapitiSoggetto(RecapitoSoggettoDTO recapitoSoggetto) {
        if (this.recapitiSoggetto == null)
            this.recapitiSoggetto = new HashSet<RecapitoSoggettoDTO>()
        this.recapitiSoggetto.remove(recapitoSoggetto)
        recapitoSoggetto.soggetto = null
    }

    void addToContribuenti(ContribuenteDTO contribuente) {
        if (this.contribuenti == null)
            this.contribuenti = new HashSet<ContribuenteDTO>()
        this.contribuenti.add(contribuente)
        contribuente.soggetto = this
    }

    void removeFromContribuenti(ContribuenteDTO contribuente) {
        if (this.contribuenti == null)
            this.contribuenti = new HashSet<ContribuenteDTO>()
        this.contribuenti.remove(contribuente)
        contribuente.soggetto = null
    }

    Soggetto getDomainObject() {
        return Soggetto.get(this.id)
    }

    Soggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    String getIndirizzo() {
        return (archivioVie ? archivioVie?.denomUff : denominazioneVia ?: "") +
                (numCiv ? ", $numCiv" : "") +
                (suffisso ? "/$suffisso" : "") +
                (scala ? " Sc.$scala" : "") +
                (piano ? " P.$piano" : "") +
                (interno ? " Int.$interno" : "")
    }

    boolean gsd

    String getResidente() {
        //decode(dati_generali.flag_integrazione_gsd,null,soggetti.tipo_residente,decode( soggetti.tipo_residente,0, decode(soggetti.fascia,1,'SI',3,'NI','NO'),'NO')) Residente,
        boolean integrazioneGSD = DatoGenerale.findByChiave(Long.valueOf(1)).flagIntegrazioneGsd ?: "N".equals("S")

        if (integrazioneGSD) {
            if (!tipoResidente) {
                if (fascia?.value == 1) {
                    return "SI"
                } else if (fascia?.value == 3) {
                    return "NI"
                } else {
                    return "NO"
                }
            } else {
                return "NO"
            }
        }
        else {
            //tipo_residente (0 = True, 1 = False)
            if(tipoResidente){
                return "NO"
            }
            else {
                return "SI"
            }
        }
    }

    boolean isGsd() {
        return !tipoResidente
    }

    String getResidenza() {
        String capRes = cap ? cap : comuneResidenza?.ad4Comune?.cap
        return (capRes ? capRes + " " : "") +
                (comuneResidenza?.ad4Comune?.denominazione ? comuneResidenza?.ad4Comune?.denominazione + " " : "") +
                (comuneResidenza?.ad4Comune?.provincia?.sigla ? comuneResidenza?.ad4Comune?.provincia?.sigla + " " : "")
    }

    void setContribuente(ContribuenteDTO contribuente) {
        addToContribuenti(contribuente)
    }

    ContribuenteDTO getContribuente() {
        (contribuenti && !contribuenti.isEmpty()) ? contribuenti[0] : null
    }
}
