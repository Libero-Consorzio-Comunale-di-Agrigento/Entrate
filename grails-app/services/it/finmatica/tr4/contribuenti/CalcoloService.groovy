package it.finmatica.tr4.contribuenti

import grails.plugins.springsecurity.SpringSecurityService
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.ContattoContribuenteDTO
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.OggettoImpostaDTO
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import org.hibernate.criterion.CriteriaSpecification

import java.text.SimpleDateFormat

@Transactional
class CalcoloService {

    final Map descrizioneCodiciTributo = [
            "ICI" : [
                    'TERRENO'                : ["3914 - Comune", "3915 - Stato"]
                    , 'AREA'                 : ["3916 - Comune", "3917 - Stato"]
                    , 'ABITAZIONE_PRINCIPALE': ["3912 - Comune", ""]
                    , 'ALTRO_FABBRICATO'     : ["3918 - Comune", "3919 - Stato"]
                    , 'RURALE'               : ["3913 - Comune", ""]
                    , 'FABBRICATO_D'         : ["3930 - Comune", "3925 - Stato"]
            ],
            "TASI": [
                    'TERRENO'                : ["", ""]
                    , 'AREA'                 : ["3960 - Comune", ""]
                    , 'ABITAZIONE_PRINCIPALE': ["3958 - Comune", ""]
                    , 'ALTRO_FABBRICATO'     : ["3961 - Comune", ""]
                    , 'RURALE'               : ["3959 - Comune", ""]
                    , 'FABBRICATO_D'         : ["", ""]
            ],
    ]

    def dataSource
    SpringSecurityService springSecurityService
    CommonService commonService
    def sessionFactory
    def propertyInstanceMap = org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP

