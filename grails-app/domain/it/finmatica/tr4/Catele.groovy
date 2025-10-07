package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Catele implements Serializable {

	String codComune
	String codAzienda
	String codUtente
	String codFiscale
	String denominazione
	String sesso
	String dataNas
	String comuneNas
	String provinciaUte
	String sezione
	String foglio
	String numero
	String subalterno
	String protocollo
	Byte anno
	String indirizzo
	String scala
	String piano
	String interno
	Integer capFornitura
	String utilizzato
	String localitaFornitura
	Integer supImmobile
	Boolean rurale
	String codComAmm
	String codFiscalePro
	String denominazionePro
	String sessoPro
	String dataNasPro
	String comNasPro
	String provinciaPro
	Boolean utenza
	String nomRec
	String indRec
	Integer capRec
	String filRec
	String locRec
	Boolean flagCodFisUte
	Boolean flagCodFisPro
	Boolean dup
	Boolean codFisUt
	Boolean datiImm
	Boolean superficieImm
	Boolean codFisPro
	Boolean infQuest
	String codAtt
	String codAttNew
	String partitaIva

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codComune
		builder.append codAzienda
		builder.append codUtente
		builder.append codFiscale
		builder.append denominazione
		builder.append sesso
		builder.append dataNas
		builder.append comuneNas
		builder.append provinciaUte
		builder.append sezione
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append protocollo
		builder.append anno
		builder.append indirizzo
		builder.append scala
		builder.append piano
		builder.append interno
		builder.append capFornitura
		builder.append utilizzato
		builder.append localitaFornitura
		builder.append supImmobile
		builder.append rurale
		builder.append codComAmm
		builder.append codFiscalePro
		builder.append denominazionePro
		builder.append sessoPro
		builder.append dataNasPro
		builder.append comNasPro
		builder.append provinciaPro
		builder.append utenza
		builder.append nomRec
		builder.append indRec
		builder.append capRec
		builder.append filRec
		builder.append locRec
		builder.append flagCodFisUte
		builder.append flagCodFisPro
		builder.append dup
		builder.append codFisUt
		builder.append datiImm
		builder.append superficieImm
		builder.append codFisPro
		builder.append infQuest
		builder.append codAtt
		builder.append codAttNew
		builder.append partitaIva
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codComune, other.codComune
		builder.append codAzienda, other.codAzienda
		builder.append codUtente, other.codUtente
		builder.append codFiscale, other.codFiscale
		builder.append denominazione, other.denominazione
		builder.append sesso, other.sesso
		builder.append dataNas, other.dataNas
		builder.append comuneNas, other.comuneNas
		builder.append provinciaUte, other.provinciaUte
		builder.append sezione, other.sezione
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append protocollo, other.protocollo
		builder.append anno, other.anno
		builder.append indirizzo, other.indirizzo
		builder.append scala, other.scala
		builder.append piano, other.piano
		builder.append interno, other.interno
		builder.append capFornitura, other.capFornitura
		builder.append utilizzato, other.utilizzato
		builder.append localitaFornitura, other.localitaFornitura
		builder.append supImmobile, other.supImmobile
		builder.append rurale, other.rurale
		builder.append codComAmm, other.codComAmm
		builder.append codFiscalePro, other.codFiscalePro
		builder.append denominazionePro, other.denominazionePro
		builder.append sessoPro, other.sessoPro
		builder.append dataNasPro, other.dataNasPro
		builder.append comNasPro, other.comNasPro
		builder.append provinciaPro, other.provinciaPro
		builder.append utenza, other.utenza
		builder.append nomRec, other.nomRec
		builder.append indRec, other.indRec
		builder.append capRec, other.capRec
		builder.append filRec, other.filRec
		builder.append locRec, other.locRec
		builder.append flagCodFisUte, other.flagCodFisUte
		builder.append flagCodFisPro, other.flagCodFisPro
		builder.append dup, other.dup
		builder.append codFisUt, other.codFisUt
		builder.append datiImm, other.datiImm
		builder.append superficieImm, other.superficieImm
		builder.append codFisPro, other.codFisPro
		builder.append infQuest, other.infQuest
		builder.append codAtt, other.codAtt
		builder.append codAttNew, other.codAttNew
		builder.append partitaIva, other.partitaIva
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codComune", "codAzienda", "codUtente", "codFiscale", "denominazione", "sesso", "dataNas", "comuneNas", "provinciaUte", "sezione", "foglio", "numero", "subalterno", "protocollo", "anno", "indirizzo", "scala", "piano", "interno", "capFornitura", "utilizzato", "localitaFornitura", "supImmobile", "rurale", "codComAmm", "codFiscalePro", "denominazionePro", "sessoPro", "dataNasPro", "comNasPro", "provinciaPro", "utenza", "nomRec", "indRec", "capRec", "filRec", "locRec", "flagCodFisUte", "flagCodFisPro", "dup", "codFisUt", "datiImm", "superficieImm", "codFisPro", "infQuest", "codAtt", "codAttNew", "partitaIva"]
		version false
	}

	static constraints = {
		codComune nullable: true, maxSize: 5
		codAzienda nullable: true, maxSize: 5
		codUtente nullable: true, maxSize: 14
		codFiscale nullable: true, maxSize: 16
		denominazione nullable: true, maxSize: 63
		sesso nullable: true, maxSize: 1
		dataNas nullable: true, maxSize: 7
		comuneNas nullable: true, maxSize: 25
		provinciaUte nullable: true, maxSize: 2
		sezione nullable: true, maxSize: 3
		foglio nullable: true, maxSize: 5
		numero nullable: true, maxSize: 5
		subalterno nullable: true, maxSize: 4
		protocollo nullable: true, maxSize: 6
		anno nullable: true
		indirizzo nullable: true, maxSize: 24
		scala nullable: true, maxSize: 2
		piano nullable: true, maxSize: 2
		interno nullable: true, maxSize: 2
		capFornitura nullable: true
		utilizzato nullable: true, maxSize: 1
		localitaFornitura nullable: true, maxSize: 18
		supImmobile nullable: true
		rurale nullable: true
		codComAmm nullable: true, maxSize: 4
		codFiscalePro nullable: true, maxSize: 16
		denominazionePro nullable: true, maxSize: 63
		sessoPro nullable: true, maxSize: 1
		dataNasPro nullable: true, maxSize: 7
		comNasPro nullable: true, maxSize: 27
		provinciaPro nullable: true, maxSize: 2
		utenza nullable: true
		nomRec nullable: true, maxSize: 20
		indRec nullable: true, maxSize: 24
		capRec nullable: true
		filRec nullable: true, maxSize: 1
		locRec nullable: true, maxSize: 17
		flagCodFisUte nullable: true
		flagCodFisPro nullable: true
		dup nullable: true
		codFisUt nullable: true
		datiImm nullable: true
		superficieImm nullable: true
		codFisPro nullable: true
		infQuest nullable: true
		codAtt nullable: true, maxSize: 4
		codAttNew nullable: true, maxSize: 5
		partitaIva nullable: true, maxSize: 11
	}
}
