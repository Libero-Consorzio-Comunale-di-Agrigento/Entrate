package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.PartizioneOggettoPratica
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO

public class PartizioneOggettoPraticaDTO implements DTO<PartizioneOggettoPratica> {
    private static final long serialVersionUID = 1L

    def uuid = UUID.randomUUID().toString().replace('-', '')

    Long id
    BigDecimal consistenza
    BigDecimal consistenzaReale
    String flagEsenzione
    String note
    Byte numero
    OggettoPraticaDTO oggettoPratica
    Short sequenza
    TipoAreaDTO tipoArea

    PartizioneOggettoPratica getDomainObject() {
        return PartizioneOggettoPratica.createCriteria().get {
            eq('oggettoPratica.id', this.oggettoPratica.id)
            eq('sequenza', this.sequenza)
        }
    }

    PartizioneOggettoPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
