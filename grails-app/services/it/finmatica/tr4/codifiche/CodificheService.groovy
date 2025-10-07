package it.finmatica.tr4.codifiche

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import it.finmatica.tr4.ContributiIfel
import it.finmatica.tr4.InstallazioneParametro
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.ContributiIfelDTO
import it.finmatica.tr4.dto.InstallazioneParametroDTO

@Transactional
class CodificheService {

    def salvaContributo(ContributiIfelDTO contributiIfelDTO, boolean inModifica) {
        ContributiIfel contributiIfel = inModifica ? contributiIfelDTO.getDomainObject() : new ContributiIfel()
        contributiIfel.anno = contributiIfelDTO.anno
        contributiIfel.aliquota = contributiIfelDTO?.aliquota
        contributiIfel.save(flush: true, failOnError: true, insert: !inModifica).toDTO()
    }

    def cancellaContributo(ContributiIfelDTO contributiIfelDTO) {
        ContributiIfel d = contributiIfelDTO.getDomainObject()
        d?.delete(failOnError: true)
    }

    @NotTransactional
    def getContributi() {
        ContributiIfel.list()?.toDTO()
    }

    def getContributo(def anno) {
        ContributiIfel.findByAnno(anno)?.toDTO()
    }

    @NotTransactional
    List<String> shortParamsList() {

        OggettiCache.INSTALLAZIONE_PARAMETRI.valore.collect {
            it.parametro.indexOf("_") > 0 ? it.parametro[0..it.parametro.indexOf("_") - 1] : ""
        }.unique().sort { it }
    }

    @NotTransactional
    List<InstallazioneParametroDTO> installazioneParametroList(String shortParam) {
        return InstallazioneParametro.createCriteria().list {
            if (shortParam != null) {
                ilike("parametro", "%${shortParam}%")
            }

            order("parametro")
        }.toList().toDTO()

    }

    void eliminaInstallazioneParametro(InstallazioneParametroDTO installazioneParametroDTO) {
        installazioneParametroDTO.toDomain().delete()
    }

    String aggiornaInstallazioneParametro(InstallazioneParametroDTO installazioneParametroDTO, Boolean modifica) {
        if (!modifica) {
            if (InstallazioneParametro.exists(installazioneParametroDTO.parametro)) {
                return "Esiste gia' un parametro con chiave ${installazioneParametroDTO.parametro}"
            }

        }

        installazioneParametroDTO.toDomain().save(flush: true, failOnError: true)

        return ""
    }

}
