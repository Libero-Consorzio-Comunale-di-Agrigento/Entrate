package it.finmatica.tr4.imposte.datiesterni

class FiltroRicercaFornitureAEG5 {

	def		progDocDa = null;
	def		progDocA = null;
	def		dataFornituraDa = null;
	def		dataFornituraA = null;
	def		dataRipartizioneOrigDa = null;
	def		dataRipartizioneOrigA = null;
	
	boolean isDirty() {
		
		return (this.progDocDa != null) ||
				(this.progDocA != null) ||
				(this.dataFornituraDa != null) ||
				(this.dataFornituraA != null) ||
				(this.dataRipartizioneOrigDa != null) ||
				(this.dataRipartizioneOrigA != null)
	}
	
	def prepara() {
		
		def filtri = [
				progDocDa : this.progDocDa,
				progDocA : this.progDocA,
				dataFornituraDa : this.dataFornituraDa,
				dataFornituraA : this.dataFornituraA,
				dataRipartizioneOrigDa : this.dataRipartizioneOrigDa,
				dataRipartizioneOrigA : this.dataRipartizioneOrigA,
		]
		
		return filtri;
	}

	def preparaTipoM() {
		
		def filtri = [
				tipoRecord : 'M',
				///
				progDocDa : this.progDocDa,
				progDocA : this.progDocA,
				dataFornituraDa : this.dataFornituraDa,
				dataFornituraA : this.dataFornituraA,
				///
				dataRipartizioneDa : this.dataRipartizioneOrigDa,	/// Stessa maschera ma nomi DB diversi
				dataRipartizioneA : this.dataRipartizioneOrigA,
		]
		
		return filtri;
	}
}
