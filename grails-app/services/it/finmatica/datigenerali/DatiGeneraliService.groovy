package it.finmatica.datigenerali

import groovy.sql.Sql
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.as4.As4SoggettoCorrente
import it.finmatica.so4.struttura.So4Amministrazione
import it.finmatica.tr4.DatoGenerale
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.DatoGeneraleDTO
import org.hibernate.transform.AliasToEntityMapResultTransformer

/**
 * Service per le impostazioni
 *
 * @author seva
 *
 */

class DatiGeneraliService {
    static transactional = false

    def sessionFactory

    def springSecurityService

    def dataSource
    def commonService

    Ad4ComuneDTO getComuneCliente() {
        //FIXME: prendo la chiave 1 per ora
        return OggettiCache.DATI_GENERALI.valore[0].comuneCliente.ad4Comune
    }

    boolean gestioneCompetenzeAbilitata() {
        return OggettiCache.DATI_GENERALI.valore[0].flagCompetenze == 'S'
    }

    boolean integrazioneGSDAbilitata() {
        return OggettiCache.DATI_GENERALI.valore[0].flagIntegrazioneGsd ?: "N".equals("S")
    }

    boolean flagProvinciaAbilitato() {
        return OggettiCache.DATI_GENERALI.valore[0].flagProvincia == 'S'
    }

    def extractDatiGenerali(Long chiave = 1) {

        DatoGeneraleDTO datoGenerale = OggettiCache.DATI_GENERALI.valore[0]

        if (datoGenerale == null) {
            throw new Exception("Dato generale non compilato!")
        }

        def ad4Comune = datoGenerale.comuneCliente?.ad4Comune

        def extract = [
                codComune          : ad4Comune?.comune,
                desComune          : ad4Comune?.denominazione,
                codProvincia       : datoGenerale.comuneCliente?.provinciaStato,
                desProvincia       : (ad4Comune.provincia) ? ad4Comune.provincia.denominazione : ad4Comune.stato.denominazione,
                flagIntegrazioneGsd: datoGenerale.flagIntegrazioneGsd == 'S',
                flagIntegrazioneTrb: datoGenerale.flagIntegrazioneTrb == 'S',
                flagProvincia      : datoGenerale.flagProvincia == 'S',
                flagCompetenze     : datoGenerale.flagCompetenze == 'S',
                codComuneRuolo     : datoGenerale.codComuneRuolo,
                codAbi             : datoGenerale.codAbi,
                codCab             : datoGenerale.codCab,
                codAzienda         : datoGenerale.codAzienda,
                flagCatastoCu      : (datoGenerale.flagCatastoCu == 'S') ? 'CU' : 'CC',
                flagAccTotale      : datoGenerale.flagAccTotale == 'S',
                area               : datoGenerale.area,
                tipoComune         : datoGenerale.tipoComune,
        ]

        return extract
    }

    def determinaSoggettoCorrente() {

        Long ni = 1

        So4Amministrazione amministrazione = springSecurityService.principal.amministrazione
        As4SoggettoCorrente soggetto = amministrazione.soggetto
        if (soggetto) {
            ni = soggetto.id
        }

        return ni
    }

    def getDatiSoggettoCorrente(Long ni = -1) {

        def datiSoggetto = [
                codProvinciaResidenza: 0,
                desProvinciaResidenza: "",
                codComuneResidenza   : 0,
                desComuneResidenza   : "",
                cognome              : "",
                codiceFiscale        : "",
                partitaIva           : "",
                indirizzoResidenza   : "",
                provinciaResidenza   : null,
                capResidenza         : ""
        ]

        if (ni < 0) {
            ni = determinaSoggettoCorrente()
        }

        As4SoggettoCorrente soggettoCorrente = As4SoggettoCorrente.findById(ni)
        if (soggettoCorrente == null) {
            throw new Exception("E' necessario valorizzare la tabella AS4_V_SOGGETTI_CORRENTI")
        }

        datiSoggetto = getProvinciaComuneSoggettoCorrente(ni, datiSoggetto)

        datiSoggetto.cognome = soggettoCorrente.cognome
        datiSoggetto.codiceFiscale = soggettoCorrente.codiceFiscale
        datiSoggetto.partitaIva = soggettoCorrente.partitaIva
        datiSoggetto.indirizzoResidenza = soggettoCorrente.indirizzoResidenza
        datiSoggetto.capResidenza = soggettoCorrente.capResidenza

        return datiSoggetto
    }

