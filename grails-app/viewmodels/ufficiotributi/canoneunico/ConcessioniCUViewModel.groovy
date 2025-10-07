package ufficiotributi.canoneunico

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ConcessioniCUViewModel {

    // Componenti
    def self

    // Service
    def denunceService
    CommonService commonService
	CanoneUnicoService canoneUnicoService

    // Modello
    def contribuenteSelezionato = [:]
    def listaCanoni
    def canoniSelezionati

    Long idPratica
    PraticaTributo pratica
	Short annoPratica
    String tipoPratica
    String tipoEvento
    Boolean perAccertamento

	String tipoTributo
    Short annoChiusura
    def soggDestinazione
    def inizioOccupazione
    def dataDecorrenza

    def data1
    def data2

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
				         @ExecutionArgParam("pratica") def idPratica,
				         @ExecutionArgParam("contribuente") ContribuenteDTO cnt,
				         @ExecutionArgParam("tipoEvento") TipoEventoDenuncia tipoEvento,
				         @ExecutionArgParam("anno") def anno) {

        this.self = w
		
		this.tipoTributo = 'CUNI'
		
        this.idPratica = idPratica ?: -1

        if (anno != null) {
            this.annoChiusura = anno as short
        }

        if ((this.idPratica == -1) && (tipoEvento == null) && (cnt == null)) {
            throw new RuntimeException("Indicare la pratica o il tipo evento ed il contribuente.")
        }

        this.pratica = (this.idPratica as Long != -1) ? PraticaTributo.get(idPratica) : new PraticaTributo(
                contribuente: cnt.toDomain(),
                tipoEvento: tipoEvento
        )
		
		this.annoPratica = this.pratica.anno ?: new Date().getYear() + 1900

        this.tipoEvento = this.pratica.tipoEvento.tipoEventoDenuncia
        this.tipoPratica = this.pratica.tipoPratica

        this.perAccertamento = (this.tipoPratica == TipoPratica.A.id)

        onApriMascheraRicercaSoggetto()
    }

    @Command
    def onApriMascheraRicercaSoggetto() {
		
        if (tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.U.tipoEventoDenuncia]) {
            commonService.creaPopup("/archivio/listaSoggettiRicerca.zul", self,
				[
					filtri: null,
					listaVisibile: true,
					soloContribuenti: true
				],
				{ event ->
	                if (event.data) {
	                    if (event.data.status == "Soggetto") {
	                        def soggSel = event.data.Soggetto
	                        contribuenteSelezionato.cognomeNome = "${soggSel.cognome} ${soggSel.nome}".trim()
	                        contribuenteSelezionato.codFiscale = soggSel.contribuente.codFiscale
	
	                        contribuenteSelezionato.indirizzo = (soggSel.denominazioneVia ? "${soggSel.denominazioneVia} " : '') +
										                        ((soggSel.numCiv != null) ? soggSel.numCiv : '') +
										                                (soggSel.piano != null ? " P. ${soggSel.piano}" : '') +
										                                (soggSel.interno != null ? " Int. ${soggSel.interno}" : '')
	
	                        def comuneResidenza = soggSel.comuneResidenza?.ad4Comune
	                        contribuenteSelezionato.comuneResidenza = (comuneResidenza?.denominazione?.trim() ? comuneResidenza?.denominazione : '') +
	                                									(comuneResidenza?.provincia?.sigla ? " (${comuneResidenza?.provincia?.sigla})" : '')
	
							listaCanoni = canoneUnicoService.getConcessioniCessate(
									contribuenteSelezionato.codFiscale,
	                                pratica.id,
	                                this.tipoTributo
							)

	                        BindUtils.postNotifyChange(null, null, this, "contribuenteSelezionato")
	                        BindUtils.postNotifyChange(null, null, this, "listaCanoni")
	                    }
	                }
				}
			)
        } else {
			if (tipoEvento in [TipoEventoDenuncia.V.tipoEventoDenuncia, TipoEventoDenuncia.C.tipoEventoDenuncia]) {
	            listaCanoni = canoneUnicoService.getConcessioniVariazioneCessazione(
	                    pratica.contribuente.codFiscale,
	                    pratica.id ?: this.idPratica,
	                    this.tipoTributo,
	                    pratica.tipoEvento
	            )
	
	            if (annoChiusura != null) {
	                listaCanoni = listaCanoni.findAll {
	                    ((commonService.yearFromDate(it.dettagli.dataDecorrenza) ?: 0) <= annoChiusura) &&
	                            ((commonService.yearFromDate(it.dettagli.dataCessazione) ?: 9999) >= annoChiusura)
	                }
	            }
	
	            BindUtils.postNotifyChange(null, null, this, "listaCanoni")
	        }
        }
    }
	
	@Command
	def onCanoneSelected() {
		
	}
	
	@Command
	def onSelectCanoneCessato() {
		
	}

    @Command
    def onSeleziona() {

		if(verificaParametri() == false)
			return;

        // Se almeno un oggetto ha data di cessazione >= rispetto a quella di decorrenza vienew visualizzato un messaggio di conferma inserimento
        def avvisiCessazione = []

        canoniSelezionati.each {
            if (it.dettagli.dataCessazione >= data2) {
                avvisiCessazione << it.oggettoRef as String
            }
        }

        if (!avvisiCessazione.isEmpty()) {

            String message = "Oggett" + ((avvisiCessazione.size() > 1) ? "i" : "o") + " : " + avvisiCessazione.join(", ") + "\n\n" +
							"con data di cessazione uguale o successiva alla data di decorrenza.\n\n" +
							"Si desidera procedere con l'inserimento?\n"
							
            Messagebox.show(message, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
							confermaSelezione()
                        }
                    }
                }
            )
        }
		else {
			confermaSelezione()
		}
    }

    @Command
    onCambiaInizioOccupazione() {
		
        // Se si annulla la data inizio occupazione
        if (!inizioOccupazione) {
            // Si annulla anche la data decorrenza
            dataDecorrenza = null
        } else {
            dataDecorrenza = denunceService.fGetDecorrenzaCessazione(inizioOccupazione, tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia ? 1 : 0)
        }

        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onCambiaData1() {

        // Se si annulla la data inizio occupazione
        if (!data1) {
            // Si annulla anche la data decorrenza
            data2 = null
        } else {

            if (tipoEvento == TipoEventoDenuncia.U) {

                // Se si valorizza la data occupazione, se la data decorrenza è nulla si setta a data occupazione
                data2 = data2 ?: data1

            } else {
                data2 = denunceService.fGetDecorrenzaCessazione(data1, tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia ? 1 : 0)
            }
        }

        BindUtils.postNotifyChange(null, null, this, "data2")
    }

    @Command
    def onApriRicercaSoggDest() {
        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    soggDestinazione = event.data.Soggetto
                    BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
                }
            }
        }
        w.doModal()
    }

    @Command
    def onEliminaSoggDest() {
		
        soggDestinazione = null
        inizioOccupazione = null
        dataDecorrenza = null
		
        BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
        BindUtils.postNotifyChange(null, null, this, "inizioOccupazione")
        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
	
	def confermaSelezione() {
		
		Date inizioOcc
		Date fineOcc
		Date dataDec
		Date dataCess
		
		if(this.idPratica == -1) {
			inizioOcc = inizioOccupazione
			fineOcc = null
			dataDec = dataDecorrenza
			dataCess = null
		}
		else {
			if(tipoEvento == TipoEventoDenuncia.U.tipoEventoDenuncia) {
				dataDec = data1
				dataCess = data2
				inizioOcc = data1
				fineOcc = data2
			}
			else {
				dataDec = data2
				dataCess = null
				inizioOcc = data1
				fineOcc = null
			}
		}
		
		def datiCanoni = [
			anno            	 	: annoChiusura,
			canoni           		: canoniSelezionati,
			soggDest        		: soggDestinazione,
			dataInizioOccupazione	: inizioOcc,
			dataFineOccupazione		: fineOcc,
			dataDecorrenza			: dataDec,
			dataCessazione			: dataCess 
		] 

		Events.postEvent(Events.ON_CLOSE, self, [ datiCanoni : datiCanoni] )
	}
	
	///
	/// *** Verifica coerenza parametri chiusura
	///
	private def verificaParametri() {
		
		def report = verificaMaschera()
		
		if(report.result == 0) {

			def dataChiusura = data2
			
			def elencoCanoniDaChiudere = canoniSelezionati.collect { it.oggettoPraticaRef }
			def canoniDaChiudere = listaCanoni.findAll { it.oggettoPraticaRef in elencoCanoniDaChiudere }

			report = canoneUnicoService.verificaSubentro(annoPratica, canoniDaChiudere, dataChiusura, null)
		}
		
		if(report.result != 0) {
			
			Messagebox.show(report.message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
			return false;
		}
		
		return true
	}


	def verificaMaschera() {
		
		Long result = 0
		String message = ""

        def errori = []

        if (this.idPratica == -1) {
            if (annoChiusura == null) {
                errori << "Campo 'Anno' non valorizzato."
            }

            if (soggDestinazione != null) {
                if (!dataDecorrenza) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }

                if (dataDecorrenza != null && data2 != null && dataDecorrenza < data2) {
                    errori << "Impossibile trasferiri gli oggetti in una data precedente alla data di cessazione"
                }
            } else {
                if (dataDecorrenza != null || inizioOccupazione != null) {
                    errori << "Indicare il contribuente su cui trasferire gli oggetti"
                }
            }
        }

        if (perAccertamento) {
            if (!data1) {
                errori << "Campo 'Inizio occupazione' non valorizzato."
            }
            if (!data2) {
                errori << "Campo 'Data decorrenza' non valorizzato."
            }
        } else {
            if (tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]) {
                if (!data2) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }
            } else if (tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia) {
                if (!data2) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
                canoniSelezionati.each {
                    if (data2 && it.dataDecorrenza > data2) {
                        errori << "Per l'oggetto ${it.oggetto} la data di cessazione e' precedente alla data di decorrenza."
                    }
                }

            } else if (tipoEvento == TipoEventoDenuncia.U.tipoEventoDenuncia) {
                if (!data1) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }
                if (!data2) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
            }
        }

        if (!errori.isEmpty()) {
			message = errori.join("\n")
			result = 2
        }
		
		return [ result : result, message : message ]
	}
}
