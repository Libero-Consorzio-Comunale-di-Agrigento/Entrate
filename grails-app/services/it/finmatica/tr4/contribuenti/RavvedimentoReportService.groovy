package it.finmatica.tr4.contribuenti

import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.SanzionePratica
import it.finmatica.tr4.dto.SanzionePraticaDTO
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.transform.AliasToEntityMapResultTransformer

import javax.servlet.ServletContext
import java.text.DecimalFormat

class RavvedimentoReportService {

	ServletContext servletContext
	Ad4EnteService ad4EnteService
	JasperService jasperService
	CommonService commonService
	LiquidazioniAccertamentiService liquidazioniAccertamentiService

	static transactional = false
	def dataSource
	def sessionFactory
	def springSecurityService

	// Genera report ravvedimento - Semplice
	def generaReportRavvedimento(def idPratica) {

		def ravvedimentoReport = [:]

		def report = generaTestata(idPratica)
		if(report.size() > 0) {
			ravvedimentoReport.testata = generaTestata(idPratica)[0]
			ravvedimentoReport.note = ravvedimentoReport.testata.note
		}
		else {
			ravvedimentoReport.testata = [:]
			ravvedimentoReport.note = "Problema ricavando i dati del report - Verificare il Log!"
		}

		return ravvedimentoReport
	}

