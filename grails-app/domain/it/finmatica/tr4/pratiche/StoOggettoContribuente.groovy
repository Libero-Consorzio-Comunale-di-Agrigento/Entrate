package it.finmatica.tr4.pratiche

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class StoOggettoContribuente implements Serializable {

    Contribuente contribuente
    StoOggettoPratica oggettoPratica
    Short anno
    String tipoRapporto
    Date inizioOccupazione
    Date fineOccupazione
    Date dataDecorrenza
    Date dataCessazione
    BigDecimal percPossesso
    BigDecimal percDetrazione
    Short mesiOccupato
    Short mesiOccupato1sem
    Short mesiPossesso
    Short mesiPossesso1sem
    Short mesiEsclusione
    Short mesiRiduzione
    Short mesiAliquotaRidotta
    BigDecimal detrazione
    boolean flagPossesso
    boolean flagEsclusione
    boolean flagRiduzione
    boolean flagAbPrincipale
    boolean flagAlRidotta
    Ad4Utente utente
    Date lastUpdated
    String note
    Long successione
    Integer progressivoSudv
    String tipoRapportoK
    StoOggettoPratica oggettoPraticaId
    Short daMesePossesso

    static mapping = {
        id composite: ["contribuente", "oggettoPratica"]
        version false
        oggettoPraticaId column: "oggetto_pratica", updateable: false, insertable: false
        mesiPossesso1sem column: "mesi_possesso_1sem"
        mesiOccupato1sem column: "mesi_occupato_1sem"
        tipoRapportoK column: "tipo_rapporto_k"
        contribuente column: "cod_fiscale"
        oggettoPratica column: "oggetto_pratica"
        utente column: "utente", ignoreNotFound: true

        flagPossesso type: SiNoType
        flagEsclusione type: SiNoType
        flagRiduzione type: SiNoType
        flagAbPrincipale type: SiNoType
        flagAlRidotta type: SiNoType

        inizioOccupazione sqlType: 'Date'
        fineOccupazione sqlType: 'Date'
        dataDecorrenza sqlType: 'Date'
        dataCessazione sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'

        table 'sto_oggetti_contribuente'
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append contribuente?.codFiscale
        builder.append oggettoPratica.id
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append contribuente?.codFiscale, other.contribuente.codFiscale
        builder.append oggettoPratica.id, other.oggettoPratica.id
        builder.isEquals()
    }

    /**
     * Controlla che non sia un quadro duplicato.
     * Se non ci sono contitolari, aliquoteOgco e detrazioniOgco si passa a verificare
     * l'uguaglianza fra i vari campi della dichiarazione.
     *
     * @param quadro
     * @return
     */
    boolean isQuadroDuplicato(StoOggettoContribuente quadro) {

        List<StoOggettoContribuente> contitolari = getContitolari()

        (contitolari.isEmpty()
                && aliquoteOgco.isEmpty()
                && detrazioniOgco.isEmpty()
                && contribuente.codFiscale == quadro.contribuente.codFiscale
                && anno == quadro.anno
                && detrazione == quadro.detrazione
                && flagAbPrincipale == quadro.flagAbPrincipale
                && flagAlRidotta == quadro.flagAlRidotta
                && flagEsclusione == quadro.flagEsclusione
                && flagPossesso == quadro.flagPossesso
                && flagRiduzione == quadro.flagRiduzione
                && mesiAliquotaRidotta == quadro.mesiAliquotaRidotta
                && mesiEsclusione == quadro.mesiEsclusione
                && mesiPossesso == quadro.mesiPossesso
                && mesiPossesso1sem == quadro.mesiPossesso1sem
                && mesiRiduzione == quadro.mesiRiduzione
                && percPossesso == quadro.percPossesso
                && oggettoPratica.valore == quadro.oggettoPratica.valore
                && oggettoPratica.categoriaCatasto?.categoriaCatasto == quadro.oggettoPratica.categoriaCatasto?.categoriaCatasto
                && oggettoPratica.tipoOggetto?.tipoOggetto == quadro.oggettoPratica.tipoOggetto?.tipoOggetto)
    }

    String toString() {
        contribuente?.codFiscale + " " + oggettoPratica.id
    }

    public List<StoOggettoContribuente> getContitolari() {
        StoOggettoContribuente.createCriteria().list {
            eq("oggettoPratica.id", oggettoPratica.id)
            eq("tipoRapporto", "C")

            order("contribuente.codFiscale", "asc")
        }
    }
}
