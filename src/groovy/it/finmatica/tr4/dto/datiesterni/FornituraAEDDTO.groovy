package it.finmatica.tr4.dto.datiesterni;

import java.math.BigDecimal;
import java.util.Date;

import it.finmatica.tr4.datiesterni.DocumentoCaricato;
import it.finmatica.tr4.datiesterni.FornituraAED;
import it.finmatica.tr4.dto.datiesterni.DocumentoCaricatoDTO;

public class FornituraAEDDTO implements it.finmatica.dto.DTO<FornituraAED> {
	
	private static final long serialVersionUID = 1L;

	DocumentoCaricatoDTO	documentoCaricato
	Integer 				progressivo

	String		tipoRecord
	String		desTipoRecord
	
	Date		dataFornitura
	Short		progrFornitura
	
	Date		dataRipartizione
	Short		progrRipartizione
	Date		dataBonifico
	Integer		progrDelega
	Short		progrRiga
	
	Integer		codEnte
	String		desEnte
	String		tipoEnte
	String		desTipoEnte
	
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
	String		desTipoImposta
	
	String		codFiscale2
	String		codIdentificativo2
	String		idOperazione
	
	Short		annoAcc
	Integer		numeroAcc
	
	String		numeroProvvisorio
	Date		dataProvvisorio
	
	BigDecimal	importoNetto
	BigDecimal	importoIfel
	BigDecimal	importoLordo
	
	public FornituraAED getDomainObject () {
		return FornituraAED.createCriteria().get {
			eq('documentoCaricato', this.documentoCaricato.getDomainObject())
			eq('progressivo', this.progressivo)
		}
	}
	
	public FornituraAED toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
