package it.finmatica.tr4.imposte

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.AliquotaOgcoDTO
import it.finmatica.tr4.dto.DetrazioneDTO
import it.finmatica.tr4.dto.DetrazioneOgcoDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.codehaus.groovy.runtime.InvokerHelper
import org.hibernate.criterion.CriteriaSpecification
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class DetrazioniService {

    def dataSource
    def sessionFactory
    CommonService commonService


    @NotTransactional
    BigDecimal calcolaDetrazioneAcconto(def anno, def detrazione
                                        , def mesiPossesso, def mesiPossesso1Sem
                                        , TipoTributo tipoTributo) {
        Detrazione detr = Detrazione.findByAnnoAndTipoTributo(anno, tipoTributo)
        BigDecimal detrAnno = (detr?.detrazioneBase ?: 0) * (mesiPossesso ?: 0) / 12
        BigDecimal detrAnnoPrec = (detr?.detrazioneBase ?: 0) * (mesiPossesso1Sem ?: 0) / 12
        BigDecimal coeff = 0
        if (detrAnno > 0) {
            coeff = detrazione / detrAnno
        }
        if (anno > 2000 && anno < 2012) {
            detrAnnoPrec = (Detrazione.findByAnnoAndTipoTributo(anno - 1, tipoTributo)?.detrazioneBase ?: 0) * (mesiPossesso1Sem ?: 0) / 12
        }
        return detrAnnoPrec * coeff
    }

    @NotTransactional
    def getDetrazioni(def filtri) {
        def lista = Detrazione.createCriteria().list {
            eq("tipoTributo.tipoTributo", filtri.tipoTributo)
            if (filtri.daAnno) {
                ge('anno', filtri.daAnno as Short)
            }
            if (filtri.aAnno) {
                le('anno', filtri.aAnno as Short)
            }
            if (filtri.daDetrazione) {
                ge('detrazione', filtri.daDetrazione)
            }
            if (filtri.aDetrazione) {
                le('detrazione', filtri.aDetrazione)
            }
            if (filtri.daDetrazioneBase) {
                ge('detrazioneBase', filtri.daDetrazioneBase)
            }
            if (filtri.aDetrazioneBase) {
                le('detrazioneBase', filtri.aDetrazioneBase)
            }
            if (filtri.aDetrazioneFiglio) {
                le('detrazioneFiglio', filtri.aDetrazioneFiglio)
            }
            if (filtri.daDetrazioneFiglio) {
                ge('detrazioneFiglio', filtri.daDetrazioneFiglio)
            }
            if (filtri.aDetrazioneMaxFigli) {
                le('detrazioneMaxFigli', filtri.aDetrazioneMaxFigli)
            }
            if (filtri.daDetrazioneMaxFigli) {
                ge('detrazioneMaxFigli', filtri.daDetrazioneMaxFigli)
            }
            if (filtri.flagPertinenze != null) {
                if (filtri.flagPertinenze) {
                    eq('flagPertinenze', 'S')
                } else {
                    isNull('flagPertinenze')
                }
            }
        }.toDTO()
    }

    def existsDetrazione(TipoTributoDTO tipoTributo, DetrazioneDTO detrazione) {
        return Detrazione.createCriteria().count {
            eq('tipoTributo.tipoTributo', tipoTributo.tipoTributo)
            eq('anno', detrazione.anno)
        } > 0
    }

    def salvaDetrazione(TipoTributoDTO tipoTributoDTO, DetrazioneDTO detrazioneDTO, boolean modifica) {
        Detrazione detrazione = detrazioneDTO.getDomainObject() ?: new Detrazione()

        detrazione.tipoTributo = TipoTributo.get(tipoTributoDTO?.tipoTributo)
        detrazione.anno = detrazioneDTO.anno
        detrazione.detrazioneBase = detrazioneDTO.detrazioneBase
        detrazione.detrazione = detrazioneDTO.detrazione
        detrazione.aliquota = detrazioneDTO.aliquota
        detrazione.detrazioneImponibile = detrazioneDTO.detrazioneImponibile
        detrazione.flagPertinenze = (detrazioneDTO.flagPertinenze) ? 'S' : null
        detrazione.detrazioneFiglio = detrazioneDTO.detrazioneFiglio
        detrazione.detrazioneMaxFigli = detrazioneDTO.detrazioneMaxFigli

        (modifica) ? detrazione.save(failOnError: true) : detrazione.save(failOnError: true, insert: true)
    }

    def cancellaDetrazione(DetrazioneDTO detrazioneDTO) {
        Detrazione det = detrazioneDTO.getDomainObject()
        det?.delete(failOnError: true)
    }

    @NotTransactional
    def getListaDetrazioni(def filtri, def paging, def wholeList = false) {

        def parametri = [:]

        parametri << ["p_anno_da": filtri.annoDa ?: 1900]
        parametri << ["p_anno_a": filtri.annoA ?: 9999]
        parametri << ["p_mode_da": filtri.motivoDa.motivoDetrazione]
        parametri << ["p_mode_a": filtri.motivoA.motivoDetrazione]
        parametri << ["p_detr_da": filtri.detrazioneDa ?: 0]
        parametri << ["p_detr_a": filtri.detrazioneA ?: Integer.MAX_VALUE]
        parametri << ["p_titr": filtri.tipoTributo.tipoTributo]


        def query = """
                        SELECT sum(DETRAZIONI_OGCO.DETRAZIONE) over(Partition by DETRAZIONI_OGCO.ANNO, DETRAZIONI_OGCO.MOTIVO_DETRAZIONE) AS totale_detrazioni,
                               count(distinct DETRAZIONI_OGCO.COD_FISCALE) over(Partition by DETRAZIONI_OGCO.ANNO, DETRAZIONI_OGCO.MOTIVO_DETRAZIONE) AS totale_contribuenti,
                               DETRAZIONI_OGCO.ANNO,
                               DETRAZIONI_OGCO.DETRAZIONE,
                               DETRAZIONI_OGCO.DETRAZIONE_ACCONTO,
                               DETRAZIONI_OGCO.NOTE,
                               CONTRIBUENTI.COD_FISCALE,
                               OGGETTI.OGGETTO,
                               nvl(OGGETTI_PRATICA.TIPO_OGGETTO, OGGETTI.TIPO_OGGETTO) tipo_oggetto,
                               decode(OGGETTI.COD_VIA,
                                      null,
                                      OGGETTI.INDIRIZZO_LOCALITA,
                                      ARCHIVIO_VIE.DENOM_UFF) ||
                               decode(OGGETTI.NUM_CIV, null, null, ', ' || to_char(OGGETTI.NUM_CIV)) ||
                               decode(OGGETTI.SUFFISSO, null, null, '/' || OGGETTI.SUFFISSO) indirizzo,
                               DETRAZIONI_OGCO.MOTIVO_DETRAZIONE || ' - ' ||
                               MOTIVI_DETRAZIONE.DESCRIZIONE motivo_detr,
                               SOGGETTI.DATA_NAS,
                               decode(NVL(SOGGETTI.CAP, AD4_COMUNI.CAP),
                                      NULL,
                                      '',
                                      NVL(SOGGETTI.CAP, AD4_COMUNI.CAP) || ' ' ||
                                      AD4_COMUNI.DENOMINAZIONE) || ' ' ||
                               decode(AD4_PROVINCIE.SIGLA,
                                      NULL,
                                      '',
                                      '(' || AD4_PROVINCIE.SIGLA || ')') com_nas,
                               translate(SOGGETTI.COGNOME_NOME, '/', ' ') nominativo,
                               DETRAZIONI_OGCO.MOTIVO_DETRAZIONE,
                               CONTRIBUENTI.NI,
                               OGGETTI_PRATICA.OGGETTO_PRATICA,
                               OGGETTI_PRATICA.PRATICA,
                               DETRAZIONI_OGCO.TIPO_TRIBUTO,
                               sum(DETRAZIONI_OGCO.DETRAZIONE) over() tot_detrazione,
                               count(*) over() tot_num
                          FROM DETRAZIONI_OGCO,
                               CONTRIBUENTI,
                               SOGGETTI,
                               AD4_COMUNI,
                               AD4_PROVINCIE,
                               MOTIVI_DETRAZIONE,
                               OGGETTI,
                               ARCHIVIO_VIE,
                               OGGETTI_PRATICA,
                               pratiche_tributo
                         WHERE ad4_comuni.provincia_stato = ad4_provincie.provincia(+)
                           and soggetti.cod_com_nas = ad4_comuni.comune(+)
                           and soggetti.cod_pro_nas = ad4_comuni.provincia_stato(+)
                           and SOGGETTI.ni = CONTRIBUENTI.ni + 0
                           and DETRAZIONI_OGCO.COD_FISCALE || '' = CONTRIBUENTI.COD_FISCALE
                           and DETRAZIONI_OGCO.MOTIVO_DETRAZIONE =
                               MOTIVI_DETRAZIONE.MOTIVO_DETRAZIONE
                           and OGGETTI.OGGETTO = OGGETTI_PRATICA.OGGETTO
                           and OGGETTI_PRATICA.OGGETTO_PRATICA = DETRAZIONI_OGCO.OGGETTO_PRATICA
                           and oggetti_pratica.pratica = pratiche_tributo.pratica
                           and pratiche_tributo.tipo_pratica in ('A', 'D', 'L')
                           and archivio_vie.cod_via(+) = oggetti.cod_via
                           and DETRAZIONI_OGCO.ANNO between :p_anno_da and :p_anno_a
                           and DETRAZIONI_OGCO.MOTIVO_DETRAZIONE between :p_mode_da and :p_mode_a
                           and DETRAZIONI_OGCO.DETRAZIONE between :p_detr_da and :p_detr_a
                           and detrazioni_ogco.tipo_tributo = :p_titr
                           and MOTIVI_DETRAZIONE.tipo_tributo = :p_titr
                           and pratiche_tributo.tipo_tributo || '' = :p_titr
                         ORDER BY DETRAZIONI_OGCO.ANNO ASC,
                                  DETRAZIONI_OGCO.MOTIVO_DETRAZIONE ASC,
                                  translate(SOGGETTI.COGNOME_NOME, '/', ' '),
                                  CONTRIBUENTI.COD_FISCALE,
                                  decode(OGGETTI.COD_VIA,
                                         null,
                                         OGGETTI.INDIRIZZO_LOCALITA,
                                         ARCHIVIO_VIE.DENOM_UFF) ||
                                  decode(OGGETTI.NUM_CIV,
                                         null,
                                         null,
                                         ', ' || to_char(OGGETTI.NUM_CIV)) ||
                                  decode(OGGETTI.SUFFISSO, null, null, '/' || OGGETTI.SUFFISSO),
                                  OGGETTI_PRATICA.PRATICA
                    """


        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            if (!wholeList) {
                setFirstResult(paging.activePage * paging.pageSize)
                setMaxResults(paging.pageSize)
            }

            list()
        }

        result.each {

            it.groupHeader = ""

            if (it.anno != null) {
                it.groupHeader = "Anno: ${it.anno}"
            }
            if (it.motivoDetr != null) {
                it.groupHeader += " Motivo: ${it.motivoDetr}"
            }
            if (it.totaleDetrazioni != null) {
                it.groupHeader += " Totale: ${commonService.formattaValuta(it.totaleDetrazioni)}"
            }
            if (it.totaleContribuenti != null) {
                it.groupHeader += " Contribuenti: ${it.totaleContribuenti}"
            }
        }

        def totali = [
                "totNum"       : 0,
                "totDetrazione": 0
        ]

        if (result.size() > 0) {
            totali.totNum = result[0].totNum
            totali.totDetrazione = result[0].totDetrazione
        }

        return [totali: totali, records: result]
    }

    @NotTransactional
    def getTipiTributo() {
        return TipoTributo.list().toDTO()
    }

    @NotTransactional
    def getMotiviDetrazione(def tipoTributo) {

        def parametri = ["p_tipo_tributo": tipoTributo.tipoTributo]

        def query = """
                           select *
                           from motivi_detrazione
                           where tipo_tributo = :p_tipo_tributo
                           order by motivo_detrazione
                           """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {
            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }

        return result
    }

    @NotTransactional
    def getListaAliquote(def filtri, def paging, def campiOrdinamento, def wholeList = false) {

        def parametri = [:]

        parametri << ["p_anno_da": filtri.annoDa ?: 1900]
        parametri << ["p_anno_a": filtri.annoA ?: 9999]
        parametri << ["p_tial_da": filtri.tipoAliquotaDa?.tipoAliquota]
        parametri << ["p_tial_a": filtri.tipoAliquotaA?.tipoAliquota]
        parametri << ["p_titr": filtri.tipoTributo.tipoTributo]

        def orderBy = " order by "


        def size = campiOrdinamento.size()
        def campoNum = 1

        campiOrdinamento.each { k, v ->
            if (v.verso) {
                if (campoNum != size) {
                    orderBy += "${k} ${v.verso}, "
                } else {
                    orderBy += "${k} ${v.verso} "
                }
            }
            campoNum++
        }


        def query = """
                            SELECT count(*) over() "tot_num",
                                   ALIQUOTE_OGCO.DAL,
                                   ALIQUOTE_OGCO.AL,
                                   ALIQUOTE_OGCO.TIPO_ALIQUOTA || ' -  ' || TIPI_ALIQUOTA.DESCRIZIONE tipo_aliquota,
                                   ALIQUOTE_OGCO.NOTE,
                                   CONTRIBUENTI.COD_FISCALE,
                                   OGGETTI.OGGETTO,
                                   nvl(OGGETTI_PRATICA.TIPO_OGGETTO, OGGETTI.TIPO_OGGETTO) tipo_oggetto,
                                   decode(OGGETTI.COD_VIA,
                                          null,
                                          OGGETTI.INDIRIZZO_LOCALITA,
                                          ARCHIVIO_VIE.DENOM_UFF) ||
                                   decode(OGGETTI.NUM_CIV, null, null, ', ' || to_char(OGGETTI.NUM_CIV)) ||
                                   decode(OGGETTI.SUFFISSO, null, null, '/' || OGGETTI.SUFFISSO) indirizzo,
                                   translate(SOGGETTI.COGNOME_NOME, '/', ' ') nominativo,
                                   CONTRIBUENTI.NI,
                                   OGGETTI_PRATICA.OGGETTO_PRATICA,
                                   OGGETTI_PRATICA.PRATICA,
                                   ALIQUOTE_OGCO.TIPO_TRIBUTO
                              FROM ALIQUOTE_OGCO,
                                   CONTRIBUENTI,
                                   SOGGETTI,
                                   TIPI_ALIQUOTA,
                                   OGGETTI,
                                   ARCHIVIO_VIE,
                                   OGGETTI_PRATICA,
                                   pratiche_tributo
                             WHERE SOGGETTI.ni = CONTRIBUENTI.ni
                               and ALIQUOTE_OGCO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE
                               and OGGETTI.OGGETTO = OGGETTI_PRATICA.OGGETTO
                               and OGGETTI_PRATICA.OGGETTO_PRATICA = ALIQUOTE_OGCO.OGGETTO_PRATICA
                               and oggetti_pratica.pratica = pratiche_tributo.pratica
                               and pratiche_tributo.tipo_pratica in ('A', 'D', 'L')
                               and archivio_vie.cod_via(+) = oggetti.cod_via
                               and to_number(to_char(ALIQUOTE_OGCO.DAL, 'yyyy')) <= :p_anno_a
                               and to_number(to_char(ALIQUOTE_OGCO.AL, 'yyyy')) >= :p_anno_da
                               and ALIQUOTE_OGCO.TIPO_ALIQUOTA between :p_tial_da and :p_tial_a
                               and TIPI_ALIQUOTA.TIPO_ALIQUOTA = ALIQUOTE_OGCO.TIPO_ALIQUOTA
                               and TIPI_ALIQUOTA.tipo_tributo = :p_titr
                               and ALIQUOTE_OGCO.tipo_tributo = :p_titr
                               and pratiche_tributo.tipo_tributo || '' = :p_titr
                           """


        String sqlResult = """
					select *
					from (${query})
					${orderBy}  
		"""

        def result = sessionFactory.currentSession.createSQLQuery(sqlResult).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            if (!wholeList) {
                setFirstResult(paging.activePage * paging.pageSize)
                setMaxResults(paging.pageSize)
            }

            list()
        }

        return [totali: result.size() > 0 ? result[0].totNum : 0, records: result]
    }

    @NotTransactional
    def getContribuente(def codFiscale) {
        return Contribuente.findByCodFiscale(codFiscale)
    }

    @NotTransactional
    def getListaOggetti(def tipoTributo, def codFiscale, def anno) {


        def parametri = [:]

        parametri << ["p_titr": tipoTributo]
        parametri << ["p_cod_fis": codFiscale]
        parametri << ["p_anno": anno]

        def query = """
                            select ogge.oggetto,
                                   ogpr.oggetto_pratica,
                                   ogge.cod_via,
                                   ogge.num_civ,
                                   ogge.suffisso,
                                   ogge.interno,
                                   ogge.indirizzo_localita,
                                   arvi.denom_uff,
                                   ogge.sezione,
                                   ogge.foglio,
                                   ogge.numero,
                                   ogge.subalterno,
                                   ogge.zona,
                                   ogge.partita,
                                   ogge.protocollo_catasto,
                                   ogge.anno_catasto,
                                   ogpr.tipo_oggetto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CA') categoria_catasto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CL') classe_catasto,
                                   ogco.perc_possesso,
                                   ogco.mesi_possesso,
                                   ogco.mesi_possesso_1sem,
                                   ogco.mesi_esclusione,
                                   ogco.mesi_riduzione,
                                   ogco.flag_possesso,
                                   ogco.flag_esclusione,
                                   ogco.flag_riduzione,
                                   ogco.flag_ab_principale,
                                   decode(ogge.cod_via,
                                          null,
                                          indirizzo_localita,
                                          denom_uff || decode(num_civ, null, '', ', ' || num_civ) ||
                                          decode(suffisso, null, '', '/' || suffisso)) indirizzo,
                                   ogpr.flag_provvisorio,
                                   ogco.detrazione,
                                   prtr.anno,
                                   deog.oggetto_pratica det,
                                   alog.oggetto_pratica ali
                              from archivio_vie arvi,
                                   oggetti ogge,
                                   pratiche_tributo prtr,
                                   oggetti_pratica ogpr,
                                   oggetti_contribuente ogco,
                                   (select oggetto_pratica
                                      from detrazioni_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) deog,
                                   (select oggetto_pratica
                                      from aliquote_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) alog
                             where arvi.cod_via(+) = ogge.cod_via
                               and prtr.pratica = ogpr.pratica
                               and ogge.oggetto = ogpr.oggetto
                               and ogpr.oggetto_pratica = ogco.oggetto_pratica
                               and ogco.cod_fiscale = :p_cod_fis
                               and prtr.tipo_pratica in ('A', 'D', 'L')
                               and deog.oggetto_pratica(+) = ogpr.oggetto_pratica
                               and alog.oggetto_pratica(+) = ogpr.oggetto_pratica
                               and nvl(to_number(to_char(ogco.data_decorrenza, 'YYYY')),
                                       nvl(ogco.anno, 0)) <= :p_anno
                               and nvl(to_number(to_char(ogco.data_cessazione, 'YYYY')), 9999) >=
                                   decode(:p_anno, 9999, 0, :p_anno)
                               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3
                               and f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CA') like 'A%'
                               and ogpr.oggetto_pratica =
                                   f_max_ogpr_cont_ogge(ogge.oggetto,
                                                        :p_cod_fis,
                                                        'ICI',
                                                        decode(:p_anno, 9999, '%', prtr.tipo_pratica),
                                                        :p_anno,
                                                        '%')
                               and decode(prtr.tipo_tributo,
                                          'ICI',
                                          decode(flag_possesso,
                                                 'S',
                                                 flag_possesso,
                                                 decode(:p_anno, 9999, 'S', prtr.anno, 'S', null)),
                                          'S') = 'S'
                               and prtr.tipo_tributo = :p_titr
                            union
                            select ogge.oggetto,
                                   ogpr.oggetto_pratica,
                                   ogge.cod_via,
                                   ogge.num_civ,
                                   ogge.suffisso,
                                   ogge.interno,
                                   ogge.indirizzo_localita,
                                   arvi.denom_uff,
                                   ogge.sezione,
                                   ogge.foglio,
                                   ogge.numero,
                                   ogge.subalterno,
                                   ogge.zona,
                                   ogge.partita,
                                   ogge.protocollo_catasto,
                                   ogge.anno_catasto,
                                   ogpr.tipo_oggetto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CA') categoria_catasto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CL') classe_catasto,
                                   ogco.perc_possesso,
                                   ogco.mesi_possesso,
                                   ogco.mesi_possesso_1sem,
                                   ogco.mesi_esclusione,
                                   ogco.mesi_riduzione,
                                   ogco.flag_possesso,
                                   ogco.flag_esclusione,
                                   ogco.flag_riduzione,
                                   ogco.flag_ab_principale,
                                   decode(ogge.cod_via,
                                          null,
                                          indirizzo_localita,
                                          denom_uff || decode(num_civ, null, '', ', ' || num_civ) ||
                                          decode(suffisso, null, '', '/' || suffisso)) indirizzo,
                                   ogpr.flag_provvisorio,
                                   ogco.detrazione,
                                   prtr.anno,
                                   deog.oggetto_pratica det,
                                   alog.oggetto_pratica ali
                              from archivio_vie arvi,
                                   oggetti ogge,
                                   pratiche_tributo prtr,
                                   oggetti_pratica ogpr,
                                   oggetti_contribuente ogco,
                                   (select oggetto_pratica
                                      from detrazioni_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) deog,
                                   (select oggetto_pratica
                                      from aliquote_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) alog
                             where arvi.cod_via(+) = ogge.cod_via
                               and prtr.pratica = ogpr.pratica
                               and ogge.oggetto = ogpr.oggetto
                               and ogpr.oggetto_pratica = ogco.oggetto_pratica
                               and ogco.cod_fiscale = :p_cod_fis
                               and prtr.tipo_pratica in ('A', 'D', 'L')
                               and deog.oggetto_pratica = ogpr.oggetto_pratica
                               and alog.oggetto_pratica(+) = ogpr.oggetto_pratica
                               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3
                               and prtr.tipo_tributo = :p_titr
                            union
                            select ogge.oggetto,
                                   ogpr.oggetto_pratica,
                                   ogge.cod_via,
                                   ogge.num_civ,
                                   ogge.suffisso,
                                   ogge.interno,
                                   ogge.indirizzo_localita,
                                   arvi.denom_uff,
                                   ogge.sezione,
                                   ogge.foglio,
                                   ogge.numero,
                                   ogge.subalterno,
                                   ogge.zona,
                                   ogge.partita,
                                   ogge.protocollo_catasto,
                                   ogge.anno_catasto,
                                   ogpr.tipo_oggetto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CA') categoria_catasto,
                                   f_max_riog(ogpr.oggetto_pratica, prtr.anno, 'CL') classe_catasto,
                                   ogco.perc_possesso,
                                   ogco.mesi_possesso,
                                   ogco.mesi_possesso_1sem,
                                   ogco.mesi_esclusione,
                                   ogco.mesi_riduzione,
                                   ogco.flag_possesso,
                                   ogco.flag_esclusione,
                                   ogco.flag_riduzione,
                                   ogco.flag_ab_principale,
                                   decode(ogge.cod_via,
                                          null,
                                          indirizzo_localita,
                                          denom_uff || decode(num_civ, null, '', ', ' || num_civ) ||
                                          decode(suffisso, null, '', '/' || suffisso)) indirizzo,
                                   ogpr.flag_provvisorio,
                                   ogco.detrazione,
                                   prtr.anno,
                                   deog.oggetto_pratica det,
                                   alog.oggetto_pratica ali
                              from archivio_vie arvi,
                                   oggetti ogge,
                                   pratiche_tributo prtr,
                                   oggetti_pratica ogpr,
                                   oggetti_contribuente ogco,
                                   (select oggetto_pratica
                                      from detrazioni_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) deog,
                                   (select oggetto_pratica
                                      from aliquote_ogco
                                     where cod_fiscale = :p_cod_fis
                                       and tipo_tributo = :p_titr
                                     group by oggetto_pratica) alog
                             where arvi.cod_via(+) = ogge.cod_via
                               and prtr.pratica = ogpr.pratica
                               and ogge.oggetto = ogpr.oggetto
                               and ogpr.oggetto_pratica = ogco.oggetto_pratica
                               and ogco.cod_fiscale = :p_cod_fis
                               and prtr.tipo_pratica in ('A', 'D', 'L')
                               and deog.oggetto_pratica(+) = ogpr.oggetto_pratica
                               and alog.oggetto_pratica = ogpr.oggetto_pratica
                               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3
                               and prtr.tipo_tributo = :p_titr
                             order by 1 asc
                          """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE


            list()
        }

        return result
    }

    @NotTransactional
    def getAliquoteDettaglio(def tipoTributo, def codFiscale, def oggettoPratica) {

        def lista = AliquotaOgco.createCriteria().list {

            createAlias("oggettoContribuente", "ogco", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogco.contribuente", "cont", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogco.oggettoPratica", "ogpr", CriteriaSpecification.LEFT_JOIN)

            eq("oggettoContribuente.contribuente.codFiscale", codFiscale)
            eq("oggettoContribuente.oggettoPratica.id", oggettoPratica as Long)
            eq("tipoAliquota.tipoTributo.tipoTributo", tipoTributo)

            order("dal")

        }

        return lista
    }

    @NotTransactional
    def getDetrazioniDettaglio(def tipoTributo, def codFiscale, def oggettoPratica) {


        def lista = DetrazioneOgco.createCriteria().list {

            createAlias("oggettoContribuente", "ogco", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogco.contribuente", "cont", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogco.oggettoPratica", "ogpr", CriteriaSpecification.LEFT_JOIN)
            createAlias("motivoDetrazione", "motd", CriteriaSpecification.LEFT_JOIN)

            eq("oggettoContribuente.contribuente.codFiscale", codFiscale)
            eq("oggettoContribuente.oggettoPratica.id", oggettoPratica as Long)
            eq("tipoTributo.tipoTributo", tipoTributo)

            order("anno")

        }

        return lista
    }


    def salvaDettagli(def listaDTO, def listaEliminateDTO, def tabSelezionata) {

        listaDTO.each {
            // Se nuova entry o modificata
            if (it.nuovo || it.modificato) {

                // Valido solo per le detrazioni, al cambio di anno bisogna eliminare l'entity vecchia
                if (tabSelezionata == "detrazioni" && it.annoCambiato) {
                    def detPrecedente = costruisciDetrPrecedente(it)
                    detPrecedente.toDomain().delete(failOnError: true, flush: true)
                } else if (tabSelezionata == "aliquote" && it.dataDalCambiata) {
                    //Stessa cosa per le aliquote
                    def aliqPrecedente = costruisciAliqPrecedente(it)
                    aliqPrecedente.toDomain().delete(failOnError: true, flush: true)
                }

                it.toDomain().save(failOnError: true, flush: true)
            }
        }

        listaEliminateDTO.each {
            // Per evitare di dover cancellare nuove entry aggiunte e poi subito dopo eliminate (mai presenti sul db)
            if (!it.esistente && !it.nuovo) {
                it.toDomain().delete(failOnError: true, flush: true)
            }
        }

    }

    @NotTransactional
    def getOggettoContribuente(def codFiscale, def oggPratica) {

        return OggettoContribuente.createCriteria().get {
            eq("contribuente.codFiscale", codFiscale)
            eq("oggettoPratica.id", oggPratica as Long)
        }.toDTO()

    }

    @NotTransactional
    def getAnniDetrazione(def tipoTributo) {

        return Detrazione.createCriteria().list {
            projections { property("anno") }
            eq("tipoTributo.tipoTributo", tipoTributo)
            order("anno", "asc")
        }
    }

    def existsDetrazione(def codFiscale, def oggPratica, def anno, def tipoTributo) {
        def result = DetrazioneOgco.createCriteria().list {
            eq("anno", anno as short)
            eq("oggettoContribuente.oggettoPratica.id", oggPratica as Long)
            eq("oggettoContribuente.contribuente.codFiscale", codFiscale)
            eq("tipoTributo.tipoTributo", tipoTributo)
        }

        return result != null && result.size() != 0
    }

    private def costruisciDetrPrecedente(def detrazione) {

        def nuovaDetrazione = new DetrazioneOgcoDTO()
        InvokerHelper.setProperties(nuovaDetrazione, detrazione.properties)
        nuovaDetrazione.uuid = UUID.randomUUID().toString().replace('-', '')
        nuovaDetrazione.anno = nuovaDetrazione.annoPrecedente
        return nuovaDetrazione
    }

    private def costruisciAliqPrecedente(def aliquota) {

        def nuovaAliquota = new AliquotaOgcoDTO()
        InvokerHelper.setProperties(nuovaAliquota, aliquota.properties)
        nuovaAliquota.uuid = UUID.randomUUID().toString().replace('-', '')
        nuovaAliquota.dal = nuovaAliquota.dataDalPrecedente
        return nuovaAliquota
    }
}
