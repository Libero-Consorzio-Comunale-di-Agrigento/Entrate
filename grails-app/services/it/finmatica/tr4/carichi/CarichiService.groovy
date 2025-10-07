package it.finmatica.tr4.carichi

import grails.transaction.Transactional
import it.finmatica.tr4.CaricoTarsu
import it.finmatica.tr4.dto.CaricoTarsuDTO

@Transactional
class CarichiService {

    private final static String FLAG_ACTIVE = "S"

    Collection<CaricoTarsuDTO> getByCriteria(def criteria = [:], boolean byFilteringCriteria) {
        return byFilteringCriteria ? getByFilteringCriteria(criteria).toDTO() : getByCriteria_internal(criteria).toDTO()
    }

    boolean exist(def criteria = [:]) {
        return getByCriteria_internal(criteria).size() > 0
    }

    private static Collection<CaricoTarsu> getByCriteria_internal(def criteria = [:]) {

        return CaricoTarsu.createCriteria().list {
            if (criteria?.anno) eq("anno", criteria.anno as Short)
            order("anno", 'desc')
        }
    }

    private static Collection<CaricoTarsu> getByFilteringCriteria(def criteria = [:]) {

        return CaricoTarsu.createCriteria().list {
            if (criteria?.daAnno) gte("anno", criteria.daAnno as Short)
            if (criteria?.aAnno) lte("anno", criteria.aAnno as Short)

            if (criteria?.daAddizionaleEca) gte("addizionaleEca", criteria.daAddizionaleEca as BigDecimal)
            if (criteria?.aAddizionaleEca) lte("addizionaleEca", criteria.aAddizionaleEca as BigDecimal)

            if (criteria?.daMaggiorazioneEca) gte("maggiorazioneEca", criteria.daMaggiorazioneEca as BigDecimal)
            if (criteria?.aMaggiorazioneEca) lte("maggiorazioneEca", criteria.aMaggiorazioneEca as BigDecimal)

            if (criteria?.daAddizionalePro) gte("addizionalePro", criteria.daAddizionalePro as BigDecimal)
            if (criteria?.aAddizionalePro) lte("addizionalePro", criteria.aAddizionalePro as BigDecimal)

            if (criteria?.daNonDovutoPro) gte("nonDovutoPro", criteria.daNonDovutoPro as BigDecimal)
            if (criteria?.aNonDovutoPro) lte("nonDovutoPro", criteria.aNonDovutoPro as BigDecimal)

            if (criteria?.daCommissioneCom) gte("commissioneCom", criteria.daCommissioneCom as BigDecimal)
            if (criteria?.aCommissioneCom) lte("commissioneCom", criteria.aCommissioneCom as BigDecimal)

            if (criteria?.daTariffaDomestica) gte("tariffaDomestica", criteria.daTariffaDomestica as BigDecimal)
            if (criteria?.aTariffaDomestica) lte("tariffaDomestica", criteria.aTariffaDomestica as BigDecimal)

            if (criteria?.daTariffaNonDomestica) gte("tariffaNonDomestica", criteria.daTariffaNonDomestica as BigDecimal)
            if (criteria?.aTariffaNonDomestica) lte("tariffaNonDomestica", criteria.aTariffaNonDomestica as BigDecimal)

            if (criteria?.daAliquota) gte("aliquota", criteria.daAliquota as BigDecimal)
            if (criteria?.aAliquota) lte("aliquota", criteria.aAliquota as BigDecimal)

            if (criteria?.daIvaFattura) gte("ivaFattura", criteria.daIvaFattura as BigDecimal)
            if (criteria?.aIvaFattura) lte("ivaFattura", criteria.aIvaFattura as BigDecimal)

            if (criteria?.daCompensoMinimo) gte("compensoMinimo", criteria.daCompensoMinimo as BigDecimal)
            if (criteria?.aCompensoMinimo) lte("compensoMinimo", criteria.aCompensoMinimo as BigDecimal)

            if (criteria?.daCompensoMassimo) gte("compensoMassimo", criteria.daCompensoMassimo as BigDecimal)
            if (criteria?.aCompensoMassimo) lte("compensoMassimo", criteria.aCompensoMassimo as BigDecimal)

            if (criteria?.daPercCompenso) gte("percCompenso", criteria.daPercCompenso as BigDecimal)
            if (criteria?.aPercCompenso) lte("percCompenso", criteria.aPercCompenso as BigDecimal)

            if (criteria?.daLimite) gte("limite", criteria.daLimite as BigDecimal)
            if (criteria?.aLimite) lte("limite", criteria.aLimite as BigDecimal)

            if (criteria?.flagLordo && criteria?.flagLordo != "T") {
                if (criteria?.flagLordo == "S") {
                    eq("flagLordo", 'S')
                } else {
                    isNull("flagLordo")
                }
            }

            if (criteria?.flagSanzioneAddP && criteria?.flagSanzioneAddP != "T") {
                if (criteria?.flagSanzioneAddP == "S") {
                    eq("flagSanzioneAddP", 'S')
                } else {
                    isNull("flagSanzioneAddP")
                }
            }

            if (criteria?.flagSanzioneAddT && criteria?.flagSanzioneAddT != "T") {
                if (criteria?.flagSanzioneAddT == "S") {
                    eq("flagSanzioneAddT", 'S')
                } else {
                    isNull("flagSanzioneAddT")
                }
            }
            if (criteria?.flagInteressiAdd && criteria?.flagInteressiAdd != "T") {
                if (criteria?.flagInteressiAdd == "S") {
                    eq("flagInteressiAdd", 'S')
                } else {
                    isNull("flagInteressiAdd")
                }
            }

            if (criteria?.daMesiCalcolo) gte("mesiCalcolo", criteria.daMesiCalcolo as Short)
            if (criteria?.aMesiCalcolo) lte("mesiCalcolo", criteria.aMesiCalcolo as Short)

            if (criteria?.daMaggiorazioneTares) gte("maggiorazioneTares", criteria.daMaggiorazioneTares as BigDecimal)
            if (criteria?.aMaggiorazioneTares) lte("maggiorazioneTares", criteria.aMaggiorazioneTares as BigDecimal)

            if (criteria?.flagMaggAnno && criteria?.flagMaggAnno != "T") {
                if (criteria?.flagMaggAnno == "S") {
                    eq("flagMaggAnno", 'S')
                } else {
                    isNull("flagMaggAnno")
                }
            }

            if (criteria?.modalitaFamiliari) eq("modalitaFamiliari", criteria.modalitaFamiliari)

            if (criteria?.flagNoTardivo && criteria?.flagNoTardivo != "T") {
                if (criteria?.flagNoTardivo == "S") {
                    eq("flagNoTardivo", 'S')
                } else {
                    isNull("flagNoTardivo")
                }
            }

            if (criteria?.flagTariffeRuolo && criteria?.flagTariffeRuolo != "T") {
                if (criteria?.flagTariffeRuolo == "S") {
                    eq("flagTariffeRuolo", 'S')
                } else {
                    isNull("flagTariffeRuolo")
                }
            }

            if (criteria?.rataPerequative && criteria?.rataPerequative != "X") {
                eq("rataPerequative", criteria.rataPerequative)
            }

            if (criteria?.flagTariffaPuntuale && criteria?.flagTariffaPuntuale != "T") {
                if (criteria?.flagTariffaPuntuale == "S") {
                    eq("flagTariffaPuntuale", 'S')
                } else {
                    isNull("flagTariffaPuntuale")
                }
            }

            if (criteria?.daCostoUnitario) gte("costoUnitario", criteria.daCostoUnitario as BigDecimal)
            if (criteria?.aCostoUnitario) lte("costoUnitario", criteria.aCostoUnitario as BigDecimal)

            order("anno", 'desc')
        }
    }

    def salva(CaricoTarsuDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(CaricoTarsuDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

    def getListaMesiCalcolo() {
        return (MeseCalcolo.values() as List).sort { it.id }
    }

    enum MeseCalcolo {
        ZERO(0),
        UNO(1),
        DUE(2)

        Integer id

        MeseCalcolo(Integer id) {
            this.id = id
        }

        static MeseCalcolo findById(def id) {
            switch (id) {
                case 0:
                    return ZERO
                case 1:
                    return UNO
                case 2:
                    return DUE
            }
        }
    }

}
