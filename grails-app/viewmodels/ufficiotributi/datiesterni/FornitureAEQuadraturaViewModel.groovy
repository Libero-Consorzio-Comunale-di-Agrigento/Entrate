package ufficiotributi.datiesterni

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.dto.datiesterni.FornituraAEDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.DecimalFormat

class FornitureAEQuadraturaViewModel {

	Window self

	def springSecurityService
	
    DatiGeneraliService datiGeneraliService
	FornitureAEService fornitureAEService
	CommonService commonService

	def porzioneAttiva = null
	Boolean modificabile = false
	Boolean modifiche = false

	Double totaleAccredito = 0.0
	Double totaleAccreditoEnte = 0.0
	Double totaleAccreditoIFEL = 0.0
	Double totaleRecupero = 0.0
	Double totaleRecuperoEnte = 0.0
	Double totaleRecuperoIFEL = 0.0
	
	Double totaleNetto = 0.0
	Double totaleIFEL = 0.0
	Double totaleLordo = 0.0
	
	/// Paginazione
	def pagingList = [
		activePage: 0,
		pageSize  : 10,
		totalSize : 0
	]
	
	/// Forniture
	def listaForniture = []
	def fornituraSelezionata = null
	
    Boolean flagProvincia = false

	@Init init(@ContextParam(ContextType.COMPONENT) Window w,
								 @ExecutionArgParam("porzione") def pz,
								 @ExecutionArgParam("modificabile") Boolean md) {
		
		this.self 	= w
		
		modificabile = md
		porzioneAttiva = pz
		
        flagProvincia = datiGeneraliService.flagProvinciaAbilitato()

		caricaAccredito()
		caricaRecupero()
		
		if(controllaQuadraturaVersamenti() == false) {
			eseguiQuadraturaVersamenti()
		}
		
		onRicaricaLista()
	}
	
	/// Elenco forniture ####################################################################################

	@Command
	def onRicaricaLista() {
		
		if(modifiche) {
			String messaggio = "Questa operazione annullera\' tutte le eventuali modifiche!\n\nProcedere ?"
			Messagebox.show(messaggio, "Attenzione",
				Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
				new org.zkoss.zk.ui.event.EventListener() {
					void onEvent(Event e) {
						if (Messagebox.ON_YES.equals(e.getName())) {
							ricaricaLista(true)
						}
					}
				}
			)
		}
		else {
			ricaricaLista(true)
		}
	}
	
	@Command
	def onCambioPagina() {
		
		caricaLista(false)
	}
	
	@Command
	def onFornituraSelected()  {
		
	}
	
	@Command
	def onModificaFornitura() {
		
	}
	
	@Command
	def onChangeImportoIFEL(@BindingParam("detail") def detail) {
		
		def netto = detail.dto.importoNetto ?: 0
		def ifel = detail.dto.importoIfel ?: 0
		detail.importoLordo = netto + ifel
		
		def delta = ifel - detail.importoIFELPrecedente
		detail.importoIFELPrecedente = ifel
		totaleIFEL += delta
		totaleLordo += delta

		BindUtils.postNotifyChange(null, null, this, "listaForniture")
		BindUtils.postNotifyChange(null, null, this, "totaleIFEL")
		BindUtils.postNotifyChange(null, null, this, "totaleLordo")
		
		modifiche = true
		BindUtils.postNotifyChange(null, null, this, "modifiche")
	}
	
	@Command
	def onEseguiQuadraturaVersamenti() {
	
		if((controllaQuadraturaVersamenti() != false) || (modifiche != false)) {
			
			String messaggio = "Questa operazione sostituira\' tutti i dati esistenti e le eventuali modifiche andranno perse!\n\nProcedere ?"
			Messagebox.show(messaggio, "Attenzione",
				Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
				new org.zkoss.zk.ui.event.EventListener() {
					void onEvent(Event e) {
						if (Messagebox.ON_YES.equals(e.getName())) {
							eseguiQuadraturaVersamenti()
						}
					}
				}
			)
		}
		else {
			eseguiQuadraturaVersamenti()
		}
	}
	
	@Command
	def onVerificaQuadraturaVersamenti() {
		
		if(modifiche) {
			String messaggio = "Questa operazione annullera\' tutte le modifiche non salvate!\n\nProcedere ?"
			Messagebox.show(messaggio, "Attenzione",
				Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
				new org.zkoss.zk.ui.event.EventListener() {
					void onEvent(Event e) {
						if (Messagebox.ON_YES.equals(e.getName())) {
							verificaQuadraturaVersamenti()
						}
					}
				}
			)
		}
		else {
			verificaQuadraturaVersamenti()
		}
	}
	
