package ufficiotributi.imposte

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.Scadenza
import it.finmatica.tr4.LimiteCalcolo
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.jobs.CalcoloImpostaJob
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

class CalcoloImpostaViewModel {

    private static final Logger log = Logger.getLogger(CalcoloImpostaViewModel.class)

    // services
    def springSecurityService
    ImposteService imposteService
    CommonService commonService
    CompetenzeService competenzeService
    CanoneUnicoService canoneUnicoService
    IntegrazioneDePagService integrazioneDePagService

    // componenti
    Window self

    // dati
    def anno
    TipoTributoDTO tipoTributo
    String codiceFiscale
    String cognomeNome
    def pratica

    def adAnno
    List<TipoTributoDTO> listaTipiTributo
    def isCalcoloMassivo = false
    List tipiCalcoloErrore = []

    def flagNormalizzato = 'T'
    def flagRateizzazione = false
    def tipoRateizzazione = null

    def disableTipoCalcolo = true
    def disableRateizzazione = true
    def disableRateizzazioneContribuente = false

    def intervalloAnni = false
    def limiteRateizzazione = null
	
	List<GruppoTributoDTO> listaGruppiTributo
	GruppoTributoDTO gruppoTributo
    String gruppoTributoPratica
	String tipoOccupazione
    def dataScadenzaPratica

	def paramAggiuntivi = [
		gruppoTributo : null,
		scadenzaRata0 : null,
		scadenzaRata1 : null,
		scadenzaRata2 : null,
		scadenzaRata3 : null,
		scadenzaRata4 : null,
	] 

