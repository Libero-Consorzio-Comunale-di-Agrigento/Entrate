package it.finmatica.tr4.versamenti

import grails.transaction.NotTransactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.dto.VersamentoDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.FetchMode
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Date
import java.text.DecimalFormat

class VersamentiService {

    static transactional = false

    def sessionFactory

    def dataSource

    ContribuentiService contribuentiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    CommonService commonService

    // Riporta un versamento
    def getVersamento(String codFiscale, Short anno, String tipoTributo, Short sequenza) {

        VersamentoDTO versamento

        List<VersamentoDTO> versamenti = Versamento.createCriteria().list() {
            fetchMode("tipoTributo", FetchMode.JOIN)
            eq("contribuente.codFiscale", codFiscale)
            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("anno", anno)
            eq("sequenza", sequenza)
        }?.toDTO([
                "contribuente",
                "contribuente.soggetto",
                "pratica"
        ])

        if (versamenti.size() > 0) {
            versamento = versamenti[0]
        } else {
            versamento = null
        }

        return versamento
    }

    /**
     * Lista versamenti
     *
     * @param tipoOrdinamento
     * @param parRicerca
     * @param tipoTributo
     * @param pageSize
     * @param activePage
     * @return
     */
    @NotTransactional
    def listaVersamentiImuTasi(def tipoOrdinamento, def parRicerca, String tipoTributo, int pageSize, int activePage, boolean wholeList) {

        def sortBySql = ""
        if (tipoOrdinamento) {
            if (tipoOrdinamento == CampiOrdinamento.ALFA) {
                sortBySql += "order by 16 asc, 17 asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.sequenza asc "
            } else if (tipoOrdinamento == CampiOrdinamento.CF) {
                sortBySql += "order by contribuenti.cod_fiscale asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc "
            } else if (tipoOrdinamento == CampiOrdinamento.ANNO) {
                sortBySql += "order by versamenti.anno asc, soggetti.cognome asc, soggetti.nome asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc  "
            } else if (tipoOrdinamento == CampiOrdinamento.DATA) {
                sortBySql += "order by versamenti.data_pagamento asc,soggetti.cognome asc, soggetti.nome asc, versamenti.anno asc, versamenti.tipo_versamento asc "
            } else if (tipoOrdinamento == CampiOrdinamento.TIPO) {
                sortBySql += "order by pratiche_tributo.tipo_pratica asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc  "
            }
        }

		String addedWhere = ""
		def filtri = [:]
		
		filtri << ['tipoTributo': tipoTributo]
		
		if(parRicerca.cognome) {
			filtri << ['cognome': parRicerca.cognome ]
			addedWhere += """and upper(soggetti.cognome_ric) like upper(:cognome)\n"""
		}
		if(parRicerca.nome) {
			filtri << ['nome': parRicerca.nome ]
			addedWhere += """and upper(soggetti.nome_ric) like upper(:nome)\n"""
		}
		if(parRicerca.cf) {
			filtri << ['codFiscale': parRicerca.cf ]
			addedWhere += """and (upper(soggetti.cod_fiscale) like upper(:codFiscale) or upper(soggetti.partita_iva) like upper(:codFiscale)) \n"""
		}
		if(parRicerca.ruolo) {
			filtri << ['ruolo': parRicerca.ruolo as Long ]
			addedWhere += """and versamenti.ruolo = :ruolo\n"""
		}

        def sql = """
                    select   versamenti.anno "anno",
                             versamenti.tipo_versamento "tipoVersamento",
                             versamenti.importo_versato "importoVersato",
                             versamenti.data_pagamento "dataPagamento" ,
                             versamenti.fabbricati "fabbricati",
                             versamenti.terreni_agricoli "terreniAgricoli",
                             versamenti.aree_fabbricabili "areeFabbricabili",
                             versamenti.ab_principale "abPrincipale",
                             versamenti.altri_fabbricati "altriFabbricati",
                             versamenti.detrazione "detrazione",
                             versamenti.fonte "fonte",
	                         versamenti.tipo_tributo "tipoTributo",
	                         versamenti.sequenza "sequenza",
                             pratiche_tributo.pratica "pratica",
                             pratiche_tributo.tipo_pratica "tipoPratica",
                             upper(translate (soggetti.cognome_nome, '/', ' ')) "contribuente",
                             versamenti.cod_fiscale "codFiscale",
                             upper (replace (soggetti.cognome, ' ', '')) "cognome",
                             upper (replace (soggetti.nome, ' ', '')) "nome",
                             contribuenti.ni "ni",
                             pratiche_tributo.tipo_evento "tipoEvento",
                             versamenti.documento_id "documentoId",
                             versamenti.data_reg "dataReg",
                             versamenti.altri_comune "altriComune",
                             versamenti.aree_comune "areeComune",
                             versamenti.terreni_comune "terreniComune",
                             versamenti.num_fabbricati_altri "numFabbricatiAltri",
                             versamenti.num_fabbricati_rurali "numFabbricatiRurali",
                             versamenti.altri_erariale "altriErariale",
                             versamenti.num_fabbricati_ab "numFabbricatiAb",
                             versamenti.aree_erariale "areeErariale",
                             versamenti.terreni_erariale "terreniErariale",
                             versamenti.rurali "rurali",
                             versamenti.rata "rata",
                             versamenti.num_fabbricati_terreni "numFabbricatiTerreni",
                             versamenti.num_fabbricati_aree "numFabbricatiAree",
                             'versamenti '|| f_descrizione_titr (:tipoTributo, to_number (to_char (sysdate, 'yyyy')))  "titolo",
                              versamenti.fabbricati_d "fabbricatiD",
                             versamenti.fabbricati_d_erariale "fabbricatiDErariale",
                             versamenti.fabbricati_d_comune "fabbricatiDComune",
                             versamenti.num_fabbricati_d "numFabbricatiD",
                             versamenti.rurali_erariale "ruraliErariale",
                             versamenti.rurali_comune "ruraliComune",
                             versamenti.fabbricati_merce "fabbricatiMerce",
                             versamenti.num_fabbricati_merce "numFabbricatiMerce",
                             f_descrizione_titr (:tipoTributo, versamenti.anno) "des_titr"
                        from versamenti,
                             pratiche_tributo,
                             contribuenti,
                             soggetti
                     where  (versamenti.pratica = pratiche_tributo.pratica(+))
                            and (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                            and (contribuenti.ni = soggetti.ni)
                            and versamenti.tipo_tributo = :tipoTributo
							${addedWhere}
		"""

        if (parRicerca.fonte && parRicerca.fonte?.codice != -1) {
            sql += """ and versamenti.fonte = ${parRicerca.fonte.codice}\n"""
        }

        if (parRicerca.tipoVersamento && parRicerca.tipoVersamento?.codice != "T") {
            sql += """ and versamenti.tipo_versamento = '${parRicerca.tipoVersamento.codice}'\n"""
        }

        if (parRicerca.tipoPratica && parRicerca.tipoPratica?.codice != "T") {
            if (parRicerca.tipoPratica.codice != 'O') {
                sql += """ and pratiche_tributo.tipo_pratica = '${parRicerca.tipoPratica.codice}'\n"""
            } else {
                sql += """ and versamenti.pratica is null\n"""
            }
        }

        if (parRicerca.progrDocVersamento && parRicerca.progrDocVersamento?.codice != -1) {
            sql += """ and nvl (versamenti.documento_id, 0) = ${parRicerca.progrDocVersamento.codice}\n"""
        }

        sql += """${(parRicerca.daAnno && parRicerca.aAnno) ? " and versamenti.anno between ${parRicerca.daAnno} and ${parRicerca.aAnno}\n" : ""}
                                ${(parRicerca.daAnno && parRicerca.aAnno == null) ? " and versamenti.anno >= ${parRicerca.daAnno}\n" : ""}
                                ${(parRicerca.daAnno == null && parRicerca.aAnno) ? " and versamenti.anno <= ${parRicerca.aAnno}\n" : ""} """

        if (!parRicerca.daDataPagamento) {
            sql += """ and trunc(nvl(versamenti.data_pagamento, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_pagamento) between trunc(to_date('${parRicerca.daDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        if (!parRicerca.daDataProvvedimento) {
            sql += """ and trunc(nvl(versamenti.data_provvedimento, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataProvvedimento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_provvedimento) between trunc(to_date('${parRicerca.daDataProvvedimento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataProvvedimento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        if (!parRicerca.daDataRegistrazione) {
            sql += """ and trunc(nvl(versamenti.data_reg, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_reg) between trunc(to_date('${parRicerca.daDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        sql += """
            ${(parRicerca.daImporto && parRicerca.aImporto) ? " and versamenti.importo_versato between to_number (translate (' ${parRicerca.daImporto}', ',', '.')) and to_number (translate (' ${parRicerca.aImporto}',',','.'))\n" : ""}
            ${(parRicerca.daImporto && parRicerca.aImporto == null) ? " and versamenti.importo_versato >= to_number(translate('${parRicerca.daImporto}',',','.'))\n" : ""}
            ${(parRicerca.daImporto == null && parRicerca.aImporto) ? " and versamenti.importo_versato <= to_number(translate('${parRicerca.aImporto}',',','.'))\n" : ""}
            ${parRicerca.statoSoggetto == "D" ? "and soggetti.stato = 50\n" : ""}
            ${parRicerca.statoSoggetto == "ND" ? "and nvl (soggetti.stato, 0) <> 50\n" : ""}
		"""
		
        def params = [:]
        params.max = pageSize ?: 10
        params.activePage = activePage ?: 0
        params.offset = activePage * pageSize

        // Numero totale di elementi
        def totale = eseguiQuery("""
                select count(*) as "totale" ,
                       sum("importoVersato") "totImpVersato",
                       sum("terreniAgricoli") "totTerreniAgricoli",
                       sum("areeFabbricabili") "totAreeFabbricabili",
                       sum("abPrincipale") "totAbPrincipale",
                       sum("altriFabbricati") "totAltriFabbricati",
                       sum("detrazione") "totDetrazione",
                       sum("terreniComune") "totTerreniComune",
                       sum("terreniErariale") "totTerreniErariale",
                       sum("areeComune") "totAreeComune",
                       sum("areeErariale") "totAreeErariale",
                       sum("rurali") "totRurali",
                       sum("ruraliComune") "totRuraliComune",
                       sum("ruraliErariale") "totRuraliErariale",
                       sum("altriComune") "totAltriComune",
                       sum("altriErariale") "totAltriErariale",
                       sum("fabbricatiD") "totFabbricatiD",
                       sum("fabbricatiDComune") "totFabbricatiDComune",
                       sum("fabbricatiDErariale") "totFabbricatiDErariale"
                       FROM ($sql)""", filtri, params, true)[0]

        def v1 = eseguiQuery("$sql $sortBySql", filtri, params, wholeList)

        def versamenti = eseguiQuery("$sql $sortBySql", filtri, params, wholeList).each { row ->
            row.pratica = row.pratica as Integer
            row.id = row.pratica
            row.importoVersato = row.importoVersato ? row.importoVersato : null
            row.dataPagamento = row.dataPagamento ? new Date(row.dataPagamento.time).format("dd/MM/yyyy") : null
            row.documentoId = row.documentoId as Integer
            row.fabbricati = row.fabbricati as Integer
            row.terreniAgricoli = row.terreniAgricoli ? row.terreniAgricoli : null
            row.areeFabbricabili = row.areeFabbricabili ? row.areeFabbricabili : null
            row.abPrincipale = row.abPrincipale ? row.abPrincipale : null
            row.altriFabbricati = row.altriFabbricati ? row.altriFabbricati : null
            row.detrazione = row.detrazione ? row.detrazione : null
            row.fonte = row.fonte ? Fonte.get(row.fonte)?.toDTO() : null
            row.terreniComune = row.terreniComune ? row.terreniComune : null
            row.terreniErariale = row.terreniErariale ? row.terreniErariale : null
            row.areeComune = row.areeComune ? row.areeComune : null
            row.areeErariale = row.areeErariale ? row.areeErariale : null
            row.rurali = row.rurali ? row.rurali : null
            row.ruraliComune = row.ruraliComune ? row.ruraliComune : null
            row.ruraliErariale = row.ruraliErariale ? row.ruraliErariale : null
            row.altriComune = row.altriComune ? row.altriComune : null
            row.altriErariale = row.altriErariale ? row.altriErariale : null
            row.fabbricatiD = row.fabbricatiD ? row.fabbricatiD : null
            row.fabbricatiDComune = row.fabbricatiDComune ? row.fabbricatiDComune : null
            row.fabbricatiDErariale = row.fabbricatiDErariale ? row.fabbricatiDErariale : null
            row.numFabbricatiAb = row.numFabbricatiAb as Integer
            row.numFabbricatiRurali = row.numFabbricatiRurali as Integer
            row.numFabbricatiAltri = row.numFabbricatiAltri as Integer
            row.numFabbricatiTerreni = row.numFabbricatiTerreni as Integer
            row.numFabbricatiAree = row.numFabbricatiAree as Integer
            row.numFabbricatiD = row.numFabbricatiD as Integer
            row.tipoTributo = row.tipoTributo as String
            row.sequenza = row.sequenza as Short
        }
		
        def totali = [
                "totale"                : totale.totale ?: 0,
                "totImpVersato"         : totale.totImpVersato ?: null,
                "totTerreniAgricoli"    : totale.totTerreniAgricoli ?: null,
                "totAreeFabbricabili"   : totale.totAreeFabbricabili ?: null,
                "totAbPrincipale"       : totale.totAbPrincipale ?: null,
                "totAltriFabbricati"    : totale.totAltriFabbricati ?: null,
                "totDetrazione"         : totale.totDetrazione ?: null,
                "totTerreniComune"      : totale.totTerreniComune ?: null,
                "totTerreniErariale"    : totale.totTerreniErariale ?: null,
                "totAreeComune"         : totale.totAreeComune ?: null,
                "totAreeErariale"       : totale.totAreeErariale ?: null,
                "totRurali"             : totale.totRurali ?: null,
                "totRuraliComune"       : totale.totRuraliComune ?: null,
                "totRuraliErariale"     : totale.totRuraliErariale ?: null,
                "totAltriComune"        : totale.totAltriComune ?: null,
                "totAltriErariale"      : totale.totAltriErariale ?: null,
                "totFabbricati"         : totale.totFabbricatiD ?: null,
                "totFabbricatiDComune"  : totale.totFabbricatiDComune ?: null,
                "totFabbricatiDErariale": totale.totFabbricatiDErariale ?: null
        ]

        return [
                result: versamenti,
                totali: totali
        ]
    }

    @NotTransactional
    def listaVersamentiTari(def tipoOrdinamento, def parRicerca, String tipoTributo, int pageSize, int activePage, boolean wholeList) {

        def sortBySql = ""
        if (tipoOrdinamento) {
            if (tipoOrdinamento == CampiOrdinamento.ALFA) {
                sortBySql += "order by cognome asc, nome asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.CF) {
                sortBySql += "order by contribuenti.cod_fiscale asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.ANNO) {
                sortBySql += "order by versamenti.anno asc, cognome asc, nome asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc"
            } else if (tipoOrdinamento == CampiOrdinamento.DATA) {
                sortBySql += "order by versamenti.data_pagamento asc,cognome asc, nome asc, versamenti.anno asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.TIPO) {
                sortBySql += "order by pratiche_tributo.tipo_pratica asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc  "
            }
        }
		
		String addedWhere = ""
		def filtri = [:]
		
		filtri << ['tipoTributo': tipoTributo]
		
		if(parRicerca.cognome) {
			filtri << ['cognome': parRicerca.cognome ]
			addedWhere += """and upper(soggetti.cognome_ric) like upper(:cognome)\n"""
		}
		if(parRicerca.nome) {
			filtri << ['nome': parRicerca.nome ]
			addedWhere += """and upper(soggetti.nome_ric) like upper(:nome)\n"""
		}
		if(parRicerca.cf) {
			filtri << ['codFiscale': parRicerca.cf ]
			addedWhere += """and (upper(soggetti.cod_fiscale) like upper(:codFiscale) or upper(soggetti.partita_iva) like upper(:codFiscale))\n"""
		}
		if(parRicerca.ruolo) {
			filtri << ['ruolo': parRicerca.ruolo as Long ]
			addedWhere += """and versamenti.ruolo = :ruolo\n"""
		}

        def sql = """
                  select versamenti.anno "anno",   
                         versamenti.tipo_versamento "tipoVersamento",   
                         versamenti.importo_versato "importoVersato",   
                         versamenti.data_pagamento "dataPagamento",   
                         versamenti.fonte "fonte",   
                         versamenti.tipo_tributo "tipoTributo",
                         versamenti.sequenza "sequenza",
                         pratiche_tributo.pratica "pratica",
                         pratiche_tributo.tipo_pratica "tipoPratica", 
                         pratiche_tributo.tipo_evento "tipoEvento", 
                         upper(translate(soggetti.cognome_nome, '/', ' ')) "contribuente",   
                         versamenti.cod_fiscale "codFiscale",   
                         versamenti.rata "rata",   
                         upper(replace(cognome,' ','')) "cognome",   
                         upper(replace(nome,' ','')) "nome",   
                         contribuenti.ni "ni",   
                         versamenti.spese_spedizione "speseSpedizione",   
                         versamenti.spese_mora "speseMora",
                         versamenti.documento_id "documentoId", 
                         versamenti.data_reg "dataReg",
                         decode(versamenti.pratica
                               ,null,f_importi_anno_tarsu(versamenti.cod_fiscale,versamenti.anno,versamenti.tipo_tributo,versamenti.sequenza,versamenti.ruolo,versamenti.rata,'IMPOSTA')
                                    ,f_importi_acc(versamenti.pratica,'N','LORDO')
                               )                   "importoDovuto" ,
                         decode(versamenti.pratica
                               ,null,f_importi_anno_tarsu(versamenti.cod_fiscale,versamenti.anno,versamenti.tipo_tributo,versamenti.sequenza,versamenti.ruolo,versamenti.rata,'NETTO')
                                    ,f_importi_acc(versamenti.pratica,'N','NETTO')
                               )                   "imposta" ,
                         decode(versamenti.pratica
                               ,null,f_importi_anno_tarsu(versamenti.cod_fiscale,versamenti.anno,versamenti.tipo_tributo,versamenti.sequenza,versamenti.ruolo,versamenti.rata,'ECA')
                                    ,f_importi_acc(versamenti.pratica,'N','ADD_ECA') + f_importi_acc(versamenti.pratica,'N','MAG_ECA')
                               )                    "addizionaleMaggiorazioneECA" ,
                         decode(versamenti.pratica
                               ,null,f_importi_anno_tarsu(versamenti.cod_fiscale,versamenti.anno,versamenti.tipo_tributo,versamenti.sequenza,versamenti.ruolo,versamenti.rata,'ADD_PRO')
                                    ,f_importi_acc(versamenti.pratica,'N','ADD_PRO')
                               )                    "addizionaleProvinciale",
                         decode(nvl(carichi_tarsu.maggiorazione_tares,0),0,to_number(null),
                                decode(versamenti.pratica
                                      ,null,f_importi_anno_tarsu(versamenti.cod_fiscale,versamenti.anno,versamenti.tipo_tributo,versamenti.sequenza,versamenti.ruolo,versamenti.rata,'MAG_TAR')
                                           ,f_importi_acc(versamenti.pratica,'N','MAGGIORAZIONE')
                                      )
                               )                   "magTar",
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'S','LORDO')
                               )                   "importoRidotto" ,
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'S','NETTO')
                               )                   "impostaRidotta" ,
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'N','INTERESSI')
                               )                    "interessi",
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'N','SANZIONI') 
                               )                   "sanzioni",
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'S','SANZIONI') 
                               )                   "sanzioniRidotte",
                         decode(versamenti.pratica
                               ,null
                               ,to_number(null)
                               ,f_importi_acc(versamenti.pratica,'S','SPESE') 
                               )                   "spese",
                         tipi_stato.descrizione "statoPratica",
						 versamenti.interessi "interessiVers",
						 versamenti.sanzioni_1 "sanzioniVers",
						 versamenti.addizionale_pro "addizionalePro",
						 versamenti.sanzioni_add_pro "sanzioniAddPro",
						 versamenti.interessi_add_pro "interessiAddPro",
                         'versamenti '|| f_descrizione_titr (:tipoTributo, to_number (to_char (sysdate, 'yyyy')))  "titolo",
                         f_descrizione_titr (:tipoTributo, versamenti.anno) "desTitr",
                         decode(nvl(carichi_tarsu.maggiorazione_tares,0),0,to_number(null),versamenti.maggiorazione_tares) "maggiorazioneTares",
                         decode(versamenti.id_compensazione,null,'','S') "compensazione",
						 versamenti.descrizione "descrizione",
						 versamenti.provvedimento "provvedimento",
						 versamenti.ufficio_pt "ufficioPt",
						 versamenti.causale "causale",
						 versamenti.note "note",
						 versamenti.fattura "fattura", 
						 versamenti.utente "utente",
						 versamenti.data_variazione "dataVariazione",
                         versamenti.ruolo "ruolo"
                  from   versamenti,   
                         carichi_tarsu,
                         pratiche_tributo,   
                         contribuenti,   
                         soggetti,
                         tipi_stato
                  where  versamenti.pratica = pratiche_tributo.pratica (+) and  
                         versamenti.cod_fiscale = contribuenti.cod_fiscale and
                         contribuenti.ni = soggetti.ni  and  
                         pratiche_tributo.stato_accertamento = tipi_stato.tipo_stato (+) and
                         versamenti.anno = carichi_tarsu.anno and
                         versamenti.tipo_tributo = :tipoTributo
						 ${addedWhere}
		"""

        if (parRicerca.fonte && parRicerca.fonte?.codice != -1) {
            sql += """ and versamenti.fonte = ${parRicerca.fonte.codice}\n"""
        }

        if (parRicerca.statoPratica && parRicerca.statoPratica?.codice != "T") {
            sql += """ and pratiche_tributo.stato_accertamento = '${parRicerca.statoPratica.codice}'\n"""
        }

        if (parRicerca.tipoPratica && parRicerca.tipoPratica?.codice != "T") {
            if (parRicerca.tipoPratica.codice != 'O') {
                sql += """ and pratiche_tributo.tipo_pratica = '${parRicerca.tipoPratica.codice}'\n"""
            } else {
                sql += """ and versamenti.pratica is null\n"""
            }
        }

        if (parRicerca.progrDocVersamento && parRicerca.progrDocVersamento?.codice != -1) {
            sql += """ and nvl (versamenti.documento_id, 0) = ${parRicerca.progrDocVersamento.codice}\n"""
        }

        sql += """
				${(parRicerca.daAnno && parRicerca.aAnno) ? " and versamenti.anno between ${parRicerca.daAnno} and ${parRicerca.aAnno}\n" : ""}
                ${(parRicerca.daAnno && parRicerca.aAnno == null) ? " and versamenti.anno >= ${parRicerca.daAnno}\n" : ""}
                ${(parRicerca.daAnno == null && parRicerca.aAnno) ? " and versamenti.anno <= ${parRicerca.aAnno}\n" : ""}
		"""

        if (!parRicerca.daDataPagamento) {
            sql += """ and trunc(nvl(versamenti.data_pagamento, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_pagamento) between trunc(to_date('${parRicerca.daDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        if (!parRicerca.daDataRegistrazione) {
            sql += """ and trunc(nvl(versamenti.data_reg, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_reg) between trunc(to_date('${parRicerca.daDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        sql += """
                ${(parRicerca.daImporto && parRicerca.aImporto) ? " and versamenti.importo_versato between to_number (translate (' ${parRicerca.daImporto}', ',', '.')) and to_number (translate (' ${parRicerca.aImporto}',',','.'))\n" : ""}
                ${(parRicerca.daImporto && parRicerca.aImporto == null) ? " and versamenti.importo_versato >= to_number(translate('${parRicerca.daImporto}',',','.'))\n" : ""}
                ${(parRicerca.daImporto == null && parRicerca.aImporto) ? " and versamenti.importo_versato <= to_number(translate('${parRicerca.aImporto}',',','.'))\n" : ""}
                ${parRicerca.statoSoggetto == "D" ? "and soggetti.stato = 50\n" : ""}
                ${parRicerca.statoSoggetto == "ND" ? "and nvl (soggetti.stato, 0) <> 50\n" : ""}
		"""

        def params = [:]
        params.max = pageSize ?: 10
        params.activePage = activePage ?: 0
        params.offset = activePage * pageSize

        // Numero totale di elementi
        def totale = eseguiQuery("""
                select count(*) as "totale" ,
                       sum("importoVersato") "totImpVersato",
                       sum("maggiorazioneTares") "totMaggiorazioneTares",
                       sum("importoDovuto") "totImportoDovuto",
                       sum("imposta") "totImposta",
                       sum("addizionaleMaggiorazioneECA") "totAddEca",
                       sum("addizionaleProvinciale") "totAddProvinciale",
                       sum("magTar") "totMagTar",
                       sum("sanzioni") "totSanzioni",
                       sum("interessi") "totInteressi",
                       sum("importoRidotto") "totImportoRidotto",
                       sum("impostaRidotta") "totImpostaRidotta",
                       sum("sanzioniRidotte") "totSanzioniRidotte",
                       sum("spese") "totSpese"
                       FROM ($sql)""", filtri, params, true)[0]

        def versamenti = eseguiQuery("$sql $sortBySql", filtri, params, wholeList).each { row ->
            row.pratica = row.pratica as Integer
            row.dataPagamento = row.dataPagamento ? new Date(row.dataPagamento.time).format("dd/MM/yyyy") : null
            row.documentoId = row.documentoId as Integer
            row.fonte = row.fonte ? Fonte.get(row.fonte)?.toDTO() : null
            row.tipoTributo = row.tipoTributo as String
            row.sequenza = row.sequenza as Short

            row.impostaVersato =
                    (row.importoVersato ?: 0) -
                            ((row.addizionalePro ?: 0) +
                                    (row.sanzioniVers ?: 0) +
                                    (row.interessiVers ?: 0) +
                                    (row.sanzioniAddPro ?: 0) +
                                    (row.interessiAddPro ?: 0) +
                                    (row.speseSpedizione ?: 0) +
                                    (row.speseMora ?: 0) +
                                    (row.maggiorazioneTares ?: 0))

        }

        def totali = [
                "totale"               : totale.totale ?: 0,
                "totImpVersato"        : totale.totImpVersato ?: null,
                "totMaggiorazioneTares": totale.totMaggiorazioneTares ?: null,
                "totImportoDovuto"     : totale.totImportoDovuto ?: null,
                "totImposta"           : totale.totImposta ?: null,
                "totAddEca"            : totale.totAddEca ?: null,
                "totAddProvinciale"    : totale.totAddProvinciale ?: null,
                "totMagTar"            : totale.totMagTar ?: null,
                "totSanzioni"          : totale.totSanzioni ?: null,
                "totInteressi"         : totale.totInteressi ?: null,
                "totImportoRidotto"    : totale.totImportoRidotto ?: null,
                "totImpostaRidotta"    : totale.totImpostaRidotta ?: null,
                "totSanzioniRidotte"   : totale.totSanzioniRidotte ?: null,
                "totSpese"             : totale.totSpese ?: null
        ]

        return [
                result: versamenti,
                totali: totali
        ]
    }

    @NotTransactional
    def listaVersamentiPubblTosapCuni(def tipoOrdinamento, def parRicerca, String tipoTributo, int pageSize, int activePage, boolean wholeList) {

        def sortBySql = ""
        if (tipoOrdinamento) {
            if (tipoOrdinamento == CampiOrdinamento.ALFA) {
                sortBySql += "order by cognome asc, nome asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.CF) {
                sortBySql += "order by contribuenti.cod_fiscale asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.ANNO) {
                sortBySql += "order by versamenti.anno asc, soggetti.cognome asc, soggetti.nome asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.DATA) {
                sortBySql += "order by versamenti.data_pagamento asc,soggetti.cognome asc, soggetti.nome asc, versamenti.anno asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            } else if (tipoOrdinamento == CampiOrdinamento.TIPO) {
                sortBySql += "order by pratiche_tributo.tipo_pratica asc, versamenti.anno asc, versamenti.data_pagamento asc, versamenti.tipo_versamento asc, versamenti.rata asc "
            }
        }

		String addedWhere = ""
		def filtri = [:]
		
		filtri << ['tipoTributo': tipoTributo]
		
		if(parRicerca.cognome) {
			filtri << ['cognome': parRicerca.cognome ]
			addedWhere += """and upper(soggetti.cognome_ric) like upper(:cognome)\n"""
		}
		if(parRicerca.nome) {
			filtri << ['nome': parRicerca.nome ]
			addedWhere += """and upper(soggetti.nome_ric) like upper(:nome)\n"""
		}
		if(parRicerca.cf) {
			filtri << ['codFiscale': parRicerca.cf ]
			addedWhere += """and (upper(soggetti.cod_fiscale) like upper(:codFiscale) or upper(soggetti.partita_iva) like upper(:codFiscale))\n"""
		}
		if(parRicerca.ruolo) {
			filtri << ['ruolo': parRicerca.ruolo as Long ]
			addedWhere += """and versamenti.ruolo = :ruolo\n"""
		}

        def sql = """
                    select   versamenti.anno "anno",
                             versamenti.tipo_versamento "tipoVersamento",
                             versamenti.importo_versato "importoVersato",
                             versamenti.data_pagamento "dataPagamento" ,                             
                             versamenti.fonte "fonte",
                             versamenti.tipo_tributo "tipoTributo",
                             versamenti.sequenza "sequenza",
                             versamenti.documento_id "documentoId",
                             pratiche_tributo.pratica "pratica",
                             pratiche_tributo.tipo_pratica "tipoPratica",
                             upper(translate (soggetti.cognome_nome, '/', ' ')) "contribuente",
                             versamenti.cod_fiscale "codFiscale",
                             upper (replace (soggetti.cognome, ' ', '')) "cognome",
                             upper (replace (soggetti.nome, ' ', '')) "nome",
                             contribuenti.ni "ni",
                             versamenti.rata "rata",
                             versamenti.ruolo "ruolo",
							 versamenti.num_bollettino "numBollettino",
                             versamenti.imposta "imposta",
							 versamenti.sanzioni_1 "sanzioni1",
							 versamenti.interessi "interessi",
                             versamenti.data_reg "dataRegistrazione",
							 versamenti.spese_spedizione "speseSpedizione",
							 versamenti.spese_mora "speseMora",
						     decode(versamenti.id_compensazione,null,'','S') "compensazione",
							 versamenti.descrizione "descrizione",
 							 versamenti.provvedimento "provvedimento",
							 versamenti.ufficio_pt "ufficioPt",
 							 versamenti.causale "causale",
							 versamenti.note "note",
							 versamenti.fattura "fattura", 
							 versamenti.utente "utente",
							 versamenti.data_variazione "dataVariazione" 
                        from versamenti,
                             pratiche_tributo,
                             contribuenti,
                             soggetti
                     where  (versamenti.pratica = pratiche_tributo.pratica(+))
                            and (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                            and (contribuenti.ni = soggetti.ni)
                            and versamenti.tipo_tributo = :tipoTributo
							${addedWhere}   
		"""

        if (parRicerca.fonte && parRicerca.fonte?.codice != -1) {
            sql += """ and versamenti.fonte = ${parRicerca.fonte.codice}\n"""
        }

        if (parRicerca.rata && parRicerca.rata != -1) {
            sql += """ and versamenti.rata = ${parRicerca.rata}\n"""
        }

        if (parRicerca.tipoPratica && parRicerca.tipoPratica?.codice != "T") {
            if (parRicerca.tipoPratica.codice != 'O') {
                sql += """ and pratiche_tributo.tipo_pratica = '${parRicerca.tipoPratica.codice}'\n"""
            } else {
                sql += """ and versamenti.pratica is null\n"""
            }
        }

        if (parRicerca.progrDocVersamento && parRicerca.progrDocVersamento?.codice != -1) {
            sql += """ and nvl (versamenti.documento_id, 0) = ${parRicerca.progrDocVersamento.codice}\n"""
        }

        sql += """
				${(parRicerca.daAnno && parRicerca.aAnno) ? " and versamenti.anno between ${parRicerca.daAnno} and ${parRicerca.aAnno}\n" : ""}
                ${(parRicerca.daAnno && parRicerca.aAnno == null) ? " and versamenti.anno >= ${parRicerca.daAnno}\n" : ""}
                ${(parRicerca.daAnno == null && parRicerca.aAnno) ? " and versamenti.anno <= ${parRicerca.aAnno}\n" : ""}
		"""

        if (!parRicerca.daDataPagamento) {
            sql += """ and trunc(nvl(versamenti.data_pagamento, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_pagamento) between trunc(to_date('${parRicerca.daDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataPagamento?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        if (!parRicerca.daDataRegistrazione) {
            sql += """ and trunc(nvl(versamenti.data_reg, to_date('01/01/1901', 'dd/mm/yyyy'))) <= trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        } else {
            sql += """ and trunc(versamenti.data_reg) between trunc(to_date('${parRicerca.daDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy')) and trunc(to_date('${parRicerca.aDataRegistrazione?.format('dd/MM/yyyy')}', 'dd/mm/yyyy'))\n"""
        }

        sql += """
                ${(parRicerca.daImporto && parRicerca.aImporto) ? " and versamenti.importo_versato between to_number (translate (' ${parRicerca.daImporto}', ',', '.')) and to_number (translate (' ${parRicerca.aImporto}',',','.'))\n" : ""}
                ${(parRicerca.daImporto && parRicerca.aImporto == null) ? " and versamenti.importo_versato >= to_number(translate('${parRicerca.daImporto}',',','.'))\n" : ""}
                ${(parRicerca.daImporto == null && parRicerca.aImporto) ? " and versamenti.importo_versato <= to_number(translate('${parRicerca.aImporto}',',','.'))\n" : ""}
                ${parRicerca.statoSoggetto == "D" ? "and soggetti.stato = 50\n" : ""}
                ${parRicerca.statoSoggetto == "ND" ? "and nvl (soggetti.stato, 0) <> 50\n" : ""}
		"""

        def params = [:]
        params.max = pageSize ?: 10
        params.activePage = activePage ?: 0
        params.offset = activePage * pageSize

        // Numero totale di elementi
        def totale = eseguiQuery("""
                select count(*) as "totale" ,
                       sum("importoVersato") "totImpVersato"
                       FROM ($sql)""", filtri, params, true)[0]

        def versamenti = eseguiQuery("$sql $sortBySql", filtri, params, wholeList).each { row ->
            row.pratica = row.pratica as Integer
            row.id = row.pratica
            row.importoVersato = row.importoVersato ? row.importoVersato : null
            row.dataPagamento = row.dataPagamento ? new Date(row.dataPagamento.time).format("dd/MM/yyyy") : null
            row.fonte = row.fonte ? Fonte.get(row.fonte)?.toDTO() : null
            row.documentoId = row.documentoId as Integer
            row.dataRegistrazione = row.dataRegistrazione ? new Date(row.dataRegistrazione.time).format("dd/MM/yyyy") : null
            row.rata = row.rata as Integer
            row.tipoTributo = row.tipoTributo as String
            row.sequenza = row.sequenza as Short
        }

        def totali = [
                "totale"       : totale.totale ?: 0,
                "totImpVersato": totale.totImpVersato ?: null
        ]
        return [
                result: versamenti,
                totali: totali
        ]
    }

    // Legge elenco dovuti rateizzati
    def getElencoDovutiRateizzati(String codFiscale, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
			SELECT
				ANNO,
				RATA,
				SUM(NVL(IMPOSTA,0)) AS IMPOSTA,
				SUM(NVL(IMPOSTA_ROUND,NVL(IMPOSTA,0))) AS IMPOSTA_ROUND
			FROM
				RATE_IMPOSTA
			WHERE
				TIPO_TRIBUTO = :tipoTributo AND
				COD_FISCALE = :codFiscale
			GROUP BY
				COD_FISCALE,
				ANNO,
				RATA
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.anno = it['ANNO'] as Short
            record.rata = it['RATA'] as Short
            record.imposta = it['IMPOSTA'] as Double
            record.impostaRound = it['IMPOSTA_ROUND'] as Double

            records << record
        }

        return records
    }

    // Legge elenco dovuti per pratica
    def getElencoDovutiPerPratica(Long praticaId, String codFiscale, String tipoTributo) {

        def filtri = [:]

        filtri << ['praticaId': praticaId]
        filtri << ['codFiscale': codFiscale]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
			SELECT 
				OGIM.ANNO AS ANNO,
				0 AS RATA,
				SUM(OGIM.IMPOSTA) AS IMPOSTA,
				ROUND(SUM(OGIM.IMPOSTA)) AS IMPOSTA_ROUND
			FROM
				OGGETTI_IMPOSTA OGIM
			WHERE
				OGIM.COD_FISCALE = :codFiscale AND
				OGIM.TIPO_TRIBUTO = :tipoTributo AND
				OGIM.OGGETTO_PRATICA IN
				(SELECT
					OGPR.OGGETTO_PRATICA
				FROM
					OGGETTI_PRATICA OGPR
				WHERE
					PRATICA = :praticaId AND
					COD_FISCALE = :codFiscale)
			GROUP BY
				OGIM.ANNO
			UNION
			SELECT 
				RAIM.ANNO,
				RAIM.RATA,
				SUM(RAIM.IMPOSTA) AS IMPOSTA,
				SUM(RAIM.IMPOSTA_ROUND) AS IMPOSTA_ROUND
			FROM
				RATE_IMPOSTA RAIM
			WHERE
				RAIM.COD_FISCALE = :codFiscale AND
				RAIM.OGGETTO_IMPOSTA IN
				(SELECT
					OGIM.OGGETTO_IMPOSTA
				FROM
					OGGETTI_IMPOSTA OGIM,
					OGGETTI_PRATICA OGPR
				WHERE
					OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.PRATICA = :praticaId AND
					OGIM.COD_FISCALE = :codFiscale AND
					OGIM.TIPO_TRIBUTO = :tipoTributo)
			GROUP BY
				RAIM.ANNO, RAIM.RATA
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.anno = it['ANNO'] as Short
            record.rata = it['RATA'] as Short
            record.imposta = it['IMPOSTA'] as Double
            record.impostaRound = it['IMPOSTA_ROUND'] as Double

            records << record
        }

        return records
    }

    // Legge elenco fatture
    def getElencoFatture(String codFiscale) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]

        String sql = """
			SELECT
				FATTURA,
				ANNO,
				NUMERO,
				DATA_EMISSIONE,
				IMPORTO_TOTALE
			FROM
				FATTURE
			WHERE
				COD_FISCALE = :codFiscale
			ORDER BY
				ANNO,
				NUMERO,
				DATA_EMISSIONE
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.fattura = it['FATTURA'] as Long
            record.anno = it['ANNO'] as Short
            record.numero = it['NUMERO'] as Long
            record.dataEmissione = it['DATA_EMISSIONE']
            record.importoTotale = it['IMPORTO_TOTALE'] as Double

            record.descrizione = "${record.numero}/${record.anno}"
            record.descrizioneFull = record.descrizione + " del " + ((record.dataEmissione) ? record.dataEmissione.format("dd/MM/yyyy") : "")

            records << record
        }

        return records
    }

    // Legge elenco annualita oggetti per versamento
    def getAnnualitaOggettiVersamento(String codFiscale, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
			SELECT
			  OGIM.ANNO ANNO
			FROM
			  OGGETTI_IMPOSTA OGIM,
			  OGGETTI_PRATICA OGPR,
			  OGGETTI OGGE,   
			  PRATICHE_TRIBUTO PRTR,   
			  OGGETTI_CONTRIBUENTE OGCO,  
			  CODICI_TRIBUTO COTR,
			  TIPI_TRIBUTO TITR
			WHERE
			  OGPR.OGGETTO = OGGE.OGGETTO AND  
			  PRTR.PRATICA = OGPR.PRATICA AND  
			  OGIM.COD_FISCALE = OGCO.COD_FISCALE AND  
			  OGIM.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND  
			  OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND  
			  COTR.TRIBUTO = OGPR.TRIBUTO AND
			  TITR.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO AND
			  OGIM.COD_FISCALE = :codFiscale AND
			  OGIM.FLAG_CALCOLO = 'S' AND
			  PRTR.TIPO_TRIBUTO||'' = :tipoTributo AND
			  (OGIM.RUOLO IS NULL OR
			    (OGIM.RUOLO IS NOT NULL AND 
			      EXISTS (SELECT 'x' FROM RUOLI
			        WHERE RUOLI.RUOLO = OGIM.RUOLO
			          AND RUOLI.INVIO_CONSORZIO IS NOT NULL)))
			GROUP BY OGIM.ANNO
			ORDER BY OGIM.ANNO DESC
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def anno = it['ANNO'] as Short

            records << anno
        }

        return records
    }

    // Legge elenco oggetti per versamento
    def getOggettiVersamento(String codFiscale, Short anno, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
					SELECT
						NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO) TIPO_OGGETTO,
						DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVE.DENOM_UFF ) ||
											DECODE(OGGE.NUM_CIV,NULL,'',', '||TO_CHAR(OGGE.NUM_CIV)) ||
															DECODE(OGGE.SUFFISSO,NULL,'','/'||OGGE.SUFFISSO) INDIRIZZO,
						OGGE.SEZIONE,
						OGGE.FOGLIO,
						OGGE.NUMERO,
						OGGE.SUBALTERNO,
						OGGE.ZONA,
						OGGE.PARTITA,
						OGGE.OGGETTO,
						DECODE(OGIM.RUOLO,NULL,OGIM.IMPOSTA,F_IMPOSTA_RUOL_CONT_ANNO_TITR(OGIM.COD_FISCALE,
															OGIM.ANNO,PRTR.TIPO_TRIBUTO,OGIM.OGGETTO_PRATICA,
																NVL(COTR.CONTO_CORRENTE,TITR.CONTO_CORRENTE),OGIM.RUOLO)) IMPOSTA,
						OGPR.PRATICA,
						OGIM.OGGETTO_IMPOSTA
					FROM
						OGGETTI_IMPOSTA OGIM,
						OGGETTI_PRATICA OGPR,
						OGGETTI OGGE,
						ARCHIVIO_VIE ARVE,
						PRATICHE_TRIBUTO PRTR,
						OGGETTI_CONTRIBUENTE OGCO,
						CARICHI_TARSU CATR,
						CODICI_TRIBUTO COTR,
						TIPI_TRIBUTO TITR
					WHERE
						OGGE.COD_VIA = ARVE.COD_VIA (+) AND
						OGPR.OGGETTO = OGGE.OGGETTO AND
						PRTR.PRATICA = OGPR.PRATICA AND
						OGIM.COD_FISCALE = OGCO.COD_FISCALE AND
						OGIM.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND
						OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
						CATR.ANNO (+) = OGIM.ANNO AND
						COTR.TRIBUTO = OGPR.TRIBUTO AND
						TITR.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO AND
						:anno IN (-1, OGIM.ANNO) AND
						OGIM.COD_FISCALE = :codFiscale AND
						OGIM.FLAG_CALCOLO = 'S' AND
						PRTR.TIPO_TRIBUTO||'' = :tipoTributo AND
						(OGIM.RUOLO IS NULL OR
							(OGIM.RUOLO IS NOT NULL AND
							  EXISTS (SELECT 'x' FROM RUOLI
									   WHERE RUOLI.RUOLO = OGIM.RUOLO
										 AND RUOLI.INVIO_CONSORZIO IS NOT NULL)))
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []
        Integer id = 0

        results.each {

            def record = [:]

            record.id = ++id

            record.oggetto = it['OGGETTO']
            record.oggettoImposta = it['OGGETTO_IMPOSTA']
            record.pratica = it['PRATICA']

            record.tipoOggetto = it['TIPO_OGGETTO']
            record.indirizzo = it['INDIRIZZO']
            record.sezione = it['SEZIONE']
            record.foglio = it['FOGLIO']
            record.numero = it['NUMERO']
            record.subalterno = it['SUBALTERNO']
            record.zona = it['ZONA']
            record.partita = it['PARTITA']
            record.imposta = it['IMPOSTA']

            records << record
        }

        return records
    }

    // Legge elenco versamenti Cumulativi
    def getVersamentiCumulativi(String codFiscale, Short anno, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
				SELECT
					VERS.COD_FISCALE,
					VERS.ANNO,
					VERS.TIPO_TRIBUTO,
					VERS.SEQUENZA,
					VERS.RATA,
					VERS.NUM_BOLLETTINO,
					VERS.DATA_PAGAMENTO,
					VERS.IMPORTO_VERSATO,
					VERS.RUOLO,
					VERS.FONTE,
					VERS.UTENTE,
					VERS.DATA_REG,
					VERS.RATA_IMPOSTA,
					VERS.SPESE_SPEDIZIONE,
					VERS.SPESE_MORA,
					VERS.FATTURA,
					VERS.MAGGIORAZIONE_TARES,
					VERS.ID_COMPENSAZIONE,
					VERS.DESCRIZIONE,
					VERS.PROVVEDIMENTO,
					VERS.UFFICIO_PT,
					VERS.CAUSALE,
					VERS.SERVIZIO,
					VERS.NOTE,
					VERS.DATA_VARIAZIONE,
					VERS.ADDIZIONALE_PRO,
					VERS.SANZIONI_1,
					VERS.SANZIONI_2,
					VERS.INTERESSI,
					VERS.SANZIONI_ADD_PRO,
					VERS.INTERESSI_ADD_PRO
				FROM
					RATE_IMPOSTA,
					VERSAMENTI VERS,
					FATTURE FATT,
					AD4_UTENTI
				WHERE
					(VERS.COD_FISCALE = :codFiscale) AND
					(VERS.ANNO = NVL(:anno, VERS.ANNO)) AND
					(VERS.TIPO_TRIBUTO || '' = :tipoTributo) AND
					(VERS.OGGETTO_IMPOSTA IS NULL) AND
					(VERS.PRATICA IS NULL) AND
					(RATE_IMPOSTA.RATA_IMPOSTA(+) = VERS.RATA_IMPOSTA) AND
					(RATE_IMPOSTA.OGGETTO_IMPOSTA IS NULL) AND
					(FATT.FATTURA(+) = VERS.FATTURA) AND
					(AD4_UTENTI.UTENTE(+) = VERS.UTENTE)
				ORDER BY
					VERS.RATA
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []
        Integer id = 0

        results.each {

            def record = [:]

            record.id = ++id

            record.codFiscale = it['COD_FISCALE']
            record.tipoTributo = it['TIPO_TRIBUTO']
            record.sequenza = it['SEQUENZA']

            record.anno = it['ANNO']
            record.rata = it['RATA']
            record.dataPagamento = it['DATA_PAGAMENTO']
            record.dataReg = it['DATA_REG']
            record.note = it['NOTE']

            record.numBollettino = it['NUM_BOLLETTINO']
            record.speseSpedizione = it['SPESE_SPEDIZIONE']
            record.speseMora = it['SPESE_MORA']
            record.fattura = it['FATTURA'] as Long
            record.maggiorazioneTares = it['MAGGIORAZIONE_TARES']
            record.idCompensazione = it['ID_COMPENSAZIONE'] as Long
            record.chkCompensazione = (record.idCompensazione ?: 0) > 0 ? true : false
            record.descrizione = it['DESCRIZIONE']
            record.provvedimento = it['PROVVEDIMENTO']
            record.ufficioPt = it['UFFICIO_PT']
            record.causale = it['CAUSALE']
            record.servizio = it['SERVIZIO']
            record.dataVariazione = it['DATA_VARIAZIONE']

            record.importoVersato = it['IMPORTO_VERSATO'] as Double
            record.addizionalePro = it['ADDIZIONALE_PRO'] as Double
            record.sanzioni1 = it['SANZIONI_1'] as Double
            record.sanzioni2 = it['SANZIONI_2'] as Double
            record.interessi = it['INTERESSI'] as Double
            record.sanzioniAddPro = it['SANZIONI_ADD_PRO'] as Double
            record.interessiAddPro = it['INTERESSI_ADD_PRO'] as Double

            record.ruoloId = it['RUOLO']
            record.rataImposta = it['RATA_IMPOSTA']
            record.fonte = it['FONTE']
            record.utente = it['UTENTE']

            aggiornaImportoVersamento(record)

            record.status = 0

            records << record
        }

        return records
    }

    // Legge elenco versamenti oggetto imposta
    def getVersamentiOggetto(String codFiscale, Short anno, String tipoTributo, def oggettoImposta) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]
        filtri << ['tipoTributo': tipoTributo]
        filtri << ['oggettoImposta': oggettoImposta]

        String sql = """
				SELECT
					VERS.COD_FISCALE,
					VERS.ANNO,
					VERS.TIPO_TRIBUTO,
					VERS.SEQUENZA,
					VERS.RATA,
					VERS.NUM_BOLLETTINO,
					VERS.DATA_PAGAMENTO,
					VERS.IMPORTO_VERSATO,
					VERS.RUOLO,
					VERS.FONTE,
					VERS.UTENTE,
					VERS.OGGETTO_IMPOSTA,
					VERS.DATA_REG,
					VERS.RATA_IMPOSTA,
					VERS.SPESE_SPEDIZIONE,
					VERS.SPESE_MORA,
					VERS.MAGGIORAZIONE_TARES,
					VERS.ADDIZIONALE_PRO,
					VERS.SANZIONI_1,
					VERS.SANZIONI_2,
					VERS.INTERESSI,
					VERS.SANZIONI_ADD_PRO,
					VERS.INTERESSI_ADD_PRO,
					DECODE(VERS.ID_COMPENSAZIONE, '', '', 'S') CHK_COMPENSAZIONE
				FROM
					VERSAMENTI VERS
				WHERE
					(VERS.cod_fiscale = :codFiscale)
				     AND (VERS.ANNO = :anno)
				     AND (VERS.TIPO_TRIBUTO || '' = :tipoTributo)
				     AND (VERS.PRATICA IS NULL)
				     AND (VERS.RATA_IMPOSTA IS NOT NULL AND EXISTS
				          (SELECT 1
				             FROM RATE_IMPOSTA
				            WHERE RATE_IMPOSTA.OGGETTO_IMPOSTA = :oggettoImposta
				              AND RATE_IMPOSTA.RATA_IMPOSTA = VERS.RATA_IMPOSTA) or
				          VERS.OGGETTO_IMPOSTA = :oggettoImposta)
				ORDER BY VERS.RATA
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []
        Integer id = 0

        results.each {

            def record = [:]

            record.id = ++id

            record.codFiscale = it['COD_FISCALE']
            record.anno = it['ANNO']
            record.tipoTributo = it['TIPO_TRIBUTO']
            record.sequenza = it['SEQUENZA']

            record.rata = it['RATA']
            record.numBollettino = it['NUM_BOLLETTINO']
            record.dataPagamento = it['DATA_PAGAMENTO']
            record.importoVersato = it['IMPORTO_VERSATO']
            record.oggettoImposta = it['OGGETTO_IMPOSTA']
            record.dataReg = it['DATA_REG']
            record.speseSpedizione = it['SPESE_SPEDIZIONE']
            record.speseMora = it['SPESE_MORA']
            record.maggiorazioneTares = it['MAGGIORAZIONE_TARES']
            record.addizionalePro = it['ADDIZIONALE_PRO']
            record.sanzioni1 = it['SANZIONI_1']
            record.sanzioni2 = it['SANZIONI_2']
            record.interessi = it['INTERESSI']
            record.sanzioniAddPro = it['SANZIONI_ADD_PRO']
            record.interessiAddPro = it['INTERESSI_ADD_PRO']
            record.chkCompensazione = it['CHK_COMPENSAZIONE']

            record.ruoloId = it['RUOLO']
            record.rataImposta = it['RATA_IMPOSTA']
            record.fonte = it['FONTE']
            record.utente = it['UTENTE']

            aggiornaImportoVersamento(record)

            record.status = 0

            records << record
        }

        return records
    }

    // Legge elenco annualità con versamenti su oggetto imposta
    def getVersamentiOggettoPerAnno(String codFiscale, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
		        SELECT
		          VERS.ANNO,
		          COUNT(VERS.IMPORTO_VERSATO) AS NUM_VERSAMENTI
		        FROM
		          VERSAMENTI VERS
		        WHERE
		          (VERS.COD_FISCALE = :codFiscale)
		    		 AND (VERS.TIPO_TRIBUTO || '' = :tipoTributo)
		             AND (VERS.PRATICA IS NULL)
		             AND (VERS.RATA_IMPOSTA IS NOT NULL AND EXISTS
		                  (SELECT 1
		                     FROM RATE_IMPOSTA
		                    WHERE RATE_IMPOSTA.OGGETTO_IMPOSTA is not null
		                      AND RATE_IMPOSTA.RATA_IMPOSTA = VERS.RATA_IMPOSTA) or
		                  VERS.OGGETTO_IMPOSTA is not null)
		        GROUP BY
		              VERS.ANNO,
		              VERS.TIPO_TRIBUTO
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.anno = it['ANNO'] as Short
            record.versamenti = it['NUM_VERSAMENTI'] as Long

            records << record
        }

        return records
    }

    // Legge elenco annualit� con versamenti cumulativi
    def getVersamentiCumulativiPerAnno(String codFiscale, String tipoTributo) {

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['tipoTributo': tipoTributo]

        String sql = """
				SELECT
		          VERS.ANNO,
		          COUNT(VERS.IMPORTO_VERSATO) AS NUM_VERSAMENTI
				FROM
					RATE_IMPOSTA,
					VERSAMENTI VERS,
					FATTURE FATT
				WHERE
					(VERS.COD_FISCALE = :codFiscale) AND
					(VERS.TIPO_TRIBUTO || '' = :tipoTributo) AND
					(VERS.OGGETTO_IMPOSTA IS NULL) AND
					(VERS.PRATICA IS NULL) AND
					(RATE_IMPOSTA.RATA_IMPOSTA(+) = VERS.RATA_IMPOSTA) AND
					(RATE_IMPOSTA.OGGETTO_IMPOSTA IS NULL) AND
					FATT.FATTURA(+) = VERS.FATTURA
		        GROUP BY
		              VERS.ANNO,
		              VERS.TIPO_TRIBUTO
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.anno = it['ANNO'] as Short
            record.versamenti = it['NUM_VERSAMENTI'] as Long

            records << record
        }

        return records
    }

    // Collega pratica a versamento (pratica può essere null -> sgancia versamento)
    def collegaPratica(VersamentoDTO versamento, PraticaTributoDTO pratica) {

        PraticaTributo praticaSalva
        Versamento versamentoSalva

        try {
            praticaSalva = (pratica != null) ? pratica.getDomainObject() : null
            versamentoSalva = versamento.getDomainObject()

            versamentoSalva.pratica = praticaSalva

            versamentoSalva.save(failOnError: true, flush: true)
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

        return versamentoSalva.toDTO()
    }

    // Ricava descrizione della pratica dal versamento
    def getDescrizionePraticaDaVersamento(VersamentoDTO versamento) {

        PraticaTributoDTO praticaTributo = versamento.pratica
        String tipoPratica = praticaTributo.tipoPratica
        String tipoTributo = versamento.tipoTributo.tipoTributo
        Short anno = praticaTributo.anno

        String numero = (praticaTributo.numero) ? praticaTributo.numero.toString() : "Senza Numero"
        String pratica = praticaTributo.id.toString()
        String data = praticaTributo.data?.format("dd/MM/yyyy")

        String descrizioneTipo = liquidazioniAccertamentiService.getDescrizioneTipoPratica(tipoPratica, tipoTributo, anno)

        String descrizione = "${descrizioneTipo} (${anno.toString()}) Nr. ${numero} del ${data}"

        return descrizione
    }

    // Appplica modifiche al versamento
    def applicaModificheVersamento(def modifiche, def versamento) {

        versamento.tipoVersamento = modifiche.tipoVersamento
        versamento.rata = modifiche.rata
        versamento.importoVersato = modifiche.importoVersato
        versamento.dataPagamento = modifiche.dataPagamento
        versamento.dataReg = modifiche.dataReg
        versamento.documentoId = modifiche.documentoId

        versamento.detrazione = modifiche.detrazione

        versamento.terreniAgricoli = modifiche.terreniAgricoli
        versamento.terreniComune = modifiche.terreniComune
        versamento.terreniErariale = modifiche.terreniErariale
        versamento.areeFabbricabili = modifiche.areeFabbricabili
        versamento.areeComune = modifiche.areeComune
        versamento.areeErariale = modifiche.areeErariale
        versamento.abPrincipale = modifiche.abPrincipale
        versamento.rurali = modifiche.rurali
        versamento.ruraliComune = modifiche.ruraliComune
        versamento.ruraliErariale = modifiche.ruraliErariale
        versamento.altriFabbricati = modifiche.altriFabbricati
        versamento.altriComune = modifiche.altriComune
        versamento.altriErariale = modifiche.altriErariale
        versamento.fabbricatiD = modifiche.fabbricatiD
        versamento.fabbricatiDComune = modifiche.fabbricatiDComune
        versamento.fabbricatiDErariale = modifiche.fabbricatiDErariale
        versamento.fabbricatiMerce = modifiche.fabbricatiMerce
        versamento.numFabbricatiTerreni = modifiche.numFabbricatiTerreni
        versamento.numFabbricatiAree = modifiche.numFabbricatiAree
        versamento.numFabbricatiAb = modifiche.numFabbricatiAb
        versamento.numFabbricatiRurali = modifiche.numFabbricatiRurali
        versamento.numFabbricatiAltri = modifiche.numFabbricatiAltri
        versamento.numFabbricatiD = modifiche.numFabbricatiD
        versamento.numFabbricatiMerce = modifiche.numFabbricatiMerce
        versamento.fabbricati = modifiche.fabbricati

        versamento.imposta = modifiche.imposta
        versamento.interessi = modifiche.interessi
        versamento.sanzioni1 = modifiche.sanzioni1
        versamento.sanzioni2 = modifiche.sanzioni2

        versamento.maggiorazioneTares = modifiche.maggiorazioneTares

        versamento.addizionalePro = modifiche.addizionalePro
        versamento.sanzioniAddPro = modifiche.sanzioniAddPro
        versamento.interessiAddPro = modifiche.interessiAddPro

        versamento.speseSpedizione = modifiche.speseSpedizione
        versamento.speseMora = modifiche.speseMora

        versamento.servizio = modifiche.servizio

        versamento.numBollettino = modifiche.numBollettino
        versamento.rataImposta = modifiche.rataImposta
        versamento.fattura = modifiche.fattura
        versamento.descrizione = modifiche.descrizione
        versamento.provvedimento = modifiche.provvedimento
        versamento.ufficioPt = modifiche.ufficioPt
        versamento.causale = modifiche.causale
        versamento.note = modifiche.note

        versamento.ruolo = modifiche.ruolo
        versamento.pratica = modifiche.pratica

        versamento.idCompensazione = modifiche.idCompensazione
    }

    // Calcola importo
    def aggiornaImportoVersamento(def versamento) {

        def imposta = versamento.importoVersato ?: 0
        def sanzioni = versamento.sanzioni1 ?: 0
        sanzioni += versamento.sanzioni2 ?: 0
        def interessi = versamento.interessi ?: 0

        def maggiorazioneTares = versamento.maggiorazioneTares ?: 0

        def addizionalePro = versamento.addizionalePro ?: 0
        def sanzioniAddPro = versamento.sanzioniAddPro ?: 0
        def interessiAddPro = versamento.interessiAddPro ?: 0

        def speseSpedizione = versamento.speseSpedizione ?: 0
        def speseMora = versamento.speseMora ?: 0

        versamento.imposta = imposta - sanzioni - interessi - maggiorazioneTares - addizionalePro - sanzioniAddPro - interessiAddPro - speseSpedizione - speseMora
    }

    // Controlla coerenza dati versamento prima di aggiornare
    def verificaVersamento(VersamentoDTO versamento, Short annoNuovo, def dovutiRateizzati) {

        String message = ""
        Integer result = 0

        String tipoTributo

        try {

            if (versamento.tipoTributo == null) {
                throw new Exception("ORA-20999: Tipo Tributo non impostato\n")
            }
            if (versamento.fonte == null) {
                throw new Exception("ORA-20999: Fonte non impostata\n")
            }

            tipoTributo = versamento.tipoTributo.tipoTributo

            if (!versamento.anno && !annoNuovo) {
                message += "- Indicare l'anno\n"
                if (result < 2) result = 2
            }
            if (versamento.importoVersato == null) {
                message += "- Importo Versato non specificata\n"
                if (result < 2) result = 2
            }
            if (versamento.dataPagamento == null) {
                message += "- Data Pagamento non specificata\n"
                if (result < 2) result = 2
            }
            if ((versamento.tipoVersamento == null) && (versamento.rata == null)) {
                message += "- Indicare Tipo Versamento o Rata\n"
                if (result < 2) result = 2
            }

            String messageRata = verificaVersamentoRata(versamento, annoNuovo, dovutiRateizzati)
            if (!messageRata.isEmpty()) {
                message += messageRata
                if (result < 1) result = 1
            }

            if (versamento.pratica == null) {

                BigDecimal versato = versamento.importoVersato ?: 0
                BigDecimal totale = versamento.getTotaleDaVersare()

                if (Math.abs(totale) > 0.5) {
                    if (Math.abs(totale - versato) > 0.5) {
                        message += "- L'importo totale non coincide con il versato\n"
                        if (result < 1) result = 1
                    }
                }
            }

            if (tipoTributo in ['ICI']) {

                BigDecimal comune
                BigDecimal erariale
                BigDecimal totale
                BigDecimal imposta

                comune = versamento.terreniComune ?: 0.0
                erariale = versamento.terreniErariale ?: 0.0
                imposta = versamento.terreniAgricoli ?: 0.0
                totale = comune + erariale

                if ((Math.abs(totale) > 0.5) && (Math.abs(imposta - totale) > 0.5)) {
                    message += "- La somma di Comune e Stato non coincide con il Totale per Terreni Agricoli\n"
                    if (result < 1) result = 1
                }

                comune = versamento.areeComune ?: 0.0
                erariale = versamento.areeErariale ?: 0.0
                imposta = versamento.areeFabbricabili ?: 0.0
                totale = comune + erariale

                if ((Math.abs(totale) > 0.5) && (Math.abs(imposta - totale) > 0.5)) {
                    message += "- La somma di Comune e Stato non coincide con il Totale per Aree Fabbricabili\n"
                    if (result < 1) result = 1
                }

                comune = versamento.ruraliComune ?: 0.0
                erariale = versamento.ruraliErariale ?: 0.0
                imposta = versamento.rurali ?: 0.0
                totale = comune + erariale

                if ((Math.abs(totale) > 0.5) && (Math.abs(imposta - totale) > 0.5)) {
                    message += "- La somma di Comune e Stato non coincide con il Totale\n"
                    if (result < 1) result = 1
                }

                comune = versamento.altriComune ?: 0.0
                erariale = versamento.altriErariale ?: 0.0
                imposta = versamento.altriFabbricati ?: 0.0
                totale = comune + erariale

                if ((Math.abs(totale) > 0.5) && (Math.abs(imposta - totale) > 0.5)) {
                    message += "- La somma di Comune e Stato non coincide con il Totale\n"
                    if (result < 1) result = 1
                }

                comune = versamento.fabbricatiDComune ?: 0.0
                erariale = versamento.fabbricatiDErariale ?: 0.0
                imposta = versamento.fabbricatiD ?: 0.0
                totale = comune + erariale

                if ((Math.abs(totale) > 0.5) && (Math.abs(imposta - totale) > 0.5)) {
                    message += "- La somma di Comune e Stato non coincide con il Totale\n"
                    if (result < 1) result = 1
                }
            }

            Short totaleFabbricati = versamento.getTotaleFabbricati()
            if ((totaleFabbricati != 0) && (totaleFabbricati != (versamento.fabbricati ?: 0))) {
                message += "- Il Totale Fabbricati non coincide con la somma dei parziali\n"
                if (result < 1) result = 1
            }
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

        return [result: result, message: message]
    }

    // Verifica coerenza rata con dovuto
    String verificaVersamentoRata(def versamento, Short annoNuovo, def dovutiRateizzati, Boolean rataUnica = false) {

        String message = ""

        Short rataMinima = (rataUnica) ? 0 : 1

        Short annoDovuto = (annoNuovo) ? annoNuovo : (versamento.anno ?: -1)
        Short rata = versamento.rata ?: 0

        if ((annoDovuto > 0) && (rata >= rataMinima)) {

            BigDecimal versato = versamento.importoVersato ?: 0

            def rateazione = dovutiRateizzati.find { it.anno == annoDovuto && it.rata == rata }
            if (rateazione != null) {
                def dovutoRata = rateazione.impostaRound as BigDecimal
                if (Math.abs(dovutoRata - versato) > 0.5) {
                    DecimalFormat fmtValuta = new DecimalFormat("€ #,##0.00")
                    String importoRata = fmtValuta.format(dovutoRata)
                    message += "- L'importo versato non corrisponde al dovuto della rata ($importoRata)\n"
                }
            } else {
                message += "- Dovuto della rata non recuperabile\n"
            }
        }

        return message
    }

    // Aggiorna versamento
    def aggiornaVersamento(VersamentoDTO versamento, Short annoNuovo) {

        Contribuente contribuenteSalva
        Fonte fonteSalva
        OggettoImposta oggettoImpostaSalva
        RataImposta rataImpostaSalva
        Ruolo ruoloSalva
        TipoTributo tipoTributoSalva
        PraticaTributo praticaSalva
        Versamento versamentoSalva
        Versamento versamentoElimina

        try {
            contribuenteSalva = versamento.contribuente.getDomainObject()
            fonteSalva = (versamento.fonte != null) ? versamento.fonte.getDomainObject() : null
            oggettoImpostaSalva = (versamento.oggettoImposta != null) ? versamento.oggettoImposta.getDomainObject() : null
            rataImpostaSalva = (versamento.rataImposta != null) ? versamento.rataImposta.getDomainObject() : null
            ruoloSalva = (versamento.ruolo != null) ? versamento.ruolo.getDomainObject() : null
            tipoTributoSalva = (versamento.tipoTributo != null) ? versamento.tipoTributo.getDomainObject() : null
            praticaSalva = (versamento.pratica != null) ? versamento.pratica.getDomainObject() : null

            if (praticaSalva != null) {

                annoNuovo = praticaSalva.anno
            }

            if (annoNuovo != versamento.anno) {

                // Cambio anno, elimina vecchio e crea una copia x anno nuovo
                versamentoSalva = new Versamento()

                versamentoSalva.anno = annoNuovo
                versamentoSalva.sequenza = null

                versamentoElimina = versamento.getDomainObject()
            } else {

                // Stesso anno, riscrive o crea nuovo
                versamentoSalva = versamento.getDomainObject()

                if (versamentoSalva == null) {
                    versamentoSalva = new Versamento()
                    versamentoSalva.sequenza = null
                } else {
                    versamentoSalva.sequenza = versamento.sequenza
                }

                versamentoSalva.anno = versamento.anno

                versamentoElimina = null
            }

            if ((versamentoSalva.sequenza ?: 0) == 0) {
                versamentoSalva.sequenza = getNuovaSequenzaVersamento(contribuenteSalva.codFiscale, tipoTributoSalva.tipoTributo, versamentoSalva.anno)
            }

            versamentoSalva.id = versamento.id
            versamentoSalva.tipoVersamento = versamento.tipoVersamento

            versamentoSalva.contribuente = contribuenteSalva
            versamentoSalva.fonte = fonteSalva
            versamentoSalva.oggettoImposta = oggettoImpostaSalva
            versamentoSalva.rataImposta = rataImpostaSalva
            versamentoSalva.ruolo = ruoloSalva
            versamentoSalva.tipoTributo = tipoTributoSalva
            versamentoSalva.pratica = praticaSalva

            versamentoSalva.abPrincipale = versamento.abPrincipale
            versamentoSalva.altriComune = versamento.altriComune
            versamentoSalva.altriErariale = versamento.altriErariale
            versamentoSalva.altriFabbricati = versamento.altriFabbricati
            versamentoSalva.fabbricatiMerce = versamento.fabbricatiMerce
            versamentoSalva.areeComune = versamento.areeComune
            versamentoSalva.areeErariale = versamento.areeErariale
            versamentoSalva.areeFabbricabili = versamento.areeFabbricabili
            versamentoSalva.detrazione = versamento.detrazione
            versamentoSalva.fabbricatiD = versamento.fabbricatiD
            versamentoSalva.fabbricatiDComune = versamento.fabbricatiDComune
            versamentoSalva.fabbricatiDErariale = versamento.fabbricatiDErariale
            versamentoSalva.importoVersato = versamento.importoVersato
            versamentoSalva.rurali = versamento.rurali
            versamentoSalva.ruraliComune = versamento.ruraliComune
            versamentoSalva.ruraliErariale = versamento.ruraliErariale
            versamentoSalva.terreniAgricoli = versamento.terreniAgricoli
            versamentoSalva.terreniComune = versamento.terreniComune
            versamentoSalva.terreniErariale = versamento.terreniErariale

            versamentoSalva.numFabbricatiTerreni = versamento.numFabbricatiTerreni
            versamentoSalva.numFabbricatiAree = versamento.numFabbricatiAree
            versamentoSalva.numFabbricatiAb = versamento.numFabbricatiAb
            versamentoSalva.numFabbricatiRurali = versamento.numFabbricatiRurali
            versamentoSalva.numFabbricatiAltri = versamento.numFabbricatiAltri
            versamentoSalva.numFabbricatiD = versamento.numFabbricatiD
            versamentoSalva.numFabbricatiMerce = versamento.numFabbricatiMerce
            versamentoSalva.fabbricati = versamento.fabbricati

            versamentoSalva.fattura = versamento.fattura
            versamentoSalva.maggiorazioneTares = versamento.maggiorazioneTares
            versamentoSalva.speseMora = versamento.speseMora
            versamentoSalva.speseSpedizione = versamento.speseSpedizione

            versamentoSalva.dataPagamento = versamento.dataPagamento
            versamentoSalva.dataProvvedimento = versamento.dataProvvedimento
            versamentoSalva.dataReg = versamento.dataReg
            versamentoSalva.documentoId = versamento.documentoId

            versamentoSalva.dataSentenza = versamento.dataSentenza
            versamentoSalva.provvedimento = versamento.provvedimento

            versamentoSalva.imposta = versamento.imposta
            versamentoSalva.interessi = versamento.interessi
            versamentoSalva.numBollettino = versamento.numBollettino
            versamentoSalva.ogprOgim = versamento.ogprOgim
            versamentoSalva.progrAnci = versamento.progrAnci
            versamentoSalva.sanzioni1 = versamento.sanzioni1
            versamentoSalva.sanzioni2 = versamento.sanzioni2
            versamentoSalva.idCompensazione = versamento.idCompensazione

            versamentoSalva.addizionalePro = versamento.addizionalePro
            versamentoSalva.sanzioniAddPro = versamento.sanzioniAddPro
            versamentoSalva.interessiAddPro = versamento.interessiAddPro

            versamentoSalva.rata = versamento.rata

            versamentoSalva.servizio = versamento.servizio

            versamentoSalva.causale = versamento.causale
            versamentoSalva.descrizione = versamento.descrizione
            versamentoSalva.estremiProvvedimento = versamento.estremiProvvedimento
            versamentoSalva.estremiSentenza = versamento.estremiSentenza
            versamentoSalva.note = versamento.note
            versamentoSalva.ufficioPt = versamento.ufficioPt

            versamentoSalva.save(failOnError: true, flush: true)

            if (versamentoElimina != null) {

                versamentoElimina.delete(failOnError: true, flush: true)
            }

            return versamentoSalva.toDTO()
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    // Aggiorna versamento
    def eliminaVersamento(VersamentoDTO versamentoDTO) {

        Versamento versamentoElimina

        try {
            versamentoElimina = versamentoDTO.getDomainObject()

            if (versamentoElimina == null) {
                throw new RuntimeException("ORA-20999: Versamento non trovato !\n")
            }

            versamentoElimina.delete(failOnError: true, flush: true)
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def getVersamentoOpposto(def versamento) {
        return Versamento.createCriteria().get {
            eq("idCompensazione", versamento.idCompensazione)
            eq("importoVersato", -(versamento.importoVersato ?: 0) as BigDecimal)
        }
    }

    // Ricava prossima sequenza per versamento
    Short getNuovaSequenzaVersamento(String codFiscale, String tipoTributo, Short anno) {

        Short sequenza = 0

        Sql sql = new Sql(dataSource)
        sql.call('{call VERSAMENTI_NR(?, ?, ?, ?)}',
                [
                        codFiscale,
                        anno,
                        tipoTributo,
                        Sql.NUMERIC
                ],
                { sequenza = it }
        )

        return sequenza
    }

    // Esegue query
    private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

        filtri = filtri ?: [:]

        if (!query || query.isEmpty()) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }

    def getListaVersamentiDoppi(def params) {

        def parametri = [:]

        parameetri << ["p_titr": params.tipoTributo]
        parameetri << ["p_anno": params.anno]

        def query = """
                    select translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                       vers_a.cod_fiscale,
                       anno,
                       tipo_versamento tipo_ver,
                       data_pagamento data_pag,
                       importo_versato,
                       terreni_agricoli terreni,
                       aree_fabbricabili aree,
                       ab_principale abitazione,
                       altri_fabbricati altri,
                       rurali,
                       fabbricati_d,
                       fabbricati_merce,
                       detrazione,
                       upper(replace(SOGGETTI.COGNOME, ' ', '')) cognome,
                       upper(replace(SOGGETTI.NOME, ' ', '')) nome,
                       'Versamenti Doppi ' || f_descrizione_titr(:p_titr, anno) titolo,
                       'Anno: ' || anno st_anno,
                       vers_a.pratica
                  from versamenti vers_a, contribuenti, soggetti
                 WHERE (contribuenti.ni = soggetti.ni)
                   and (vers_a.cod_fiscale = contribuenti.cod_fiscale)
                   and (vers_a.anno = :p_anno)
                   and (vers_a.tipo_tributo = :p_titr)
                   and (1 < (select count(*)
                               from versamenti vers_b
                              where vers_b.tipo_tributo = vers_a.tipo_tributo
                                and nvl(vers_b.pratica, 0) = nvl(vers_a.pratica, 0)
                                and vers_b.cod_fiscale = vers_a.cod_fiscale
                                and vers_b.tipo_versamento = vers_a.tipo_versamento
                                and vers_b.anno + 0 = vers_a.anno
                                and decode(vers_b.pratica, null, 0, 1) =
                                    (select count(*)
                                       from pratiche_tributo prtr
                                      where prtr.pratica = vers_b.pratica
                                        and prtr.tipo_pratica(+) = 'V')))
                 order by vers_a.cod_fiscale, vers_a.tipo_versamento, vers_a.pratica
                    """
    }

    def getListaVersamentiDoppi(def tipoTributo, def anno, def ordinamento) {

        def parametri = [:]

        parametri << ["p_titr": tipoTributo]
        parametri << ["p_anno": anno]

        def queryOrdinamento = ""

        if (ordinamento && ordinamento == "alfa") {
            queryOrdinamento += " order by soggetti.cognome, soggetti.nome, (case when regexp_like(vers_a.cod_fiscale, '^[0-9]+\$') then 1 else 2 end) asc, vers_a.cod_fiscale, vers_a.tipo_versamento, vers_a.pratica "
        } else if (ordinamento && ordinamento == "cf") {
            queryOrdinamento += " order by (case when regexp_like(vers_a.cod_fiscale, '^[0-9]+\$') then 1 else 2 end) asc, vers_a.cod_fiscale, soggetti.cognome, soggetti.nome, vers_a.tipo_versamento, vers_a.pratica"
        }

        def query = """
                            select translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                                   vers_a.cod_fiscale,
                                   anno,
                                   tipo_versamento tipo_ver,
                                   data_pagamento data_pag,
                                   importo_versato,
                                   terreni_agricoli terreni,
                                   aree_fabbricabili aree,
                                   ab_principale abitazione,
                                   altri_fabbricati altri,
                                   rurali,
                                   fabbricati_d,
                                   fabbricati_merce,
                                   detrazione,
                                   upper(replace(SOGGETTI.COGNOME, ' ', '')) cognome,
                                   upper(replace(SOGGETTI.NOME, ' ', '')) nome,
                                   'Versamenti Doppi ' || f_descrizione_titr(:p_titr, anno) titolo,
                                   'Anno: ' || anno st_anno,
                                   vers_a.pratica
                              from versamenti vers_a, contribuenti, soggetti
                             WHERE (contribuenti.ni = soggetti.ni)
                               and (vers_a.cod_fiscale = contribuenti.cod_fiscale)
                               and (vers_a.anno = :p_anno)
                               and (vers_a.tipo_tributo = :p_titr)
                               and (1 < (select count(*)
                                           from versamenti vers_b
                                          where vers_b.tipo_tributo = vers_a.tipo_tributo
                                            and nvl(vers_b.pratica, 0) = nvl(vers_a.pratica, 0)
                                            and vers_b.cod_fiscale = vers_a.cod_fiscale
                                            and vers_b.tipo_versamento = vers_a.tipo_versamento
                                            and vers_b.anno + 0 = vers_a.anno
                                            and decode(vers_b.pratica, null, 0, 1) =
                                                (select count(*)
                                                   from pratiche_tributo prtr
                                                  where prtr.pratica = vers_b.pratica
                                                    and prtr.tipo_pratica(+) = 'V')))
                               ${queryOrdinamento}
                          """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def getListaSquadraturaTotalePrimaPagina(def tipoTributo, def codFiscale, def anno, def scarto, def ordinamento) {

        def parametri = [:]

        parametri << ["p_tiptrib": tipoTributo]
        parametri << ["p_codfis": codFiscale ?: '%']
        parametri << ["p_anno": anno]
        parametri << ["p_scarto": scarto != null ? scarto : 0]

        def queryOrdinamento = ""

        if (ordinamento && ordinamento == "alfa") {
            queryOrdinamento += " order by cog_nom, cod_fiscale, anno "
        } else if (ordinamento && ordinamento == "cf") {
            queryOrdinamento += " order by cod_fiscale, cog_nom, anno "
        }

        def queryImu = """
                            select versamenti.anno,
                                   translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                                   versamenti.cod_fiscale,
                                   sum(versamenti.importo_versato) versato,
                                   sum(versamenti.terreni_agricoli) terreni_agricoli,
                                   sum(versamenti.aree_fabbricabili) aree_fabbricabili,
                                   sum(versamenti.ab_principale) ab_principale,
                                   sum(versamenti.altri_fabbricati) altri_fabbricati,
                                   f_round(sum(nvl(versamenti.terreni_agricoli, 0)) +
                                           sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                           sum(nvl(versamenti.ab_principale, 0)) +
                                           sum(nvl(versamenti.altri_fabbricati, 0)) +
                                           sum(nvl(versamenti.fabbricati_d, 0)) +
                                           sum(nvl(versamenti.rurali, 0)) +
                                           sum(nvl(versamenti.fabbricati_merce, 0)),
                                           1) somma,
                                   upper(replace(soggetti.cognome, ' ', '')) cognome,
                                   upper(replace(soggetti.nome, ' ', '')) nome,
                                   sum(versamenti.rurali) rurali,
                                   sum(versamenti.fabbricati_d) fabbricati_d,
                                   sum(versamenti.fabbricati_merce) fabbricati_merce
                              from versamenti, contribuenti, soggetti
                             where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                               and (contribuenti.ni = soggetti.ni)
                               and (versamenti.pratica is null)
                               and (versamenti.tipo_tributo = :p_tiptrib)
                               and ((versamenti.cod_fiscale like :p_codfis) and
                                   (versamenti.anno = :p_anno))
                               and :p_anno < 2012
                             group by versamenti.anno,
                                      translate(soggetti.cognome_nome, '/', ' '),
                                      soggetti.cognome,
                                      soggetti.nome,
                                      versamenti.cod_fiscale
                            having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) + :p_scarto))
                            union all
                            select versamenti.anno,
                                   translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                                   versamenti.cod_fiscale,
                                   sum(versamenti.importo_versato) versato,
                                   sum(versamenti.terreni_agricoli) terreni_agricoli,
                                   sum(versamenti.aree_fabbricabili) aree_fabbricabili,
                                   sum(versamenti.ab_principale) ab_principale,
                                   sum(versamenti.altri_fabbricati) altri_fabbricati,
                                   f_round(sum(nvl(versamenti.terreni_agricoli, 0)) +
                                           sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                           sum(nvl(versamenti.ab_principale, 0)) +
                                           sum(nvl(versamenti.altri_fabbricati, 0)) +
                                           sum(nvl(versamenti.fabbricati_d, 0)) +
                                           sum(nvl(versamenti.rurali, 0)) +
                                           sum(nvl(versamenti.fabbricati_merce, 0)),
                                           1) somma,
                                   upper(replace(soggetti.cognome, ' ', '')) cognome,
                                   upper(replace(soggetti.nome, ' ', '')) nome,
                                   sum(versamenti.rurali) rurali,
                                   sum(versamenti.fabbricati_d) fabbricati_d,
                                   sum(versamenti.fabbricati_merce) fabbricati_merce
                              from versamenti, contribuenti, soggetti
                             where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                               and (contribuenti.ni = soggetti.ni)
                               and (versamenti.pratica is null)
                               and (versamenti.tipo_tributo = :p_tiptrib)
                               and ((versamenti.cod_fiscale like :p_codfis) and
                                   (versamenti.anno = :p_anno))
                               and :p_anno >= 2012
                             group by versamenti.anno,
                                      translate(soggetti.cognome_nome, '/', ' '),
                                      soggetti.cognome,
                                      soggetti.nome,
                                      versamenti.cod_fiscale
                            having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) + :p_scarto)) or abs(nvl(sum(versamenti.terreni_agricoli), 0) - (nvl(sum(versamenti.terreni_comune), 0) + nvl(sum(versamenti.terreni_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.aree_fabbricabili), 0) - (nvl(sum(versamenti.aree_comune), 0) + nvl(sum(versamenti.aree_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.rurali), 0) - (nvl(sum(versamenti.rurali_comune), 0) + nvl(sum(versamenti.rurali_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.altri_fabbricati), 0) - (nvl(sum(versamenti.altri_comune), 0) + nvl(sum(versamenti.altri_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.fabbricati_d), 0) - (nvl(sum(versamenti.fabbricati_d_comune), 0) + nvl(sum(versamenti.fabbricati_d_erariale), 0))) > :p_scarto
                          """

        def queryTasi = """
                        select versamenti.anno,
                               translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                               versamenti.cod_fiscale,
                               sum(versamenti.importo_versato) versato,
                               sum(versamenti.terreni_agricoli) terreni_agricoli,
                               sum(versamenti.aree_fabbricabili) aree_fabbricabili,
                               sum(versamenti.ab_principale) ab_principale,
                               sum(versamenti.altri_fabbricati) altri_fabbricati,
                               f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                       sum(nvl(versamenti.ab_principale, 0)) +
                                       sum(nvl(versamenti.altri_fabbricati, 0)) +
                                       sum(nvl(versamenti.rurali, 0)),
                                       1) somma,
                               upper(replace(soggetti.cognome, ' ', '')) cognome,
                               upper(replace(soggetti.nome, ' ', '')) nome,
                               sum(versamenti.rurali) rurali,
                               sum(versamenti.fabbricati_d) fabbricati_d
                          from versamenti, contribuenti, soggetti
                         where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                           and (contribuenti.ni = soggetti.ni)
                           and (versamenti.pratica is null)
                           and (versamenti.tipo_tributo = :p_tiptrib)
                           and ((versamenti.cod_fiscale like :p_codfis) and
                               (versamenti.anno = :p_anno))
                           and :p_anno < 2012
                         group by versamenti.anno,
                                  translate(soggetti.cognome_nome, '/', ' '),
                                  soggetti.cognome,
                                  soggetti.nome,
                                  versamenti.cod_fiscale
                        having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) + :p_scarto))
                        union all
                        select versamenti.anno,
                               translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                               versamenti.cod_fiscale,
                               sum(versamenti.importo_versato) versato,
                               sum(versamenti.terreni_agricoli) terreni_agricoli,
                               sum(versamenti.aree_fabbricabili) aree_fabbricabili,
                               sum(versamenti.ab_principale) ab_principale,
                               sum(versamenti.altri_fabbricati) altri_fabbricati,
                               f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                       sum(nvl(versamenti.ab_principale, 0)) +
                                       sum(nvl(versamenti.altri_fabbricati, 0)) +
                                       sum(nvl(versamenti.rurali, 0)),
                                       1) somma,
                               upper(replace(soggetti.cognome, ' ', '')) cognome,
                               upper(replace(soggetti.nome, ' ', '')) nome,
                               sum(versamenti.rurali) rurali,
                               sum(versamenti.fabbricati_d) fabbricati_d
                          from versamenti, contribuenti, soggetti
                         where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                           and (contribuenti.ni = soggetti.ni)
                           and (versamenti.pratica is null)
                           and (versamenti.tipo_tributo = :p_tiptrib)
                           and ((versamenti.cod_fiscale like :p_codfis) and
                               (versamenti.anno = :p_anno))
                           and :p_anno >= 2012
                         group by versamenti.anno,
                                  translate(soggetti.cognome_nome, '/', ' '),
                                  soggetti.cognome,
                                  soggetti.nome,
                                  versamenti.cod_fiscale
                        having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) + :p_scarto))
                        
                         order by 1, 2, 3
                        """

        def sqlOrdTotale = """
                            select * 
                            from (${tipoTributo == 'ICI' ? queryImu : queryTasi})
                            ${queryOrdinamento}
                           """

        return sessionFactory.currentSession.createSQLQuery(sqlOrdTotale).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }


    def getListaSquadraturaTotaleSecondaPagina(def tipoTributo, def codFiscale, def anno, def scarto, def ordinamento) {

        def parametri = [:]

        parametri << ["p_tiptrib": tipoTributo]
        parametri << ["p_codfis": codFiscale ?: '%']
        parametri << ["p_anno": anno]
        parametri << ["p_scarto": scarto != null ? scarto : 0]


        def queryImu = """
                           select anno,
                               sum(versato) versato,
                               sum(versato_altri_comu) versato_altri_comu,
                               sum(versato_fabb_d_comu) versato_fabb_d_comu,
                               sum(versato_terreni_comu) versato_terreni_comu,
                               sum(versato_aree_comu) versato_aree_comu,
                               sum(versato_ab_comu) versato_ab_comu,
                               sum(versato_rurali_comu) versato_rurali_comu,
                               sum(versato_fabb_merce_comu) versato_fabb_merce_comu,
                               sum(versato_altri_erar) versato_altri_erar,
                               sum(versato_fabb_d_erar) versato_fabb_d_erar,
                               sum(versato_terreni_erar) versato_terreni_erar,
                               sum(versato_aree_erar) versato_aree_erar,
                               sum(versato_terreni_agricoli) versato_terreni_agricoli,
                               sum(versato_aree_fabbricabili) versato_aree_fabbricabili,
                               sum(versato_ab_principale) versato_ab_principale,
                               sum(versato_altri_fabbricati) versato_altri_fabbricati,
                               sum(versato_fabbricati_d) versato_fabbricati_d,
                               sum(versato_rurali) versato_rurali,
                               sum(versato_fabbricati_merce) versato_fabbricati_merce
                          from (select versamenti.anno,
                                       translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                                       versamenti.cod_fiscale,
                                       sum(versamenti.importo_versato) versato,
                                       sum(versamenti.altri_comune) versato_altri_comu,
                                       sum(versamenti.fabbricati_d_comune) versato_fabb_d_comu,
                                       sum(versamenti.terreni_comune) versato_terreni_comu,
                                       sum(versamenti.aree_comune) versato_aree_comu,
                                       sum(versamenti.ab_principale) versato_ab_comu,
                                       sum(versamenti.rurali_comune) versato_rurali_comu,
                                       sum(versamenti.fabbricati_merce) versato_fabb_merce_comu,
                                       sum(versamenti.altri_erariale) versato_altri_erar,
                                       sum(versamenti.fabbricati_d_erariale) versato_fabb_d_erar,
                                       sum(versamenti.terreni_erariale) versato_terreni_erar,
                                       sum(versamenti.aree_erariale) versato_aree_erar,
                                       sum(nvl(versamenti.terreni_agricoli, 0)) versato_terreni_agricoli,
                                       sum(nvl(versamenti.aree_fabbricabili, 0)) versato_aree_fabbricabili,
                                       sum(nvl(versamenti.ab_principale, 0)) versato_ab_principale,
                                       sum(nvl(versamenti.altri_fabbricati, 0)) versato_altri_fabbricati,
                                       sum(nvl(versamenti.fabbricati_d, 0)) versato_fabbricati_d,
                                       sum(nvl(versamenti.rurali, 0)) versato_rurali,
                                       sum(nvl(versamenti.fabbricati_merce, 0)) versato_fabbricati_merce,
                                       f_round(sum(nvl(versamenti.terreni_agricoli, 0)) +
                                               sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                               sum(nvl(versamenti.ab_principale, 0)) +
                                               sum(nvl(versamenti.altri_fabbricati, 0)) +
                                               sum(nvl(versamenti.fabbricati_d, 0)) +
                                               sum(nvl(versamenti.rurali, 0)) +
                                               sum(nvl(versamenti.fabbricati_merce, 0)),
                                               1) somma,
                                       upper(replace(soggetti.cognome, ' ', '')) cognome,
                                       upper(replace(soggetti.nome, ' ', '')) nome
                                  from versamenti, contribuenti, soggetti
                                 where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                                   and (contribuenti.ni = soggetti.ni)
                                   and (versamenti.pratica is null)
                                   and (versamenti.tipo_tributo = :p_tiptrib)
                                   and ((versamenti.cod_fiscale like :p_codfis) and
                                       (versamenti.anno = :p_anno))
                                   and :p_anno >= 2012
                                 group by versamenti.anno,
                                          translate(soggetti.cognome_nome, '/', ' '),
                                          soggetti.cognome,
                                          soggetti.nome,
                                          versamenti.cod_fiscale
                                having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.terreni_agricoli, 0)) + sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.fabbricati_d, 0)) + sum(nvl(versamenti.rurali, 0)) + sum(nvl(versamenti.fabbricati_merce, 0)), 1)) + :p_scarto)) or abs(nvl(sum(versamenti.terreni_agricoli), 0) - (nvl(sum(versamenti.terreni_comune), 0) + nvl(sum(versamenti.terreni_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.aree_fabbricabili), 0) - (nvl(sum(versamenti.aree_comune), 0) + nvl(sum(versamenti.aree_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.rurali), 0) - (nvl(sum(versamenti.rurali_comune), 0) + nvl(sum(versamenti.rurali_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.altri_fabbricati), 0) - (nvl(sum(versamenti.altri_comune), 0) + nvl(sum(versamenti.altri_erariale), 0))) > :p_scarto or abs(nvl(sum(versamenti.fabbricati_d), 0) - (nvl(sum(versamenti.fabbricati_d_comune), 0) + nvl(sum(versamenti.fabbricati_d_erariale), 0))) > :p_scarto) vers
                         group by anno
                           """


        def queryTasi = """
                            select anno,
                                   sum(versato) versato,
                                   sum(versato_altri_comu) versato_altri_comu,
                                   sum(versato_fabb_d_comu) versato_fabb_d_comu,
                                   sum(versato_terreni_comu) versato_terreni_comu,
                                   sum(versato_aree_comu) versato_aree_comu,
                                   sum(versato_ab_comu) versato_ab_comu,
                                   sum(versato_rurali_comu) versato_rurali_comu,
                                   sum(versato_altri_erar) versato_altri_erar,
                                   sum(versato_fabb_d_erar) versato_fabb_d_erar,
                                   sum(versato_terreni_erar) versato_terreni_erar,
                                   sum(versato_aree_erar) versato_aree_erar,
                                   sum(versato_terreni_agricoli) versato_terreni_agricoli,
                                   sum(versato_aree_fabbricabili) versato_aree_fabbricabili,
                                   sum(versato_ab_principale) versato_ab_principale,
                                   sum(versato_altri_fabbricati) versato_altri_fabbricati,
                                   sum(versato_fabbricati_d) versato_fabbricati_d,
                                   sum(versato_rurali) versato_rurali
                              from (select versamenti.anno,
                                           translate(soggetti.cognome_nome, '/', ' ') cog_nom,
                                           versamenti.cod_fiscale,
                                           sum(versamenti.importo_versato) versato,
                                           sum(versamenti.altri_comune) versato_altri_comu,
                                           sum(versamenti.fabbricati_d_comune) versato_fabb_d_comu,
                                           sum(versamenti.terreni_comune) versato_terreni_comu,
                                           sum(versamenti.aree_comune) versato_aree_comu,
                                           sum(versamenti.ab_principale) versato_ab_comu,
                                           sum(versamenti.rurali) versato_rurali_comu,
                                           sum(versamenti.altri_erariale) versato_altri_erar,
                                           sum(versamenti.fabbricati_d_erariale) versato_fabb_d_erar,
                                           sum(versamenti.terreni_erariale) versato_terreni_erar,
                                           sum(versamenti.aree_erariale) versato_aree_erar,
                                           sum(nvl(versamenti.terreni_agricoli, 0)) versato_terreni_agricoli,
                                           sum(nvl(versamenti.aree_fabbricabili, 0)) versato_aree_fabbricabili,
                                           sum(nvl(versamenti.ab_principale, 0)) versato_ab_principale,
                                           sum(nvl(versamenti.altri_fabbricati, 0)) versato_altri_fabbricati,
                                           sum(nvl(versamenti.fabbricati_d, 0)) versato_fabbricati_d,
                                           sum(nvl(versamenti.rurali, 0)) versato_rurali,
                                           f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) +
                                                   sum(nvl(versamenti.ab_principale, 0)) +
                                                   sum(nvl(versamenti.altri_fabbricati, 0)) +
                                                   sum(nvl(versamenti.rurali, 0)),
                                                   1) somma,
                                           upper(replace(soggetti.cognome, ' ', '')) cognome,
                                           upper(replace(soggetti.nome, ' ', '')) nome
                                      from versamenti, contribuenti, soggetti
                                     where (versamenti.cod_fiscale = contribuenti.cod_fiscale)
                                       and (contribuenti.ni = soggetti.ni)
                                       and (versamenti.pratica is null)
                                       and (versamenti.tipo_tributo = :p_tiptrib)
                                       and ((versamenti.cod_fiscale like :p_codfis) and
                                           (versamenti.anno = :p_anno))
                                       and :p_anno >= 2012
                                     group by versamenti.anno,
                                              translate(soggetti.cognome_nome, '/', ' '),
                                              soggetti.cognome,
                                              soggetti.nome,
                                              versamenti.cod_fiscale
                                    having(sum(versamenti.importo_versato) < ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) - :p_scarto)) or (sum(versamenti.importo_versato) > ((f_round(sum(nvl(versamenti.aree_fabbricabili, 0)) + sum(nvl(versamenti.ab_principale, 0)) + sum(nvl(versamenti.altri_fabbricati, 0)) + sum(nvl(versamenti.rurali, 0)), 1)) + :p_scarto))) vers
                             group by anno
                        """

        return sessionFactory.currentSession.createSQLQuery(tipoTributo == 'ICI' ? queryImu : queryTasi).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def getListaTotaleVersamentiPrimaPagina(def tipoTributo, def anno) {

        def parametri = [:]

        parametri << ["p_tiptrib": tipoTributo]
        parametri << ["p_anno": anno]


        def query = """
                            SELECT 'A' tipo,
                                   vers.tipo_versamento,
                                   sum(nvl(vers.terreni_agricoli, 0)) terreni_agricoli,
                                   sum(nvl(vers.aree_fabbricabili, 0)) aree_fabbricabili,
                                   sum(nvl(vers.ab_principale, 0)) ab_principali,
                                   sum(nvl(vers.altri_fabbricati, 0)) altri_fabbricati,
                                   sum(nvl(vers.fabbricati_d, 0)) fabbricati_d,
                                   sum(nvl(vers.rurali, 0)) rurali,
                                   sum(nvl(vers.fabbricati_merce, 0)) fabbricati_merce,
                                   sum(nvl(vers.detrazione, 0)) detrazioni,
                                   sum(nvl(vers.importo_versato, 0)) importi_versati,
                                   count(1) num_versamenti
                              FROM versamenti vers
                             WHERE vers.anno = :p_anno
                               AND vers.tipo_tributo = :p_tiptrib
                             GROUP BY vers.tipo_versamento
                            
                            UNION
                            
                            SELECT 'B' tipo,
                                   decode(aver.acconto_saldo, 1, 'Acconto', 2, 'Saldo', 'Unico'),
                                   sum(nvl(aver.terreni_agricoli, 0) /
                                       decode(dage.fase_euro, 1, 1, 100)) terreni_agricoli,
                                   sum(nvl(aver.aree_fabbricabili, 0) /
                                       decode(dage.fase_euro, 1, 1, 100)) aree_fabbricabili,
                                   sum(nvl(aver.ab_principale, 0) / decode(dage.fase_euro, 1, 1, 100)) ab_principali,
                                   sum(nvl(aver.altri_fabbricati, 0) /
                                       decode(dage.fase_euro, 1, 1, 100)) altri_fabbricati,
                                   0 fabbricati_d,
                                   0 rurali,
                                   0 fabbricati_merce,
                                   sum(nvl(aver.detrazione, 0) / decode(dage.fase_euro, 1, 1, 100)) detrazioni,
                                   sum(nvl(aver.importo_versato, 0) / decode(dage.fase_euro, 1, 1, 100)) importi_versati,
                                   count(1) num_versamenti
                              FROM dati_generali dage, anci_ver aver
                             WHERE aver.anno_fiscale = :p_anno
                               AND aver.tipo_anomalia is not null
                             GROUP BY decode(aver.acconto_saldo, 1, 'Acconto', 2, 'Saldo', 'Unico')
                            
                            UNION
                            
                            SELECT 'B1' tipo,
                                   '',
                                   0 terreni_agricoli,
                                   0 aree_fabbricabili,
                                   0 ab_principali,
                                   0 altri_fabbricati,
                                   0 fabbricati_d,
                                   0 rurali,
                                   0 fabbricati_merce,
                                   0 detrazioni,
                                   0 importi_versati,
                                   0 num_versamenti
                              FROM dual
                             WHERE :p_anno < 2012
                               AND NOT EXISTS (SELECT 1
                                      FROM dati_generali dage, anci_ver aver
                                     WHERE aver.anno_fiscale = :p_anno
                                       AND aver.tipo_anomalia is not null)
                            
                            UNION
                            
                            SELECT 'C' tipo,
                                   decode(wver.tipo_versamento, 'A', 'Acconto', 'S', 'Saldo', 'Unico'),
                                   sum(nvl(wver.terreni_agricoli, 0)) terreni_agricoli,
                                   sum(nvl(wver.aree_fabbricabili, 0)) aree_fabbricabili,
                                   sum(nvl(wver.ab_principale, 0)) ab_principali,
                                   sum(nvl(wver.altri_fabbricati, 0)) altri_fabbricati,
                                   sum(nvl(wver.fabbricati_d, 0)) fabbricati_d,
                                   sum(nvl(wver.rurali, 0)) rurali,
                                   sum(nvl(wver.fabbricati_merce, 0)) fabbricati_merce,
                                   sum(nvl(wver.detrazione, 0)) detrazioni,
                                   sum(nvl(wver.importo_versato, 0)) importi_versati,
                                   count(1) num_versamenti
                              FROM dati_generali dage, wrk_versamenti wver
                             WHERE wver.anno = :p_anno
                               AND wver.tipo_tributo = :p_tiptrib
                               AND wver.tipo_incasso = 'F24'
                             GROUP BY decode(wver.tipo_versamento,
                                             'A',
                                             'Acconto',
                                             'S',
                                             'Saldo',
                                             'Unico')
                            
                            UNION
                            
                            SELECT 'C1' tipo,
                                   null,
                                   0 terreni_agricoli,
                                   0 aree_fabbricabili,
                                   0 ab_principali,
                                   0 altri_fabbricati,
                                   0 fabbricati_d,
                                   0 rurali,
                                   0 fabbricati_merce,
                                   0 detrazioni,
                                   0 importi_versati,
                                   0 num_versamenti
                              FROM dual
                             WHERE NOT EXISTS (SELECT 1
                                      FROM dati_generali dage, wrk_versamenti wver
                                     WHERE wver.anno = :p_anno
                                       AND wver.tipo_tributo = :p_tiptrib
                                       AND wver.tipo_incasso = 'F24')
                    """

        def lista = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        lista.each {
            it.somma = (it.areeFabbricabili ?: 0) + (it.abPrincipali ?: 0) + (it.rurali ?: 0) + (it.altriFabbricati ?: 0)
            if (tipoTributo == 'ICI') {
                it.somma += ((it.terreniAgricoli ?: 0) + (it.fabbricatiD ?: 0) + (it.fabbricatiMerce ?: 0))
            }
            it.tipoVersamentoDesc = it.tipoVersamento == "A" ? "Acconto" : (it.tipoVersamento == "S" ? "Saldo" : (it.tipoVersamento == "U" ? "Unico" : it.tipoVersamento))
        }

        return lista

    }

    def getListaTotaleVersamentiSecondaPagina(def tipoTributo, def anno) {

        def parametri = [:]

        parametri << ["p_anno": anno]

        def queryImu = """
                            select sum(deim.altri_comu) dovuto_altri_comu,sum(deim.vers_altri_comu) versato_altri_comu,
                                   sum(deim.fabb_d_comu) dovuto_fabb_d_comu,sum(deim.vers_fab_d_comu) versato_fabb_d_comu,
                                   sum(deim.terreni_comu) dovuto_terreni_comu,sum(deim.vers_terreni_comu) versato_terreni_comu,
                                   sum(deim.aree_comu) dovuto_aree_comu,sum(deim.vers_aree_comu) versato_aree_comu,
                                   sum(deim.ab_comu) dovuto_ab_comu,sum(deim.vers_ab_princ) versato_ab_comu,
                                   sum(deim.rurali_comu) dovuto_rurali_comu,sum(deim.vers_rurali) versato_rurali_comu,
                                   sum(deim.altri_erar) dovuto_altri_erar,sum(deim.vers_altri_erar) versato_altri_erar,
                                   sum(deim.fabb_d_erar) dovuto_fabb_d_erar,sum(deim.vers_fab_d_erar) versato_fabb_d_erar,
                                   sum(deim.terreni_erar) dovuto_terreni_erar,sum(deim.vers_terreni_erar) versato_terreni_erar,
                                   sum(deim.aree_erar) dovuto_aree_erar,sum(deim.vers_aree_erar) versato_aree_erar,
                                   sum(deim.fabb_merce_comu) dovuto_fabb_merce_comu,sum(deim.vers_fab_merce) versato_fabb_merce_comu,
                                   decode(sum(deim.imposta_comu),0,to_number(null),sum(deim.imposta_comu)) tot_dovuto_comu,
                                   decode(sum(deim.versamenti_comu),0,to_number(null),sum(deim.versamenti_comu)) tot_versato_comu,
                                   decode(sum(deim.imposta_comu),0,to_number(null),sum(deim.imposta_comu - deim.versamenti_comu)) totale_comu,
                                   decode(sum(deim.imposta_erar),0,to_number(null),sum(deim.imposta_erar)) tot_dovuto_erar,
                                   decode(sum(deim.versamenti_erar),0,to_number(null),sum(deim.versamenti_erar)) tot_versato_erar,
                                   decode(sum(deim.imposta_erar),0,to_number(null),sum(deim.imposta_erar - deim.versamenti_erar)) tot_erar,
                                   decode(sum(deim.imposta_comu + deim.imposta_erar),0,to_number(null),sum(deim.imposta_comu + deim.imposta_erar)) tot_dovuto,
                                   decode(sum(deim.versamenti_comu + deim.versamenti_erar),0,to_number(null),sum(deim.versamenti_comu + deim.versamenti_erar)) tot_versato,
                                   decode(sum(deim.imposta_comu + deim.imposta_erar),0,to_number(null),
                                          sum(deim.imposta_comu + deim.imposta_erar - deim.versamenti_comu - deim.versamenti_erar)) tot_tot
                            from   dettagli_imu deim
                            where  deim.anno = :p_anno
                    """

        def queryTasi = """
                        select sum(dtsi.altri_comu) dovuto_altri_comu,sum(dtsi.vers_altri_comu) versato_altri_comu,
                               sum(dtsi.fabb_d_comu) dovuto_fabb_d_comu,sum(dtsi.vers_fab_d_comu) versato_fabb_d_comu,
                               sum(dtsi.terreni_comu) dovuto_terreni_comu,sum(dtsi.vers_terreni_comu) versato_terreni_comu,
                               sum(dtsi.aree_comu) dovuto_aree_comu,sum(dtsi.vers_aree_comu) versato_aree_comu,
                               sum(dtsi.ab_comu) dovuto_ab_comu,sum(dtsi.vers_ab_princ) versato_ab_comu,
                               sum(dtsi.rurali_comu) dovuto_rurali_comu,sum(dtsi.vers_rurali) versato_rurali_comu,
                               sum(dtsi.altri_erar) dovuto_altri_erar,sum(dtsi.vers_altri_erar) versato_altri_erar,
                               sum(dtsi.fabb_d_erar) dovuto_fabb_d_erar,sum(dtsi.vers_fab_d_erar) versato_fabb_d_erar,
                               sum(dtsi.terreni_erar) dovuto_terreni_erar,sum(dtsi.vers_terreni_erar) versato_terreni_erar,
                               sum(dtsi.aree_erar) dovuto_aree_erar,sum(dtsi.vers_aree_erar) versato_aree_erar
                        from   dettagli_tasi dtsi
                        where  dtsi.anno = :p_anno
                        """

        return sessionFactory.currentSession.createSQLQuery(tipoTributo == "ICI" ? queryImu : queryTasi).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }


    def getListaTotaleVersamentiPerGiorno(def tipoTributo, def da, def a, ordinamento) {

        def parametri = [:]

        parametri << ["p_tipo_trib": tipoTributo]
        parametri << ["p_data_da": da]
        parametri << ["p_data_a": a]

        def filtroTipo = ""

        if (ordinamento && ordinamento == "temp") {
            filtroTipo += " and oggetti_pratica.tipo_occupazione = 'T' "
        } else if (ordinamento && ordinamento == "perm") {
            filtroTipo += " and oggetti_pratica.tipo_occupazione = 'P' "
        }

        def query = """
                          select VERSAMENTI.data_pagamento,
                                VERSAMENTI.importo_versato,
                              to_char(:p_data_da,'DD/MM/YYYY') data1,
                                to_char(:p_data_a,'DD/MM/YYYY') data2,  
                              decode(oggetti_pratica.tipo_occupazione,'P','PERMANENTE',
                                decode(oggetti_pratica.tipo_occupazione,'T','TEMPORANEA','')) tipo_occupazione
                           FROM PRATICHE_TRIBUTO,
                              OGGETTI_PRATICA,   
                              OGGETTI_IMPOSTA,
                              VERSAMENTI    
                          WHERE PRATICHE_TRIBUTO.PRATICA = OGGETTI_PRATICA.PRATICA and  
                              OGGETTI_PRATICA.OGGETTO_PRATICA = OGGETTI_IMPOSTA.OGGETTO_PRATICA and
                              OGGETTI_IMPOSTA.OGGETTO_IMPOSTA = VERSAMENTI.OGGETTO_IMPOSTA (+) and
                              PRATICHE_TRIBUTO.TIPO_PRATICA||'' = 'D' and  
                              PRATICHE_TRIBUTO.TIPO_TRIBUTO||'' = :p_tipo_trib and
                              OGGETTI_IMPOSTA.RUOLO IS NULL and
                              VERSAMENTI.data_pagamento between :p_data_da and :p_data_a 
                              ${filtroTipo}
                           UNION 
                          select VERSAMENTI.data_pagamento,
                                VERSAMENTI.importo_versato,
                              to_char(:p_data_da,'DD/MM/YYYY') data1,
                                to_char(:p_data_a,'DD/MM/YYYY') data2,  
                              decode(oggetti_pratica.tipo_occupazione,'P','PERMANENTE',
                                decode(oggetti_pratica.tipo_occupazione,'T','TEMPORANEA','')) tipo_occupazione
                           FROM PRATICHE_TRIBUTO,
                              OGGETTI_PRATICA,   
                              OGGETTI_IMPOSTA,
                              VERSAMENTI    
                          WHERE PRATICHE_TRIBUTO.PRATICA = OGGETTI_PRATICA.PRATICA and  
                              OGGETTI_PRATICA.OGGETTO_PRATICA = OGGETTI_IMPOSTA.OGGETTO_PRATICA and 
                              PRATICHE_TRIBUTO.PRATICA = VERSAMENTI.PRATICA and
                              PRATICHE_TRIBUTO.TIPO_PRATICA||'' IN ('A','I','L') and 
                              PRATICHE_TRIBUTO.TIPO_TRIBUTO||'' = :p_tipo_trib and
                              OGGETTI_IMPOSTA.RUOLO IS NULL and
                              VERSAMENTI.data_pagamento between :p_data_da and :p_data_a 
                              ${filtroTipo}
                        --  ORDER BY 1 ASC, 5 ASC
                    """


        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

    }

}
