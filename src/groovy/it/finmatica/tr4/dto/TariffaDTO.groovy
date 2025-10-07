package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.Tariffa

class TariffaDTO implements DTO<Tariffa> {
	private static final long serialVersionUID = 1L

	Long id
	Short anno
	Short tipoTariffa
	String descrizione
	BigDecimal limite
	BigDecimal limitePrec
	BigDecimal percRiduzione
	BigDecimal tariffa
	BigDecimal tariffaPrec
	BigDecimal tariffaQuotaFissa
	BigDecimal tariffaSuperiore
	BigDecimal tariffaSuperiorePrec
	String flagTariffaBase
	BigDecimal riduzioneQuotaFissa
	BigDecimal riduzioneQuotaVariabile

	Boolean	flagNoDepag

	So4AmministrazioneDTO ente

	CategoriaDTO categoria

	// Campi CU, al momento derivati
	Integer tipologiaTariffa
	Integer tipologiaCalcolo
	Integer tipologiaSecondaria

	public static final Integer TAR_TIPOLOGIA_STANDARD = 0
	public static final Integer TAR_TIPOLOGIA_PERMANENTE = 1
	public static final Integer TAR_TIPOLOGIA_TEMPORANEA = 2
	public static final Integer TAR_TIPOLOGIA_ESENZIONE = 3

	public static final Integer TAR_TIPOLOGIA_TEMPORANEA_CONSISTENZA = 200
	public static final Integer TAR_TIPOLOGIA_TEMPORANEA_GIORNI = 201

	public static final Integer TAR_CALCOLO_LIMITE_CONSISTENZA = 0
	// Modalità compatibile : limite usato per quotare consistenza
	public static final Integer TAR_CALCOLO_LIMITE_GIORNI = 1
	// Modalità giornaliera : limite usato per quotare giornate

	public static final Integer TAR_SECONDARIA_NESSUNA = 0
	public static final Integer TAR_SECONDARIA_USOSUOLO = 1

	Tariffa getDomainObject() {
		return Tariffa.get(this.id)
	}

	Tariffa toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */
	// attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	// Estrae i flag di lavoro dalle colonne riutilizzate per il CU
	def estraiFlag() {

		def codiceTributo = categoria?.codiceTributo?.id ?: 0

		Integer tipo
		Integer calcolo
		Integer secondaria

		if ((anno >= 2021) && (codiceTributo >= 8600) && (codiceTributo <= 8699)) {

			secondaria = riduzioneQuotaFissa as Integer
			tipo = riduzioneQuotaVariabile as Integer

			switch (tipo) {
				default:
					calcolo = TAR_CALCOLO_LIMITE_CONSISTENZA
					break
				case TAR_TIPOLOGIA_TEMPORANEA_CONSISTENZA:
					tipo = TAR_TIPOLOGIA_TEMPORANEA
					calcolo = TAR_CALCOLO_LIMITE_CONSISTENZA
					break
				case TAR_TIPOLOGIA_TEMPORANEA_GIORNI:
					tipo = TAR_TIPOLOGIA_TEMPORANEA
					calcolo = TAR_CALCOLO_LIMITE_GIORNI
					break
			}
		} else {
			tipo = TAR_TIPOLOGIA_STANDARD
			secondaria = TAR_SECONDARIA_NESSUNA
			calcolo = TAR_CALCOLO_LIMITE_CONSISTENZA
		}

		tipologiaTariffa = tipo
		tipologiaSecondaria = secondaria

		tipologiaCalcolo = calcolo

		return
	}

	// Accorpa i flag di lavoro sulle colonne riutilizzate per il CU
	def accorpaFlag() {
		
		if(tipologiaTariffa != TAR_TIPOLOGIA_STANDARD) {
			
			if(tipologiaTariffa == TAR_TIPOLOGIA_TEMPORANEA) {
				if(tipologiaCalcolo == TAR_CALCOLO_LIMITE_GIORNI) {
					riduzioneQuotaVariabile = TAR_TIPOLOGIA_TEMPORANEA_GIORNI as BigDecimal
				}
				else {
					def limiteNow = limite ?: 0
					riduzioneQuotaVariabile = ((limiteNow != 0) ? TAR_TIPOLOGIA_TEMPORANEA_CONSISTENZA : TAR_TIPOLOGIA_TEMPORANEA) as BigDecimal
				}
			}
			else {
				riduzioneQuotaVariabile = tipologiaTariffa as BigDecimal
			}
		
			riduzioneQuotaFissa = tipologiaSecondaria as BigDecimal
		}
	}
}
