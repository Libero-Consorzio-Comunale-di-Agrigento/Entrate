package it.finmatica.tr4.pratiche


import it.finmatica.tr4.AliquotaOgco
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.DetrazioneOgco
import it.finmatica.tr4.OggettoImposta
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettoContribuente implements Serializable {

    Contribuente contribuente
    OggettoPratica oggettoPratica
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
    boolean flagPuntoRaccolta
    String utente
    Date lastUpdated
    String note
    Long successione
    Integer progressivoSudv
    String tipoRapportoK
    OggettoPratica oggettoPraticaId
    Short daMesePossesso
    Date dataEvento


    static hasMany = [detrazioniOgco  : DetrazioneOgco
                      , aliquoteOgco  : AliquotaOgco
                      , oggettiImposta: OggettoImposta
                      , attributiOgco : AttributoOgco]

    static mapping = {
        id composite: ["contribuente", "oggettoPratica"]
        version false
        oggettoPraticaId column: "oggetto_pratica", updateable: false, insertable: false
        mesiPossesso1sem column: "mesi_possesso_1sem"
        mesiOccupato1sem column: "mesi_occupato_1sem"
        tipoRapportoK column: "tipo_rapporto_k"
        contribuente column: "cod_fiscale"
        oggettoPratica column: "oggetto_pratica"

        flagPossesso type: SiNoType
        flagEsclusione type: SiNoType
        flagRiduzione type: SiNoType
        flagAbPrincipale type: SiNoType
        flagAlRidotta type: SiNoType
        flagPuntoRaccolta type: SiNoType

        inizioOccupazione sqlType: 'Date'
        fineOccupazione sqlType: 'Date'
        dataDecorrenza sqlType: 'Date'
        dataCessazione sqlType: 'Date'
        dataEvento sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'

        table 'oggetti_contribuente'
        // in questo modo riesco a cancellare tutti i figli
    }

    static constraints = {
        contribuente maxSize: 16
        tipoRapporto nullable: true, maxSize: 1
        inizioOccupazione nullable: true
        fineOccupazione nullable: true
        lastUpdated nullable: true
        dataDecorrenza nullable: true
        dataCessazione nullable: true
        dataEvento nullable: true
        percPossesso nullable: true
        percDetrazione nullable: true
        mesiPossesso nullable: true
        mesiPossesso1sem nullable: true
        mesiOccupato nullable: true
        mesiOccupato1sem nullable: true
        mesiEsclusione nullable: true
        mesiRiduzione nullable: true
        mesiAliquotaRidotta nullable: true
        daMesePossesso nullable: true
        detrazione nullable: true
        flagPossesso nullable: true, maxSize: 1
        flagEsclusione nullable: true, maxSize: 1
        flagRiduzione nullable: true, maxSize: 1
        flagAbPrincipale nullable: true, maxSize: 1
        flagAlRidotta nullable: true, maxSize: 1
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        successione nullable: true
        progressivoSudv nullable: true
        tipoRapportoK nullable: true, maxSize: 1
        oggettoPraticaId nullable: true
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

    def springSecurityService
    static transients = ['springSecurityService', 'attributoOgco']

    def beforeValidate() {
        utente = springSecurityService.currentUser?.id
        detrazioniOgco*.beforeValidate()
    }

    def beforeInsert() {
        utente = utente ?: springSecurityService.currentUser?.id
        detrazioniOgco*.beforeInsert()
    }

    /**
     * Controlla che non sia un quadro duplicato.
     * Se non ci sono contitolari, aliquoteOgco e detrazioniOgco si passa a verificare
     * l'uguaglianza fra i vari campi della dichiarazione.
     *
     * @param quadro
     * @return
     */
    boolean isQuadroDuplicato(OggettoContribuente quadro) {

        List<OggettoContribuente> contitolari = getContitolari()

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

    public void setAttributoOgco(AttributoOgco attributoOgco) {
        if (attributoOgco)
            addToAttributiOgco(attributoOgco)
        else
            attributiOgco?.clear()
    }

    public AttributoOgco getAttributoOgco() {
        (attributiOgco && !attributiOgco.isEmpty()) ? attributiOgco[0] : null
    }

    public List<OggettoContribuente> getContitolari() {
        OggettoContribuente.createCriteria().list {
            eq("oggettoPratica.id", oggettoPratica.id)
            eq("tipoRapporto", "C")

            order("contribuente.codFiscale", "asc")
        }
    }
}