    def getProvinciaComuneSoggettoCorrente(Long ni, def datiSoggetto) {

        def filtri = [:]

        filtri << ['ni': ni ?: 0]

        String sql = """
			SELECT	SOCO.PROVINCIA_RES AS COD_PROVINCIA_RES,
					ADPR.DENOMINAZIONE AS DEN_PROVINCIA_RES,
					SOCO.COMUNE_RES AS COD_COMUN_RES,
					ADCO.DENOMINAZIONE AS DEN_COMUNE_RES
			FROM	AS4_V_SOGGETTI_CORRENTI SOCO,
					AD4_PROVINCE ADPR,
					AD4_COMUNI ADCO
			WHERE SOCO.ni = :ni AND
				  SOCO.PROVINCIA_RES = ADPR.PROVINCIA (+) AND
				  SOCO.COMUNE_RES = ADCO.COMUNE(+) AND
				  ADCO.PROVINCIA_STATO = ADPR.PROVINCIA
		"""

        def params = [:]

        def results = eseguiQuery("${sql}", filtri, params, true)

        if (results.size() > 0) {

            def result = results[0]

            datiSoggetto.codProvinciaResidenza = result['COD_PROVINCIA_RES'] as Long
            datiSoggetto.desProvinciaResidenza = result['DEN_PROVINCIA_RES'] as String
            datiSoggetto.codComuneResidenza = result['COD_COMUN_RES'] as Long
            datiSoggetto.desComuneResidenza = result['DEN_COMUNE_RES'] as String
        }

        return datiSoggetto
    }

    def getDatiBanca(Integer codAbi, Integer codCab) {

        def datiBanca = [
                nomeBanca: ""
        ]

        def filtri = [:]

        filtri << ['codAbi': codAbi ?: 0]
        filtri << ['codCab': codCab ?: 0]

        String sql = """
				SELECT	AD4_BANCHE.DENOMINAZIONE || ' ' || AD4_SPORTELLI.DESCRIZIONE DES_BANCA
				FROM	AD4_BANCHE, AD4_SPORTELLI
				WHERE	(LPAD(TO_CHAR(:codAbi),5,'0') = AD4_BANCHE.ABI(+)) AND
						(LPAD(TO_CHAR(:codAbi),5,'0') = AD4_SPORTELLI.ABI(+)) AND
						(LPAD(TO_CHAR(:codCab),5,'0') = AD4_SPORTELLI.CAB(+))
		"""

        def params = [:]

        def results = eseguiQuery("${sql}", filtri, params, true)

        if (results.size() > 0) {

            def result = results[0]

            datiBanca.nomeBanca = result['DES_BANCA'] as String
        }

        return datiBanca
    }

