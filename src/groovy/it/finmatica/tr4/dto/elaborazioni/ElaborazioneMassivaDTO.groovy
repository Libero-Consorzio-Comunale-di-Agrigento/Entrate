package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioneMassiva
import it.finmatica.tr4.elaborazioni.TipoElaborazione

class ElaborazioneMassivaDTO implements DTO<ElaborazioneMassiva> {

    private static final long serialVersionUID = 1L;

    def id
    String nomeElaborazione
    Date dataElaborazione
    TipoTributoDTO tipoTributo
	String gruppoTributo
    String tipoPratica
    Long ruolo
    String utente
    Date dataVariazione
    String note
	Short anno
    TipoElaborazioneDTO tipoElaborazione

    Set<AttivitaElaborazioneDTO> attivita
    Set<DettaglioElaborazioneDTO> dettagli

    @Override
    ElaborazioneMassiva getDomainObject() {
        return ElaborazioneMassiva.get(id)
    }

    ElaborazioneMassiva toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    Map asMap() {
        this.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [ (it.name):this."$it.name" ]
        }
    }
}
