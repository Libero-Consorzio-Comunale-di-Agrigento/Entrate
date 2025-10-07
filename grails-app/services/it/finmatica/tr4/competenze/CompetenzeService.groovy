package it.finmatica.tr4.competenze

import grails.orm.HibernateCriteriaBuilder
import grails.plugins.springsecurity.SpringSecurityService
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import grails.util.Holders
import it.finmatica.ad4.Ad4Tr4Utente
import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dto.Ad4Tr4UtenteDTO
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.dto.DtoUtils
import it.finmatica.tr4.Funzioni
import it.finmatica.tr4.Si4Abilitazioni
import it.finmatica.tr4.Si4Competenze
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.dto.Si4CompetenzeDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import org.apache.log4j.Logger
import org.codehaus.groovy.runtime.InvokerHelper
import org.hibernate.criterion.*

import javax.annotation.PostConstruct

@Transactional
class CompetenzeService implements GroovyInterceptable {

    static final FUNZIONI = [
            SUPPORTO_SERVIZI_MENU      : "SUPPORTO_SERVIZI_MENU",
            SOGGETTI_INDIRIZZO_EMIGRATO: "SOGGETTI_INDIRIZZO_EMIGRATO",
            GESTIONE_TEFA              : "GESTIONE_TEFA"
    ]

    static final TIPO_OGGETTO = 3L // TIPI TRIBUTO
    static final TIPO_FUNZIONI = 4L // TIPI FUNZIONE

    private static final Logger log = Logger.getLogger(CompetenzeService.class)

    public static final def TIPO_ABILITAZIONE = [
            LETTURA      : "L",
            AGGIORNAMENTO: "A"
    ]


    TributiSession tributiSession
    private SpringSecurityService springSecurityService
    private DatiGeneraliService datiGeneraliService
    def sessionFactory
    CommonService commonService

    @PostConstruct
    def init() {
        // L'injection sulla classe astratta non viene eseguita
        springSecurityService = (SpringSecurityService) Holders.grailsApplication.mainContext
                .getBean("springSecurityService")
        datiGeneraliService = (DatiGeneraliService) Holders.grailsApplication.mainContext
                .getBean("datiGeneraliService")

    }

    @NotTransactional
    def invokeMethod(String name, Object args) {

        // Solo se e' attiva la gestione delle competenze
        if (datiGeneraliService.gestioneCompetenzeAbilitata()) {
            def method = metaClass.theClass.declaredMethods.find { it.name == name }
            CompetenzaScrittura annotation = method?.annotations?.find { it instanceof CompetenzaScrittura }
            if (annotation != null) {
                checkAbilitazioneScrittura(annotation.oggetto(), "${metaClass.theClass.simpleName}.$name")
            }
        }

        def metaClass = InvokerHelper.getMetaClass(this)
        def result = metaClass.invokeMethod(this, name, args)
        return result
    }

    def caricaCompetenze() {
        def currentDate = new Date()
        return Si4Competenze.createCriteria().list {
            createAlias("si4Abilitazioni", "abil", CriteriaSpecification.INNER_JOIN)
            createAlias("abil.si4TipiAbilitazione", "tiab", CriteriaSpecification.INNER_JOIN)

            projections {
                property("oggetto", "oggetto")
                property("tiab.tipoAbilitazione", "tipoAbilitazione")
            }

            eq("utente", springSecurityService?.currentUser as Ad4Utente)
            or {
                le('dal', currentDate)
                isNull('dal')
            }
            or {
                gt('al', currentDate)
                isNull('al')
            }

        }.collect { [oggetto: it[0], tipoAbilitazione: it[1]] }
    }

    // L: lettura, A: aggiornamento, null: non abilitato
    def tipoAbilitazioneUtente(def oggetto) {

        // Se la gestione delle competenze non e' abilitata si restituisce A
        def tipoAbilitazione = ""
        if (!datiGeneraliService.gestioneCompetenzeAbilitata()) {
            tipoAbilitazione = 'A'
        } else {

            tipoAbilitazione = tributiSession.competenze.find { it.oggetto == oggetto }?.tipoAbilitazione
        }

        return tipoAbilitazione
    }

