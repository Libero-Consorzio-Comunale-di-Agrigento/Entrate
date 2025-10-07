package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.OggettiCache

class TipoTributoDTO implements DTO<TipoTributo> {
    private static final long serialVersionUID = 1L

    String codEnte
    Integer contoCorrente
    String descrizione
    String descrizioneCc
    String flagCanone
    String flagLiqRiog
    String flagTariffa
    String indirizzoUfficio
    String testoBollettino
    String tipoTributo
    String ufficio
    String codUfficio
    String tipoUfficio

    Set<CodiceTributoDTO> codiciTributo
    Set<UtilizzoTributoDTO> utilizziTributo
    Set<ConsistenzaTributoDTO> consistenzeTributo
    Set<VersamentoDTO> versamenti
    Set<OggettoTributoDTO> oggettiTributo

    TipoTributo getDomainObject() {
        return TipoTributo.get(this.tipoTributo)
    }

    TipoTributo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    void addToCodiciTributo(CodiceTributoDTO codiceTributo) {
        if (this.codiciTributo == null)
            this.codiciTributo = new HashSet<CodiceTributoDTO>()
        this.codiciTributo.add(codiceTributo)
        codiceTributo.tipoTributo = this
    }

    void removeFromCodiciTributo(CodiceTributoDTO codiceTributo) {
        if (this.codiciTributo == null)
            this.codiciTributo = new HashSet<CodiceTributoDTO>()
        this.codiciTributo.remove(codiceTributo)
        codiceTributo.tipoTributo = null
    }

    void removeFromUtilizziTributo(UtilizzoTributoDTO utilizzoTributo) {
        if (this.utilizziTributo == null)
            this.utilizziTributo = new HashSet<UtilizzoTributoDTO>()
        this.utilizziTributo.remove(utilizzoTributo)
        utilizzoTributo.tipoTributo = null
    }

    void addToUtilizziTributo(UtilizzoTributoDTO utilizzoTributo) {
        if (this.utilizziTributo == null)
            this.utilizziTributo = new HashSet<UtilizzoTributoDTO>()
        this.utilizziTributo.add(utilizzoTributo)
        utilizzoTributo.tipoTributo = this
    }

    void addToConsistenzeTributo(ConsistenzaTributoDTO consistenzaTributo) {
        if (this.consistenzeTributo == null)
            this.consistenzeTributo = new HashSet<ConsistenzaTributoDTO>()
        this.consistenzeTributo.add(consistenzaTributo)
        consistenzaTributo.tipoTributo = this
    }

    void removeFromConsistenzeTributo(ConsistenzaTributoDTO consistenzaTributo) {
        if (this.consistenzeTributo == null)
            this.consistenzeTributo = new HashSet<ConsistenzaTributoDTO>()
        this.consistenzeTributo.remove(consistenzaTributo)
        consistenzaTributo.tipoTributo = null
    }

    void addToVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.add(versamento)
        versamento.tipoTributo = this
    }

    void removeFromVersamenti(VersamentoDTO versamento) {
        if (this.versamenti == null)
            this.versamenti = new HashSet<VersamentoDTO>()
        this.versamenti.remove(versamento)
        versamento.tipoTributo = null
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    String getTipoTributoAttuale(Short anno = null) {
        List<InstallazioneParametroDTO> inpa = OggettiCache.INSTALLAZIONE_PARAMETRI.valore
        InstallazioneParametroDTO riga = inpa.find { it.parametro == "DES_${tipoTributo}" }
        if (!riga) {
            return tipoTributo
        }
        def pAnno = anno ?: GregorianCalendar.getInstance().get(Calendar.YEAR)
        String inpaValore = riga.valore
        while (inpaValore.length() > 10) {
            Short annoDa = Short.valueOf(inpaValore.substring(inpaValore.indexOf("=") + 1, inpaValore.indexOf("=") + 5))
            Short annoA = Short.valueOf(inpaValore.substring(inpaValore.indexOf("-") + 1, inpaValore.indexOf("-") + 5))
            if (pAnno >= annoDa && pAnno <= annoA) {
                return inpaValore.substring(0, inpaValore.indexOf("="))
            }
            inpaValore = inpaValore.substring(inpaValore.indexOf("-") + 5).trim()
        }
        return tipoTributo
    }

    def getOrdine() {
        def tipiTributoOrdine =
                ['CUNI' : 4,
                 'ICI'  : 1,
                 'ICIAP': 8,
                 'ICP'  : 5,
                 'TARSU': 3,
                 'TASI' : 2,
                 'TOSAP': 6,
                 'TRASV': 7]

        return tipiTributoOrdine[tipoTributo]
    }

    def getVisibileInSportello() {
        def tipiTributoVisibili =
                ['CUNI' : true,
                 'ICI'  : true,
                 'ICIAP': false,
                 'ICP'  : true,
                 'TARSU': true,
                 'TASI' : true,
                 'TOSAP': true,
                 'TRASV': false]

        return tipiTributoVisibili[tipoTributo]
    }
}
