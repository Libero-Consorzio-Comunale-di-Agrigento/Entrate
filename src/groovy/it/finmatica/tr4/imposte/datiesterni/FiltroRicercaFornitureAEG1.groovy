package it.finmatica.tr4.imposte.datiesterni

class FiltroRicercaFornitureAEG1 {

	String	codFiscale = '';
	String	codEnteComunale = '';
	def		codiceTributoDa = null;
	def		codiceTributoA = null;
	def		annoRifDa = null;
	def		annoRifA = null;
	def		dataRiscossioneDa = null;
	def		dataRiscossioneA = null;
	def		filtroAccertato = null;
	def		filtroProvvisorio = null;

	def		dataFornituraDa = null;
	def		dataFornituraA = null;
	def		dataRipartizioneDa = null;
	def		dataRipartizioneA = null;
	def		dataBonificoDa = null;
	def		dataBonificoA = null;
	
	boolean isDirty() {
		
		return (this.codFiscale != '') ||
				(this.codEnteComunale != '') ||
				(this.codiceTributoDa != null) ||
				(this.codiceTributoA != null) ||
				(this.annoRifDa != null) ||
				(this.annoRifA != null) ||
				(this.dataRiscossioneDa != null) ||
				(this.dataRiscossioneA != null) ||
				(this.filtroAccertato != null) ||
				(this.filtroProvvisorio != null) ||
				(this.dataFornituraDa != null) ||
				(this.dataFornituraA != null) ||
				(this.dataRipartizioneDa != null) ||
				(this.dataRipartizioneA != null) ||
				(this.dataBonificoDa != null) ||
				(this.dataBonificoA != null)
	}
	
	boolean isExtended() {
		
		return  (this.dataFornituraDa != null) ||
				(this.dataFornituraA != null) ||
				(this.dataRipartizioneDa != null) ||
				(this.dataRipartizioneA != null) ||
				(this.dataBonificoDa != null) ||
				(this.dataBonificoA != null)
	}
	
	def prepara() {
		
		def filtri = [
				codFiscale : this.codFiscale,
				codEnteComunale : this.codEnteComunale,
				codiceTributoDa : this.codiceTributoDa,
				codiceTributoA : this.codiceTributoA,
				annoRifDa : this.annoRifDa,
				annoRifA : this.annoRifA,
				dataRiscossioneDa : this.dataRiscossioneDa,
				dataRiscossioneA : this.dataRiscossioneA,
				filtroAccertato : this.filtroAccertato,
				filtroProvvisorio : this.filtroProvvisorio,
				dataFornituraDa : this.dataFornituraDa,
				dataFornituraA : this.dataFornituraA,
				dataRipartizioneDa : this.dataRipartizioneDa,
				dataRipartizioneA : this.dataRipartizioneA,
				dataBonificoDa : this.dataBonificoDa,
				dataBonificoA : this.dataBonificoA,
		]
		
		return filtri;
	}
}
