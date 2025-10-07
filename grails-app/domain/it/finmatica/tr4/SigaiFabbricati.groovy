package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiFabbricati implements Serializable {

	String fiscale
	String persona
	String dataSit
	String tdich
	String progMod
	String numOrd
	String caratteristica
	String comune
	String istatCom
	String prov
	String cap
	String indirizzo
	String sezione
	String foglio
	String numero
	String subalterno
	String protocollo
	String annoDeAcc
	String catCatastale
	String classe
	String immStorico
	String idenRendValore
	String flagValProv
	String tipoImm
	String soggIci
	String detrazPrinc
	String riduzione
	String rendita
	String percPoss
	String mesiPoss
	String mesiEscEsenzi
	String mesiApplRidu
	String possesso
	String esclusoEsente
	String riduzione2
	String abitPrinc
	String fiscDichCong
	String flagcF
	String renditaRedd
	String giorniPossRedd
	String percPossRedd
	String redditoEffRedd
	String utilizzoRedd
	String dePianoEnRedd
	String datScIlorRedd
	String imponIrpefRedd
	String titoloRedd
	String soggIsiRedd
	String imponIlor
	String progressivo
	String recoModificato
	String invio
	String relazione
	String annoFiscale

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append fiscale
		builder.append persona
		builder.append dataSit
		builder.append tdich
		builder.append progMod
		builder.append numOrd
		builder.append caratteristica
		builder.append comune
		builder.append istatCom
		builder.append prov
		builder.append cap
		builder.append indirizzo
		builder.append sezione
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append protocollo
		builder.append annoDeAcc
		builder.append catCatastale
		builder.append classe
		builder.append immStorico
		builder.append idenRendValore
		builder.append flagValProv
		builder.append tipoImm
		builder.append soggIci
		builder.append detrazPrinc
		builder.append riduzione
		builder.append rendita
		builder.append percPoss
		builder.append mesiPoss
		builder.append mesiEscEsenzi
		builder.append mesiApplRidu
		builder.append possesso
		builder.append esclusoEsente
		builder.append riduzione2
		builder.append abitPrinc
		builder.append fiscDichCong
		builder.append flagcF
		builder.append renditaRedd
		builder.append giorniPossRedd
		builder.append percPossRedd
		builder.append redditoEffRedd
		builder.append utilizzoRedd
		builder.append dePianoEnRedd
		builder.append datScIlorRedd
		builder.append imponIrpefRedd
		builder.append titoloRedd
		builder.append soggIsiRedd
		builder.append imponIlor
		builder.append progressivo
		builder.append recoModificato
		builder.append invio
		builder.append relazione
		builder.append annoFiscale
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append fiscale, other.fiscale
		builder.append persona, other.persona
		builder.append dataSit, other.dataSit
		builder.append tdich, other.tdich
		builder.append progMod, other.progMod
		builder.append numOrd, other.numOrd
		builder.append caratteristica, other.caratteristica
		builder.append comune, other.comune
		builder.append istatCom, other.istatCom
		builder.append prov, other.prov
		builder.append cap, other.cap
		builder.append indirizzo, other.indirizzo
		builder.append sezione, other.sezione
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append protocollo, other.protocollo
		builder.append annoDeAcc, other.annoDeAcc
		builder.append catCatastale, other.catCatastale
		builder.append classe, other.classe
		builder.append immStorico, other.immStorico
		builder.append idenRendValore, other.idenRendValore
		builder.append flagValProv, other.flagValProv
		builder.append tipoImm, other.tipoImm
		builder.append soggIci, other.soggIci
		builder.append detrazPrinc, other.detrazPrinc
		builder.append riduzione, other.riduzione
		builder.append rendita, other.rendita
		builder.append percPoss, other.percPoss
		builder.append mesiPoss, other.mesiPoss
		builder.append mesiEscEsenzi, other.mesiEscEsenzi
		builder.append mesiApplRidu, other.mesiApplRidu
		builder.append possesso, other.possesso
		builder.append esclusoEsente, other.esclusoEsente
		builder.append riduzione2, other.riduzione2
		builder.append abitPrinc, other.abitPrinc
		builder.append fiscDichCong, other.fiscDichCong
		builder.append flagcF, other.flagcF
		builder.append renditaRedd, other.renditaRedd
		builder.append giorniPossRedd, other.giorniPossRedd
		builder.append percPossRedd, other.percPossRedd
		builder.append redditoEffRedd, other.redditoEffRedd
		builder.append utilizzoRedd, other.utilizzoRedd
		builder.append dePianoEnRedd, other.dePianoEnRedd
		builder.append datScIlorRedd, other.datScIlorRedd
		builder.append imponIrpefRedd, other.imponIrpefRedd
		builder.append titoloRedd, other.titoloRedd
		builder.append soggIsiRedd, other.soggIsiRedd
		builder.append imponIlor, other.imponIlor
		builder.append progressivo, other.progressivo
		builder.append recoModificato, other.recoModificato
		builder.append invio, other.invio
		builder.append relazione, other.relazione
		builder.append annoFiscale, other.annoFiscale
		builder.isEquals()
	}

	static mapping = {
		id composite: ["fiscale", "persona", "dataSit", "tdich", "progMod", "numOrd", "caratteristica", "comune", "istatCom", "prov", "cap", "indirizzo", "sezione", "foglio", "numero", "subalterno", "protocollo", "annoDeAcc", "catCatastale", "classe", "immStorico", "idenRendValore", "flagValProv", "tipoImm", "soggIci", "detrazPrinc", "riduzione", "rendita", "percPoss", "mesiPoss", "mesiEscEsenzi", "mesiApplRidu", "possesso", "esclusoEsente", "riduzione2", "abitPrinc", "fiscDichCong", "flagcF", "renditaRedd", "giorniPossRedd", "percPossRedd", "redditoEffRedd", "utilizzoRedd", "dePianoEnRedd", "datScIlorRedd", "imponIrpefRedd", "titoloRedd", "soggIsiRedd", "imponIlor", "progressivo", "recoModificato", "invio", "relazione", "annoFiscale"]
		version false
		riduzione2	column: "RIDUZIONE_2"
		flagcF		column: "FLAGC_F"
	}

	static constraints = {
		fiscale nullable: true, maxSize: 16
		persona nullable: true, maxSize: 1
		dataSit nullable: true, maxSize: 10
		tdich nullable: true, maxSize: 1
		progMod nullable: true, maxSize: 5
		numOrd nullable: true, maxSize: 4
		caratteristica nullable: true, maxSize: 1
		comune nullable: true, maxSize: 21
		istatCom nullable: true, maxSize: 6
		prov nullable: true, maxSize: 2
		cap nullable: true, maxSize: 5
		indirizzo nullable: true, maxSize: 36
		sezione nullable: true, maxSize: 3
		foglio nullable: true, maxSize: 5
		numero nullable: true, maxSize: 5
		subalterno nullable: true, maxSize: 4
		protocollo nullable: true, maxSize: 6
		annoDeAcc nullable: true, maxSize: 4
		catCatastale nullable: true, maxSize: 3
		classe nullable: true, maxSize: 2
		immStorico nullable: true, maxSize: 1
		idenRendValore nullable: true, maxSize: 1
		flagValProv nullable: true, maxSize: 1
		tipoImm nullable: true, maxSize: 1
		soggIci nullable: true, maxSize: 1
		detrazPrinc nullable: true, maxSize: 7
		riduzione nullable: true, maxSize: 1
		rendita nullable: true, maxSize: 13
		percPoss nullable: true, maxSize: 5
		mesiPoss nullable: true, maxSize: 2
		mesiEscEsenzi nullable: true, maxSize: 2
		mesiApplRidu nullable: true, maxSize: 2
		possesso nullable: true, maxSize: 1
		esclusoEsente nullable: true, maxSize: 1
		riduzione2 nullable: true, maxSize: 1
		abitPrinc nullable: true, maxSize: 1
		fiscDichCong nullable: true, maxSize: 16
		flagcF nullable: true, maxSize: 1
		renditaRedd nullable: true, maxSize: 10
		giorniPossRedd nullable: true, maxSize: 3
		percPossRedd nullable: true, maxSize: 5
		redditoEffRedd nullable: true, maxSize: 9
		utilizzoRedd nullable: true, maxSize: 1
		dePianoEnRedd nullable: true, maxSize: 9
		datScIlorRedd nullable: true, maxSize: 4
		imponIrpefRedd nullable: true, maxSize: 9
		titoloRedd nullable: true, maxSize: 1
		soggIsiRedd nullable: true, maxSize: 1
		imponIlor nullable: true, maxSize: 9
		progressivo nullable: true, maxSize: 7
		recoModificato nullable: true, maxSize: 1
		invio nullable: true, maxSize: 3
		relazione nullable: true, maxSize: 8
		annoFiscale nullable: true, maxSize: 4
	}
}
