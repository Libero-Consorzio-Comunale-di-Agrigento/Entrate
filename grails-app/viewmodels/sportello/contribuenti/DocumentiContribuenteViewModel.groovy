package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.TipiCanale
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.smartpnd.SmartPndService
import net.sf.jmimemagic.Magic
import net.sf.jmimemagic.MagicMatch
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import java.nio.file.Files

class DocumentiContribuenteViewModel {

	private Logger log = LoggerFactory.getLogger(DocumentiContribuenteViewModel.class)

	// componenti
	Window self

	// services
	ContribuentiService contribuentiService
	DocumentaleService documentaleService
	SmartPndService smartPndService
	CommonService commonService


	// Modello
	SoggettoDTO soggetto
	String codFiscale
	def listaDocumenti
	def listaComunicazioniPND = [:]
	DocumentoContribuente documentoSelezionato
	def ultimoStato = ""
	Popup popupNote
	def smartPndAbilitato = false
	def listaAllegati
	def noteDocumentoContribuente


	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("idSoggetto") long idSoggetto) {
		this.self = w
		if (idSoggetto > 0) {
			soggetto = Soggetto.get(idSoggetto).toDTO([
					"contribuenti",
					"comuneResidenza",
					"comuneResidenza.ad4Comune",
					"archivioVie",
					"stato"
			])

			if (soggetto.stato) {
				ultimoStato = soggetto.stato.descrizione
				if (soggetto.dataUltEve) {
					ultimoStato += " il " + soggetto.dataUltEve.format('dd/MM/yyyy')
				}
			}

			codFiscale = soggetto?.contribuente?.codFiscale
			caricaLista()
		}
		smartPndAbilitato = smartPndService.smartPNDAbilitato()
	}

	@Command
	def onSelezionaDocumento() {
		fetchListaAllegati()
	}

	private fetchListaAllegati() {
		listaAllegati = documentoSelezionato ? contribuentiService.allegatiDocumentoContribuente(documentoSelezionato).toDTO() : []
		BindUtils.postNotifyChange(null, null, this, 'listaAllegati')
	}


	@Command
	onRefresh() {
		caricaLista()
	}

	@Command
	onOpenSituazioneContribuente() {
		def ni = Contribuente.findBySoggetto(soggetto.getDomainObject())?.soggetto?.id

		if (!ni) {
			Clients.showNotification("Contribuente non trovato."
					, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
			return
		}
		Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
	}

	@Command
	def onChiudiPopupNote(@BindingParam("doc") DocumentoContribuente doc) {
		documentoSelezionato.note = noteDocumentoContribuente
		contribuentiService.caricaDocumento(doc)
		BindUtils.postNotifyChange(null, null, documentoSelezionato, "note")
		popupNote.close()
	}

	@Command
	def onApriPopupNote(@BindingParam("popup") Popup popup) {
		popupNote = popup
		if (popup?.id?.startsWith("popupNote_")) {
			noteDocumentoContribuente = documentoSelezionato.note
			BindUtils.postNotifyChange(null, null, this, "noteDocumentoContribuente")
		}
	}

	@Command
	onChiudiPopup() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	@Command
	onChangeTipoTributo() {
		caricaLista()
	}

	@Command
	documentiToXls() {

		Map fields = ["sequenza"         : "Sequenza"
					  , "titolo"         : "Titolo"
					  , "nomeFile"       : "Nome File"
					  , "dataInserimento": "Data Inserimento"
					  , "validitaDal"    : "Inizio Validità"
					  , "validitaAl"     : "Fine Validità"
					  , "informazioni"   : "Informazioni"
					  , "note"           : "Note"]

		String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.XLSX,
				FileNameGenerator.GENERATORS_TITLES.ELENCO_DOCUMENTI,
				[codFiscale: soggetto.contribuente.codFiscale])

		List<Map> lista = listaDocumenti.collect {
			[sequenza       : it.sequenza,
			 titolo         : it.titolo,
			 nomeFile       : it.nomeFile,
			 dataInserimento: it.dataInserimento,
			 validitaDal    : it.validitaDal,
			 validitaAl     : it.validitaAl,
			 informazioni   : it.informazioni,
			 note           : it.note]
		}

		XlsxExporter.exportAndDownload(nomeFile, lista, fields)
	}

	@Command
	def onVisualizzaDocumento() {

		// Se inviato al documentale
		if (documentoSelezionato.idComunicazionePnd != null) {

			try {
				def comunicazione = smartPndService.getComunicazione(documentoSelezionato.idComunicazionePnd)

				commonService.creaPopup(
						"/sportello/contribuenti/smartPndComunicazione.zul",
						null,
						[comunicazione: comunicazione]
				)
			} catch(Exception e){
				Clients.showNotification("Impossibile contattare ${SmartPndService.TITOLO_SMART_PND}:\n${e.message}",
						Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
			}
		} else if (documentoSelezionato.idDocumentoGdm != null) {
			def url = documentaleService.urlInGDM(documentoSelezionato.idDocumentoGdm)

			log.info "Apertura Documentale: ${url}"

			Clients.evalJavaScript("window.open('${url}','_blank');")
		} else if (documentoSelezionato.idMessaggio != null) {
			creaPopup("/messaggistica/messaggio.zul", [
					codFiscale: soggetto.contribuente.codFiscale,
					sequenza  : documentoSelezionato.sequenza
			])
		} else {

			String extension = ""

			int i = documentoSelezionato.nomeFile.lastIndexOf('.')
			if (i >= 0) {
				extension = documentoSelezionato.nomeFile.substring(i + 1)
			}

			String mimeType

			if (documentoSelezionato.documento) {
				Magic parser = new Magic()
				MagicMatch match = parser.getMagicMatch(documentoSelezionato.documento)
				mimeType = match.mimeType

			} else {
				mimeType = Files.probeContentType(new File(documentoSelezionato.nomeFile).toPath())
			}

			AMedia amedia = new AMedia(documentoSelezionato.nomeFile, extension, mimeType, documentoSelezionato.documento ?: [] as byte[])
			Filedownload.save(amedia)
		}
	}

	@Command
	def onOpenFinestraCaricamento(@BindingParam("azione") String azione) {

		Window w = Executions.createComponents("/sportello/contribuenti/caricaDocumento.zul", null,
				[
						documento    : (azione == 'visualizza' ? documentoSelezionato : new DocumentoContribuente([contribuente: soggetto.contribuente.domainObject])),
						daDocumentale: documentoSelezionato?.idDocumentoGdm != null
				]
		)
		w.doModal()
		w.onClose() {
			onRefresh()
			BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
		}
	}

	@Command
	def onEliminaDocumento() {

		Messagebox.show("Eliminazione della registrazione?", "Documenti Contribuente", Messagebox.OK | Messagebox.CANCEL,
				Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
			void onEvent(Event evt) throws InterruptedException {
				if (evt.getName().equals("onOK")) {
					DocumentoContribuente.get(documentoSelezionato).delete(failOnError: true, flush: true)
					onRefresh()
					BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
				}
			}
		})

	}

	@Command
	def onInviaEmail() {

		creaPopup("/messaggistica/email/email.zul", [codFiscale: soggetto.contribuente.codFiscale],
				{ e ->
					if (e?.data?.esito == 'inviato') {
						listaDocumenti = contribuentiService.documentiContribuente(soggetto.contribuente.codFiscale)
						BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
					}
				})
	}

	private caricaLista() {
		listaDocumenti = documentiContribuenteSmartPND(codFiscale)
		BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
		documentoSelezionato = null
		BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
		fetchListaAllegati()
	}

	def documentiContribuenteSmartPND(String codFiscale) {

		def tipiCanale = TipiCanale.findAll()

		def lista = contribuentiService.documentiContribuente(codFiscale, "list")
		if (smartPndService.smartPNDAbilitato()) {
			listaComunicazioniPND = [:]

			lista.each {

				if (it.idComunicazionePnd != null) {

					def comunicazione = null
					if (it.idComunicazionePnd != null) {
						try {
							comunicazione = it.idComunicazionePnd ? smartPndService.getComunicazione(it.idComunicazionePnd) : null
						} catch (Exception e) {
							log.error("Errore nel recupero della comunicazione ${it.idComunicazionePnd}", e)
						}
					}

					listaComunicazioniPND << [
							(it.idComunicazionePnd): [
									smartPndComunicazione: comunicazione,
									tipoCanaleDescr      : it.tipoCanale != null ? tipiCanale.find { tc -> tc.id == (it.tipoCanale as Long) }?.descrizione : null
							]
					]
				}

			}
		}

		BindUtils.postNotifyChange(null, null, this, "listaComunicazioniPND")

		return lista
	}

	@Command
	def allegatiToXls() throws Exception {
		Map fields = ["sequenza"         : "Sequenza"
					  , "titolo"         : "Titolo"
					  , "nomeFile"       : "Nome File"
					  , "dataInserimento": "Data Inserimento"
					  , "validitaDal"    : "Inizio Validità"
					  , "validitaAl"     : "Fine Validità"
					  , "informazioni"   : "Informazioni"
					  , "note"           : "Note"]
		String nomeFile = "ElencoAllegati_${soggetto.contribuente.codFiscale}"

		XlsxExporter.exportAndDownload(nomeFile, listaAllegati, fields)
	}

	///
	/// Crea popup
	///
	private void creaPopup(String zul, def parametri, def onClose = {}) {

		Window w = Executions.createComponents(zul, self, parametri)
		w.onClose = onClose
		w.doModal()
	}

}
