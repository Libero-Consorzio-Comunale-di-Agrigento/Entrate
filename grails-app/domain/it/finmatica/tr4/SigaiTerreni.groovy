package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiTerreni implements Serializable {

	String fiscale
	String persona
	String dataSit
	String centroCons
	String proviidd
	String uffIidd
	String centServ
	String tdich
	String progMod
	String comune
	String istatCom
	String prov
	String numOrdTerr
	String partitaCat
	String soggIci
	String condDir
	String areaFab
	String reddNom
	String perPoss
	String fDichCong
	String totReddDom
	String qtRedDomIrpef
	String qtRedDomIlor
	String valoreIsi
	String titolo
	String totReddAgr
	String qtRedAgrIrpef
	String qtRedAgrIlor
	String dedIlor
	String progressivo
	String recoModificato
	String invio
	String relazione
	String annoFiscale
	String mesiPoss
	String mesiEscEsenzi
	String mesiApplRidu
	String possesso
	String esenzione
	String riduzione
	String indirizzo

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append fiscale
		builder.append persona
		builder.append dataSit
		builder.append centroCons
		builder.append proviidd
		builder.append uffIidd
		builder.append centServ
		builder.append tdich
		builder.append progMod
		builder.append comune
		builder.append istatCom
		builder.append prov
		builder.append numOrdTerr
		builder.append partitaCat
		builder.append soggIci
		builder.append condDir
		builder.append areaFab
		builder.append reddNom
		builder.append perPoss
		builder.append fDichCong
		builder.append totReddDom
		builder.append qtRedDomIrpef
		builder.append qtRedDomIlor
		builder.append valoreIsi
		builder.append titolo
		builder.append totReddAgr
		builder.append qtRedAgrIrpef
		builder.append qtRedAgrIlor
		builder.append dedIlor
		builder.append progressivo
		builder.append recoModificato
		builder.append invio
		builder.append relazione
		builder.append annoFiscale
		builder.append mesiPoss
		builder.append mesiEscEsenzi
		builder.append mesiApplRidu
		builder.append possesso
		builder.append esenzione
		builder.append riduzione
		builder.append indirizzo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append fiscale, other.fiscale
		builder.append persona, other.persona
		builder.append dataSit, other.dataSit
		builder.append centroCons, other.centroCons
		builder.append proviidd, other.proviidd
		builder.append uffIidd, other.uffIidd
		builder.append centServ, other.centServ
		builder.append tdich, other.tdich
		builder.append progMod, other.progMod
		builder.append comune, other.comune
		builder.append istatCom, other.istatCom
		builder.append prov, other.prov
		builder.append numOrdTerr, other.numOrdTerr
		builder.append partitaCat, other.partitaCat
		builder.append soggIci, other.soggIci
		builder.append condDir, other.condDir
		builder.append areaFab, other.areaFab
		builder.append reddNom, other.reddNom
		builder.append perPoss, other.perPoss
		builder.append fDichCong, other.fDichCong
		builder.append totReddDom, other.totReddDom
		builder.append qtRedDomIrpef, other.qtRedDomIrpef
		builder.append qtRedDomIlor, other.qtRedDomIlor
		builder.append valoreIsi, other.valoreIsi
		builder.append titolo, other.titolo
		builder.append totReddAgr, other.totReddAgr
		builder.append qtRedAgrIrpef, other.qtRedAgrIrpef
		builder.append qtRedAgrIlor, other.qtRedAgrIlor
		builder.append dedIlor, other.dedIlor
		builder.append progressivo, other.progressivo
		builder.append recoModificato, other.recoModificato
		builder.append invio, other.invio
		builder.append relazione, other.relazione
		builder.append annoFiscale, other.annoFiscale
		builder.append mesiPoss, other.mesiPoss
		builder.append mesiEscEsenzi, other.mesiEscEsenzi
		builder.append mesiApplRidu, other.mesiApplRidu
		builder.append possesso, other.possesso
		builder.append esenzione, other.esenzione
		builder.append riduzione, other.riduzione
		builder.append indirizzo, other.indirizzo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["fiscale", "persona", "dataSit", "centroCons", "proviidd", "uffIidd", "centServ", "tdich", "progMod", "comune", "istatCom", "prov", "numOrdTerr", "partitaCat", "soggIci", "condDir", "areaFab", "reddNom", "perPoss", "fDichCong", "totReddDom", "qtRedDomIrpef", "qtRedDomIlor", "valoreIsi", "titolo", "totReddAgr", "qtRedAgrIrpef", "qtRedAgrIlor", "dedIlor", "progressivo", "recoModificato", "invio", "relazione", "annoFiscale", "mesiPoss", "mesiEscEsenzi", "mesiApplRidu", "possesso", "esenzione", "riduzione", "indirizzo"]
		version false
	}

	static constraints = {
		fiscale nullable: true, maxSize: 16
		persona nullable: true, maxSize: 1
		dataSit nullable: true, maxSize: 10
		centroCons nullable: true, maxSize: 3
		proviidd nullable: true, maxSize: 3
		uffIidd nullable: true, maxSize: 3
		centServ nullable: true, maxSize: 3
		tdich nullable: true, maxSize: 1
		progMod nullable: true, maxSize: 5
		comune nullable: true, maxSize: 32
		istatCom nullable: true, maxSize: 6
		prov nullable: true, maxSize: 2
		numOrdTerr nullable: true, maxSize: 4
		partitaCat nullable: true, maxSize: 8
		soggIci nullable: true, maxSize: 1
		condDir nullable: true, maxSize: 1
		areaFab nullable: true, maxSize: 1
		reddNom nullable: true, maxSize: 10
		perPoss nullable: true, maxSize: 5
		fDichCong nullable: true, maxSize: 16
		totReddDom nullable: true, maxSize: 9
		qtRedDomIrpef nullable: true, maxSize: 9
		qtRedDomIlor nullable: true, maxSize: 9
		valoreIsi nullable: true, maxSize: 9
		titolo nullable: true, maxSize: 1
		totReddAgr nullable: true, maxSize: 9
		qtRedAgrIrpef nullable: true, maxSize: 9
		qtRedAgrIlor nullable: true, maxSize: 9
		dedIlor nullable: true, maxSize: 9
		progressivo nullable: true, maxSize: 7
		recoModificato nullable: true, maxSize: 1
		invio nullable: true, maxSize: 3
		relazione nullable: true, maxSize: 8
		annoFiscale nullable: true, maxSize: 4
		mesiPoss nullable: true, maxSize: 2
		mesiEscEsenzi nullable: true, maxSize: 2
		mesiApplRidu nullable: true, maxSize: 2
		possesso nullable: true, maxSize: 1
		esenzione nullable: true, maxSize: 1
		riduzione nullable: true, maxSize: 1
		indirizzo nullable: true, maxSize: 36
	}
}
