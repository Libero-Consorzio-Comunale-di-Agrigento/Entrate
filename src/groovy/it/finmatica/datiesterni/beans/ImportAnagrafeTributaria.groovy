package it.finmatica.datiesterni.beans

import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.anagrafetributaria.AllineamentoAnagrafeTributariaService
import org.apache.log4j.Logger

class ImportAnagrafeTributaria {

	private static final Logger log = Logger.getLogger(ImportAnagrafeTributaria.class)

	AllineamentoAnagrafeTributariaService allineamentoAnagrafeTributariaService

	def importaC01151(def parametri) {

		long idDocumento = parametri.idDocumento
		DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

		InputStream fileCaricato = new ByteArrayInputStream(doc.contenuto)

		Long row = 1

		Long datiCaricati = 0

		try {
			def fileData = [
				rispostaAttuale : null,
				documentoId : idDocumento,
				utente : parametri.utente.getDomainObject(),
				anomalie : 0,
			]
			def fileStats = [ 
				risposteTipo0 : 0,
				risposteTipo9 : 0,
				risposteTipo1 : 0,
				risposteTipo2 : 0,
				risposteTipoI : 0,
				risposteTipoR : 0,
				risposteTipoS : 0,
			]
			
			String recordType
			String controlCheck

			fileCaricato.eachLine { line ->

				Long lineLength = line.size()

				if (lineLength != 700) {
					throw new Throwable("Dimensione record non corretta : atteso 700, trovato ${lineLength}")
				}
				controlCheck = line.substring(699, 700)
				if (controlCheck != 'A') {
					throw new Throwable("Fine record non valido : atteso 'A', trovato ${controlCheck}")
				}

				recordType = line.substring(0, 1)

				switch (recordType) {
					case '0':
						fileStats.risposteTipo0 += allineamentoAnagrafeTributariaService.importaRecord0(line, fileData)
						break
					case '1':
						fileStats.risposteTipo1 += allineamentoAnagrafeTributariaService.importaRecord1(line, fileData)
						break
					case '2':
						fileStats.risposteTipo2 += allineamentoAnagrafeTributariaService.importaRecord2(line, fileData)
						break
					case 'I':
						fileStats.risposteTipoI += allineamentoAnagrafeTributariaService.importaRecordI(line, fileData)
						break
					case 'R':
						fileStats.risposteTipoR += allineamentoAnagrafeTributariaService.importaRecordR(line, fileData)
						break
					case 'S':
						fileStats.risposteTipoS += allineamentoAnagrafeTributariaService.importaRecordS(line, fileData)
						break
					case '9':
						fileStats.risposteTipo9 += allineamentoAnagrafeTributariaService.importaRecord9(line, fileData)
						break
					default:
						throw new Throwable("Tipo Record ${recordType} non riconosciuto")
				}
				row++
			}
			
			datiCaricati = fileStats.risposteTipo0 + fileStats.risposteTipo9  
			datiCaricati += fileStats.risposteTipo1 + fileStats.risposteTipo2
			datiCaricati += fileStats.risposteTipoI
			datiCaricati += fileStats.risposteTipoR
			datiCaricati += fileStats.risposteTipoS
			
			String note = "Caricati $datiCaricati risultati da C01.151.\n\n"
			note += "Di cui:\n"
			note += "- ${fileStats.risposteTipo1} persone fisiche\n"			
			note += "- ${fileStats.risposteTipo2} persone giuridiche\n"			
			note += "- ${fileStats.risposteTipoI} dettagli Partita IVA\n"			
			note += "- ${fileStats.risposteTipoR} dettagli Rappresentante Legale\n"			
			note += "- ${fileStats.risposteTipoS} dettagli Ditte/Societa\' Rappresentate"
			if(fileData.anomalie > 0) {
				note += "\n\nRiscontrate ${fileData.anomalie} anomalie"
			}
			
			doc.note = note
			doc.stato = 2
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)

			return "File " + doc.nomeDocumento + " importato con successo"
		}
		catch (Throwable e) {
			log.error("""Errore in importazione C01.151 riga [$row] """ + e.getMessage())
			doc.note = e.getMessage()
			doc.stato = 4
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			throw e
		}
    }
}
