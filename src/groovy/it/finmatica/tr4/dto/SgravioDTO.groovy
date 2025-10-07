package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Sgravio
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO

class SgravioDTO implements it.finmatica.dto.DTO<Sgravio> {
    private static final long serialVersionUID = 1L

    Short aMese
    BigDecimal addizionaleEca
    BigDecimal addizionalePro
    Short codConcessione
    Short daMese
    Date dataElenco
    BigDecimal fattura
    boolean flagAutomatico
    Short giorniSgravio
    BigDecimal importo
    BigDecimal iva
    BigDecimal maggiorazioneEca
    BigDecimal maggiorazioneTares
    Short mesiSgravio
    MotivoSgravioDTO motivoSgravio
    Integer numRuolo
    Short numeroElenco
    Short semestri
    Short sequenzaSgravio
    String tipoSgravio
    String note
    RuoloContribuenteDTO ruoloContribuente
    OggettoPraticaDTO oggettoPratica
    Short progrSgravio

    Sgravio getDomainObject() {
        return Sgravio.createCriteria().get {
            eq('ruoloContribuente.ruolo.id', this.ruoloContribuente.id)
            eq('ruoloContribuente.contribuente.codFiscale', this.ruoloContribuente.contribuente.codFiscale)
            eq('ruoloContribuente.sequenza', this.ruoloContribuente.sequenza)
            eq('sequenzaSgravio', this.sequenzaSgravio)
        }
    }

    Sgravio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
