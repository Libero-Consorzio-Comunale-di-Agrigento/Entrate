package it.finmatica.tr4.commons.modelli

import it.finmatica.tr4.Modelli
import it.finmatica.tr4.TipiModello
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.modelli.ModelliService
import org.apache.log4j.Logger

import javax.servlet.ServletContext
import java.security.MessageDigest

class ConfigurazioneModelli {

    private static final Logger log = Logger.getLogger(ConfigurazioneModelli.class)

    private final def DISABILITA_INSTALLAIONE_MODLELLI = "DISMODINST"

    ServletContext servletContext
    ModelliService modelliService

    ConfigurazioneModelli(ServletContext servletContext, def modelliService) {
        this.servletContext = servletContext
        this.modelliService = modelliService
    }

    def installaModelli() {

        def disabilitaInstallazione = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == DISABILITA_INSTALLAIONE_MODLELLI }
        if (disabilitaInstallazione) {
            log.info "Installazione dei modelli disabilitata."
            return
        }

        def versioni0Create = 0
        def versioni0Aggiornate = 0
        def versioni1Create = 0

        new File(servletContext.getRealPath('WEB-INF/modelli/')).listFiles().each {

            def versione0 = { m -> m.versioni.find { it.versione == 0 } }

            log.info "--------------------------------------------------------------------------------------------------"
            log.info "Configurazione modelli di stampa..."
            log.info "--------------------------------------------------------------------------------------------------"
            it.listFiles().each {
                FileInputStream fis = new FileInputStream(it)
                ObjectInputStream ois = new ObjectInputStream(fis)
                def modelloDaCaricare = ois.readObject()
                log.info "Verifica modello[${modelloDaCaricare.descrizione.value.toString()}, ${modelloDaCaricare.tipoModello.tipoModello.toString()}, ${modelloDaCaricare.tipoTributo.toString()}]"

                def modelliInDb = Modelli.findAllByDescrizioneAndTipoModelloAndTipoTributo(
                        modelloDaCaricare.descrizione.value.toString(),
                        new TipiModello([tipoModello: modelloDaCaricare.tipoModello.tipoModello.toString()]),
                        modelloDaCaricare.tipoTributo.toString()
                )

                // Se il modello esiste ed il documento alla versione 0 è diverso si aggiorna.
                // Se non esiste si inserisce il nuovo modello
                if (!modelliInDb.isEmpty()) {

                    modelliInDb.each { modelloInDb ->
                        def digest = versione0(modelloInDb) ? MessageDigest.getInstance("SHA-512").digest(versione0(modelloInDb).documento) : null

                        // Esiste il modello ma non la versione 0
                        if (modelloInDb.versioni.isEmpty()) {
                            // Versione 0 - Versione standard di ADS
                            log.info "Creazione versione 0 ${modelloDaCaricare.descrizione.value}"
                            modelliService.caricaModello(modelloInDb, modelloDaCaricare.ultimaVersione.documento, "Versione ADS. (${modelloDaCaricare.ultimaVersione.versione})")

                            // Versione 1 - Versione iniziale
                            log.info "Creazione versione 1 ${modelloDaCaricare.descrizione.value}"
                            modelliService.caricaModello(modelloInDb, modelloDaCaricare.ultimaVersione.documento, "Versione iniziale. (${modelloDaCaricare.ultimaVersione.versione})")

                            versioni0Create++
                            versioni1Create++
                        } else {
                            // Se il modello è diverso si aggiorna la versione 0
                            if (digest && modelloDaCaricare.ultimaVersione.digest != digest) {
                                // La versione 0 è stata modificata

                                log.info "Aggiornamento versione 0 ${modelloDaCaricare.descrizione.value}"
                                versione0(modelloInDb).documento = modelloDaCaricare.ultimaVersione.documento
                                versione0(modelloInDb).note += "Versione ADS. (${modelloDaCaricare.ultimaVersione.versione})"

                                try {
                                    modelloInDb.save(flush: true, failOnError: true)
                                } catch (Exception e) {
                                    e.printStackTrace()
                                }
                                versioni0Aggiornate++
                            } else {
                                // Se è una vecchia installazione si aggiorna la versione nella descrizione
                                if (!(versione0(modelloInDb).note =~ "\\d+")) {
                                    versione0(modelloInDb).note += " (${modelloDaCaricare.ultimaVersione.versione})"
                                    modelloInDb.save(flush: true, failOnError: true)
                                }
                            }

                            // Se esiste la sola versione 0, si crea la 1
                            if (modelloInDb.versioni.size() == 1) {
                                // Versione 1 - Versione iniziale
                                log.info "Creazione versione 1 ${modelloDaCaricare.descrizione.value}"
                                modelliService.caricaModello(modelloInDb, modelloDaCaricare.ultimaVersione.documento, "Versione iniziale. (${modelloDaCaricare.ultimaVersione.versione})")
                                versioni1Create++
                            }
                        }
                    }

                } else {
                    // Non esiste il modello.

                    log.info("Modello non presente in db: [${modelloDaCaricare.descrizione.value.toString()}, ${modelloDaCaricare.tipoModello.tipoModello.toString()}]")
                }
                ois.close()
                fis.close()
            }
        }
        log.info "--------------------------------------------------------------------------------------------------"
        log.info "Fine configurazione modelli di stampa:"
        log.info "Versioni 0 create: ${versioni0Create}"
        log.info "Versioni 1 create: ${versioni1Create}"
        log.info "Versioni 0 aggiornate: ${versioni0Aggiornate}"
        log.info "--------------------------------------------------------------------------------------------------"
    }
}