    // Non viene aperto tutto nel caso di gestione delle competenze spenta.
    // Utilizzata per funzionalità tipo SUPPORTO_SERVIZI_MENU da abilitare solo a determinati utenti.
    def tipoAbilitazioneNoCmpetenze(def oggetto) {
        return tributiSession.competenze.find { it.oggetto == oggetto }?.tipoAbilitazione
    }

    boolean isAmministratore() {

        if (!datiGeneraliService.gestioneCompetenzeAbilitata()) {
            return true
        } else {
            return Si4Competenze.createCriteria().count {
                eq('utente.id', springSecurityService.currentUser.id)
                eq("ruolo", 'AMM')
            } > 0
        }
    }

    List<Ad4UtenteDTO> listaUtentiConCompetenze() {

        DetachedCriteria competenze = DetachedCriteria.forClass(Si4Competenze, "comp")
                .setProjection(Projections.property("id"))

        competenze.with {
            add(Restrictions.eqProperty("comp.utente.id", "this.id"))
        }

        def lista = Ad4Utente.createCriteria().list {

            add(new ExistsSubqueryExpression("exists", competenze))

            order("nominativo")
        }

        return DtoUtils.toDto(lista)

    }

    List<Ad4Tr4UtenteDTO> listaUtenti() {

        HibernateCriteriaBuilder criteria = Ad4Tr4Utente.createCriteria()

        def lista = criteria.list {
            createAlias("dirittiAccesso", "diac", CriteriaSpecification.INNER_JOIN)
            createAlias("diac.tr4Istanza", "ista", CriteriaSpecification.INNER_JOIN)

            eq("tipoUtente", "U")
            eq("ista.userOracle", commonService.istanza)

            order("nominativo")

        }

        return DtoUtils.toDto(lista)

    }

    def listaFunzioni() {

        def lista = Funzioni.findAll().sort { it.descrizione }

        return lista
    }

    def isCompetenzaEditable(Si4CompetenzeDTO competenza) {
        def tipoOggettoCompetenza = competenza.si4Abilitazioni.si4TipiOggetto.id
        if (tipoOggettoCompetenza != CompetenzeService.TIPO_FUNZIONI) {
            return true
        }

        def visibleFunzioni = listaFunzioni().findAll { it.flagVisibile }.collect { it.funzione }
        return competenza.oggetto in visibleFunzioni
    }

    def tipoTributiPerUtente(String utente) {

        def lista = Si4Competenze.createCriteria().list {
            createAlias("utente", "uten", CriteriaSpecification.INNER_JOIN)
            createAlias("si4Abilitazioni", "abil", CriteriaSpecification.INNER_JOIN)
            createAlias("abil.si4TipiAbilitazione", "tiab", CriteriaSpecification.INNER_JOIN)
            createAlias("abil.si4TipiOggetto", "tiogg", CriteriaSpecification.INNER_JOIN)


            eq("uten.id", utente)

            'in'("tiogg.id", [3L, 4L])
            order("tiogg.id")
            order("tiab.descrizione")

        }.toDTO(["si4Abilitazioni"])


        lista.each { it ->
            it.tipoOggettoDesc = it.si4Abilitazioni.si4TipiOggetto.id == TIPO_OGGETTO ? "Tipo Tributo" : "Funzione"
            it.descrizioneTributo = it.si4Abilitazioni.si4TipiOggetto.id == TIPO_OGGETTO ?
                    OggettiCache.TIPI_TRIBUTO.valore
                            .find { trib ->
                                trib.tipoTributo == it.oggetto
                            }.getTipoTributoAttuale()
                    : (it.oggetto ? it.oggetto + " - " + Funzioni.get(it.oggetto).descrizione : "")

        }


        return lista
    }

    def competenzePerOggetto(String oggetto, Long tipoOggetto) {

        return Si4Competenze.createCriteria().list {
            createAlias("utente", "uten", CriteriaSpecification.INNER_JOIN)
            createAlias("si4Abilitazioni", "abil", CriteriaSpecification.INNER_JOIN)
            createAlias("abil.si4TipiOggetto", "tiog", CriteriaSpecification.INNER_JOIN)
            createAlias("abil.si4TipiAbilitazione", "tiab", CriteriaSpecification.INNER_JOIN)

            eq("oggetto", oggetto)
            eq("tiog.id", tipoOggetto)

            order("uten.id")

        }.toDTO()


    }

