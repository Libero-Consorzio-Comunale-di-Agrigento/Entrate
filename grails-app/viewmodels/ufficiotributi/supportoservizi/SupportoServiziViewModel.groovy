package ufficiotributi.supportoservizi

import OrdinamentoMutiColonnaViewModel
import commons.OrdinamentoMutiColonnaViewModel
import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.TipoParametro
import it.finmatica.tr4.ParametroUtente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.supportoservizi.FiltroRicercaSupportoServizi
import it.finmatica.tr4.jobs.SupportoServiziJob
import it.finmatica.tr4.supportoservizi.SupportoServiziService

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listbox
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SupportoServiziViewModel extends OrdinamentoMutiColonnaViewModel {

    Window self

    @Wire
    Listbox listBoxSupporto

    // services
    SpringSecurityService springSecurityService
    TributiSession tributiSession

    CommonService commonService
    CompetenzeService competenzeService

    SupportoServiziService supportoServiziService

    // Filtri
    FiltroRicercaSupportoServizi filtriList
    boolean filtroAttivo = false

    // Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 30,
            totalSize : 0
    ]

    // Forniture
    def listaElementi = []
	
    def selectedAnyElemento = false
    def elementiSelezionati = [:]
    def elementoSelezionato = null
	def elementiProps = [:]
	
    def cbTributiAbilitatiScrittura = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        campiOrdinamento = [
                'differenzaImposta': [verso: null, posizione: 1],
        ]

        campiCssOrdinamento = [
                'differenzaImposta': '',
        ]

        verificaCompetenze()

        if (!tributiSession.filtroRicercaSupportoServizi) {
            tributiSession.filtroRicercaSupportoServizi = new FiltroRicercaSupportoServizi()
			
			def anni = parametriSupportoServizi(null)
			tributiSession.filtroRicercaSupportoServizi.annoDa = anni.annoDa as Short 
			tributiSession.filtroRicercaSupportoServizi.annoA = anni.annoA as Short
		}
        filtriList = tributiSession.filtroRicercaSupportoServizi

        if (filtriList.isDirty()) {
            onOpenFiltri()
        } else {
            caricaLista(true)
        }
    }

    @Command
    def onColSize() {
        listBoxSupporto?.invalidate()
    }

    // Eventi interfaccia #####################################################################################

    @Command
    def onRicaricaLista() {

        caricaLista(true)
    }

    @Command
    def onCambioPagina() {

        caricaLista(false)
    }

    @Command
    def onSelectedElement() {

    }

    @Command
    def onEditElement() {

    }

    @Command
    def onCheckElemento(@BindingParam("detail") def detail) {
		
		checkElementoProps(detail)
		
        selectedAnyElementoRefresh()
    }
	
	@Command
	def onCheckAllElementi() {

		selectedAnyElementoRefresh()

		elementiSelezionati = [:]

		if (!selectedAnyElemento) {

			def filtriNow = completaFiltri()
			def totaleElementi = supportoServiziService.getListaSupportoServizi(filtriNow, Integer.MAX_VALUE, 0)
			def listaElementi = totaleElementi.lista

			listaElementi.each() { it ->
				(elementiSelezionati << [(it.id): true])
				checkElementoProps(it)
			}
		}

		BindUtils.postNotifyChange(null, null, this, "elementiSelezionati")
		selectedAnyElementoRefresh()
	}

    @Command
    def onSituazioneContribuente() {

        String codFisccale = elementoSelezionato.dto.codFiscale ?: '-'
        Contribuente contribuente = Contribuente.get(codFisccale)

        if (contribuente == null) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Long ni = contribuente.soggetto.id
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onPopolamentoSupporto() {

        commonService.creaPopup("/ufficiotributi/supportoservizi/supportoServiziPopolamento.zul", self, [:],
                { event ->
                    if (event.data) {
                        if (event.data.parametri) {
                            popolaSupporto(event.data.parametri)
                        }
                    }
                })
    }

    @Command
    def onAssegnazioneContribuenti() {

        commonService.creaPopup("/ufficiotributi/supportoservizi/supportoServiziAssegnaContribuenti.zul", self, [:],
                { event ->
                    if (event.data) {
                        if (event.data.parametri) {
                            assegnazioneContribuenti(event.data.parametri)
                        }
                    }
                })
    }

    @Command
    def onAggiornaAssegnazione() {

        commonService.creaPopup("/ufficiotributi/supportoservizi/supportoServiziAggiornaAssegnazione.zul", self, [:],
                { event ->
                    if (event.data) {
                        if (event.data.parametri) {
                            aggiornaAssegnazione(event.data.parametri)
                        }
                    }
                })
    }
	
	@Command
	def onModificaAssegnazione() {
		
		def tipiTributo = ricavaElencoTributi()

		commonService.creaPopup("/ufficiotributi/supportoservizi/supportoServiziModificaAssegnazione.zul", self, [ tipiTributo : tipiTributo ],
			{ event ->
				if (event.data) {
					if (event.data.parametri) {
						modificaAssegnazioneContribuenti(event.data.parametri)
					}
				}
			})
	}

    @Command
    def onOpenFiltri() {

        commonService.creaPopup("/ufficiotributi/supportoservizi/supportoServiziRicerca.zul", self, [filtri: filtriList],
                { event ->
                    if (event.data) {
                        if (event.data.status == "cerca") {

                            filtriList = event.data.filtri
                            tributiSession.filtroRicercaSupportoServizi = filtriList
							
							def anni = [
								annoDa : filtriList.annoDa,
								annoA : filtriList.annoA
							]
							parametriSupportoServizi(anni)
							
                            aggiornafiltroAttivo()
                            caricaLista(true)
                        }
                    }
                })
    }

    @Command
    def onExportToXls() {

        def filtriNow = completaFiltri()
        def totaleElementi = supportoServiziService.getListaSupportoServizi(filtriNow, Integer.MAX_VALUE, 0)
        def elencoElementi = totaleElementi.lista

        def fields = [
                'descrTributo'                 : 'Tributo',
                'dto.utenteAssegnato'          : 'Ut. Assegnato',
                'dto.utenteOperativo'          : 'Ut. Operativo',

                'dto.numero'                   : 'Numero 1. Liq.',
                'dto.data'                     : 'Data 1. Liq.',
                'descrStato'                   : 'Stato 1. Liq.',
                'descrTipoAtto'                : 'Tipo Atto 1. Liq.',
				'dto.dataNotifica'             : 'Notifica 1. Liq.',
				
                'dto.tipologia'                : 'Tipologia',
                'dto.segnalazioneIniziale'     : 'Segnalazione Iniziale',
                'dto.segnalazioneUltima'       : 'Segnalazione Ultima',
                'dto.cognomeNome'              : 'Cognome e Nome',
                'dto.codFiscale'               : 'Cod. Fiscale',
                'dto.anno'                     : 'Anno',
				
                'dto.numOggetti'               : 'Num. Oggetti',
                'dto.numFabbricati'            : 'Num. Fabbricati',
                'dto.numTerreni'               : 'Num. Terreni',
                'dto.numAree'                  : 'Num. Aree',
                'dto.differenzaImposta'        : 'Differenza Imposta',
                'dto.resStoricoGsdInizioAnno'  : 'Res. storico GSD inizio anno',
                'dto.resStoricoGsdFineAnno'    : 'Res. storico GSD fine anno',
                'dto.residenteDaAnno'          : 'Residente da anno',
                'dto.tipoPersona'              : 'Tipo Persona',
                'dto.dataNas'                  : 'Data Nas.',
                'dto.aireStoricoGsdInizioAnno' : 'AIRE storico GSD inizio anno',
                'dto.aireStoricoGsdFineAnno'   : 'AIRE storico GSD fine anno',
                'dto.flagDeceduto'             : 'Deceduto',
                'dto.dataDecesso'              : 'Data decesso',
                'dto.contribuenteDaFare'       : 'Contribuente da fare',
                'dto.minPercPossesso'          : 'Min % Possesso',
                'dto.maxPercPossesso'          : 'Max % Possesso',
                'dto.flagDiffFabbricatiCatasto': 'Diff fabbricati cat.',
                'dto.flagDiffTerreniCatasto'   : 'Diff terreni cat.',
                'dto.fabbricatiNonCatasto'     : 'Fabbricati non cat.',
                'dto.terreniNonCatasto'        : 'Terreni non Cat,',
                'dto.catastoNonTr4Fabbricati'  : 'Cat. non TR4 fabbricati',
                'dto.catastoNonTr4Terreni'     : 'Cat. non TR4 terreni',
                'dto.flagLiqAcc'               : 'Liq. Acc.',
                'dto.iterAds'                  : 'Iter ADS',
                'dto.flagRavvedimento'         : 'Ravvedimento',
                'descrTributo'                 : 'Tipo Tributo',
                'dto.versato'                  : 'Versato',
                'dto.dovuto'                   : 'Dovuto',
                'dto.dovutoComunale'           : 'Dovuto Comunale',
                'dto.dovutoErariale'           : 'Dovuto Erariale',
                'dto.dovutoAcconto'            : 'Dovuto Acconto',
                'dto.dovutoComunaleAcconto'    : 'Dovuto Comunale Acconto',
                'dto.dovutoErarialeAcconto'    : 'Dovuto Erariale Acconto',
                'dto.diffTotContr'             : 'Diff Tot Contr',
                'dto.denunceImu'               : 'Denunce IMU',
                'dto.codiceAttivitaCont'       : 'Codice attivita Cont',
                'dto.residenteOggi'            : 'Residente oggi',
                'dto.abPrincipali'             : 'Ab. Principali',
                'dto.pertinenze'               : 'Pertinenze',
                'dto.altriFabbricati'          : 'Altri Fabbricati',
                'dto.fabbricatiD'              : 'Fabbricati D',
                'dto.terreni'                  : 'Terreni',
                'dto.terreniRidotti'           : 'Terreni Rid.',
                'dto.aree'                     : 'Aree',
                'dto.abitativo'                : 'Abitativo',
                'dto.commercialiArtigianali'   : 'Commerciali e Artigianali',
                'dto.rurali'                   : 'Rurali',
                'dto.cognome'                  : 'Cognome',
                'dto.nome'                     : 'Nome',
                'dto.cognomeNomeRic'           : 'Cognome e Nome Ric.',
                'dto.cognomeRic'               : 'Cognome Ric.',
                'dto.nomeRic'                  : 'Nome Ric.',
                'dto.note'                     : 'Note',

                'dto.liq2Utente'               : 'Ut. 2. Liq.',
                'dto.liq2Numero'               : 'Numero 2. Liq.',
                'dto.liq2Data'                 : 'Data 2. Liq.',
                'descrLiq2Stato'               : 'Stato 2. Liq.',
                'descrLiq2TipoAtto'            : 'Tipo Atto 2. Liq.',
                'dto.liq2DataNotifica'         : 'Notifica 2. Liq.',
        ]

        def converters = [
                'dto.flagDeceduto'             : Converters.flagBooleanToString,
                'dto.flagDiffFabbricatiCatasto': Converters.flagBooleanToString,
                'dto.flagDiffTerreniCatasto'   : Converters.flagBooleanToString,
                'dto.flagLiqAcc'               : Converters.flagBooleanToString,
                'dto.flagRavvedimento'         : Converters.flagBooleanToString,
        ]

        XlsxExporter.exportAndDownload("BonifichePerContribuente", elencoElementi as List, fields, converters)
    }

    // Funzioni interne ####################################################################################

    /**
     * Lancia procedura popolamento supporto, quindi aggiorna lista
     */
    def popolaSupporto(def parametri) {

        SupportoServiziJob.triggerNow([
                operazione       : 'popolaSupporto',
                parametri        : parametri,
                codiceUtenteBatch: springSecurityService.currentUser.id,
                codiciEntiBatch  : springSecurityService.principal.amministrazione.codice
        ])

        String title = "Bonifiche per contribuente"
        String message = "Job avviato"
        Messagebox.show(message, title, Messagebox.OK, Messagebox.INFORMATION)
    }

    /**
     * Lancia procedura assegnazione utenti supporto, quindi aggiorna lista
     */
    def assegnazioneContribuenti(def parametri) {

        SupportoServiziJob.triggerNow([
                operazione       : 'assegnazioneContribuenti',
                parametri        : parametri,
                codiceUtenteBatch: springSecurityService.currentUser.id,
                codiciEntiBatch  : springSecurityService.principal.amministrazione.codice
        ])

        String title = "Assegnazione Contribuenti"
        String message = "Job avviato"
        Messagebox.show(message, title, Messagebox.OK, Messagebox.INFORMATION)
    }

    def aggiornaAssegnazione(def parametri) {

        SupportoServiziJob.triggerNow([
                operazione       : 'aggiornaAssegnazione',
                parametri        : parametri,
                codiceUtenteBatch: springSecurityService.currentUser.id,
                codiciEntiBatch  : springSecurityService.principal.amministrazione.codice
        ])

        String title = "Aggiorna Assegnazione"
        String message = "Job avviato"
        Messagebox.show(message, title, Messagebox.OK, Messagebox.INFORMATION)
    }

	/// Ricava elenco tributi degli elementi selezionati	
	def ricavaElencoTributi() {
		
		def elencoElementi = elementiSelezionati .findAll { it.value } .collect { it.key }
		def daProcessare = elementiProps.findAll { it.key in elencoElementi } .collect { it.value }
		def elencoTributi = daProcessare.collect { it.tipoTributo }.unique { a, b -> a <=> b }

		return elencoTributi
	}
	
	def modificaAssegnazioneContribuenti(def parametri) {
		
		def elementi = elementiSelezionati .findAll { it.value } .collect { it.key }
		
		def report = supportoServiziService.modificaAssegnazione(elementi, parametri.utente)
		
		visualizzaReport(report, "Modifica assegnazione eseguita")
		
		caricaLista(true)
	}

    /**
     * Verifica impostazioni filtro
     */

    def aggiornafiltroAttivo() {

        filtroAttivo = filtriList.isDirty()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    /**
     *  Rilegge elenco forniture
     */
    void caricaLista(boolean resetPaginazione = false) {

        if (resetPaginazione) {
            pagingList.activePage = 0
        }

        def filtriNow = completaFiltri()
        def totaleElementi = supportoServiziService.getListaSupportoServizi(filtriNow, pagingList.pageSize, pagingList.activePage, campiOrdinamento)
        listaElementi = totaleElementi.lista
        pagingList.totalSize = totaleElementi.totale

		if(resetPaginazione) {
			elementiSelezionatiReset()
			elementiProps = [:]
		}
        elementoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "pagingList")
        BindUtils.postNotifyChange(null, null, this, "listaElementi")
        BindUtils.postNotifyChange(null, null, this, "elementoSelezionato")
    }

    /**
     * Completa il filtro per la ricerca
     */
    def completaFiltri() {

        def filtri = filtriList.prepara()

        return filtri
    }

	def checkElementoProps(def detail) {
		
		if (elementiProps.get(detail.id) == null) {

			elementiProps << [
				(detail.id): [
					"tipoTributo" : detail.tipoTributo
				]]
		}
	}
	
    def elementiSelezionatiReset() {

        elementiSelezionati = [:]
        BindUtils.postNotifyChange(null, null, this, "elementiSelezionati")
        selectedAnyElementoRefresh()
    }

    def selectedAnyElementoRefresh() {

        selectedAnyElemento = (elementiSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyElemento")
    }

    private verificaCompetenze() {

        competenzeService.tipiTributoUtenzaScrittura().each {
            cbTributiAbilitatiScrittura << [(it.tipoTributo): true]
        }
    }
	
	def parametriSupportoServizi(def imposta) {
		
		String nomeParametro = 'SUPPORTO_SERVIZI'
		String valore
		String userId
		
		Short annoDaDef = 1900
		Short annoADef = 2999
		
		def config = [
			annoDa : null,
			annoA : null,
		]
		
		TipoParametro tipoParametro = TipoParametro.get(nomeParametro)
		ParametroUtente settings
		
		userId = springSecurityService.currentUser.id
		if(tipoParametro) {
			settings = ParametroUtente.findByTipoParametroAndUtente(tipoParametro, userId)
		}
		
		if(imposta) {
			valore = (imposta.annoDa ?: annoDaDef) + ' ' + (imposta.annoA ?: annoADef)
			if(!settings) {
				settings = new ParametroUtente()
				settings.tipoParametro = tipoParametro
				settings.utente = springSecurityService.currentUser.id
			}	
			settings.valore = valore
			settings.save(flush: true)
		}
		else {
			valore = settings?.valore
			if(valore) {
				def anni = valore.split(" ")
				if(anni.size() == 2) {
					config.annoDa = anni[0] as Short
					config.annoA = anni[1] as Short
					if(config.annoDa == annoDaDef) config.annoDa = null
					if(config.annoA == annoADef) config.annoA = null
				}
			}
		}
		
		return config
	}
	
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }

        return
    }
}