    def caricaPraticaK(String pTipoTributo, String pCodFiscale, Short pAnno,
                       def pEnte, def pUtente) {
        def r
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_web_carica_pratica_k(?, ?, ?, ?, ?)}'
                , [
                Sql.DECIMAL,
                pTipoTributo,
                pCodFiscale,
                pAnno,
                pUtente.id,
                'WEB'
        ]) { r = it }

        return r
    }

    def ripristinaPraticaK(String pTitr, Short pAnno,
                           Date pData, String codFiscale, PraticaTributoDTO pratica,
                           Object oggettiImposta, boolean creaContatto) {
        //cancellaPratica(pratica)
        long idPraticaNuova = caricaPraticaK(pTitr, codFiscale,
                pAnno, springSecurityService.principal.amministrazione,
                springSecurityService.currentUser)
        PraticaTributo p = PraticaTributo.createCriteria().get {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente", "ogco", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggettiContribuente.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggetto.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            eq("id", idPraticaNuova)
        }
        if (!p) {
            p = PraticaTributo.createCriteria().get {
                eq("id", idPraticaNuova)
            }
        }

        PraticaTributoDTO pDTO = p.toDTO(["oggettiPratica"
                                          , "oggettiPratica.oggettiContribuente"
                                          , "oggettiPratica.oggettiContribuente.oggettiImposta"
                                          , "oggettiPratica.oggettiContribuente.oggettiImposta.tipoAliquota"
                                          , "oggettiPratica.oggetto"
                                          , "oggettiPratica.oggetto.archivioVie"
                                          , "oggettiPratica.oggetto.riferimentiOggetto"])
        //restituisco una lista degli ogim della pratica (potebbe anche essere vuota)
        List<OggettoImpostaDTO> ogim = pDTO.oggettiPratica?.oggettiContribuente.oggettiImposta.flatten().sort {
            ((it.oggettoContribuente.flagAbPrincipale ? "A" : "Z")
                    + (it.oggettoContribuente.oggettoPratica.oggetto.sezionePadded ?: ("Z".padLeft(3, "Z")))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.foglioPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.numeroPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.subalternoPadded ?: "Z".padLeft(4, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.zonaPadded ?: "Z".padLeft(3, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.partitaPadded ?: "Z".padLeft(8, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto.toString().padLeft(2, "0"))
                    + (it.oggettoContribuente.oggettoPratica.numOrdine))
        }
        return [pratica: pDTO, data: null, listaOggetti: ogim]
    }

    def esistePraticaK(String pTitr, Short pAnno, SoggettoDTO pSoggetto) {
        PraticaTributo p = PraticaTributo.createCriteria().get {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente.oggettiImposta", "ogim", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggetto.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            eq("contribuente.codFiscale", pSoggetto.contribuente.codFiscale)
            eq("tipoTributo.tipoTributo", pTitr)
            eq("anno", pAnno)
            eq("tipoPratica", "K")
            ne("utente", "WEB")
        }

        if (!p) {
            PraticaTributo.createCriteria().get {
                eq("contribuente.codFiscale", pSoggetto.contribuente.codFiscale)
                eq("tipoTributo.tipoTributo", pTitr)
                eq("anno", pAnno)
                eq("tipoPratica", "K")
                ne("utente", "WEB")
            }
        }

        return p
    }

    def recuperaUltimoContatto(String pTitr, Short pAnno, String codFiscale) {
        ContattoContribuente contatto = ContattoContribuente.createCriteria().list {
            eq("tipoContatto.tipoContatto", 4)
            eq("tipoTributo.tipoTributo", pTitr)
            eq("anno", pAnno)
            eq("contribuente.codFiscale", codFiscale)

            order("sequenza", "desc")
        }[0]
    }

    def lanciaCaricaPraticaK(String pTitr, Short pAnno,
                             Date pData, SoggettoDTO pSoggetto, PraticaTributoDTO pratica,
                             Object oggettiImposta, boolean creaContatto) {
        Date dataCoco
        PraticaTributo p

        try {

            // Se non è richiesta la creazione del contatto si sgancia l'ultimo se presente.
            if (creaContatto) {
                p = esistePraticaK(pTitr, pAnno, pSoggetto)
            } else {
                //annullaPraticaContatto(esistePraticaK(pTitr, pAnno, pSoggetto).toDTO())
                def coco = recuperaUltimoContatto(pTitr, pAnno, pSoggetto.contribuente.codFiscale)
                if (coco) {
                    coco.pratica = null
                    coco.save(flush: true, failOnError: true)
                }
            }

            //se non c'è una pratica K esistente, o se lavoro senza creare contatti
            //(cioè voglio una pratica nuova)
            //la crea con caricaPraticaK e poi la prende con il createCriteria
            //in modo da avere anche gli oggetti figli disponibili per il DTO
            if (!p) {
                long idPraticaNuova = caricaPraticaK(pTitr, pSoggetto.contribuente.codFiscale,
                        pAnno, springSecurityService.principal.amministrazione,
                        springSecurityService.currentUser)
                p = PraticaTributo.createCriteria().get {
                    createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggettiPratica.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggettiPratica.oggettiContribuente.oggettiImposta", "ogim", CriteriaSpecification.LEFT_JOIN)
                    createAlias("oggettiPratica.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggettiPratica.oggetto.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
                    createAlias("oggettiPratica.oggetto.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
                    eq("id", idPraticaNuova)
                }

                if (!p) {
                    p = PraticaTributo.createCriteria().get {
                        eq("id", idPraticaNuova)
                    }
                }
            } else {

                // Per le vecchie pratiche create da TR4 non è presente un'associazione tra pratica e contatto.
                // Si recupera l'ultimo contatto presente e si associa.
                if (creaContatto) {
                    if (!p.contattoContribuente) {
                        ContattoContribuente contatto = recuperaUltimoContatto(pTitr, pAnno, pSoggetto.contribuente.codFiscale)
                        if (contatto) {
                            contatto.pratica = p
                            contatto.save(flush: true, failOnError: true)

                            p.contattiContribuente << contatto
                        }
                    }

                    dataCoco = p?.contattoContribuente?.data
                }
            }
            //creo il DTO caricando anche gli oggetti figli
            PraticaTributoDTO pDTO = p.toDTO(["oggettiPratica"
                                              , "oggettiPratica.oggettiContribuente"
                                              , "oggettiPratica.oggettiContribuente.oggettiImposta"
                                              , "oggettiPratica.oggettiContribuente.oggettiImposta.tipoAliquota"
                                              , "oggettiPratica.oggetto"
                                              , "oggettiPratica.oggetto.archivioVie"
                                              , "oggettiPratica.oggetto.riferimentiOggetto"])

            //restituisco una lista degli ogim della pratica (potebbe anche essere vuota)
            List<OggettoImpostaDTO> ogim = pDTO.oggettiPratica?.oggettiContribuente.oggettiImposta.flatten().sort {
                ((it.oggettoContribuente.flagAbPrincipale ? "A" : "Z")
                        + (it.oggettoContribuente.oggettoPratica.oggetto.sezionePadded ?: ("Z".padLeft(3, "Z")))
                        + (it.oggettoContribuente.oggettoPratica.oggetto.foglioPadded ?: "Z".padLeft(5, "Z"))
                        + (it.oggettoContribuente.oggettoPratica.oggetto.numeroPadded ?: "Z".padLeft(5, "Z"))
                        + (it.oggettoContribuente.oggettoPratica.oggetto.subalternoPadded ?: "Z".padLeft(4, "Z"))
                        + (it.oggettoContribuente.oggettoPratica.oggetto.zonaPadded ?: "Z".padLeft(3, "Z"))
                        + (it.oggettoContribuente.oggettoPratica.oggetto.partitaPadded ?: "Z".padLeft(8, "Z"))
                        + (it.oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto.toString().padLeft(2, "0"))
                        + (it.oggettoContribuente.oggettoPratica.numOrdine))
            }
			
			bonificaValoreOggettiPraticaK(ogim)
			
            return [pratica: pDTO, data: dataCoco, listaOggetti: ogim]

        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }
							 
	 ///
	 /// per coerenza di interfaccia grafica svuota il valore (rendita) del'oggeto pratica pratia K dove non richiesto
	 ///
	 def bonificaValoreOggettiPraticaK(List ogImPraticaK)  {
	 
		 ogImPraticaK.each {
			 if((it.oggettoContribuente.oggettoPratica.valore ?: 0.0) == 0.0) {
				 if(!richiedeRenditaOgPr(it.oggettoContribuente.oggettoPratica)) {
					 it.oggettoContribuente.oggettoPratica.valore = null
				 }
			 }
		 }
	 }
						 
	///
	/// Restituisce true se l'oggetto_pratica richiede una rendita
	///						 
	def richiedeRenditaOgPr(def ogpr) {
		
		 def ogge = ogpr.oggetto
		 
		 long tipoOgg = ogpr.tipoOggetto?.tipoOggetto ?: ogge.tipoOggetto.tipoOggetto ?: 3
		 String catOgg = ogpr?.categoriaCatasto?.categoriaCatasto ?: '-'
		 String catOggT = catOgg.substring(0,1)
		 
		 if((tipoOgg == 1) || ((tipoOgg == 3) && (catOggT in ['E','F']))) {
		 	return false
		 }
		 return true
	}

    @NotTransactional
    def dettagliPraticaKPerTabella(PraticaTributo pratica, Object oggetto, Object categoriaCatasto) {
        def lista = OggettoPratica.createCriteria().list {
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("ogco.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)
            createAlias("ogim.tipoAliquota", "tial", CriteriaSpecification.INNER_JOIN)

            eq("prtr.id", pratica.id)
            eq("ogge.id", oggetto)
            eqProperty("prtr.contribuente", "ogco.contribuente")

            projections {
                property("ogge.id")                        // 0
                property("categoriaCatasto")            // 1
                property("ogim.id")                        // 2
                property("id")                            // 3
                property("tipoOggetto")                    // 4
                property("ogge.tipoOggetto")            // 5
                property("oggettoPraticaRifAp")            // 6
                property("ogco.flagAbPrincipale")        // 7
                property("ogim.imposta")                // 8
                property("ogim.impostaAcconto")            // 9
                property("ogim.detrazione")                // 10
                property("ogim.detrazioneAcconto")        // 11
                property("ogim.impostaErariale")        // 12
                property("ogim.impostaErarialeAcconto")    // 13
                property("tial.tipoAliquota")    // 14
            }
            order("ogge.id", "asc") //order by decode (ogco.flag_ab_principale,'S',1,2)
            order("categoriaCatasto", "asc") //,lpad(ltrim(oggetti.sezione),3)
        }
        def listaRitorno = []
        for (def row in lista) {
            def elemento = [:]
            elemento.oggetto = row[0]
            elemento.categoriaCatasto = row[1] ? row[1].categoriaCatasto : null
            elemento.tipoOggetto = ((row[4] ? (row[4].tipoOggetto) : null) ?: (row[5] ? (row[5].tipoOggetto) : null))
            elemento.flagAbPrincipale = row[7]
            elemento.oggettoPraticaRifAp = row[6]
            elemento.imposta = row[8] ?: 0
            elemento.impostaAcconto = row[9] ?: 0
            elemento.impostaSaldo = (row[8] ?: 0) - (row[9] ?: 0)
            elemento.impostaErar = row[12]    //mi serve distinguere 0 da null, quindi non faccio nvl
            elemento.impostaErarAcconto = row[13] ?: 0
            elemento.impostaErarSaldo = (row[12] ?: 0) - (row[13] ?: 0)
            elemento.detrazione = row[10] ?: 0
            elemento.detrazioneAcconto = row[11] ?: 0
            elemento.detrazioneSaldo = (row[10] ?: 0) - (row[11] ?: 0)
            elemento.tipoAliquota = row[14]
            listaRitorno << elemento
        }
        return listaRitorno
    }

    @NotTransactional
    def dettagliPraticaKPerTipoECategoria(long praticaId) {
        def lista = OggettoPratica.createCriteria().list {
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("ogco.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)
            eq("prtr.id", praticaId)
            eqProperty("prtr.contribuente", "ogco.contribuente")

            projections {
                groupProperty("ogge.id")            // 0
                groupProperty("categoriaCatasto")    // 1
                max("ogge.foglioPadded")            // 2
                max("ogge.numeroPadded")            // 3
                max("ogge.subalternoPadded")        // 4
                max("ogge.archivioVie")                // 5
                max("ogge.numCiv")                    // 6
                max("ogge.suffisso")                // 7
                max("ogge.interno")                    // 8
                max("ogge.indirizzoLocalita")        // 9
                max("tipoOggetto")                    // 10
                max("ogge.tipoOggetto")                // 11
                sum("ogim.imposta")                    // 12
                sum("ogim.detrazione")                // 13
                sum("ogim.impostaErariale")            // 14
                max("ogge.sezionePadded")            // 15
                max("ogge.zonaPadded")                // 16
                max("ogge.protocolloCatasto")    // 17
                max("ogge.annoCatasto")            // 18
                max("ogge.partita")                // 19
                max("ogge.classeCatasto")                // 20

            }
            order("ogge.id", "asc") //order by decode (ogco.flag_ab_principale,'S',1,2)
            order("categoriaCatasto", "asc") //,lpad(ltrim(oggetti.sezione),3)
        }
        def listaRitorno = []
        for (def row in lista) {
            //.collect { row ->
            def elemento = [:]
            elemento.oggetto = row[0]
            elemento.sezione = row[15]
            elemento.foglio = row[2]
            elemento.numero = row[3]
            elemento.sub = row[4]
            elemento.zona = row[16]
            elemento.categoriaCatasto = row[1]?.toDTO()
            elemento.indirizzo = (row[5] ? row[5].denomUff : row[9] ?: "") + (row[6] ? ", ${row[6]}" : "") + (row[7] ? "/ ${row[7]}" : "")
            elemento.tipoOggetto = (row[10] ? row[10].toDTO() : row[11]?.toDTO())
            elemento.imposta = row[12] ?: 0
            elemento.impostaErar = row[14] ?: 0
            elemento.detrazione = row[13] ?: 0
            elemento.categoriaCatastoId = row[1] ? (row[1].categoriaCatasto) : null
            elemento.tipoOggettoId = row[10] ? (row[10].tipoOggetto) : null
            elemento.protocolloCatasto = row[17]
            elemento.annoCatasto = row[18]
            elemento.partita = row[19]
            elemento.classeCatasto = row[20]
            elemento.selezionato = false
            listaRitorno << elemento
        }
        return listaRitorno
    }

    def salvaImposte(def listaImposte) {
        for (def rigaImposta in listaImposte) {
            WebCalcoloDettaglio wcde = WebCalcoloDettaglio.get(rigaImposta.idDettaglio)
            wcde?.versAcconto = rigaImposta.versatoAcconto
            wcde?.versAccontoErar = rigaImposta.versatoAccontoErario
            wcde?.acconto = rigaImposta.acconto
            wcde?.accontoErar = rigaImposta.accontoErario
            wcde?.saldo = rigaImposta.saldo
            wcde?.saldoErar = rigaImposta.saldoErario
            wcde?.save(failOnError: true)
        }
    }

    @NotTransactional
    def terreniRidottiFuoriComune(String codFiscale, short anno) {
        TerreniRidotti.createCriteria().get {

            eq("codFiscale", codFiscale)
            eq("anno", anno)

            projections {
                sum "valore"
            }
        } as BigDecimal
    }


    @NotTransactional
    def impostePraticaK(Object idWCIN, Object notInList) {
        def dettagli = WebCalcoloIndividuale.createCriteria().list() {
            createAlias("webCalcoloDettagli", "wcde", CriteriaSpecification.INNER_JOIN)
            createAlias("tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)
            eq("id", idWCIN)

            if (notInList.size() > 0) {
                not { 'in'("wcde.tipoOggetto", notInList) }
            }
            projections {
                property("wcde.id")                    //0
                property("wcde.tipoOggetto")        //1
                property("wcde.versAcconto")        //2
                property("wcde.versAccontoErar")    //3
                property("wcde.acconto")            //4
                property("wcde.accontoErar")        //5
                property("wcde.saldo")                //6
                property("wcde.saldoErar")            //7
                property("wcde.numFabbricati")        //8
                property("numeroFabbricati")        //9 - totale dei fabbricati salvato nel master
                property("totaleTerreniRidotti")    //10 - valore salvato nel master
                property("saldoDetrazioneStd")        //11 - valore salvato nel master
                property("tipoCalcolo")            //12 - valore salvato nel master
                property("titr.tipoTributo")            //13
            }

            order("wcde.ordinamento", "asc")
        }
        def listaRitorno = []
        for (def row in dettagli) {
            def elemento = [:]
            elemento.idDettaglio = row[0]
            elemento.tipo = row[1]
            elemento.tipoDescrizione = row[1].descrizione
            elemento.codiceTributoComune = descrizioneCodiciTributo[row[13]][row[1].name()] ?
                    descrizioneCodiciTributo[row[13]][row[1].name()][0] : ""
            elemento.codiceTributoStato = descrizioneCodiciTributo[row[13]][row[1].name()] ?
                    descrizioneCodiciTributo[row[13]][row[1].name()][1] : ""
            elemento.versatoAcconto = row[2]
            elemento.versatoAccontoErario = row[3]
            elemento.acconto = row[4] ?: 0
            elemento.accontoErario = row[5] ?: 0
            elemento.saldo = row[6] ?: 0
            elemento.saldoErario = row[7] ?: 0
            elemento.numFabbricati = row[8]
            elemento.totaleFabbricati = row[9]
            elemento.valoreTerreniRidotti = row[10] ?: 0
            elemento.saldoDetrazioneStd = row[11] ?: 0
            elemento.miniImu = row[12].equals("Mini")
            listaRitorno << elemento
        }
        return listaRitorno
    }

    def getVersato(String codFiscale, short anno, String tipoTributo) {

        def totaliVersato = Versamento.createCriteria().list {
            projections {
                sum("abPrincipale")
                sum("terreniAgricoli")
                sum("terreniErariale")
                sum("terreniComune")
                sum("areeFabbricabili")
                sum("areeErariale")
                sum("areeComune")
                sum("altriFabbricati")
                sum("altriErariale")
                sum("altriComune")
                sum("rurali")
                sum("ruraliErariale")
                sum("ruraliComune")
                sum("fabbricatiD")
                sum("fabbricatiDErariale")
                sum("fabbricatiDComune")
                sum("fabbricatiMerce")
                sum("maggiorazioneTares")
                sum("detrazione")
                sum("speseSpedizione")
                sum("speseMora")
                sum("importoVersato")
                groupProperty("contribuente.codFiscale")
                groupProperty("tipoTributo.tipoTributo")
                groupProperty("anno")
            }
            eq("contribuente.codFiscale", codFiscale)
            eq("anno", anno)
            eq("tipoTributo.tipoTributo", tipoTributo)
            isNull("pratica")
        }

        def totaleVersato = [
                abPrincipale       : (totaliVersato.sum { it[0] } ?: 0).toBigDecimal(),
                terreniAgricoli    : (totaliVersato.sum { it[1] } ?: 0).toBigDecimal(),
                terreniErariale    : (totaliVersato.sum { it[2] } ?: 0).toBigDecimal(),
                terreniComune      : (totaliVersato.sum { it[3] } ?: 0).toBigDecimal(),
                areeFabbricabili   : (totaliVersato.sum { it[4] } ?: 0).toBigDecimal(),
                areeErariale       : (totaliVersato.sum { it[5] } ?: 0).toBigDecimal(),
                areeComune         : (totaliVersato.sum { it[6] } ?: 0).toBigDecimal(),
                altriFabbricati    : (totaliVersato.sum { it[7] } ?: 0).toBigDecimal(),
                altriErariale      : (totaliVersato.sum { it[8] } ?: 0).toBigDecimal(),
                altriComune        : (totaliVersato.sum { it[9] } ?: 0).toBigDecimal(),
                rurali             : (totaliVersato.sum { it[10] } ?: 0).toBigDecimal(),
                ruraliErariale     : (totaliVersato.sum { it[11] } ?: 0).toBigDecimal(),
                ruraliComune       : (totaliVersato.sum { it[12] } ?: 0).toBigDecimal(),
                fabbricatiD        : (totaliVersato.sum { it[13] } ?: 0).toBigDecimal(),
                fabbricatiDErariale: (totaliVersato.sum { it[14] } ?: 0).toBigDecimal(),
                fabbricatiDComune  : (totaliVersato.sum { it[15] } ?: 0).toBigDecimal(),
                fabbricatiMerce    : (totaliVersato.sum { it[16] } ?: 0).toBigDecimal(),
                maggiorazioneTares : (totaliVersato.sum { it[17] } ?: 0).toBigDecimal(),
                detrazione         : (totaliVersato.sum { it[18] } ?: 0).toBigDecimal(),
                speseSpedizione    : (totaliVersato.sum { it[19] } ?: 0).toBigDecimal(),
                speseMora          : (totaliVersato.sum { it[20] } ?: 0).toBigDecimal(),
                importoVersato     : (totaliVersato.sum { it[21] } ?: 0).toBigDecimal()
        ]
        return totaleVersato
    }

    def getVersatoRavvedimenti(String codFiscale, short anno, String tipoTributo) {

        Date now = new Date()
        Date today = now.clearTime()
        def timeStamp = new java.sql.Timestamp(today.time)

        def importoVersato = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "TOT")

        def abPrincipale = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "ABP")
        def rurali = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "RUR")

        def terreniComune = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "TEC")
        def terreniErariale = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "TEE")
        def areeComune = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "ARC")
        def areeErariale = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "ARE")
        def altriComune = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "ALC")
        def altriErariale = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "ALE")
        def fabbricatiDComune = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "FDC")
        def fabbricatiDErariale = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "FDE")

        def fabbricatiMerce = getVersatoRavvedimentiDettaglio(codFiscale, anno, tipoTributo, timeStamp, "FAM")

        def totaleVersato = [
                abPrincipale       : abPrincipale.toBigDecimal(),
                terreniAgricoli    : (BigDecimal) 0,
                terreniErariale    : (BigDecimal) 0,
                terreniComune      : (BigDecimal) 0,
                areeFabbricabili   : (areeComune + areeErariale).toBigDecimal(),
                areeErariale       : areeErariale.toBigDecimal(),
                areeComune         : areeComune.toBigDecimal(),
                altriFabbricati    : (altriComune + altriErariale).toBigDecimal(),
                altriErariale      : altriErariale.toBigDecimal(),
                altriComune        : altriComune.toBigDecimal(),
                rurali             : rurali.toBigDecimal(),
                ruraliErariale     : (BigDecimal) 0,
                ruraliComune       : rurali.toBigDecimal(),
                fabbricatiD        : (fabbricatiDComune + fabbricatiDErariale).toBigDecimal(),
                fabbricatiDErariale: fabbricatiDErariale.toBigDecimal(),
                fabbricatiDComune  : fabbricatiDComune.toBigDecimal(),
                fabbricatiMerce    : fabbricatiMerce.toBigDecimal(),
                maggiorazioneTares : (BigDecimal) 0,
                detrazione         : (BigDecimal) 0,
                speseSpedizione    : (BigDecimal) 0,
                speseMora          : (BigDecimal) 0,
                importoVersato     : importoVersato.toBigDecimal()
        ]
        return totaleVersato
    }

    def getVersatoRavvedimentiDettaglio(String codFiscale, short anno, String tipoTributo, def timeStamp, String tipoDettaglio) {

        BigDecimal versato = 0

        String tipoVersamento = 'U'

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call F_IMPORTO_VERS_RAVV_DETT(?, ?, ?, ?, ?, ?)}',
                    [
                            Sql.NUMERIC,
                            codFiscale as String,
                            tipoTributo as String,
                            anno as Integer,
                            tipoVersamento as String,
                            tipoDettaglio as String,
                            timeStamp
                    ]
            )
                    {
                        versato = it
                    }
        }
        catch (Exception e) {
            throw e
        }

        return versato
    }

    def cancellaPratica(PraticaTributoDTO pratica, boolean creaContatto) {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        Date oggi = sdf.parse(sdf.format(new Date()))

        //cancello tabella wrk
        WrkCalcoloIndividuale wrci = WrkCalcoloIndividuale.get(pratica?.id)
        wrci?.delete(failOnError: true)

        PraticaTributo p = pratica.getDomainObject()

        // Si elimina fisicamente il contatto solo se creato in data attuale e non siamo in uso calcolatrice
        if (p?.contattoContribuente?.data == oggi && creaContatto) {
            p?.contattiContribuente.each { it.delete(failOnError: true) }
        } else {
            annullaPraticaContatto(pratica)
        }

        p?.delete(flush: true, failOnError: true)

    }

    List<OggettoImpostaDTO> refreshOggettiPraticaK(List<OggettoImpostaDTO> listaOggetti, PraticaTributoDTO praticaK) {
		
        listaOggetti?.each {
            it.getDomainObject()?.refresh()
        }
		
        //faccio la select partendo dalla pratica
        //così posso usare una get che evita la moltiplicazione
        //di righe dovuta ai riog.
        PraticaTributoDTO pDTO = PraticaTributo.createCriteria().get {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente.oggettiImposta", "ogim", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggetto.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            eq("id", praticaK.id)
        }?.toDTO(["oggettiPratica"
                  , "oggettiPratica.oggettiContribuente"
                  , "oggettiPratica.oggettiContribuente.oggettiImposta"
                  , "oggettiPratica.oggettiContribuente.oggettiImposta.tipoAliquota"
                  , "oggettiPratica.oggetto"
                  , "oggettiPratica.oggetto.archivioVie"
                  , "oggettiPratica.oggetto.riferimentiOggetto"])

        //creo il DTO caricando anche gli oggetti figli

        listaOggetti = pDTO?.oggettiPratica?.oggettiContribuente?.oggettiImposta?.flatten()?.sort {

            ((it.oggettoContribuente.flagAbPrincipale ? "A" : "Z")
                    + (it.oggettoContribuente.oggettoPratica.oggetto.sezionePadded ?: ("Z".padLeft(3, "Z")))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.foglioPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.numeroPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.subalternoPadded ?: "Z".padLeft(4, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.zonaPadded ?: "Z".padLeft(3, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.partitaPadded ?: "Z".padLeft(8, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto.toString().padLeft(2, "0"))
                    + (it.oggettoContribuente.oggettoPratica.numOrdine))
        }

		bonificaValoreOggettiPraticaK(listaOggetti)
		
		return listaOggetti
    }

    def salvaOggettiPraticaK(List<OggettoImpostaDTO> listaOggetti
                             , List<OggettoImpostaDTO> listaOggettiEliminati
                             , short anno
                             , Long praticaK
                             , ContribuenteDTO contribuente
                             , Date dataCalcolo) {

        cleanUpGorm()

        PraticaTributo p = PraticaTributo.get(praticaK)
        Contribuente c = contribuente.getDomainObject()
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        Date oggi = sdf.parse(sdf.format(new Date()))
        //se ho fatto modifiche cancello i dati di eventuali calcoli precedenti
        WebCalcoloIndividuale wcin = p.webCalcoloIndividuale
        p.webCalcoloIndividuale = null
        wcin?.delete(flush: true, failOnError: true)
        for (OggettoImpostaDTO oggettoSelezionato in listaOggetti) {
            OggettoPratica ogpr = oggettoSelezionato.oggettoContribuente.oggettoPratica.id ? oggettoSelezionato.oggettoContribuente.oggettoPratica.getDomainObject() : new OggettoPratica()
            ogpr.oggetto = oggettoSelezionato.oggettoContribuente.oggettoPratica.oggetto.getDomainObject()
            ogpr.pratica = p
            ogpr.anno = anno
			/// Per i terreni ed i fabbricati E*, F* la rendita può essere nulla, ma se non metto zero il calcolo si schianta 
            ogpr.valore = oggettoSelezionato.oggettoContribuente.oggettoPratica.valore ?: 0
            ogpr.categoriaCatasto = oggettoSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto?.getDomainObject()
            ogpr.classeCatasto = oggettoSelezionato.oggettoContribuente.oggettoPratica.classeCatasto
            ogpr.flagProvvisorio = oggettoSelezionato.oggettoContribuente.oggettoPratica.flagProvvisorio ?: false
            ogpr.flagValoreRivalutato = oggettoSelezionato.oggettoContribuente.oggettoPratica.flagValoreRivalutato ?: false
            ogpr.tipoOggetto = oggettoSelezionato.oggettoContribuente.oggettoPratica.tipoOggetto.getDomainObject()
            ogpr.immStorico = oggettoSelezionato.oggettoContribuente.oggettoPratica.immStorico ?: false
			
            try {
                ogpr.oggettoPraticaRifAp = oggettoSelezionato.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp?.getDomainObject()
            } catch (Exception e) {
                ogpr.oggettoPraticaRifAp = null
            }
            if (anno > 2000) {
                ogpr.indirizzoOcc = ((oggettoSelezionato.tipoAliquotaPrec?.tipoAliquota) ?: 0).toString().padLeft(2, "0") +
                        ((Long) ((oggettoSelezionato.aliquotaPrec) ?: 0)).toString().padLeft(6, '0') +
                        ((Long) ((oggettoSelezionato.detrazionePrec ?: 0) * 100)).toString().padLeft(15, '0') +
                        ((Long) ((oggettoSelezionato.aliquotaErarPrec ?: 0) * 100)).toString().padLeft(6, '0')
                //ogpr.aliquotaAcconto	= oggettoSelezionato.oggettoContribuente.oggettoPratica.aliquotaAcconto
                //ogpr.detrazioneErariale	= oggettoSelezionato.oggettoContribuente.oggettoPratica.detrazioneErariale
                //ogpr.aliquotaErarAcconto= oggettoSelezionato.oggettoContribuente.oggettoPratica.aliquotaErarAcconto
            }
            //devo salvare per avere la chiave per ogco e ogim
            //con le addTo e salvando solo ogpr, non riesce a salvare
            //ogim che è dettaglio di ogco.
            ogpr.save(flush: true, failOnError: true)
            OggettoContribuente ogco = oggettoSelezionato.oggettoContribuente?.getDomainObject() ?: new OggettoContribuente(contribuente: c)
            ogco.anno = anno
            ogco.oggettoPratica = ogpr
            ogco.mesiPossesso = oggettoSelezionato.oggettoContribuente.mesiPossesso
            ogco.mesiPossesso1sem = oggettoSelezionato.oggettoContribuente.mesiPossesso1sem
            ogco.detrazione = oggettoSelezionato.oggettoContribuente.detrazione
            ogco.percPossesso = oggettoSelezionato.oggettoContribuente.percPossesso
            ogco.percDetrazione = null
            ogco.mesiOccupato = null
            ogco.mesiOccupato1sem = null
            ogco.mesiEsclusione = oggettoSelezionato.oggettoContribuente.mesiEsclusione
            ogco.flagEsclusione = oggettoSelezionato.oggettoContribuente.flagEsclusione ?: false
            ogco.flagRiduzione = oggettoSelezionato.oggettoContribuente.flagRiduzione ?: false
            ogco.flagAbPrincipale = oggettoSelezionato.oggettoContribuente.flagAbPrincipale ?: false
            ogco.flagAlRidotta = oggettoSelezionato.oggettoContribuente.flagAlRidotta ?: false
            ogco.tipoRapportoK = oggettoSelezionato.oggettoContribuente.tipoRapportoK
            ogco.inizioOccupazione = null
            ogco.fineOccupazione = null
            ogco.dataDecorrenza = null
            ogco.dataCessazione = null

            OggettoImposta ogim = oggettoSelezionato.id ? oggettoSelezionato.getDomainObject() : new OggettoImposta()
            ogim.oggettoContribuente = ogco
            ogim.anno = anno
            ogim.tipoAliquota = oggettoSelezionato.tipoAliquota?.getDomainObject()
            ogim.tipoAliquotaPrec = oggettoSelezionato.tipoAliquotaPrec?.getDomainObject()
            ogim.aliquota = oggettoSelezionato.aliquota
            ogim.aliquotaPrec = oggettoSelezionato.aliquotaPrec
            ogim.aliquotaErarPrec = oggettoSelezionato.aliquotaErarPrec
            ogim.detrazionePrec = oggettoSelezionato.detrazionePrec
            ogim.detrazione = oggettoSelezionato.detrazione
            ogim.detrazioneAcconto = oggettoSelezionato.detrazioneAcconto
            ogim.aliquotaErariale = oggettoSelezionato.aliquotaErariale
            ogim.aliquotaStd = oggettoSelezionato.aliquotaStd
            ogim.detrazioneStd = oggettoSelezionato.detrazioneStd
            ogim.imposta = oggettoSelezionato.imposta ?: 0    //inizializzazione di imposta per il record nuovi
            ogim.tipoTributo = p.tipoTributo
            ogco.addToOggettiImposta(ogim)
            ogco.save(flush: true, failOnError: true)
            ogpr.addToOggettiContribuente(ogco)
            p.addToOggettiPratica(ogpr)
        }

        // Necessario per non far scattare il trigger nella successiva eliminazione
        for (OggettoImpostaDTO ogg in listaOggettiEliminati) {
            if (ogg.id) {
                OggettoPratica ogprDel = ogg.oggettoContribuente.oggettoPratica.getDomainObject()
                sessionFactory.currentSession.createSQLQuery("UPDATE OGGETTI_PRATICA SET OGGETTO_PRATICA_RIF_AP = NULL WHERE OGGETTO_PRATICA = ?")
                        .setLong(0, ogprDel.id).executeUpdate()
            }
        }

        for (OggettoImpostaDTO oggettoEliminato in listaOggettiEliminati) {
            if (oggettoEliminato.id) {
                OggettoPratica ogprDel = oggettoEliminato.oggettoContribuente.oggettoPratica.getDomainObject()
                Oggetto oggetto = ogprDel.oggetto
                oggetto.removeFromOggettiPratica(ogprDel)
                p.removeFromOggettiPratica(ogprDel)
                ogprDel.delete(flush: true, failOnError: true)
                p.save(flush: true, failOnError: true)
            }
        }
        p.data = oggi
        p.save(flush: true, failOnError: true)
        //rileggo i valori di pratica e figli con un'unica query
        PraticaTributoDTO pDTO = PraticaTributo.createCriteria().get {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggettiContribuente.oggettiImposta", "ogim", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiPratica.oggetto.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiPratica.oggetto.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            eq("id", p.id)
        }?.toDTO(["oggettiPratica", "oggettiPratica.oggettiContribuente", "oggettiPratica.oggettiContribuente.oggettiImposta", "oggettiPratica.oggetto", "oggettiPratica.oggetto.archivioVie", "oggettiPratica.oggetto.riferimentiOggetto", "contattiContribuente"])

        if (!pDTO) {
            pDTO = PraticaTributo.get(p.id).toDTO()
        }

        //restituisco una lista degli ogim della pratica (potebbe anche essere vuota)
        List<OggettoImpostaDTO> oggettiImposta = pDTO.oggettiPratica?.oggettiContribuente.oggettiImposta.flatten().sort {
            ((it.oggettoContribuente.flagAbPrincipale ? "A" : "Z")
                    + (it.oggettoContribuente.oggettoPratica.oggetto.sezionePadded ?: ("Z".padLeft(3, "Z")))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.foglioPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.numeroPadded ?: "Z".padLeft(5, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.subalternoPadded ?: "Z".padLeft(4, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.zonaPadded ?: "Z".padLeft(3, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.oggetto.partitaPadded ?: "Z".padLeft(8, "Z"))
                    + (it.oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto.toString().padLeft(2, "0"))
                    + (it.oggettoContribuente.oggettoPratica.numOrdine))
        }
		
		bonificaValoreOggettiPraticaK(oggettiImposta)
		
        return [pratica: pDTO, listaOggetti: oggettiImposta]
    }

    @NotTransactional
    def getMaxPercentualeDetrazione(def pAnno, def pCodFiscale) {
        def percDetrazione = DetrazioniImponibile.createCriteria().get {
            eq("anno", (Short) pAnno)
            eq("codFiscale", pCodFiscale)
            projections {
                max("percDetrazione")
            }
        }
    }

    void annullaPraticaContatto(PraticaTributoDTO pratica) {
        //cancello i riferimenti alla pratica dal contatto esistente
        ContattoContribuente coco = ContattoContribuente.findAllByPratica(pratica.getDomainObject())[0]
        coco?.pratica = null
        coco?.save(flush: true, failOnError: true)
    }

    ContattoContribuenteDTO creaContatto(PraticaTributoDTO pratica, Date dataCoco) {
        //cancello i riferimenti alla pratica dal contatto esistente
        annullaPraticaContatto(pratica)

        // Ultimo contatto registrato
        ContattoContribuente coco = recuperaUltimoContatto(pratica.tipoTributo.tipoTributo, pratica.anno, pratica.contribuente.codFiscale)

        // Se esiste un contatto registrato in data di oggi lo aggancia alla pratica
        if (coco?.data == dataCoco) {
            coco.pratica = pratica.getDomainObject()
            coco.save(flush: true, failOnError: true)
            return coco.toDTO()
        } else {

            //creo un nuovo contatto collegato alla pratica
            PraticaTributo p = pratica.getDomainObject()
            ContattoContribuente cocoNew = new ContattoContribuente()
            cocoNew.data = dataCoco
            cocoNew.pratica = p
            cocoNew.contribuente = p.contribuente
            cocoNew.anno = p.anno
            cocoNew.tipoTributo = p.tipoTributo
            cocoNew.tipoContatto = TipoContatto.findByTipoContatto(4)
            cocoNew.tipoRichiedente = TipoRichiedente.findByTipoRichiedente(2)
            cocoNew.save(flush: true, failOnError: true)
            return cocoNew.toDTO()
        }
    }

    def proceduraCalcoloIndividuale(PraticaTributoDTO pPratica, def miniImu = false) {
        def r
        String tipoCalcolo
        //cancello eventuale calcolo precedente rimasto 'appeso'
        //lo cerco per indice univoco
        tipoCalcolo = (miniImu) ? "Mini" : "Normale"
        if (pPratica.webCalcoloIndividuale) {
            WebCalcoloIndividuale webCalcoloIndividuale = pPratica.webCalcoloIndividuale.getDomainObject()
            pPratica.getDomainObject().webCalcoloIndividuale = null
            webCalcoloIndividuale.delete(failOnError: true, flush: true)
        }

        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_web_calcolo_individuale(?, ?, ?, ?, ?, ?)}'
                , [
                Sql.DECIMAL,
                pPratica.id,
                pPratica.tipoTributo.tipoTributo,
                tipoCalcolo,
                pPratica.contribuente.codFiscale,
                pPratica.anno,
                pPratica.utente
        ]) { r = it }

        return r
    }

    ContribuenteDTO creaContribuente(SoggettoDTO soggetto) {
        try {
            Contribuente cont = new Contribuente()
            cont.codFiscale = soggetto.codFiscale ?: soggetto.partitaIva
            cont.soggetto = soggetto.getDomainObject()
            cont.save(failOnError: true) //la flush dovrebbe essere automatica all'uscita dal metodo
            return cont.toDTO()
        } catch (Exception e) {
            soggetto.contribuente
        }
    }

    SoggettoDTO cancellaContribuente(SoggettoDTO soggetto) {
        Contribuente cont = soggetto.contribuente?.getDomainObject()
        cont?.delete(flush: true, failOnError: true)
        return soggetto
    }

    boolean esisteCalcoloPerTipoTributoEData(PraticaTributoDTO praticaDiConfronto) {
        WebCalcoloIndividuale webCalcoloIndividuale = WebCalcoloIndividuale.createCriteria().get {
            eq("contribuente.codFiscale", praticaDiConfronto.contribuente.codFiscale)
            eq("tipoTributo.tipoTributo", (praticaDiConfronto.tipoTributo.tipoTributo == "ICI") ? "TASI" : "ICI")
            eq("anno", praticaDiConfronto.anno)
            pratica {
                eq("data", praticaDiConfronto.data)
            }
        }
    }

    def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }
}
