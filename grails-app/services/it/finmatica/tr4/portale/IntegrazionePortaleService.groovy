package it.finmatica.tr4.portale

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.SessionFactory
import org.springframework.beans.factory.annotation.Autowired

import javax.annotation.PostConstruct

class IntegrazionePortaleService {

    private static Log log = LogFactory.getLog(IntegrazionePortaleService.class)

    final static def STEP_RICEVUTO = "RICEVUTO"

    @Autowired
    List<IntegrazionePortaleStrategy> allStrategies

    private Map<String, IntegrazionePortaleStrategy> strategyMap = [:]

    SpringSecurityService springSecurityService
    SessionFactory sessionFactory

    @PostConstruct
    void init() {

        if (allStrategies) {
            allStrategies.each { strategy ->
                if (strategy.getTipoTributoSupportato()) {
                    log.info "Registrazione strategy per tipo tributo: ${strategy.getTipoTributoSupportato()} -> ${strategy.class.simpleName}"
                    strategyMap[strategy.getTipoTributoSupportato().toUpperCase()] = strategy
                } else {
                    log.warn "Strategy ${strategy.class.simpleName} non ha un tipo tributo supportato definito."
                }
            }
        } else {
            log.warn "Nessuna IntegrazionePortaleStrategy trovata/iniettata."
        }
    }

    private IntegrazionePortaleStrategy getStrategy(String tipoTributo) {
        def strategyKey = tipoTributo?.toUpperCase()
        def strategy = strategyMap[strategyKey]
        if (!strategy) {
            log.error "Nessuna strategy trovata per il tipo tributo: ${tipoTributo} (chiave usata: ${strategyKey})"
            throw new IllegalArgumentException("Tipo tributo non supportato: ${tipoTributo}")
        }
        return strategy
    }

    def elencoPratiche(def filtri) {
        if (!integrazionePortaleAttiva()) {
            return []
        }

        return SprVPratiche.createCriteria().list() {
            if (filtri.tipoTributo) {
                eq('tipoTributo', filtri.tipoTributo)
            }

            if (filtri.step) {
                eq('chiaveStep', filtri.step)
            }

            order('dataRichiesta')
        }.toDTO()
    }

    List<Object> elencoDettagliPratica(Long idPratica, String tipoTributo) {

        if (!integrazionePortaleAttiva()) {
            return []
        }

        if (idPratica == null || tipoTributo == null) {
            log.warn "ID pratica o tipo tributo non forniti per elencoDettagliPratica. idPratica: ${idPratica}, tipoTributo: ${tipoTributo}"
            return []
        }
        try {
            IntegrazionePortaleStrategy strategy = getStrategy(tipoTributo)
            log.debug "Recupero dettagli per pratica ID: ${idPratica}, Tipo Tributo: ${tipoTributo} con strategy: ${strategy.class.simpleName}"
            return strategy.elencoDettagliPratica(idPratica)
        } catch (IllegalArgumentException e) {
            // Loggato già da getStrategy
            return [] // O rilanciare l'eccezione se il chiamante deve gestirla diversamente
        } catch (Exception e) {
            log.error "Errore durante il recupero dei dettagli per pratica ID: ${idPratica}, Tipo Tributo: ${tipoTributo}", e
            return [] // O rilanciare
        }
    }

    String praticheDaImportare(String tipoTributo, def codFiscale = null) {

        if (!integrazionePortaleAttiva()) {
            return ''
        }

        def tt = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributo }

        if (!tipoTributo) {
            log.warn "Tipo tributo non specificato per praticheDaImportare."
            return ""
        }

        long nPratiche = SprVPratiche.createCriteria().get {
            projections {
                count('id')
            }
            eq('tipoTributo', tipoTributo)
            eq('chiaveStep', STEP_RICEVUTO)

            if (codFiscale) {
                or {
                    eq('codiceFiscaleBen', codFiscale)
                    eq('partitaIvaBen', codFiscale)
                }
            }
        } ?: 0L

        def strPratica = nPratiche != 1L ? 'pratiche' : 'pratica'
        def suffisso = "da importare da portale per ${tt.getTipoTributoAttuale()}"
        return nPratiche > 0L ? "$nPratiche $strPratica $suffisso" : ''
    }

    def acquisisciPratiche(def praticheDaAcquisire, String tipoTributo) {

        if (!integrazionePortaleAttiva()) {
            return "Servizio non attivo."
        }

        if (!praticheDaAcquisire || praticheDaAcquisire.isEmpty()) {
            log.info "Nessuna pratica fornita per l'acquisizione (Tipo: ${tipoTributo})."
            return "Nessuna pratica fornita."
        }
        if (!tipoTributo) {
            log.error "Tipo tributo non specificato per acquisisciPratiche."
            throw new IllegalArgumentException("Tipo tributo non specificato.")
        }

        IntegrazionePortaleStrategy strategy = getStrategy(tipoTributo)

        if (!strategy) {
            log.error "Nessuna strategy trovata per il tipo tributo: ${tipoTributo}"
            throw new IllegalArgumentException("Tipo tributo non supportato: ${tipoTributo}")
        }

        strategy.acquisisciPratiche(praticheDaAcquisire)

    }

    def validaPratiche(def idPratiche) {

        if (!integrazionePortaleAttiva()) {
            return "Servizio non attivo."
        }

        if (!idPratiche || idPratiche.isEmpty()) {
            return 'Nessuna pratica fornita.'
        }

        def singona = idPratiche.size() == 1

        idPratiche?.each {
            def prtr = PraticaTributo.get(it)
            prtr.tipoPratica = 'D'
            prtr.save(flush: true, failOnError: true)
        }

        if (singona) {
            return "Pratica validata con successo"
        } else {
            return "Pratiche validate con successo"
        }
    }

    def integrazionePortaleAttiva() {
        return OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "PORT_INT" }?.valore == 'S'
    }
}
