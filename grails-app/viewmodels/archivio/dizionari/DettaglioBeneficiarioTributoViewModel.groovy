package archivio.dizionari

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.codicif24.CodiciF24Service
import it.finmatica.tr4.CodiceF24
import it.finmatica.tr4.BeneficiariTributo
import it.finmatica.tr4.dto.BeneficiariTributoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioBeneficiarioTributoViewModel {

	// Componenti
	Window self

	// Services
	def springSecurityService
    DatiGeneraliService datiGeneraliService
	CodiciF24Service codiciF24Service
	
	// Dati
	String codiceF24
	BeneficiariTributo beneficiario
	
	Boolean lettura

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("codiceF24") String cc,
		 @ExecutionArgParam("beneficiario") def bb,
		 @ExecutionArgParam("lettura") Boolean lt) {

		this.self = w
		
		this.lettura = lt
		
		this.codiceF24 = cc
		
		if(bb) {
			this.beneficiario = bb
		}
		else {
			this.beneficiario = new BeneficiariTributo()
			this.beneficiario.tributoF24 = cc
		}
	}

	@Command
	onSalva() {
		
		int result = verificaParametri()
		if(result > 1) return;
		
		codiciF24Service.salvaBeneficiario(this.beneficiario.toDTO())
		
		if(result != 0) {
			Clients.showNotification('Salvataggio eseguito', Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
		}
		else {
			onChiudi()
		}
	}

	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [:])
	}
	
	def verificaParametri() {
		
        def errori = []
		int result = 0
		
		CodiceF24 codiceRaw = CodiceF24.findByTributo(this.codiceF24)
		boolean checkCF = false
		
		Integer codiceF24Num = 0
		try {
			if(codiceRaw.tipoCodice != 'C') {}
			codiceF24Num = Integer.parseInt(this.codiceF24);
			}
		catch (NumberFormatException e) { };
		if(codiceF24Num != 0) checkCF = true
		
        if (this.beneficiario.codFiscale.size() < 9) {
            errori << "Codice Fiscale non valido\n"
			result = 2
        }
		
		if(checkCF) {
			def datiSoggetto = datiGeneraliService.getDatiSoggettoCorrente()
			if(this.beneficiario.codFiscale != datiSoggetto?.codiceFiscale) {
				errori << "Il Codice Fiscale dovrebbe coincidere con quello dell'Ente impostato in Dati Generali\n"
				if(result < 1) result = 1
			}
		}

        if (this.beneficiario.intestatario.size() < 3) {
            errori << "Intestatario non valido\n"
        }

        if (this.beneficiario.iban.size() < 27) {
            errori << "IBAN non valido\n"
			result = 2
        }

        if (this.beneficiario.tassonomia.size() < 8) {
            errori << "Tassonomia non valida\n"
			result = 2
        }
		int size = this.beneficiario.tassonomiaAnniPrec?.size() ?: 0
		if ((size != 0) && (size < 8)) {
			errori << "Tassonomia A.P. non valida\n"
			result = 2
		}
		if (this.beneficiario.causaleQuota.size() < 4) {
			errori << "Causale Quota non valida\n"
			result = 2
		}
		if (this.beneficiario.desMetadata.size() < 4) {
			errori << "Descrizione Metadata non valida\n"
			result = 2
		}

        if (result > 0) {
            String message = "Attenzione :\n\n"
            errori.each { message += it }
			def tipoNotifica = (result > 1) ? Clients.NOTIFICATION_TYPE_ERROR : Clients.NOTIFICATION_TYPE_WARNING
            Clients.showNotification(message, tipoNotifica, null, "before_center", 5000, true)
        }

		return result
	}
}
