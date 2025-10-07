package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.so4.dto.struttura.So4AmministrazioneDTO
import it.finmatica.tr4.CaricoTarsu

class CaricoTarsuDTO implements DTO<CaricoTarsu>, Cloneable {
    private static final long serialVersionUID = 1L

    BigDecimal addizionaleEca
    BigDecimal addizionalePro
    BigDecimal aliquota
    Short anno
    BigDecimal commissioneCom
    BigDecimal compensoMassimo
    BigDecimal compensoMinimo
    So4AmministrazioneDTO ente
    String flagInteressiAdd
    String flagLordo
    String flagMaggAnno
    String flagSanzioneAddP
    String flagSanzioneAddT
    BigDecimal ivaFattura
    BigDecimal limite
    BigDecimal maggiorazioneEca
    BigDecimal maggiorazioneTares
    Short mesiCalcolo
    Integer modalitaFamiliari
    BigDecimal nonDovutoPro
    BigDecimal percCompenso
    BigDecimal tariffaDomestica
    BigDecimal tariffaNonDomestica
    String flagNoTardivo
    String flagTariffeRuolo
    String rataPerequative
    String flagTariffaPuntuale
    BigDecimal costoUnitario

    /// Dati derivati non in Domain
    String desRataPerequative

    CaricoTarsu getDomainObject() {
        return CaricoTarsu.findByAnno(this.anno)
    }

    CaricoTarsu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as CaricoTarsu
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
    /**
     * non esegue il cloning dell'ente
     */
    @Override
    public CaricoTarsuDTO clone() {
        def clone = new CaricoTarsuDTO()

        clone.addizionaleEca = this.addizionaleEca ? new BigDecimal(this.addizionaleEca) : null
        clone.addizionalePro = this.addizionalePro ? new BigDecimal(this.addizionalePro) : null
        clone.aliquota = this.aliquota ? new BigDecimal(this.aliquota) : null
        clone.commissioneCom = this.commissioneCom ? new BigDecimal(this.commissioneCom) : null
        clone.compensoMinimo = this.compensoMinimo ? new BigDecimal(this.compensoMinimo) : null
        clone.compensoMassimo = this.compensoMassimo ? new BigDecimal(this.compensoMassimo) : null
        clone.ivaFattura = this.ivaFattura ? new BigDecimal(this.ivaFattura) : null
        clone.limite = this.limite ? new BigDecimal(this.limite) : null
        clone.maggiorazioneEca = this.maggiorazioneEca ? new BigDecimal(this.maggiorazioneEca) : null
        clone.maggiorazioneTares = this.maggiorazioneTares ? new BigDecimal(this.maggiorazioneTares) : null
        clone.nonDovutoPro = this.nonDovutoPro ? new BigDecimal(this.nonDovutoPro) : null
        clone.percCompenso = this.percCompenso ? new BigDecimal(this.percCompenso) : null
        clone.tariffaDomestica = this.tariffaDomestica ? new BigDecimal(this.tariffaDomestica) : null
        clone.tariffaNonDomestica = this.tariffaNonDomestica ? new BigDecimal(this.tariffaNonDomestica) : null
        clone.modalitaFamiliari = this.modalitaFamiliari ? new Integer(this.modalitaFamiliari) : null
        clone.mesiCalcolo = this.mesiCalcolo ? new Short(this.mesiCalcolo) : null
        clone.anno = new Short(this.anno) // Dato che è chiave non serve controllare

        clone.flagInteressiAdd = this.flagInteressiAdd ? new String(this.flagInteressiAdd) : null
        clone.flagLordo = this.flagLordo ? new String(this.flagLordo) : null
        clone.flagMaggAnno = this.flagMaggAnno ? new String(this.flagMaggAnno) : null
        clone.flagSanzioneAddP = this.flagSanzioneAddP ? new String(this.flagSanzioneAddP) : null
        clone.flagSanzioneAddT = this.flagSanzioneAddT ? new String(this.flagSanzioneAddT) : null
        clone.flagNoTardivo = this.flagNoTardivo ? new String(this.flagNoTardivo) : null
        clone.flagTariffeRuolo = this.flagTariffeRuolo ? new String(this.flagTariffeRuolo) : null
        clone.rataPerequative = this.rataPerequative ? new String(this.rataPerequative) : null
        clone.flagTariffaPuntuale = this.flagTariffaPuntuale ? new String(this.flagTariffaPuntuale) : null
        clone.costoUnitario = this.costoUnitario ? new BigDecimal(this.costoUnitario) : null

        return clone
    }
}