	// Genera report ravvedimento - PDF
	def generaReportRavvedimento(def nomeFile, def idPratica, def listaOggetti, def listaSanzioni, def versato,
																					def debiti = null, def crediti = null) {

		Boolean ravvSuRuoli = false
		
		def pratica = PraticaTributo.get(idPratica)

		def nullSeZero = { num -> num == 0 ? null : num }
		String patternValuta = "€ #,##0.00"
		String patternNumero = "#,##0.00"

		DecimalFormat valuta = new DecimalFormat(patternValuta)
		DecimalFormat numero = new DecimalFormat(patternNumero)

		def ravvedimento = generaReportRavvedimento(pratica.id)
		ravvedimento.testata.impC = pratica.impostaTotale ? valuta.format(pratica.impostaTotale) : null
		ravvedimento.testata.sVers = versato ? valuta.format(versato) : null
		ravvedimento.testata.impRavv = pratica.importoTotale ? valuta.format(pratica.importoTotale) : null
		ravvedimento.testata.motivo = pratica.motivo

		ravvedimento.oggetti = []

		if (pratica.tipoTributo.tipoTributo != 'CUNI') {
			listaOggetti.each {

				def oggetto = [:]

				oggetto.tipoTributo = pratica.tipoTributo.tipoTributo

				oggetto.id = it.oggetto.id
				oggetto.tipoOggetto = it.tipoOggetto?.tipoOggetto
				oggetto.indirizzo = it.oggetto.indirizzo?.empty ?
						it.oggetto.indirizzoLocalita : it.oggetto.indirizzo
				oggetto.sezione = it.oggetto.sezione
				oggetto.foglio = it.oggetto.foglio
				oggetto.numero = it.oggetto.numero
				oggetto.subalterno = it.oggetto.subalterno
				oggetto.zona = it.oggetto.zona
				oggetto.protocollo = it.oggetto.protocolloCatasto
				oggetto.anno = it.oggetto.annoCatasto
				oggetto.partita = it.oggetto.partita
				oggetto.categoriaCatasto = it?.oggetto?.categoriaCatasto?.categoriaCatasto
				oggetto.classeCatasto = Oggetto.get(it.oggetto.id).classeCatasto

				oggetto.flagRiduzione = it.singoloOggettoContribuente.flagRiduzione

				oggetto.perPossesso = it.singoloOggettoContribuente.percPossesso ? numero.format(it.singoloOggettoContribuente.percPossesso) : null
				oggetto.mesiPossesso = it.singoloOggettoContribuente.mesiPossesso
				oggetto.valore = it.valore ?
						numero.format(it.valore) : null
				oggetto.impCalc = it.singoloOggettoContribuente.singoloOggettoImposta?.imposta ? numero.format(it.singoloOggettoContribuente.singoloOggettoImposta.imposta) : null
				oggetto.detrazione = it.singoloOggettoContribuente.singoloOggettoImposta?.detrazione ? numero.format(it.singoloOggettoContribuente.singoloOggettoImposta.detrazione) : null
				oggetto.note = it.note
				oggetto.tipoOccupante = pratica.tipoTributo.tipoTributo == 'TASI' ? it.singoloOggettoContribuente.singoloOggettoImposta?.tipoRapporto ?: '' : ''
				oggetto.mesiOccupazione = it.singoloOggettoContribuente.mesiOccupato

				ravvedimento.oggetti << oggetto
			}
		} else {
			// CUNI
			listaOggetti.each {

				def oggetto = [:]

				oggetto.tipoTributo = pratica.tipoTributo.tipoTributo

				oggetto.id = it.oggettoRef
				oggetto.tipoOggetto = it.tributoDescr
				oggetto.indirizzo = it.indirizzoOgg
				oggetto.sezione = it.oggetto.sezione
				oggetto.foglio = it.oggetto.foglio
				oggetto.numero = it.oggetto.numero
				oggetto.subalterno = it.oggetto.subalterno
				oggetto.dataDecorrenza = it.dettagli.dataDecorrenza
				oggetto.dataCessazione = it.dettagli.dataCessazione

				oggetto.codiceTributo = it.codiceTributo
				oggetto.categoriaDescr = it.categoriaDescr
				oggetto.tariffaDescr = it.tariffaDescr
				oggetto.tipoOccupazione = it.dettagli.tipoOccupazione
				oggetto.esenzione = it.esenzione

				oggetto.quantitaOcc = it.occupazione.quantita
				oggetto.larghezzaOcc = it.occupazione.larghezza
				oggetto.profonditaOcc = it.occupazione.profondita
				oggetto.consistenzaOcc = it.occupazione.consistenza
				oggetto.consistenzaRealeOcc = it.occupazione.consistenzaReale

				oggetto.quantitaPub = it.pubblicita.quantita
				oggetto.larghezzaPub = it.pubblicita.larghezza
				oggetto.profonditaPub = it.pubblicita.profondita
				oggetto.consistenzaPub = it.pubblicita.consistenza
				oggetto.consistenzaRealePub = it.pubblicita.consistenzaReale

				ravvedimento.oggetti << oggetto
			}
		}

		ravvedimento.debiti = []

		if(debiti) {
			ravvSuRuoli = true
			debiti.each { 
				def debito = [:]

				debito.ruoloId = it.ruoloId as String
				debito.codFiscale = it.codFiscale

				debito.ruolo = it.ruolo
				debito.annoRuolo = it.annoRuolo
				debito.specieRuolo = it.specieRuolo
				debito.tipoRuolo = it.tipoRuolo

				debito.descrizione = it.descrizione

				debito.dataScadenzaRata1 = it.dataScadenzaRata1
				debito.dataScadenzaRata2 = it.dataScadenzaRata2
				debito.dataScadenzaRata3 = it.dataScadenzaRata3
				debito.dataScadenzaRata4 = it.dataScadenzaRata4

				debito.tipoEmissione = it.tipoEmissione
				debito.dataEmissione = it.dataEmissione

				debito.rate = []

				it.rate.each {
					def rata = [:]

					rata.rataId = it.rataId as String

					rata.rata = (it.rata == 0) ? 'U' : (it.rata ? (it.rata as String) : '')
					rata.scadenzaRata = it.scadenzaRata

					rata.importo = it.importo ? numero.format(it.importo) : null
					rata.imposta = it.imposta ? numero.format(it.imposta) : null
					rata.addECA = it.addECA ? numero.format(it.addECA) : null
					rata.maggECA = it.maggECA ? numero.format(it.maggECA) : null
					rata.addPro = it.addPro ? numero.format(it.addPro) : null
					rata.iva = it.iva ? numero.format(it.iva) : null

					rata.superato = it.superato
					rata.scaduta = it.scaduta

					if (it.scaduta && !it.superato) {
						rata.versato = it.versato ? numero.format(it.versato) : null
						rata.residuo = it.residuo ? numero.format(it.residuo) : null

						rata.importoNum = it.importo ?: 0
						rata.versatoNum = it.versato ?: 0
						rata.residuoNum = it.residuo ?: 0
					}
					else {
						rata.versato = null
						rata.residuo = null

						rata.importoNum = 0
						rata.versatoNum = 0
						rata.residuoNum = 0
					}
					
					debito.rate << rata
				}

				debito.importoNum = debito.rate.sum { it.importoNum }
				debito.versatoNum = debito.rate.sum { it.versatoNum }
				debito.residuoNum = debito.rate.sum { it.residuoNum }

				ravvedimento.debiti << debito
			}
		}
		
		ravvedimento.crediti = []

		if(crediti) {
			ravvSuRuoli = true
			crediti.each { 
				def credito = [:]

				credito.versamentoId = it.versamentoId as String
				credito.tipoVersamento = it.tipoVersamento
				credito.rata = (it.rata == 0) ? 'U' : (it.rata ? (it.rata as String) : '')
				credito.ruolo = it.ruolo as String
				credito.dataPagamento  = it.dataPagamento?.format("dd/MM/yyyy")

				credito.importoVersato = it.importoVersato
				credito.importo = it.importo
				credito.totSanzioni = it.totSanzioni
				credito.totInteressi = it.totInteressi
				credito.totAltro = it.totAltro

				credito.IUV = it.IUV
				credito.note = it.note
				credito.ravvNote = it.ravvNote 

				ravvedimento.crediti << credito
			}
		}

		if(ravvSuRuoli) {
			ravvedimento.testata.impRavv = ravvedimento.testata.impLordo ? valuta.format(ravvedimento.testata.impLordo) : null
			ravvedimento.testata.impC = ravvedimento.testata.impEvasaLorda ? valuta.format(ravvedimento.testata.impEvasaLorda) : null
		}

		ravvedimento.sanzioni = []

		listaSanzioni.each { sanz ->

			def sanzione = [:]

			sanzione.tipoTributo = pratica.tipoTributo.tipoTributo

			sanzione.codice = sanz.sanzione.codSanzione
			sanzione.descrizione = sanz.sanzione.descrizione
			sanzione.giorniSemestri = "${sanz.giorni != null ? sanz.giorni : ''}${(sanz.giorni != null && sanz.semestri != null) ? '/' : ''}${sanz.semestri != null ? sanz.semestri : ''}"
			sanzione.perc = sanz.percentuale != null ? "${numero.format(sanz.percentuale)} %" : null
			sanzione.importo = sanz.importo
			sanzione.riduzione = sanz.riduzione

			sanzione.abiPri = nullSeZero(sanz.abPrincipale)
			sanzione.rurali = nullSeZero(sanz.rurali)
			sanzione.terreniComune = nullSeZero(sanz.terreniComune)
			sanzione.terreniErariale = nullSeZero(sanz.terreniErariale)
			sanzione.areeComune = nullSeZero(sanz.areeComune)
			sanzione.areeErariale = nullSeZero(sanz.areeErariale)
			sanzione.altriComune = nullSeZero(sanz.altriComune)
			sanzione.altriErariale = nullSeZero(sanz.altriErariale)
			sanzione.fabbricatiDComune = nullSeZero(sanz.fabbricatiDComune)
			sanzione.fabbricatiDErariale = nullSeZero(sanz.fabbricatiDErariale)

			sanzione.impLordo = null

			if (sanzione.tipoTributo == 'TARSU') {

				SanzionePraticaDTO sanzDTO

				if (sanz instanceof SanzionePratica) {
					sanzDTO = sanz.toDTO(["pratica", "sanzione"])
				}
				else {
					sanzDTO = sanz
				}

				liquidazioniAccertamentiService.calcoloImportoLordo(sanzDTO, sanzione.tipoTributo, false)

				sanzione.impLordo = sanzDTO.importoLordoCalcolato
			}

			sanzione.note = sanz.note ?: ''

			ravvedimento.sanzioni << sanzione
		}

		String reportName = (ravvSuRuoli) ? 'ravvedimentoRuoli.jasper' :  'ravvedimento.jasper'

		JasperReportDef reportDef = new JasperReportDef(name: reportName
				, fileFormat: JasperExportFormat.PDF_FORMAT
				, reportData: [ravvedimento]
				, parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
							   ENTE         : ad4EnteService.getEnte()])

