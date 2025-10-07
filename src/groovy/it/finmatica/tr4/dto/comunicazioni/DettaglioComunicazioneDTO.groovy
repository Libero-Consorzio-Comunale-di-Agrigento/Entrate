package it.finmatica.tr4.dto.comunicazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.comunicazioni.DettaglioComunicazione
import it.finmatica.tr4.dto.TipoTributoDTO
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DettaglioComunicazioneDTO implements DTO<DettaglioComunicazione> {
    private static final long serialVersionUID = 1L;

    TipoTributoDTO tipoTributo
    String tipoComunicazione
    Short sequenza
    String descrizione
    String tipoComunicazionePnd
    def tipoComunicazionePndObj
    String tag
    TipiCanaleDTO tipoCanale

    def flagFirma
    def flagFirmareDescr
    def flagProtocollo
    def flagProtocolloDescr
    def flagPec

    DettaglioComunicazione getDomainObject() {
        return DettaglioComunicazione.createCriteria().get {
            eq('tipoTributo', this.tipoTributo.toDomain())
            eq('tipoComunicazione', this.tipoComunicazione)
            eq('sequenza', this.sequenza)
        }
    }

    DettaglioComunicazione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as DettaglioComunicazione
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo
        builder.append tipoComunicazione
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo, other.tipoTributo
        builder.append tipoComunicazione, other.tipoComunicazione
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

}