	@Command
	def onQuadraturaToXls() {
		
		DecimalFormat fmtValuta = new DecimalFormat("€ #,##0.00")
		
		def progrDoc = porzioneAttiva.documentoId as String
		
		def filtriNow = completaFiltri()
		filtriNow.tipoRecord = 'R2'
		def totaleForniture = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
		def elencoForniture = totaleForniture.lista
		
		def intestazione = [
			"Quadratura AE " : porzioneAttiva?.descrizione ?: '-'
		]
	
		def fields = [
			'progressivo'			: 'Progr.',
			'dataFornitura'			: 'Data Fornitura',
			'progrFornitura'		: 'Progr. Fornitura',
			'dataRipartizione'		: 'Data Ripartizione',
			'progrRipartizione'		: 'Progr. Ripartizione',
			'dataBonifico'			: 'Data Bonifico',
			'annoAcc'				: 'Anno Acc. Cont.',
			'numeroAcc'				: 'Numero Acc. Cont.',
			'numeroProvvisorio'		: 'Numero Provv.',
			'dataProvvisorio'		: 'Data Provv.',
			'importoNetto'			: 'Imp. Netto',
			'importoIfel'			: 'Imp. IFEL',
			'importoLordo'			: 'Imp. Lordo',
		]
	
		def parameters = [
			"intestazione" :	intestazione,
			title :				"Dettagli Quadratura",
			"title.font.size" : "12"
		]
		
		Integer	xlsRigheMax = Integer.MAX_VALUE

		def datiDaEsportare = []
		def datiOriginali = []
		def datoDaEsportare
		def datoPerErrore = null
		
		def righeTotali = elencoForniture.size()
		datiOriginali = elencoForniture

		///
		/// Template per resoconto
		///
		def templateResoconto = [
			progressivo : "",
			dataFornitura : porzioneAttiva.dataFornitura,
			progrFornitura : porzioneAttiva.progFornitura,
			dataRipartizione : porzioneAttiva.dataRipartizione,
			progrRipartizione : porzioneAttiva.progRipartizione,
			dataBonifico : porzioneAttiva.dataBonifico,
			annoAcc : "",
			numeroAcc : "",
			numeroProvvisorio : "",
			dataProvvisorio : "",
		]

		///
		/// Resoconto record G2 e G3
		///
		while(1 == 1) {
			
			datoDaEsportare = templateResoconto.clone()
			
			datoDaEsportare.dataProvvisorio = "Accrediti"

			datoDaEsportare.importoNetto = fmtValuta.format(totaleAccreditoEnte)
			datoDaEsportare.importoIfel = fmtValuta.format(totaleAccreditoIFEL)
			datoDaEsportare.importoLordo = fmtValuta.format(totaleAccredito)
			
			datiDaEsportare << datoDaEsportare
			
			datoDaEsportare = templateResoconto.clone()
			
			datoDaEsportare.dataProvvisorio = "Recuperi"

			datoDaEsportare.importoNetto = fmtValuta.format(totaleRecuperoEnte)
			datoDaEsportare.importoIfel = fmtValuta.format(totaleRecuperoIFEL)
			datoDaEsportare.importoLordo = fmtValuta.format(totaleRecupero)
			
			datiDaEsportare << datoDaEsportare
			
			datoDaEsportare = templateResoconto.clone()
			
			datoDaEsportare.dataProvvisorio = "Saldo"

			datoDaEsportare.importoNetto = fmtValuta.format(totaleAccreditoEnte + totaleRecuperoEnte)
			datoDaEsportare.importoIfel = fmtValuta.format(totaleAccreditoIFEL + totaleRecuperoIFEL)
			datoDaEsportare.importoLordo = fmtValuta.format(totaleAccredito + totaleRecupero)
			
			datiDaEsportare << datoDaEsportare
			
			break
		}
		
		///
		/// Resoconto record R2
		///
		def importoNetto = 0.0
		def importoIFEL = 0.0
		def importoeLordo = 0.0
		
		datiOriginali.each {
			
			datoDaEsportare = [:]
			
			FornituraAEDTO dto = it.dto
			
			datoDaEsportare.progressivo = dto.progressivo
			datoDaEsportare.progrFornitura = dto.progrFornitura
			datoDaEsportare.progrRipartizione = dto.progrRipartizione
			
			datoDaEsportare.annoAcc = dto.annoAcc
			datoDaEsportare.numeroAcc = dto.numeroAcc
			datoDaEsportare.numeroProvvisorio = dto.numeroProvvisorio
			
			datoDaEsportare.dataFornitura = dto.dataFornitura
			datoDaEsportare.dataRipartizione = dto.dataRipartizione
			datoDaEsportare.dataBonifico = dto.dataBonifico
			datoDaEsportare.dataProvvisorio = dto.dataProvvisorio
			
			datoDaEsportare.importoNetto = (dto.importoNetto != null) ? fmtValuta.format(dto.importoNetto as Double) : ''
			datoDaEsportare.importoIfel = (dto.importoIfel != null) ? fmtValuta.format(dto.importoIfel as Double) : ''
			
			def netto = (dto.importoNetto ?: 0.0)
			def ifel = (dto.importoIfel ?: 0.0)
			def lordo = netto + ifel
			datoDaEsportare.importoLordo = fmtValuta.format(lordo as Double)
			
			importoNetto += netto
			importoIFEL += ifel
			importoeLordo += lordo
	
			datiDaEsportare << datoDaEsportare
		}

		///
		/// Resoconto totali record R2
		///
		while(1 == 1) {
			
			datoDaEsportare = templateResoconto.clone()
			
			datoDaEsportare.dataProvvisorio = "Totali"
			
			datoDaEsportare.importoNetto = fmtValuta.format(importoNetto)
			datoDaEsportare.importoIfel = fmtValuta.format(importoIFEL)
			datoDaEsportare.importoLordo = fmtValuta.format(importoeLordo)
			
			datiDaEsportare << datoDaEsportare
			
			break
		}
		
		if(datoPerErrore != null) {
			datiDaEsportare << datoPerErrore
		}

		String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.XLSX,
				FileNameGenerator.GENERATORS_TITLES.QUADRATURA_AE,
				[progressivo: progrDoc])

		XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields)
	}
	
	@Command
	onSalva() {
		
		String messaggio = "Sicuri di voler salvare le modifiche apportate?"
		
		Messagebox.show(messaggio, "Attenzione",
			Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
			new org.zkoss.zk.ui.event.EventListener() {
				void onEvent(Event e) {
					if (Messagebox.ON_YES.equals(e.getName())) {
						salvaModifiche()
					}
				}
			}
		)
	}
	
	@Command
	onChiudi() {
		
		if(modifiche) {
			String messaggio = "Chiudere e annullare le eventuali modifiche ?"
			Messagebox.show(messaggio, "Attenzione",
				Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
				new org.zkoss.zk.ui.event.EventListener() {
					void onEvent(Event e) {
						if (Messagebox.ON_YES.equals(e.getName())) {
							chiudi()
						}
					}
				}
			)
		}
		else {
			chiudi()
		}
	}
	
	/// Funzioni interne ####################################################################################
	
	///
	/// Chiude finestra
	///
	private def chiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
	
	///
	/// *** Ricarica lista e ricalcola resoconto
	///
	private def ricaricaLista(boolean resetPaginazione) {
		
		caricaLista(resetPaginazione)
		caricaResoconto()
	}
	
	///
	/// *** Rilegge elenco tariffe
	///
	private def caricaLista(boolean resetPaginazione) {
		
		def filtriNow = completaFiltri()
		filtriNow.tipoRecord = 'R2'

		if(resetPaginazione) {
			pagingList.activePage = 0
		}
	
		def totaleForniture = fornitureAEService.listaForniture(filtriNow, pagingList.pageSize, pagingList.activePage)
		listaForniture = totaleForniture.lista
		pagingList.totalSize = totaleForniture.totale
		
		if(resetPaginazione) {
			modifiche = false
		}
		
		BindUtils.postNotifyChange(null, null, this, "pagingList")
		BindUtils.postNotifyChange(null, null, this, "listaForniture")
		BindUtils.postNotifyChange(null, null, this, "modifiche")
	}
	
	///
	/// Ricava i valori di accredito (Record tipo G2)
	///
	private def caricaResoconto() {
		
		def filtriNow = completaFiltri()
		filtriNow.tipoRecord = 'R2'
		
		def totaleResoconto = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
		def listaResoconto = totaleResoconto.lista
		
		totaleNetto = listaResoconto.sum { it.dto.importoNetto ?: 0 } ?: 0
		totaleIFEL = listaResoconto.sum { it.dto.importoIfel ?: 0 } ?: 0
		totaleLordo = totaleNetto + totaleIFEL
		
		BindUtils.postNotifyChange(null, null, this, "totaleNetto")
		BindUtils.postNotifyChange(null, null, this, "totaleIFEL")
		BindUtils.postNotifyChange(null, null, this, "totaleLordo")
	}
	
	///
	/// Ricava i valori di accredito (Record tipo G2/M)
	///
	private def caricaAccredito() {
		
		def filtriNow = completaFiltri()
		filtriNow.tipoRecord = (flagProvincia) ? 'M' : 'G2'
		
		def totaleAccrediti = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
		def listaAccrediti = totaleAccrediti.lista
		
		def listaEnte = listaAccrediti.findAll { it.dto.codEnteBeneficiario != 'IFEL'}
		def listaIFEL = listaAccrediti.findAll { it.dto.codEnteBeneficiario == 'IFEL'}
		totaleAccreditoEnte = listaEnte.sum { it.dto.importoAccredito } ?: 0
		totaleAccreditoIFEL = listaIFEL.sum { it.dto.importoAccredito } ?: 0
		totaleAccredito = totaleAccreditoEnte + totaleAccreditoIFEL
		
		BindUtils.postNotifyChange(null, null, this, "totaleAccreditoEnte")
		BindUtils.postNotifyChange(null, null, this, "totaleAccreditoIFEL")
		BindUtils.postNotifyChange(null, null, this, "totaleAccredito")
	}
	
	///
	/// Ricava i valori di recupero (Record tipo G3/Non usato)
	///
	private def caricaRecupero() {

		if(flagProvincia) {
			totaleRecuperoEnte = 0
			totaleRecuperoIFEL = 0
		}
		else {
			def filtriNow = completaFiltri()
			filtriNow.tipoRecord = 'G3'
			filtriNow.dataBonifico = null
		
			def totaleRecuperi = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
			def listaRecuperi = totaleRecuperi.lista
		
			def listaEnte = listaRecuperi.findAll { it.dto.codEnteBeneficiario != 'IFEL'}
			def listaIFEL = listaRecuperi.findAll { it.dto.codEnteBeneficiario == 'IFEL'}
			totaleRecuperoEnte = listaEnte.sum { it.dto.importoRecupero } ?: 0
			totaleRecuperoIFEL = listaIFEL.sum { it.dto.importoRecupero } ?: 0
		}
		totaleRecupero = totaleRecuperoEnte + totaleRecuperoIFEL
		
		BindUtils.postNotifyChange(null, null, this, "totaleRecuperoEnte")
		BindUtils.postNotifyChange(null, null, this, "totaleRecuperoIFEL")
		BindUtils.postNotifyChange(null, null, this, "totaleRecupero")
	}
	
	///
	/// *** Completa il filtro per la ricerca
	///
	private def completaFiltri() {
		
		def filtri = [:]
		
		filtri.progDoc = porzioneAttiva.documentoId
		
		filtri.dataFornitura = porzioneAttiva.dataFornitura
		filtri.progFornitura = porzioneAttiva.progFornitura
		filtri.dataRipartizione = porzioneAttiva.dataRipartizione
		filtri.progRipartizione = porzioneAttiva.progRipartizione
		filtri.dataBonifico = porzioneAttiva.dataBonifico
		
		return filtri
	}
	
	///
	/// *** Controlla presenza dellqa quadratura : true -> presente, false : non presente
	///
	def controllaQuadraturaVersamenti() {
		
		def ripartizione = porzioneAttiva
		
		def result = fornitureAEService.presenzaRiepilogoProvvisori(ripartizione)
		
		return (result == 0)
	}

	///
	/// *** Esegue la quadratura generando i record di tipo R2, quindi lancia verifica.
	///
	def eseguiQuadraturaVersamenti() {
		
		def ripartizione = porzioneAttiva
	
		String msg = fornitureAEService.eseguiEmissioneRiepilogoProvvisori(ripartizione)
		if(msg == null) msg = ''
		
		if(!(msg.isEmpty())) {
			Messagebox.show(msg, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
		}
		else {
			verificaQuadraturaVersamenti()
		}
		
		ricaricaLista(true)
	}
	
	///
	/// *** Esegue la verifica della quadratrura
	///
	def verificaQuadraturaVersamenti() {
		
		def ripartizione = porzioneAttiva
	
		Integer result = fornitureAEService.presenzaRiepilogoProvvisori(ripartizione)
		if(result == 0) {
			result = fornitureAEService.eseguiQuadraturaVersamenti(ripartizione)
			if(result != 0) {
				Messagebox.show("Quadratura errata !", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
			}
			else {
				Clients.showNotification("Quadratura corretta", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
			}
		}
		else {
			Clients.showNotification("Attenzione : nessun dato nella quadratura", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
		}
			
		ricaricaLista(true)
	}
		
	///
	/// Salva le modifiche apportate
	///
	private def salvaModifiche() {
	
		def report = [
			result : 0,
			message : ""
		]
		
		listaForniture.each {
			def reportThis = fornitureAEService.salvaIFELFornitura(it.dto)
			if(reportThis.result != 0) {
				if(reportThis.result > report.result) {
					report.result = reportThis.result
				}
				if(!(report.message.isEmpty() )) report.message += "\n"
				report.message += reportThis.message
			}
		}
		
		if(!(report.message.isEmpty())) {
			Messagebox.show(report.message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
		}
		else {
			modifiche = false
		}
		
		caricaLista(false)
		caricaResoconto()
		
		BindUtils.postNotifyChange(null, null, this, "modifiche")
	}
}
