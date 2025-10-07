package it.finmatica.tr4.dto.supportoservizi

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.TipoAttoDTO
import it.finmatica.tr4.dto.TipoStatoDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.supportoservizi.SupportoServizi

class SupportoServiziDTO implements DTO<SupportoServizi> {

	private static final long serialVersionUID = 1L

	Long id

	TipoTributoDTO tipoTributo

	String tipologia
	String segnalazioneIniziale
	String segnalazioneUltima
	String cognomeNome
	String codFiscale
	Short anno

	Integer numOggetti
	Integer numFabbricati
	Integer numTerreni
	Integer numAree
	Double differenzaImposta
	String resStoricoGsdInizioAnno
	String resStoricoGsdFineAnno
	Short residenteDaAnno
	String tipoPersona
	Date dataNas
	String aireStoricoGsdInizioAnno
	String aireStoricoGsdFineAnno
	boolean flagDeceduto
	Date dataDecesso
	String contribuenteDaFare
	Double minPercPossesso
	Double maxPercPossesso
	boolean flagDiffFabbricatiCatasto
	boolean flagDiffTerreniCatasto
	Integer fabbricatiNonCatasto
	Integer terreniNonCatasto
	Integer catastoNonTr4Fabbricati
	Integer catastoNonTr4Terreni
	boolean flagLiqAcc
	String liquidazioneAds
	String iterAds
	boolean flagRavvedimento
	Double versato
	Double dovuto
	Double dovutoComunale
	Double dovutoErariale
	Double dovutoAcconto
	Double dovutoComunaleAcconto
	Double dovutoErarialeAcconto
	Double diffTotContr
	Integer denunceImu
	String codiceAttivitaCont
	String residenteOggi
	Integer abPrincipali
	Integer pertinenze
	Integer altriFabbricati
	Integer fabbricatiD
	Integer terreni
	Integer terreniRidotti
	Integer aree
	Integer abitativo
	Integer commercialiArtigianali
	Integer rurali
	String cognome
	String nome
	String cognomeNomeRic
	String cognomeRic
	String nomeRic

	String utenteAssegnato
	String utenteOperativo

	String numero
	Date data
	TipoStatoDTO stato
	TipoAttoDTO tipoAtto
	Date dataNotifica
	
	String liq2Utente
	String liq2Numero
	Date liq2Data
	TipoStatoDTO liq2Stato
	TipoAttoDTO liq2TipoAtto
	Date liq2DataNotifica
	
	String note

	Ad4UtenteDTO utente
	Date dataVariazione

	SupportoServizi getDomainObject() {
		return SupportoServizi.get(this.id)
	}

	SupportoServizi toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
