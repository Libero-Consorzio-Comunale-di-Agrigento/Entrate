package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.PartizioneOggetto

public class PartizioneOggettoDTO implements DTO<PartizioneOggetto>, Comparable<PartizioneOggettoDTO> {
    private static final long serialVersionUID = 1L;

    BigDecimal consistenza;
    String note;
    Integer numero;
    OggettoDTO oggetto;
    Long sequenza;
    TipoAreaDTO tipoArea;

    Set<ConsistenzaTributoDTO> consistenzeTributo

    public PartizioneOggetto getDomainObject() {
        return PartizioneOggetto.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('sequenza', this.sequenza)
        }
    }

    public PartizioneOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    public void addToConsistenzeTributo(ConsistenzaTributoDTO consistenzaTributo) {
        if (this.consistenzeTributo == null)
            this.consistenzeTributo = new HashSet<ConsistenzaTributoDTO>()
        this.consistenzeTributo.add(consistenzaTributo);
        consistenzaTributo.partizioneOggetto = this
    }

    public void removeFromConsistenzeTributo(ConsistenzaTributoDTO consistenzaTributo) {
        if (this.consistenzeTributo == null)
            this.consistenzeTributo = new HashSet<ConsistenzaTributoDTO>()
        this.consistenzeTributo.remove(consistenzaTributo);
        consistenzaTributo.partizioneOggetto = null
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    // proprietà per gestire negli oggetti l'apertura del master/detail
    boolean open = false


    int compareTo(PartizioneOggettoDTO obj) {
        oggetto?.id <=> obj?.oggetto?.id ?:
                sequenza <=> obj?.sequenza
    }
}