		def scheda = jasperService.generateReport(reportDef)

		return scheda
	}

	// Genera testata
	private generaTestata(def idPratica) {

		def sqlTestata = """
         select aden.descrizione "ente",
            contribuenti.cod_contribuente "codContribuente",
            translate(soggetti.cognome_nome, '/', ' ') "cognomeNome",
            decode(soggetti.cod_via,
                   null,
                   soggetti.denominazione_via,
                   archivio_vie.denom_uff) ||
            decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
            decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) ||
            decode(soggetti.interno, null, '', ' int. ' || soggetti.interno) "indirizzoSogg",
            decode(nvl(soggetti.cap, ad4_comuni.cap),
                   null,
                   '',
                   nvl(soggetti.cap, ad4_comuni.cap) || ' ' ||
                   ad4_comuni.denominazione) || ' ' ||
            decode(ad4_provincie.sigla,
                   null,
                   '',
                   '(' || ad4_provincie.sigla || ')') "residenzaSogg",
            contribuenti.cod_fiscale "codFiscale",
            f_descrizione_titr(pratiche_tributo.tipo_tributo,
                               pratiche_tributo.anno) "tipoTributoAttuale",
            pratiche_tributo.anno "praticaAnno",
            pratiche_tributo.tipo_tributo "tipoTributo",
            pratiche_tributo.pratica "pratica",
            pratiche_tributo.data_notifica "dataNotifica",
            pratiche_tributo.numero "numeroPratica",
            pratiche_tributo.data "dataLiq",
            tipi_stato.descrizione "statoAccertamento",
            pratiche_tributo.tipo_evento "tipoEvento",
            decode(pratiche_tributo.tipo_pratica,
                   'L',
                   'Liquidazione',
                   'R',
                   'Ravvedimento',
                   'Accertamento') "tipoPratica",
            pratiche_tributo.note "note",
            decode(pratiche_tributo.tipo_tributo,
                   'TARSU',
                   decode(nvl(carichi_tarsu.flag_lordo, 'N'),
                          'S',
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'LORDO'),
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'NETTO')),
                   f_round(pratiche_tributo.importo_totale, 1)) "impC",
            decode(pratiche_tributo.tipo_tributo,
                   'TARSU',
                   decode(nvl(carichi_tarsu.flag_lordo, 'N'),
                          'S',
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'LORDO'),
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'NETTO')),
                   f_round(pratiche_tributo.importo_totale, 1)) "impSanz",
            pratiche_tributo.versato_pre_rate "sVers",
		    f_importo_acc_lordo(pratiche_tributo.pratica, 'N') "impLordo",
			f_importi_acc(pratiche_tributo.pratica,'N','TASSA_EVASA_TOTALE') "impEvasaLorda",
            'Rateazione ' ||
            f_descrizione_titr(pratiche_tributo.tipo_tributo,
                               pratiche_tributo.anno) titolo,
            decode(pratiche_tributo.tipo_atto, null, '', tipi_atto.descrizione) "tipoAtto",
            pratiche_tributo.data_rateazione "dataRateazione",
            nvl(pratiche_tributo.mora, 0) "mora",
            pratiche_tributo.rate "rate",
            decode(pratiche_tributo.tipologia_rate,
                   'M',
                   'Mensile',
                   'B',
                   'Bimestrale',
                   'T',
                   'Trimestrale',
                   'Q',
                   'Quadrimestrale',
                   'S',
                   'Semestrale',
                   'A',
                   'Annuale') "tipologiaRate",
            pratiche_tributo.importo_rate "importoRate",
            pratiche_tributo.aliquota_rate "aliquotaRate",
			pratiche_tributo.data_rif_ravvedimento "dataRifRavvedimento"
       from soggetti,
            archivio_vie,
            ad4_comuni,
            ad4_provincie,
            contribuenti,
            pratiche_tributo,
            tipi_stato,
            tipi_atto,
            carichi_tarsu,
            ad4_istanze      adis,
            ad4_enti         aden
      where soggetti.cod_via = archivio_vie.cod_via(+)
        and soggetti.cod_pro_res = ad4_comuni.provincia_stato(+)
        and soggetti.cod_com_res = ad4_comuni.comune(+)
        and ad4_provincie.provincia(+) = ad4_comuni.provincia_stato
        and contribuenti.ni = soggetti.ni
        and pratiche_tributo.cod_fiscale = contribuenti.cod_fiscale
        and pratiche_tributo.stato_accertamento = tipi_stato.tipo_stato(+)
        and pratiche_tributo.tipo_atto = tipi_atto.tipo_atto(+)
        and pratiche_tributo.anno = carichi_tarsu.anno(+)
        and adis.ente = aden.ente
        and upper(adis.istanza) =  upper('${commonService.getIstanza()}')
        and pratiche_tributo.pratica = :pPratica
      order by 2, 3, 4
        """

        def testata = sessionFactory.currentSession.createSQLQuery(sqlTestata).with {

            setBigDecimal('pPratica', idPratica)

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return testata
    }
}

