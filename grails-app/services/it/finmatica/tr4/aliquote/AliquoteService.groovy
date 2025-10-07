package it.finmatica.tr4.aliquote

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.AliquotaDTO
import it.finmatica.tr4.dto.TipoAliquotaDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class AliquoteService {

    def dataSource
    def sessionFactory

    //metodo che raccoglie le varie aliquota_*_lk del tr4
    //Data tipoAliquota, anno, tipoTributo,codFiscale, categoriaCatasto,
    //oggettoPratica e eventuale oggetto di cui si è pertinenza
    //calcola aliquota (utilizzando anche f_aliquota_alca_rif_ap)
    //aliquotaAcconto, aliquotaErariale, aliquotaErarialeAcconto
    //e aliquotaStd e le restituisce tutte in una lista.
    //Per aliquota deve applicare f_aliquota_alca_rif_ap
    //Per aliquota acconto, se anno < 2012 deve prendere aliquota dell'anno precedente
    //e applicare f_aliquota_alca_rif_ap, se anno >= 2012
    // deve prendere nvl(aliquota_base, aliquota) dell'anno corrente
    // e applicare f_aliquota_alca_rif_ap
    @NotTransactional
    LinkedHashMap aliquoteLookUp(Short anno, TipoAliquotaDTO tipoAliquota
                                 , Integer fasciaSoggetto
                                 , java.sql.Date dataRif, String categoriaCatasto
                                 , OggettoPraticaDTO ogpr, OggettoPraticaDTO ogprRifAp
                                 , String codFiscale) {

        if (tipoAliquota == null) {
            return [aliquota: 0, aliquotaAcconto: 0, aliquotaErariale: 0, aliquotaStandard: 0]
        }

        BigDecimal aliquotaAcconto
        List<AliquotaDTO> listaAliquote = OggettiCache.ALIQUOTE.valore
        AliquotaDTO aliqAnno = listaAliquote.find { it.anno == anno && it.tipoAliquota.tipoAliquota == tipoAliquota.tipoAliquota && it.tipoAliquota.tipoTributo.tipoTributo == tipoAliquota.tipoTributo.tipoTributo }

        //se non trova niente deve dare errore
        if (!aliqAnno) {
            throw new Exception("Aliquota non presente in archivio!")
            /*Clients.showNotification("Aliquota non presente in archivio!"
             , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true);
             return [:]*/
        }
        //CALCOLA ALIQUOTA
        BigDecimal aliquota = aliquotaAlcaRifAp(anno, fasciaSoggetto, dataRif
                , aliqAnno.aliquota, categoriaCatasto
                , ogpr, ogprRifAp, tipoAliquota
                , codFiscale)
        if (aliquota == null) {
            throw new Exception("Problemi verifica Aliquote Categoria!")
        }
        //CALCOLA ALIQUOTA ACCONTO
        if (anno < 2012) {
            AliquotaDTO aliqAnnoPrec = listaAliquote.find { it.anno == (anno - 1) && it.tipoAliquota.tipoAliquota == tipoAliquota.tipoAliquota && it.tipoAliquota.tipoTributo.tipoTributo == tipoAliquota.tipoTributo.tipoTributo }

            if (aliqAnnoPrec == null) {
                throw new Exception("Aliquota non presente in archivio!")
            }
            aliquotaAcconto = aliquotaAlcaRifAp((Short) anno - 1, fasciaSoggetto, dataRif
                    , aliqAnnoPrec.aliquota, categoriaCatasto
                    , ogpr, ogprRifAp, tipoAliquota
                    , codFiscale)
            if (aliquotaAcconto == null) {
                throw new Exception("Problemi verifica Aliquote Categoria!")
            }
        } else {
            aliquotaAcconto = aliquotaAlcaRifAp(anno, fasciaSoggetto, dataRif
                    , aliqAnno.aliquotaBase ?: aliqAnno.aliquota
                    , categoriaCatasto
                    , ogpr, ogprRifAp, tipoAliquota
                    , codFiscale)
            if (aliquotaAcconto == null) {
                throw new Exception("Problemi verifica Aliquote Categoria!")
            }
        }
        return [aliquota: aliquota, aliquotaAcconto: aliquotaAcconto, aliquotaErariale: aliqAnno.aliquotaErariale, aliquotaStandard: aliqAnno.aliquotaStd]
    }

    //corrispondente di f_aliquota_alca
    @NotTransactional
    BigDecimal aliquotaAlca(Short anno, Integer fasciaSoggetto, java.sql.Date dataRif
                            , BigDecimal aliquota
                            , String categoriaCatasto, OggettoPraticaDTO ogpr
                            , TipoAliquotaDTO tipoAliquota, String codFiscale) {
        String caca = categoriaCatasto
        if (fasciaSoggetto == 3 || fasciaSoggetto == 4) {
            return aliquota
        }
        //se la categoria è C% si tratta di una pertinenza,
        //quindi prendo la categoria dell'immobile principale
        if (categoriaCatasto?.startsWith("C") && ogpr?.oggettoPraticaRifAp) {
            //Connection conn = DataSourceUtils.getConnection(dataSource)
            Sql sql = new Sql(dataSource)
            String r
            sql.call('{? = call f_dato_riog(?, ?, ?, ?)}'
                    , [Sql.VARCHAR,
                       codFiscale,
                       ogpr?.oggettoPratica,
                       anno,
                       'CA'
            ]) { r = it }
            //f_dato_riog non restituisce mai null, tranne nel caso in cui
            //l'oggetto pratica stesso non abbia categoria null
            caca = r ?: caca
        }
        AliquotaCategoria alca = AliquotaCategoria.createCriteria().get {
            eq("anno", anno)
            eq("tipoAliquota.tipoAliquota", tipoAliquota.tipoAliquota)
            eq("tipoAliquota.tipoTributo.tipoTributo", tipoAliquota.tipoTributo.tipoTributo)
            eq("categoriaCatasto.categoriaCatasto", caca)
        }
        return (alca?.aliquota) ?: aliquota

    }

    //corrispondente di f_aliquota_alca_rif_ap
    @NotTransactional
    BigDecimal aliquotaAlcaRifAp(Short anno, Integer fasciaSoggetto
                                 , java.sql.Date dataRif
                                 , BigDecimal aliquota
                                 , String categoriaCatasto, OggettoPraticaDTO ogpr
                                 , OggettoPraticaDTO ogprRifAp, TipoAliquotaDTO tipoAliquota
                                 , String codFiscale) {
        if (ogprRifAp == null) {
            return aliquotaAlca(anno, fasciaSoggetto, dataRif, aliquota
                    , categoriaCatasto, ogpr
                    , tipoAliquota, codFiscale)
        }
        //da qui è come aliquotaAlca, ma non considera la fascia del soggetto (chissa perchè)
        String caca = categoriaCatasto
        if (categoriaCatasto.startsWith("C")) {
            Sql sql = new Sql(dataSource)
            String r
            sql.call('{? = call f_dato_riog(?, ?, ?, ?)}'
                    , [Sql.VARCHAR, codFiscale, ogprRifAp?.id, anno, 'CA']) { r = it }
            //f_dato_riog non dovrebbe mai dare null
            caca = r ?: caca
        }
        AliquotaCategoria alca = AliquotaCategoria.createCriteria().get {
            eq("anno", anno)
            eq("tipoAliquota.tipoAliquota", tipoAliquota.tipoAliquota)
            eq("tipoAliquota.tipoTributo.tipoTributo", tipoAliquota.tipoTributo.tipoTributo)
            eq("categoriaCatasto.categoriaCatasto", caca)
        }

        return (alca?.aliquota) ?: aliquota
    }
								 
	@NotTransactional
	BigDecimal fAliquotaAlcaRifAp(Short anno, Integer tipoAliquota,String categoriaCatasto, BigDecimal aliquota, String tipoTributo, Long oggPrId, Long oggPrIdRifAp,
																															 String codFiscale, Boolean aliquotaBase = false) {
		Double	aliquotaOut
		Double	result = null
		 
		String	flagAliquotaBase = (aliquotaBase) ? 'S' : null
		
		Sql sql = new Sql(dataSource)
		sql.call('{? = call f_aliquota_alca_rif_ap(?, ?, ?, ?, ?, ?, ?, ?, ?)}',
				[
					Sql.DECIMAL,
			 ///	a_anno                   in number
					anno,
			 ///	a_tipo_aliquota          in number
					tipoAliquota,
			 ///	a_categoria_catasto      in varchar2
					categoriaCatasto,
			 ///	a_aliquota               in number
					aliquota,
			 ///	a_oggetto_pratica        in number
					oggPrId,
			 ///	a_cod_fiscale            in varchar2
					codFiscale,
			 ///	a_tipo_tributo           in varchar2
					tipoTributo,
			 ///	a_oggetto_pratica_rif_ap in number
					oggPrIdRifAp,
			 ///	a_flag_aliquota_base 	 in varchar2  default null
					flagAliquotaBase
			]
		) { result = it }
		
		aliquotaOut = (result != null) ? result : aliquota
		
		return aliquotaOut
	}

    def existsTipoAliquota(def filter) {
        return TipoAliquota.createCriteria().count {
            eq('tipoTributo.tipoTributo', filter.tipoTributo)
            eq('tipoAliquota', filter.tipoAliquota)
        } > 0
    }

	def salvaTipoAliquota(TipoTributoDTO tipoTributoDTO, TipoAliquotaDTO tipoAliquotaDTO, boolean inModifica) {
        //bisognerebbe testare il flag inModifica per evitare di avere delle update
        //al posto delle insert, ma qui la getDomainObject() in caso di nuovo con chiave
        //duplicata non trova l'istanza preesistente perchè il tipoTributo nel DTO
        //non è valorizzato in caso di nuovo (è in load nello zul).
        TipoAliquota tipoAliquota = inModifica ? tipoAliquotaDTO.getDomainObject() : new TipoAliquota()

        tipoAliquota.tipoTributo = TipoTributo.get(tipoTributoDTO?.tipoTributo)
        tipoAliquota.tipoAliquota = tipoAliquotaDTO.tipoAliquota
        tipoAliquota.descrizione = tipoAliquotaDTO.descrizione.toUpperCase()

        tipoAliquota.save(flush: true, failOnError: true, insert: !inModifica).refresh().toDTO()

        //(inModifica)?(tipoAliquota.save(flush:true, failOnError: true)):(tipoAliquota.save(flush:true, failOnError: true, insert:true))
    }

    def existsAliquota(AliquotaDTO aliquota) {
        return Aliquota.createCriteria().count {
            eq('tipoAliquota.tipoTributo.tipoTributo', aliquota.tipoAliquota.tipoTributo.tipoTributo)
            eq('tipoAliquota.tipoAliquota', aliquota.tipoAliquota.tipoAliquota)
            eq('anno', aliquota.anno)
        } > 0
    }

    def salvaAliquota(AliquotaDTO aliquotaDTO, boolean inModifica) {
        //bisogna testare il flag inModifica
        //perchè se avessero inserito in fase di NUOVO i valori chiave di un'aliquota
        //esistente la getDomainObject() la troverebbe e tutto cio' scatenerebbe
        //un update non voluta invece che una insert con segnalazione di errore per chiave duplicata.
        Aliquota aliquota = inModifica ? aliquotaDTO.getDomainObject() : new Aliquota()

        aliquota.anno = aliquotaDTO.anno
        aliquota.tipoAliquota = aliquotaDTO?.tipoAliquota?.getDomainObject()
        aliquota.aliquota = aliquotaDTO.aliquota
        aliquota.flagAbPrincipale = (aliquotaDTO.flagAbPrincipale) ? 'S' : null
        aliquota.flagPertinenze = (aliquotaDTO.flagPertinenze) ? 'S' : null
        aliquota.flagFabbricatiMerce = (aliquotaDTO.flagFabbricatiMerce) ? 'S' : null
        aliquota.aliquotaBase = aliquotaDTO.aliquotaBase
        aliquota.aliquotaErariale = aliquotaDTO.aliquotaErariale
        aliquota.aliquotaStd = aliquotaDTO.aliquotaStd
        aliquota.percSaldo = aliquotaDTO.percSaldo
        aliquota.percOccupante = aliquotaDTO.percOccupante
        aliquota.flagRiduzione = (aliquotaDTO.flagRiduzione) ? 'S' : null
        aliquota.scadenzaMiniImu = aliquotaDTO.scadenzaMiniImu
        aliquota.riduzioneImposta = aliquotaDTO.riduzioneImposta
        aliquota.note = aliquotaDTO.note

        aliquota.save(flush: true, failOnError: true, insert: !inModifica).refresh().toDTO()
        //(inModifica)?aliquota.save(flush:true, failOnError: true):(aliquota.save(flush:true, failOnError: true, insert:true))
    }

    def cancellaTipoAliquota(TipoAliquotaDTO tipoAliquotaDTO) {
        TipoAliquota ta = tipoAliquotaDTO.getDomainObject()
        ta?.delete(failOnError: true)
    }

    def cancellaAliquota(AliquotaDTO aliquotaDTO) {
        Aliquota a = aliquotaDTO.getDomainObject()
        a?.delete(failOnError: true)
    }

    int fCountAlca(short anno, Integer tipoAliquota, String tipoTributo) {

        int result
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_count_alca(?, ?, ?)}'
                , [Sql.INTEGER
                   , anno
                   , tipoAliquota
                   , tipoTributo]) { result = it }
        sql.close()
        return result
    }

    def getCategorieCatasto() {
        return CategoriaCatasto.createCriteria().list {
            eq("flagReale", "S")
            order("categoriaCatasto", "asc")
        }
    }

    def existsCategoriaCatasto(def tipoTributo, def anno, def tipoAliquota, def categoriaCatasto) {

        def parametri = [:]

        parametri << ['p_anno': anno]
        parametri << ['p_tipo_aliquota': tipoAliquota]
        parametri << ['p_titr': tipoTributo]
        parametri << ['p_cat_catasto': categoriaCatasto]

        def query = """
                            select alca.tipo_aliquota,
                                   alca.anno,
                                   alca.categoria_catasto,
                                   alca.aliquota,
                                   alca.aliquota_base,
                                   alca.note,
                                   alca.tipo_tributo,
                                   caca.descrizione
                              from aliquote_categoria alca,
                                   categorie_catasto caca
                             where alca.anno = :p_anno
                               and alca.tipo_aliquota = :p_tipo_aliquota
                               and alca.tipo_tributo = :p_titr
                               and caca.categoria_catasto = alca.categoria_catasto
                               and alca.categoria_catasto = :p_cat_catasto
                          """

        def lista = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return lista.size() > 0

    }

    def getListaAliquoteCategoria(def tipoTributo, def anno, def tipoAliquota) {

        return AliquotaCategoria.createCriteria().list {
            eq("tipoAliquota.tipoTributo.tipoTributo", tipoTributo)
            eq("anno", anno)
            eq("tipoAliquota.tipoAliquota", tipoAliquota)
        }
    }

    def salvaAliquotaCategoria(def aliquotaCategoria) {
        aliquotaCategoria.save(failOnError: true, flush: true)
    }

    def eliminaAliquotaCategoria(def aliquotaCategoria) {
        aliquotaCategoria.delete(failOnError: true, flush: true)
    }

    def getAliquotaCategoria(def anno, def tipoAliquota, def categoriaCatasto, def tipoTributo){
        return AliquotaCategoria.createCriteria().get {
            eq('anno', anno)
            eq('tipoAliquota.tipoAliquota', tipoAliquota)
            eq('categoriaCatasto.categoriaCatasto', categoriaCatasto)
            eq('tipoAliquota.tipoTributo.tipoTributo', tipoTributo)
        }
    }
}
