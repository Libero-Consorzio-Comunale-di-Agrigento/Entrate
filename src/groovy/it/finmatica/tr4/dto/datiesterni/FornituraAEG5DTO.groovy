package it.finmatica.tr4.dto.datiesterni;

import java.math.BigDecimal;
import java.util.Date;

import it.finmatica.tr4.datiesterni.DocumentoCaricato;
import it.finmatica.tr4.datiesterni.FornituraAEG5;
import it.finmatica.tr4.dto.datiesterni.DocumentoCaricatoDTO;

public class FornituraAEG5DTO implements it.finmatica.dto.DTO<FornituraAEG5> {
	
	private static final long serialVersionUID = 1L;

	DocumentoCaricatoDTO	documentoCaricato
	Integer 				progressivo
	
	String		tipoRecord
	String		desTipoRecord
	
	Date		dataFornitura
	Short		progrFornitura
	
	String		statoMandat
	String		desStatoMandato
	String		codEnteComunale
	String		codValuta
	BigDecimal	importoAccredito
	
	BigDecimal	cro
	Date		dataAccreditamento
	Date		dataRipartizioneOrig
	Short		progrRipartizioneOrig
	Date		dataBonificoOrig
		
	String		tipoImposta
	String		desTipoImposta
	
	String		iban
	String		sezioneContoTu
	Integer		numeroContoTu
	BigDecimal	codMovimento
	String		desMovimento
	Date		dataStornoScarto
	Date		dataElaborazioneNuova
	Short		progrElaborazioneNuova

	public FornituraAEG5 getDomainObject () {
		return FornituraAEG5.createCriteria().get {
			eq('documentoCaricato', this.documentoCaricato.getDomainObject())
			eq('progressivo', this.progressivo)
		}
	}
	
	public FornituraAEG5 toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
