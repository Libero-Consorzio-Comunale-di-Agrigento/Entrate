package it.finmatica.tr4.dto.datiesterni;

import java.math.BigDecimal;
import java.util.Date;

import it.finmatica.tr4.datiesterni.DocumentoCaricato;
import it.finmatica.tr4.datiesterni.FornituraAE;
import it.finmatica.tr4.dto.datiesterni.DocumentoCaricatoDTO;

public class FornituraAEDTO implements it.finmatica.dto.DTO<FornituraAE> {
	
	private static final long serialVersionUID = 1L;

	DocumentoCaricatoDTO	documentoCaricato
	Integer 				progressivo

	String		tipoRecord
	
	Date		dataFornitura
	Short		progrFornitura
	
	Date		dataRipartizione
	Short		progrRipartizione
	Date		dataBonifico
	Integer		progrDelega
	Short		progrRiga
	
	Integer		codEnte
	String		tipoEnte
	
	Integer		cab
	String		codFiscale
	Short		flagErrCodFiscale
	Date		dataRiscossione
	String		codEnteComunale
	String		codTributo
	Short		flagErrCodTributo
	Short		rateazione
	Short		annoRif
	Short		flagErrAnno
	String		codValuta
	BigDecimal	importoDebito
	BigDecimal	importoCredito
	Short		ravvedimento
	Short		immobiliVariati
	Short		acconto
	Short		saldo
	Short		numFabbricati
	Short		flagErrDati
	BigDecimal	detrazione
	String		cognomeDenominazione
	String		codFiscaleOrig
	String		nome
	String		sesso
	Date		dataNas
	String		comuneStato
	String		provincia
	
	String		tipoImposta
	
	String		codFiscale2
	String		codIdentificativo2
	String		idOperazione
	
	String		stato
	String		codEnteBeneficiario
	BigDecimal	importoAccredito
	Date		dataMandato
	Short		progrMandato
	BigDecimal	importoRecupero
	Integer		periodoRipartizioneOrig
	Short		progrRipartizioneOrig
	Date		dataBonificoOrig
	String		tipoRecupero
	String		desRecupero
	BigDecimal	importoAnticipazione
	BigDecimal	cro
	Date		dataAccreditamento
	Date		dataRipartizioneOrig
	String		iban
	String		sezioneContoTu
	Integer		numeroContoTu
	BigDecimal	codMovimento
	String		desMovimento
	Date		dataStornoScarto
	Date		dataElaborazioneNuova
	Short		progrElaborazioneNuova
	String		tipoOperazione
	Date		dataOperazione
	String		tipoTributo
	String		descrizioneTitr
	
	Short		annoAcc
	Integer		numeroAcc
	
	String		numeroProvvisorio
	Date		dataProvvisorio
	
	BigDecimal	importoNetto
	BigDecimal	importoIfel
	BigDecimal	importoLordo
		
	Short		codProvincia

	public FornituraAE getDomainObject () {
		return FornituraAE.createCriteria().get {
			eq('documentoCaricato', this.documentoCaricato.getDomainObject())
			eq('progressivo', this.progressivo)
		}
	}
	
	public FornituraAE toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
