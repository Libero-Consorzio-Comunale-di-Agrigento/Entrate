package it.finmatica.tr4.comunicazioni

import groovy.sql.Sql
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.comunicazioni.DettaglioComunicazioneDTO
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.zk.ui.util.Clients
import transform.AliasToEntityCamelCaseMapResultTransformer

class ComunicazioniService {

    static final Long TIPO_NOTIFICA_APPIO = 1

    SmartPndService smartPndService
    def dataSource
    def sessionFactory
    CommonService commonService

    def recuperaTipoComunicazione(def idPratica, def tipologia) {

        def r = ''
        Sql sql = new Sql(dataSource)
        sql.call('{? = call tr4_to_gdm.get_tipo_comunicazione(?, ?)}'
                , [Sql.VARCHAR, idPratica, tipologia]) {
            r = it
        }
        return r
    }

    def generaParametriSmartPND(def codFiscale, def anno, def idDocumento, def tipoTributo, def tipoDocumento, def nomeFile = '') {
        def parametriCursor = commonService.refCursorToCollection("TR4_TO_GDM.GENERA_PARAMETRI_PND('${codFiscale}',${anno},${idDocumento},'${tipoTributo}','${tipoDocumento}','${nomeFile?.toString()}')")

        def parametri = parametriCursor.collectEntries {
            [(it.NOME): it.VALORE]
        }

        return parametri
    }

    def recuperaTitoloDocumento(def idDocumento, def tipologia, def tipoTributo) {
        return recuperaParametroComunicazione(idDocumento, tipologia, tipoTributo, 'descrizione')
    }

    def aggiornaTitoloDocumento(def idDocumento, def tipologia, def tipoTributo, def titoloDocumento) {
        def tipoComunicazione = recuperaTipoComunicazione(idDocumento, tipologia)

        def sql = """
                    update comunicazione_parametri copa 
                      set titolo_documento = :descrizione
                     where copa.tipo_tributo = :tipoTributo
                       and copa.tipo_comunicazione = :tipoComunicazione
                    """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        sqlQuery.setString("descrizione", titoloDocumento)
        sqlQuery.setString("tipoTributo", tipoTributo)
        sqlQuery.setString("tipoComunicazione", tipoComunicazione)
        sqlQuery.executeUpdate()

    }

    def getListaComunicazioneParametri(def filter) {
        return ComunicazioneParametri.createCriteria().listDistinct {
            eq("tipoTributo", filter.tipoTributo)
            if (filter.tipoComunicazione) {
                eq("tipoComunicazione", filter.tipoComunicazione)
            }

            if (filter.descrizione) {
                ilike("descrizione", filter.descrizione)
            }

            if (filter.flagFirma != 'T') {
                if (filter.flagFirma == 'S') {
                    eq("flagFirma", 'S')
                } else if (filter.flagFirma == 'N') {
                    isNull("flagFirma")
                }
            }

            if (filter.flagProtocollo != 'T') {
                if (filter.flagProtocollo == 'S') {
                    eq("flagProtocollo", 'S')
                } else if (filter.flagProtocollo == 'N') {
                    isNull("flagProtocollo")
                }
            }

            if (filter.flagPec != 'T') {
                if (filter.flagPec == 'S') {
                    eq("flagPec", 'S')
                } else if (filter.flagPec == 'N') {
                    isNull("flagPec")
                }
            }
        }.toDTO()
    }

    def getListaDettagliComunicazione(def filter) {
        def smartPndAbilitato = smartPndService.smartPNDAbilitato()

        return DettaglioComunicazione.createCriteria().list {
            eq('tipoTributo.tipoTributo', filter.tipoTributo)
            if (filter.tipoComunicazione) {
                eq('tipoComunicazione', filter.tipoComunicazione)
            }

            if (filter.tipiCanale) {

                and {
                    'in'('tipoCanale.id', filter.tipiCanale)

                    if (smartPndAbilitato) {
                        isNotNull('tipoComunicazionePnd')
                    } else {
                        isNotNull('tag')
                    }
                }
            }

            if (filter.invioDocumentale) {
                if (smartPndAbilitato) {
                    isNotNull('tipoComunicazionePnd')
                }
            }

            order('descrizione')

        }?.toDTO()
    }

    def getDettagliComunicazioneFallback(def filter = null) {

        def tipoTributoDefault = OggettiCache.TIPI_TRIBUTO.valore.find {
            it.tipoTributo == 'TRASV'
        }?.tipoTributo

        String tipoComunicazioneDefault = 'LGE'

        filter.tipoTributo = tipoTributoDefault
        filter.tipoComunicazione = tipoComunicazioneDefault

        def smartPndAbilitato = smartPndService.smartPNDAbilitato()
        def dettagliComunicazione = getListaDettagliComunicazione(filter)

        if (dettagliComunicazione.empty) {

            def message = ""
            if (smartPndAbilitato) {
                message = "Tipo comunicazione SmartPND per il dettaglio default (TRASV, LGE) non definito"
            } else {
                message = "Tag per il dettaglio default (TRASV, LGE) non definito"
            }

            if (message?.trim()) {
                Clients.showNotification(message,
                        Clients.NOTIFICATION_TYPE_WARNING, null, "top_center", 2000, true)
            }

            return null
        }

        return dettagliComunicazione
    }

