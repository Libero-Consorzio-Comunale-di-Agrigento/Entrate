package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.pratiche.StoOggettoPratica

public class StoOggettoPraticaDTO implements it.finmatica.dto.DTO<StoOggettoPratica>, Comparable<StoOggettoPraticaDTO> {

	private static final long serialVersionUID = 1L;
	
	OggettoPraticaRenditaDTO oggettoPraticaRendita
	Long id;
	BigDecimal aChilometro;
	AssenzaEstremiCatasto assenzaEstremiCatasto;
	CategoriaCatastoDTO categoriaCatasto;
	String classeCatasto;
	Short codComOcc;
	Short codProOcc;
	BigDecimal consistenza;
	BigDecimal consistenzaReale;
	BigDecimal coperta;
	Set<CostoStoricoDTO> costiStorici;
	BigDecimal daChilometro;
	Date dataAnagrafeTributaria;
	Date dataConcessione;
	Date lastUpdated;
	DestinazioneUso destinazioneUso;
	String estremiTitolo;
	Date fineConcessione;
	boolean		flagProvvisorio
	boolean		flagValoreRivalutato
	boolean		flagFirma
	boolean		flagUipPrincipale
	boolean		flagDomicilioFiscale
	boolean		flagContenzioso
	FonteDTO fonte;
	boolean immStorico;
	BigDecimal impostaBase;
	BigDecimal impostaDovuta;
	String indirizzoOcc;
	Date inizioConcessione;
	BigDecimal larghezza;
	String lato;
	BigDecimal locale;
	Short modello;
	NaturaOccupazione naturaOccupazione;
	String note;
	Integer numConcessione;
	String numOrdine;
	Short numeroFamiliari;
	StoOggettoDTO oggetto;
	StoOggettoPraticaDTO oggettoPraticaRif;
	StoOggettoPraticaDTO oggettoPraticaRifAp;
	StoOggettoPraticaDTO oggettoPraticaRifV;
	Set<PartizioneOggettoPraticaDTO> partizioniOggettoPratica;
	StoPraticaTributoDTO pratica;
	BigDecimal profondita;
	String qualita;
	Integer quantita;
	BigDecimal reddito;
	BigDecimal scoperta;
	TariffaDTO tariffa;
	TipoOccupazione tipoOccupazione;
	TipoOggettoDTO tipoOggetto;
	Short tipoQualita;
	String titolo;
	TitoloOccupazione titoloOccupazione;
	String	utente;
	BigDecimal valore;
	Short anno;
	CodiceTributoDTO	codiceTributo
	Short				tipoTariffa
	CategoriaDTO		categoria
	Short				tipoCategoria

	Set<StoOggettoContribuenteDTO> oggettiContribuente;

	public StoOggettoPratica getDomainObject () {
		return StoOggettoPratica.get(this.id)
	}
	public StoOggettoPratica toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	int compareTo(StoOggettoPraticaDTO obj) {
		obj.numOrdine <=> numOrdine?:obj.id <=> id
	}
}
