package it.finmatica.tr4


import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.RapportoTributo

class Contribuente {

    String id
    String codFiscale
    Soggetto soggetto
    Integer codContribuente
    Byte codControllo
    String note
    String codAttivita

    SortedSet<PraticaTributo> pratiche
    SortedSet<Versamento> versamenti
    SortedSet<RapportoTributo> rapportiTributo

    static hasMany = [contattiContribuente    : ContattoContribuente
                      , documentiContribuente : DocumentoContribuente
                      , oggettiContribuente   : OggettoContribuente
                      , ruoliContribuente     : RuoloContribuente
                      , versamenti            : Versamento
                      , pratiche              : PraticaTributo
                      , rapportiTributo       : RapportoTributo
                      , contribuentiCcSoggetti: ContribuenteCcSoggetto]

    static mapping = {
        id name: "codFiscale", generator: "assigned"
        soggetto column: "ni"

        table 'contribuenti'

        version false
    }

    static constraints = {
        codFiscale maxSize: 16
        soggetto unique: true
        codContribuente nullable: true
        codControllo nullable: true
        note nullable: true, maxSize: 2000
        codAttivita nullable: true, maxSize: 5
    }

    def springSecurityService
    static transients = ['springSecurityService']
}
