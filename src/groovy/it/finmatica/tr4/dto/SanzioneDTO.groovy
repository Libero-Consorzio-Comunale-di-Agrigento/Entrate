package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Sanzione
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SanzioneDTO implements DTO<Sanzione> {
    private static final long serialVersionUID = 1L

    Long id
    Short codSanzione
    String descrizione
    String flagCalcoloInteressi
    String flagImposta
    String flagInteressi
    String flagPenaPecuniaria
    GruppiSanzioneDTO gruppoSanzione
    BigDecimal percentuale
    BigDecimal riduzione
    BigDecimal riduzione2
    BigDecimal sanzione
    BigDecimal sanzioneMinima
    TipoTributoDTO tipoTributo
    Short tributo
    String codTributoF24
    String flagMaggTares
    Short rata
    Short tipologiaRuolo
    String tipoCausale
    String tipoVersamento
    Short sequenza
    Date dataInizio
    Date dataFine
    String utente
    String note
    Date dataVariazione

    Sanzione getDomainObject() {
        return Sanzione.createCriteria().get {
            eq('tipoTributo.tipoTributo', this.tipoTributo.tipoTributo)
            eq('codSanzione', this.codSanzione)
            eq("sequenza", this.sequenza)
        }
    }

    Sanzione toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo?.tipoTributo, other.tipoTributo?.tipoTributo
        builder.append codSanzione, other.codSanzione
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        if (tipoTributo?.tipoTributo) builder.append(tipoTributo?.tipoTributo)
        if (codSanzione) builder.append(codSanzione)
        if (sequenza) builder.append(sequenza)
        builder.toHashCode()
    }

    def getDescrizioneEstesa() {

        if (codSanzione == null) {
            return ""
        }

        // A parità di descrizione estesa la componente combo restituisce il primo elemento della lista.
        // Si aggiungono un numero di spazi in base alla sequenza della sanzione per rendere univoca la descrizione
        return "$codSanzione - $descrizione${' ' * sequenza}"
    }

    def getTooltipDate() {
        if (codSanzione == null) {
            return ""
        }

        if (dataInizio) {
            return "${dataInizio?.format("dd/MM/yyyy")} - ${dataFine?.format("dd/MM/yyyy") != "31/12/9999" ? dataFine.format("dd/MM/yyyy") : ''}"
        } else {
            return ""
        }

    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


    boolean getIsRidotta() {
        return ((riduzione ?: 0) != 0) || ((riduzione2 ?: 0) != 0)
    }

    def getValidita() {
        return tipoCausale in ['S', 'I'] ? "" : "${dataInizio?.format('dd/MM/yyyy')} - ${dataFine?.format('dd/MM/yyyy') == '31/12/9999' ? '' : dataFine?.format('dd/MM/yyyy')}"
    }

}

