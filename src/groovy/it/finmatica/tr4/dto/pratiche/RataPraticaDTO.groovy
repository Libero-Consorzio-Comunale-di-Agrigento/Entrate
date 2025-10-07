package it.finmatica.tr4.dto.pratiche

import java.math.BigDecimal;

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Versamento
import it.finmatica.tr4.pratiche.RataPratica

class RataPraticaDTO implements DTO<RataPratica> {
    def id
    Byte rata
    Date dataScadenza
    Integer anno
    String tributoCapitaleF24
    BigDecimal importoCapitale
    String tributoInteressiF24
    BigDecimal importoInteressi
    BigDecimal residuoCapitale
    BigDecimal residuoInteressi
    String note
    String utente
    Date dataVariazione
	
	Short giorniAggio
	Double aliquotaAggio
	BigDecimal aggio
	BigDecimal aggioRimodulato
	Short giorniDilazione
	Double aliquotaDilazione
	BigDecimal dilazione
	BigDecimal dilazioneRimodulata
	
	BigDecimal oneri
	BigDecimal importo
	BigDecimal importoArr

    BigDecimal quotaTassa
    BigDecimal quotaTefa


    Boolean flagSospFerie

    def pratica

    RataPratica getDomainObject() {
        return RataPratica.get(id)
    }

    RataPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /*------------------------------------------------------*/

    boolean pagata() {
        if (pratica) {
            return !Versamento.createCriteria().list {
                eq('pratica.id', pratica.id)
                eq('tipoTributo.tipoTributo', pratica.tipoTributo.tipoTributo)
                eq('rata', rata as short)

            }.empty
        }
        return false
    }

    def importoRata() {
        return (importoCapitale ?: 0) + (importoInteressi ?: 0) + ((aggioRimodulato ? aggioRimodulato : aggio) ?: 0) + 
																	((dilazioneRimodulata ? dilazioneRimodulata : dilazione) ?: 0) + (oneri ?: 0)
    }
}