    def existsOverlappingCompetenza(Si4CompetenzeDTO competenza) {
        return Si4Competenze.createCriteria().count {
            createAlias('si4Abilitazioni', 'abil', CriteriaSpecification.INNER_JOIN)
            createAlias('abil.si4TipiOggetto', 'tiog', CriteriaSpecification.INNER_JOIN)
            // Avoiding to involve current item when editing it
            if (competenza.id) {
                ne('id', competenza.id)
            }

            // Required uniqueness criteria
            eq('utente.id', competenza.utente.id)
            eq('tiog.id', competenza.si4Abilitazioni.si4TipiOggetto.id)
            eq('oggetto', competenza.oggetto)

            // Date comparison
            and {
                or {
                    and {
                        isNotNull('al')
                        ge('al', competenza.dal ?: CommonService.MIN_DATE)
                    }
                    isNull('al')
                }
                or {
                    and {
                        isNotNull('dal')
                        le('dal', competenza.al ?: CommonService.MAX_DATE)
                    }
                    isNull('dal')
                }
            }

        } > 0
    }

    def aggiornaCompetenze(Si4CompetenzeDTO competenza) {
        competenza.toDomain().save(failOnError: true, flush: true)
        competenza.si4Abilitazioni.toDomain().save(failOnError: true, flush: true)

        log.debug("inserimento/aggiornamento avvenuto")

    }

    def eliminaCompetenza(Si4CompetenzeDTO competenza) {
        competenza.toDomain().delete(failOnError: true, flush: true)
    }


    def eliminaCompetenza(Si4Competenze competenza) {
        competenza.delete(failOnError: true, flush: true)
    }

    def abilitazioniPerTipoOggetto(def tipoOggetto) {

        Si4Abilitazioni.createCriteria().list {
            createAlias("si4TipiAbilitazione", "tiab", CriteriaSpecification.INNER_JOIN)
            createAlias("si4TipiOggetto", "tiog", CriteriaSpecification.INNER_JOIN)

            eq("tiog.id", tipoOggetto)
            order("tiab.descrizione")
        }.toDTO(["si4TipiAbilitazione"])
    }

    def utenteAbilitatoScrittura(def oggetto) {

        // Se la gestione delle competenze non e' abilitata
        if (!datiGeneraliService.gestioneCompetenzeAbilitata()) {
            return true
        } else {
            def tipoAbilitazione = tipoAbilitazioneUtente(oggetto)
            return tipoAbilitazione != null && tipoAbilitazione == TIPO_ABILITAZIONE.AGGIORNAMENTO
        }
    }

    List<TipoTributoDTO> tipiTributoUtenza() {
        OggettiCache.TIPI_TRIBUTO.valore.findAll {
            tipoAbilitazioneUtente(it.tipoTributo) != null
        }.sort { it.tipoTributo }
    }

    List<TipoTributoDTO> tipiTributoUtenzaScrittura() {
        OggettiCache.TIPI_TRIBUTO.valore.findAll {
            tipoAbilitazioneUtente(it.tipoTributo) == TIPO_ABILITAZIONE.AGGIORNAMENTO
        }.sort { it.tipoTributo }
    }

    List<TipoTributoDTO> tipiTributoUtenzaLettura() {
        OggettiCache.TIPI_TRIBUTO.valore.findAll {
            tipoAbilitazioneUtente(it.tipoTributo) == TIPO_ABILITAZIONE.LETTURA
        }.sort { it.tipoTributo }
    }

    Map<String, Object> getTipoTributoAndTipoAbilitazioneUtente() {
        OggettiCache.TIPI_TRIBUTO.valore.collectEntries {
            [it.tipoTributo, tipoAbilitazioneUtente(it.tipoTributo)]
        }
    }

    private void checkAbilitazioneScrittura(def oggetto, def metodo) {

        // Se la gestione delle competenze e' abilitata
        if (datiGeneraliService.gestioneCompetenzeAbilitata()) {
            log.info("Verifica competenze in scrittura per l'utente [${springSecurityService?.currentUser}] sul metodo [${metodo}]")
            if (!utenteAbilitatoScrittura(oggetto)) {
                throw new CompetenzeException("Utente [${springSecurityService?.currentUser?.id}] non abilitato per [${metodo}] su [${oggetto}].")
            }
        }
    }
}