    def getListaDettagliComunicazioneInfo(def filter) {
        def query = """
            select deco
            from DettaglioComunicazione deco
                left join fetch deco.tipoCanale tica
            where deco.tipoTributo.tipoTributo = :pTipoTributo
              and deco.tipoComunicazione = :pTipoComunicazione
        """
        def parameters = [
                'pTipoTributo'      : filter.tipoTributo,
                'pTipoComunicazione': filter.tipoComunicazione
        ]

        if (filter.descrizione) {
            query += "and lower(deco.descrizione) like lower(:pDescrizione)"
            parameters['pDescrizione'] = filter.descrizione
        }
        if (smartPndService.smartPNDAbilitato() && filter.tipoComunicazionePnd) {
            query += "and deco.tipoComunicazionePnd like :pTipoComunicazionePnd"
            parameters['pTipoComunicazionePnd'] = filter.tipoComunicazionePnd
        }
        if (!smartPndService.smartPNDAbilitato() && filter.tag) {
            query += "and lower(deco.tag) like lower(:pTag)"
            parameters['pTag'] = filter.tag
        }

        if (!smartPndService.smartPNDAbilitato() && filter.tagAppIo) {
            query += "and deco.tag = :pTag"
            parameters['pTag'] = filter.tag
        }

        if (filter.tipoCanale) {
            query += "and tica.id = :pTipoCanaleId"
            parameters['pTipoCanaleId'] = filter.tipoCanale.id
        }

        def result = DettaglioComunicazione.executeQuery(query, parameters).toDTO([])

        def filteredResult = []

        def allListaTipoComunicazione = []
        if (smartPndService.smartPNDAbilitato()) {
            allListaTipoComunicazione = smartPndService.listaTipologieComunicazione()
        }

        result.each {

            if (smartPndService.smartPNDAbilitato()) {

                it.tipoComunicazionePndObj = allListaTipoComunicazione.find { tipo ->
                    tipo.tipoComunicazione == it.tipoComunicazionePnd
                }
            }

            filteredResult << it
        }

        if (smartPndService.smartPNDAbilitato()) {
            if (filter.flagFirma && filter.flagFirma != 'T') {
                filteredResult = filteredResult.findAll { it.tipoComunicazionePndObj?.daFirmare == filter.flagFirma }
            }

            if (filter.flagProtocollo && filter.flagProtocollo != 'T') {
                filteredResult = filteredResult.findAll { it.tipoComunicazionePndObj?.daProtocollare == filter.flagProtocollo }
            }

            if (filter.flagPec && filter.flagPec != 'T') {
                filteredResult = filteredResult.findAll { (it.tipoComunicazionePndObj?.flagPec ? 'S' : 'N') == filter.flagPec }
            }

            if (filter.flagPec && filter.flagPnd != 'T') {
                filteredResult = filteredResult.findAll { (it.tipoComunicazionePndObj?.flagPnd ? 'S' : 'N') == filter.flagPnd }
            }

            if (!(filter.tagAppIo ?: '').empty) {
                filteredResult = filteredResult
                        .findAll { it.tipoComunicazionePndObj?.tagAppio?.toLowerCase()?.contains(filter.tagAppIo?.toLowerCase()) }
            }

            if (!(filter.tagPec ?: '').empty) {
                filteredResult = filteredResult
                        .findAll { it.tipoComunicazionePndObj?.tagMail?.toLowerCase()?.contains(filter.tagPec?.toLowerCase()) }
            }

            if (!(filter.tagPnd ?: '').empty) {
                filteredResult = filteredResult
                        .findAll { it.tipoComunicazionePndObj?.tagPnd?.toLowerCase()?.contains(filter.tagPnd?.toLowerCase()) }
            }

        }

        return filteredResult
    }

    def salvaDettaglioComunicazione(DettaglioComunicazioneDTO dettaglioComunicazione) {
        dettaglioComunicazione.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaDettaglioComunicazione(DettaglioComunicazioneDTO dettaglioComunicazioneDTO) {
        dettaglioComunicazioneDTO.toDomain().delete(failOnError: true, flush: true)
    }

    private def recuperaParametroComunicazione(def idDocumento, def tipologia, def tipoTributo, def parametro) {

        if (!(parametro in ['flagPec', 'descrizione'])) {
            throw new RuntimeException("Parametro non valido [$parametro]")
        }

        def tipoComunicazione = recuperaTipoComunicazione(idDocumento, tipologia)

        def valore = ""
        def sql = """
                    select titolo_documento as descrizione, flag_pec
                      from comunicazione_parametri copa
                     where copa.tipo_tributo = :tipoTributo
                       and copa.tipo_comunicazione = :tipoComunicazione
                    """
        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def lista = sqlQuery.with {
            setString('tipoTributo', tipoTributo)
            setString('tipoComunicazione', tipoComunicazione)

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        if (!lista.isEmpty()) {
            valore = lista[0][parametro]
        }

        return valore
    }

    def generaSequenza(def tipoTributo, def tipoComunicazione) {
        return (DettaglioComunicazione.findAllByTipoTributoAndTipoComunicazione(tipoTributo, tipoComunicazione).max {
            it.sequenza
        }?.sequenza ?: 0) + 1
    }
}