    def verificaDatiGenerali(def datiGenerali) {

        String message = ""
        Integer result = 0

        String codComuneRuolo = datiGenerali.codComuneRuolo ?: ''
        String codAbi = datiGenerali.codAbi ?: ''
        String codCab = datiGenerali.codCab ?: ''
        String codAzienda = datiGenerali.codAzienda ?: ''

        if (codComuneRuolo.size() != 6) {
            message += "- Cod. Comunale Ruolo non valida, specificare un codice ISTAT valido\n"
        }
        if (codAbi.size() < 1) {
            message += "- Cod. ABI Banca del Comune non specificato\n"
        }
        if (codCab.size() < 1) {
            message += "- Cod. CAB Banca del Comune non specificato\n"
        }
        if (codAzienda.size() < 1) {
            message += "- Codice Ente per Trasmissioni non specificato\n"
        }
        if (!(datiGenerali.area)) {
            message += "- Area non specificata\n"
        }
        if (!(datiGenerali.tipoComune)) {
            message += "- Tipo Comune non specificato\n"
        }

        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    def verificaDatiSoggetto(def datiSoggetto) {

        String message = ""
        Integer result = 0

        String cognome = datiSoggetto.cognome ?: ''
        String codiceFiscale = datiSoggetto.codiceFiscale ?: ''
        String partitaIva = datiSoggetto.partitaIva ?: ''
        String indirizzoResidenza = datiSoggetto.indirizzoResidenza ?: ''
        String capResidenza = datiSoggetto.capResidenza ?: ''

        if (cognome.size() < 3) {
            message += "- Denominazione non valida, specificare almeno tre caratteri\n"
        }
        if (codiceFiscale.size() < 11) {
            message += "- Codice Fiscale non valido\n"
        }
        if (partitaIva.size() < 11) {
            message += "- Partita IVA non valida\n"
        }
        if (indirizzoResidenza.size() < 5) {
            message += "- Indirizzo	 non valido, specificare almeno cinque caratteri\n"
        }
        if (capResidenza.size() != 5) {
            message += "- CAP non valido\n"
        }

        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    def creaSinonimiCu() {
        Sql sql = new Sql(dataSource)
        sql.call('{call SCELTA_VISTA_CATASTO()}')

        commonService.ricompilaOggetti(true)
    }

    def salvaDatiGenerali(def datiGenerali, Long chiave = 1) {

        DatoGenerale datoGenerale = DatoGenerale.findByChiave(chiave)

        if (datoGenerale == null) {
            throw new Exception("Dato generale non compilato !")
        }

        datoGenerale.flagProvincia = (datiGenerali.flagProvincia) ? "S" : null
        datoGenerale.flagCompetenze = (datiGenerali.flagCompetenze) ? "S" : null
        datoGenerale.codComuneRuolo = datiGenerali.codComuneRuolo
        datoGenerale.codAbi = datiGenerali.codAbi
        datoGenerale.codCab = datiGenerali.codCab
        datoGenerale.codAzienda = datiGenerali.codAzienda
        datoGenerale.flagCatastoCu = (datiGenerali.flagCatastoCu == "CU") ? "S" : null
        datoGenerale.flagAccTotale = (datiGenerali.flagAccTotale) ? "S" : null
        datoGenerale.area = datiGenerali.area
        datoGenerale.tipoComune = datiGenerali.tipoComune

        datoGenerale.save(failOnError: true, flush: true)

        if (datiGenerali.catastoChanged && datiGenerali.flagCatastoCu == "CC") {
            creaSinonimiCu()
        }
    }

    def salvaDatiSoggettoCorrente(def datiSoggetto, Long ni = -1) {

        if (ni < 0) {
            ni = determinaSoggettoCorrente()
        }

        As4SoggettoCorrente soggettoCorrente = As4SoggettoCorrente.findById(ni)
        if (soggettoCorrente == 0) {
            throw new Exception("E' necessario valorizzare la tabella AS4_V_SOGGETTI_CORRENTI")
        }

        soggettoCorrente.cognome = datiSoggetto.cognome
        soggettoCorrente.codiceFiscale = datiSoggetto.codiceFiscale
        soggettoCorrente.partitaIva = datiSoggetto.partitaIva
        soggettoCorrente.indirizzoResidenza = datiSoggetto.indirizzoResidenza
        soggettoCorrente.capResidenza = datiSoggetto.capResidenza

        soggettoCorrente.save(failOnError: true, flush: true)
    }

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

}
