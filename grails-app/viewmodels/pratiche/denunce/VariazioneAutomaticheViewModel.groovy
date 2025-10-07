package pratiche.denunce

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.TariffaDTO
import it.finmatica.tr4.jobs.VariazioneAutomaticheJob
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class VariazioneAutomaticheViewModel {

    //Services
    SpringSecurityService springSecurityService
    DenunceService denunceService

    // Componenti
    Window self

    //Comuni
    TipoTributo tipoTributo
    String tipoTributoNome

    def parametri = [:]
    def listaCodiciTributo
    List<CategoriaDTO> listaCategorie
    List<TariffaDTO> listaTariffeDa
    List<TariffaDTO> listaTariffeA
    def parametriBandBox

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt) {

        this.self = w

        this.tipoTributoNome = tt ?: 'TARSU'

        this.tipoTributo = TipoTributo.findByTipoTributo(tipoTributoNome)

        parametri << ["tipoTributo": tipoTributo]
        parametri << ["utente": springSecurityService.currentUser]

        listaCodiciTributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                .valore
                .findAll { it.tipoTributo?.tipoTributo == tipoTributoNome }
                .sort { it.id }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOk() {

        boolean aggiornaStato = false

        def errori = controlloParametri()

        if (errori.size() > 0) {

            def msg = ""
            errori.each { msg += it }

            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
            return
        }

        parametri.codFiscale = parametri.codFiscale?.toUpperCase() ?: '%'

        VariazioneAutomaticheJob.triggerNow([
                operazione       : 'variazioneAutomatiche',
                parametri        : parametri,
                codiceUtenteBatch: springSecurityService.currentUser.id,
                codiciEntiBatch  : springSecurityService.principal.amministrazione.codice
        ])

        String title = "Variazioni automatiche"
        Clients.showNotification("Calcolo Denunce di Variazione Automatiche avviato",
                Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)

        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato])
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        parametri.codVia = (event.data.id ?: null)
        parametri.indirizzo = (event.data.denomUff ?: null)
        BindUtils.postNotifyChange(null, null, this, "parametri")
    }

    @Command
    def onCambioAnno() {
        riempiCategoria(true)
		riempiTariffa(false)
		
		parametri.tariffaDa = null
		parametri.tariffaA = null
		BindUtils.postNotifyChange(null, null, null, "parametri")
		
		self.invalidate()
    }

    @Command
    def onRiempiCategoria() {
        riempiCategoria(true)
    }

    @Command
    def onRiempiTariffa(@BindingParam("type") String type) {
        riempiTariffa(true, type)
    }

    private riempiCategoria(def reset = false) {
        if (parametri?.codiceTributo?.id) {
            listaCategorie = [new CategoriaDTO()] + denunceService.getCategorie(parametri.codiceTributo.id).sort { it.id }
        } else {
            listaCategorie = [new CategoriaDTO()]
        }
        if (tipoTributoNome == 'CUNI') {
            listaCategorie = listaCategorie.findAll { it.categoria != 99 && (it.flagGiorni ?: 'N') != 'S' }
        }

        // Si resetta il valore associato alla categoria ed alla tariffa
        if (reset) {
            parametri.categoriaDa = null
            parametri.categoriaA = null
            BindUtils.postNotifyChange(null, null, null, "parametri")
        }

        riempiTariffa(reset)

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    private riempiTariffa(def reset = false, def type = '') {

        if (type == 'Da' && parametri?.categoriaDa?.id) {
            listaTariffeDa = [new TariffaDTO()] +
                    denunceService.getTariffe(parametri.categoriaDa.id, parametri.anno as short).sort { it.id }

            if (tipoTributoNome == 'CUNI') {
                listaTariffeDa.each { it.estraiFlag() }
                listaTariffeDa = listaTariffeDa.findAll {
                    it.tipologiaTariffa != TariffaDTO.TAR_TIPOLOGIA_ESENZIONE &&
                            it.tipologiaSecondaria == TariffaDTO.TAR_SECONDARIA_NESSUNA
                }
            }

        } else if (type == 'A' && parametri?.categoriaA?.id) {
            listaTariffeA = [new TariffaDTO()] +
                    denunceService.getTariffe(parametri.categoriaA.id, parametri.anno as short).sort { it.id }

            if (tipoTributoNome == 'CUNI') {
                listaTariffeA.each { it.estraiFlag() }
                listaTariffeA = listaTariffeA.findAll {
                    it.tipologiaTariffa != TariffaDTO.TAR_TIPOLOGIA_ESENZIONE &&
                            it.tipologiaSecondaria == TariffaDTO.TAR_SECONDARIA_NESSUNA
                }
            }

        } else {
            listaTariffeDa = [new TariffaDTO()]
            listaTariffeA = [new TariffaDTO()]
        }

        // Si resetta il valore associato alla tariffa
        if (reset) {
            if (type == 'Da') {
                parametri.tariffaDa = null

            } else if (type == 'A') {
                parametri.tariffaA = null
            }
            BindUtils.postNotifyChange(null, null, null, "parametri")
        }

        BindUtils.postNotifyChange(null, null, this, "listaTariffeDa")
        BindUtils.postNotifyChange(null, null, this, "listaTariffeA")
    }

    private def controlloParametri() {

        Integer changes = 0;

        def errori = []

        if (parametri.anno == null) {
            errori << "Il campo Anno è obbligatorio\n"
        }

        if (parametri.dataDenuncia == null) {
            errori << "Il campo Data Denuncia è obbligatorio\n"
        }

        if (parametri.dataDecorrenza == null) {
            errori << "Il campo Data Decorrenza è obbligatorio\n"
        }

        if (parametri.codiceTributo == null) {
            errori << "Il campo Tributo è obbligatorio\n"
        }

        if (parametri.categoriaDa == null || parametri.categoriaA == null) {
            errori << "I campi " + ((tipoTributoNome == 'CUNI') ? "Zona" : "Categoria") + " Da/A sono obbligatori\n"
        } else {
            if (tipoTributoNome == 'CUNI') {
				if(parametri.categoriaDa.id != parametri.categoriaA.id) changes++;

                String categoriaDaTipo = parametri.categoriaDa.flagGiorni
                String categoriaATipo = parametri.categoriaA.flagGiorni
                if (categoriaDaTipo != categoriaATipo) {
                    errori << "Zona Da e Zona A devono essere dello stesso Tipo Canone\n"
                }
            } else {
                if (parametri.categoriaDa.id > parametri.categoriaA.id) {
                    errori << "Il campo Categoria Da deve essere minore di Categoria A\n"
                }
            }
        }

        if (parametri.tariffaDa != null && parametri.tariffaA != null) {
            if (tipoTributoNome == 'CUNI') {
				if(parametri.tariffaDa.id != parametri.tariffaA.id) changes++;

                if (parametri.tariffaDa.tipologiaTariffa != parametri.tariffaA.tipologiaTariffa) {
                    errori << "Tariffa Da e Tariffa A devono essere dello stesso Tipo Canone\n"
                }
            } else {
                if (parametri.tariffaDa.id > parametri.tariffaA.id) {
                    errori << "Il campo Tariffa Da deve essere minore di Tariffa A\n"
                }
            }
        }

        if (tipoTributoNome == 'CUNI') {
			if(changes == 0) {
                errori << "Nessuna variazione di Zona e/o tariffa, impossibile procedere\n"
            }
        }

        return errori
    }
}
