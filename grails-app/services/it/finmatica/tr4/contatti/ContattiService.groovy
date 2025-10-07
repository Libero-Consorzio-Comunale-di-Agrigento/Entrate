package it.finmatica.tr4.contatti

import grails.transaction.Transactional
import it.finmatica.tr4.ContattoContribuente
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.TipoContatto
import it.finmatica.tr4.TipoRichiedente
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.ContattoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo

class ContattiService {

    def listaContatti(def tipiContatto, def anno, def codFiscale, def tipoTributo) {
        ContattoContribuente.createCriteria().list {
            'in'('tipoContatto.tipoContatto', tipiContatto)
            eq('anno', anno)
            eq('contribuente.codFiscale', codFiscale)
            eq('tipoTributo.tipoTributo', tipoTributo.tipoTributo)
        }
    }

    def creaContattoPerSoggetto(def idSoggetto, def anno, def tipoTributo, def tipoContatto, def tipoRichiedente) {

        Contribuente cont = Contribuente.createCriteria().get {
            eq('soggetto.id', idSoggetto)
        }

        creaContatto(cont, anno, tipoTributo, tipoContatto, tipoRichiedente)
    }

    def creaContatto(def contribuente, def anno, def tipoTributo, def tipoContatto, def tipoRichiedente) {

        ContattoContribuente cocoNew = new ContattoContribuente()
        cocoNew.data = new Date()
        cocoNew.contribuente = contribuente
        cocoNew.anno = anno
        cocoNew.tipoTributo = TipoTributo.get(tipoTributo.tipoTributo)
        cocoNew.tipoContatto = TipoContatto.findByTipoContatto(tipoContatto)
        cocoNew.tipoRichiedente = TipoRichiedente.findByTipoRichiedente(tipoRichiedente)
        cocoNew.save(flush: true, failOnError: true)
    }
}