    @NotifyChange(["listaTipiTributo", "cognomeNome", "codiceFiscale"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anno") def a
         , @ExecutionArgParam("tipoTributo") TipoTributoDTO tt
         , @ExecutionArgParam("cognomeNome") String cn
         , @ExecutionArgParam("codFiscale") String cf
         , @ExecutionArgParam("pratica") Long prt) {

        this.self = w

        anno = a ?: Calendar.getInstance().get(Calendar.YEAR)
        tipoTributo = tt
        cognomeNome = cn
        codiceFiscale = cf
        pratica = prt
		
		tipoOccupazione = TipoOccupazione.P;
        dataScadenzaPratica = null
        gruppoTributoPratica = null
		gruppoTributo = null
		
		if(pratica) {
			PraticaTributo praticaRaw = PraticaTributo.get(pratica)
            tipoOccupazione = praticaRaw.tipoEvento == TipoEventoDenuncia.U ? TipoOccupazione.T : TipoOccupazione.P
            dataScadenzaPratica = praticaRaw.dataScadenza

		    if(tipoTributo.tipoTributo in ['CUNI']) {
                def gruppiTributo = integrazioneDePagService.getGruppiTributoPratica(pratica)

                if(gruppiTributo.size() > 0) {
                    def gruppo = gruppiTributo[0]
                    gruppoTributoPratica = gruppo.gruppoTributo
                }
            }
		}

        isCalcoloMassivo = (cognomeNome == "Tutti")
        listaTipiTributo = competenzeService.tipiTributoUtenzaScrittura()

        if (tipoTributo == null) {
            tipoTributo = listaTipiTributo.find { it.tipoTributo == 'ICI' } ?: listaTipiTributo[0]
        }

        changeTipoTributo(false)
    }

    @Command
    onEseguiCalcoloMultiplo(@BindingParam("popup") Popup popupCalcoloFallito) {

		if(!verificaParametri()) 
			return;

        //Se il calcolo di imposta è massivo per tipoTributo su un intera annualità verrà lanciato un job
        if (isCalcoloMassivo) {

            tipiCalcoloErrore = []

            if (!anno) {
                Clients.showNotification("Parametro mancante: anno."
                        , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }

            def pFlagNormalizzato = null
            Integer rateazione
            def limiteRate = null

            if (flagRateizzazione) {
                rateazione = (tipoRateizzazione ?: 0) as Integer
                limiteRate = limiteRateizzazione
            } else {
                rateazione = 0
                limiteRate = null
            }

            if (adAnno) {
                pFlagNormalizzato = flagNormalizzato
            } else {
                adAnno = anno
            }

            for (int a in (anno..adAnno)) {
                String messaggioJob = "Calcolo imposta per (ANNO - TIPO_TRIBUTO)::($a - ${tipoTributo.tipoTributo})"
                log.info("Calcolo imposta [$a - ${tipoTributo.tipoTributo}]")
                try {

                    //imposteService.proceduraCalcolaImposta(a, codiceFiscale, tipoTributo.tipoTributo,flagNormalizzato, tipoRateizzazione, !flagRateizzazione ? null : limiteRateizzazione)
                    // Obbligatorio indicare codiceUtenteBatch se si vuole associare il job all'utente loggato;
                    // se codiceUtenteBatch non viene indicato il job verrà associato all'utente indicato nel paremetro di configurazione utenteBatch
                    // Obbligatorio indicare codiciEntiBatch altrimenti il processo non viene associato ad alcun ente
                    CalcoloImpostaJob.triggerNow([codiceUtenteBatch     : springSecurityService.currentUser.id
                                                  , codiciEntiBatch     : springSecurityService.principal.amministrazione.codice
                                                  , customDescrizioneJob: messaggioJob
                                                  , anno                : a
                                                  , codiceFiscale       : codiceFiscale
                                                  , tipoTributo         : tipoTributo.tipoTributo
                                                  , pFlagNormalizzato   : pFlagNormalizzato
                                                  , pChkRate            : rateazione
												  , pParametriAgg		: paramAggiuntivi
                                                  , pLimite             : limiteRate
                                                  , asincrona           : true
                    ])


                } catch (Exception e) {
                    String descrizione = "Errore " + messaggioJob + " [" + e.getMessage() + "]"
                    String errore = e.getMessage()
                    tipiCalcoloErrore << [anno: a, descrizione: descrizione, eccezione: errore]
                }
            }
            if (tipiCalcoloErrore.isEmpty()) {
                def listaAnni = (anno..adAnno)
                Clients.showNotification("Elaborazione batch per tipoTributo ${tipoTributo.tipoTributo} ed Anno " + listaAnni?.join(", "), Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                close(true)
            } else {
                popupCalcoloFallito?.open(self, "middle_center")
                BindUtils.postNotifyChange(null, null, this, "tipiCalcoloErrore")
            }
        } else {
            //Calcolo dell'imposta per il singolo contribuente
            onEseguiCalcolo()
        }
    }

    @Command
    onChiudiCalcoloFallito(@BindingParam("popup") Popup popupCalcoloFallito) {
        popupCalcoloFallito.close()
    }

    @Command
    onEseguiCalcolo() {

        Integer rateazione
        def limiteRate = null
		
		if(!verificaParametri()) 
			return;

        if (flagRateizzazione) {
            rateazione = (tipoRateizzazione ?: 0) as Integer
            limiteRate = limiteRateizzazione
        } else {
            rateazione = 0
            limiteRate = null
        }

        if (!anno) {
            Messagebox.show("Valore obbligatorio sul campo Anno", "Calcolo Imposta", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            try {
                if (adAnno) {
                    for (int a in (anno..adAnno)) {
                        log.info("Calcolo imposta [$a - ${tipoTributo.tipoTributo}]")
                        imposteService.proceduraCalcolaImposta(a, codiceFiscale, '%', tipoTributo.tipoTributo, flagNormalizzato, rateazione, limiteRate, null, null)
                    }
                    Clients.showNotification("Calcolo eseguito con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                } else {
                    if (imposteService.proceduraCalcolaImposta(anno, codiceFiscale, '%', tipoTributo.tipoTributo, flagNormalizzato,
                            															rateazione, limiteRate, pratica, null, paramAggiuntivi) == 'OK') {
                        Clients.showNotification("Calcolo eseguito con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                    }
                }
            }
            catch (Exception e) {
                if (e instanceof Application20999Error) {
                    Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                    return
                } else {
                    throw e
                }
            }
            close(true)
        }
    }

    @Command
    onStampa() {

    }

    @Command
    onChangeTributo() {
        changeTipoTributo()
    }
	
	@Command
	def onChangeGruppoTributo() {
		changeGruppoTributo()
	}
	
	@Command
	def onChangeAnno() {
		changeTipoTributo(false)
	}

    @Command
    onCheckTipoRateizzazione() {

    }
	
	@Command
	def onCambiaData0() {
		
	}

	@Command
	def onCambiaData1() {
		
	}

	@Command
	def onCambiaData2() {
		
	}

	@Command
	def onCambiaData3() {
		
	}

	@Command
	def onCambiaData4() {
		
	}

    @Command
    onChiudi() {
        close(false)
    }

    private close(def calcoloEseguito = false) {
        Events.postEvent(Events.ON_CLOSE, self, [calcoloEseguito: calcoloEseguito])
    }

    private changeTipoTributo(def resetAnni = true) {

        if (tipoTributo == null) {
            tipoTributo = competenzeService.tipiTributoUtenza()[0]
            Clients.showNotification("Il tipo tributo deve essere selezionato.", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }
		
		// Gruppo tributo - Solo CUNI
		listaGruppiTributo = []
		if(tipoTributo.tipoTributo in ['CUNI']) {
			TipoTributo tipoTributoRaw = tipoTributo.toDomain()
			List<GruppoTributoDTO> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoRaw)?.toDTO(["tipoTributo"])

            def scadPerGrp = canoneUnicoService.getScadenzePerGruppoTributo(anno as Short, tipoOccupazione)
            if(scadPerGrp.scadenzePerGruppo) {
                gruppiTributo = gruppiTributo.findAll { it.gruppoTributo in scadPerGrp.gruppiConScadenze }
			    listaGruppiTributo.addAll(gruppiTributo)
            }
            else {
			    listaGruppiTributo << new GruppoTributoDTO()
			    listaGruppiTributo.addAll(gruppiTributo)
            }
            if(gruppoTributoPratica) {
                gruppoTributo = listaGruppiTributo.find { it.gruppoTributo == gruppoTributoPratica }
            }
            if(!gruppoTributo) {
                gruppoTributo = listaGruppiTributo[0]
            }
		}

        // Tipo calcolo
        disableTipoCalcolo = tipoTributo.tipoTributo != 'TARSU'
        flagNormalizzato = 'T'

        // Rateizzazione
        disableRateizzazione = tipoTributo.tipoTributo in ['ICI', 'ICIAP', 'TASI']
        disableRateizzazioneContribuente = false

        flagRateizzazione = false
        limiteRateizzazione = null

        if (tipoTributo.tipoTributo == 'CUNI') {
            if ((pratica ?: 0) > 0) {
                disableRateizzazioneContribuente = true
                tipoRateizzazione = "2"
            } else {
                tipoRateizzazione = "1"
            }
        } else {
            tipoRateizzazione = null
        }

        // Abilita intervallo anni
        intervalloAnni = (tipoTributo.tipoTributo in ['ICI', 'TASI']) && ((pratica ?: 0) == 0)

        if (resetAnni) {
            anno = Calendar.getInstance().get(Calendar.YEAR)
            adAnno = null
        }

        BindUtils.postNotifyChange(null, null, this, "disableRateizzazione")
        BindUtils.postNotifyChange(null, null, this, "disableRateizzazioneContribuente")
        BindUtils.postNotifyChange(null, null, this, "flagRateizzazione")
        BindUtils.postNotifyChange(null, null, this, "tipoRateizzazione")
        BindUtils.postNotifyChange(null, null, this, "limiteRateizzazione")

        BindUtils.postNotifyChange(null, null, this, "disableTipoCalcolo")
        BindUtils.postNotifyChange(null, null, this, "flagNormalizzato")
        BindUtils.postNotifyChange(null, null, this, "anno")
        BindUtils.postNotifyChange(null, null, this, "adAnno")
        BindUtils.postNotifyChange(null, null, this, "intervalloAnni")
		
        BindUtils.postNotifyChange(null, null, this, "listaGruppiTributo")
        BindUtils.postNotifyChange(null, null, this, "gruppoTributo")
		
		changeGruppoTributo()
    }
	
	def changeGruppoTributo() {

		List<Scadenza> scadenze
		Scadenza scadenzaUnica
		Scadenza scadenza
		LimiteCalcolo limiteCalcolo
		
		Short sAnno = anno as Short
		String tipoScadenza = 'V'
		
		TipoTributo tipoTributoRaw = tipoTributo.toDomain()
		
		if(tipoTributo.tipoTributo in ['CUNI']) {
			String codGruppoTributo = gruppoTributo?.gruppoTributo ?: '-'
			scadenze = Scadenza.findAllByAnnoAndTipoScadenzaAndTipoTributoAndGruppoTributoAndTipoOccupazione(sAnno, tipoScadenza, tipoTributoRaw, codGruppoTributo, tipoOccupazione)
			if(scadenze.size() == 0) {
				scadenze = Scadenza.findAllByAnnoAndTipoScadenzaAndTipoTributoAndGruppoTributo(sAnno, tipoScadenza, tipoTributoRaw, codGruppoTributo)
				if(scadenze.size() == 0) {
					scadenze = Scadenza.findAllByAnnoAndTipoScadenzaAndTipoTributoAndGruppoTributo(sAnno, tipoScadenza, tipoTributoRaw, null)
				}
			}
			limiteCalcolo = LimiteCalcolo.findByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazione(sAnno, tipoTributoRaw, codGruppoTributo, tipoOccupazione)
			if(limiteCalcolo == null) {
				limiteCalcolo = LimiteCalcolo.findByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazione(sAnno, tipoTributoRaw, codGruppoTributo, null)
				if(limiteCalcolo == null) {
					limiteCalcolo = LimiteCalcolo.findByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazione(sAnno, tipoTributoRaw, null, null)
				}
			}
		}
		else {
			scadenze = Scadenza.findAllByAnnoAndTipoScadenzaAndTipoTributo(sAnno, tipoScadenza, tipoTributoRaw)
			limiteCalcolo = LimiteCalcolo.findByAnnoAndTipoTributo(sAnno, tipoTributoRaw)
		}
		
        scadenzaUnica = scadenze.find { it.rata == 0 }
		paramAggiuntivi.scadenzaRata0 = dataScadenzaPratica ?: scadenzaUnica?.dataScadenza
		scadenza = scadenze.find { it.rata == 1 } ?: scadenzaUnica
		paramAggiuntivi.scadenzaRata1 = scadenza?.dataScadenza
		scadenza = scadenze.find { it.rata == 2 }
		paramAggiuntivi.scadenzaRata2 = scadenza?.dataScadenza
		scadenza = scadenze.find { it.rata == 3 }
		paramAggiuntivi.scadenzaRata3 = scadenza?.dataScadenza
		scadenza = scadenze.find { it.rata == 4 }
		paramAggiuntivi.scadenzaRata4 = scadenza?.dataScadenza
		
		if(limiteCalcolo) {
			limiteRateizzazione = limiteCalcolo.limiteRata
		}
		else {
			if (tipoTributo.tipoTributo in ['ICP', 'TARSU']) {
				limiteRateizzazione = 1549.00
			} else if (tipoTributo.tipoTributo in ['TOSAP', 'CUNI']) {
				limiteRateizzazione = 258.00
			} else {
				limiteRateizzazione = null
			}
		}
		
        BindUtils.postNotifyChange(null, null, this, "limiteRateizzazione")
        BindUtils.postNotifyChange(null, null, this, "paramAggiuntivi")
	}
	
	def verificaParametri() {
		
		String message = ""
		Boolean result = true
		
		paramAggiuntivi.gruppoTributo = gruppoTributo?.gruppoTributo

		if(flagRateizzazione) {
			def scadenza1 = paramAggiuntivi.scadenzaRata1
			def scadenza2 = paramAggiuntivi.scadenzaRata2
			def scadenza3 = paramAggiuntivi.scadenzaRata3
			def scadenza4 = paramAggiuntivi.scadenzaRata4
			
			if(scadenza1) {
				if(scadenza4) {
					if(scadenza4 < (scadenza3 ?: new Date(9999,1,1))) {
						message += "Scadenza 4° rata antecedente scadenza 3° rata\n"
					}
				}
				if(scadenza3) {
					if(scadenza3 < (scadenza2 ?: new Date(9999,1,1))) {
						message += "Scadenza 3° rata antecedente scadenza 2° rata\n"
					}
				}
				if(scadenza2) {
					if(scadenza2 < scadenza1) {
						message += "Scadenza 2° rata antecedente scadenza 1° rata\n"
					}
				}
			}
			else {
				message += "Scadenza 1° rata non specificata\n"
			}
		}
        else {
			paramAggiuntivi.scadenzaRata1 = paramAggiuntivi.scadenzaRata0
			paramAggiuntivi.scadenzaRata2 = null
			paramAggiuntivi.scadenzaRata3 = null
			paramAggiuntivi.scadenzaRata4 = null
        }
		
		if(!message.isEmpty()) {
			message = "Attenzione :\n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
			result = false	
		}
		
		return result
	}
}
