package it.finmatica.tr4.trasmissioni

import grails.util.Holders
import groovy.sql.Sql
import it.finmatica.tr4.Trasmissione
import it.finmatica.tr4.commons.OggettiCache
import transform.AliasToEntityCamelCaseMapResultTransformer

import javax.sql.rowset.serial.SerialClob
import java.security.MessageDigest
import java.sql.Clob

class TrasmissioniService {

    def sessionFactory
    def dataSource

    private final String FTP_FOLDER = "FTP_FOLDER"
    private final String FTP_CRON = "FTP_CRON"
    private final String FTP_CRON_DEFAULT = "0 0 2 ? * * *"


    def leggiConfigurazioneBatch() {

        String utente = Holders.getGrailsApplication()?.config?.grails?.plugins?.afcquartz?.utenteBatch
        if (!utente) utente = "TR4"

        def filtri = [:]

        filtri << ['nomeUtente': utente]

        String query = """
				SELECT
					COMP.OGGETTO ENTI
				FROM
					SI4_COMPETENZE COMP,
					SI4_ABILITAZIONI ABI,
					SI4_TIPI_ABILITAZIONE TIAB,
					SI4_TIPI_OGGETTO TOGG
				WHERE
					COMP.ID_ABILITAZIONE = ABI.ID_ABILITAZIONE AND
					TIAB.ID_TIPO_ABILITAZIONE = ABI.ID_TIPO_ABILITAZIONE AND
					TOGG.ID_TIPO_OGGETTO = ABI.ID_TIPO_OGGETTO AND
					TIAB.TIPO_ABILITAZIONE = 'AA' AND
					COMP.UTENTE = :nomeUtente
		"""

        String enti = ""

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]

        enti = result.enti

        if (!enti) enti = "FINMATICA"

        return enti
    }

    def isTrasmissioniJobAttivabile() {

        def ftpFolder = getParametroFtpFolder()

        // Se il parametro è definito e valorizzata ma non esiste la cartella, si crea
        if (ftpFolder && !ftpFolder.isEmpty() && !new File(ftpFolder).exists()) {
            log.info "Creazione folder [${ftpFolder}]"
            new File(ftpFolder).mkdirs()
        }

        return ftpFolder && !ftpFolder.isEmpty() && new File(ftpFolder).exists()
    }

    def getParametroFtpFolder() {
        return OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == FTP_FOLDER }?.valore
    }

    def getParametroFtpCron() {
        def ftpCron = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == FTP_CRON }?.valore

        return ftpCron ?: FTP_CRON_DEFAULT
    }


    def salvaTrasmissione(Trasmissione trasmissione) {
        trasmissione.save(failOnError: true, flush: true)
    }

    def getNextNumSequenza() {

        Short newSequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call FTP_TRASMISSIONI_NR(?)}',
                [
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }

    def getHashDaFilePath(def filePath) {
        def file = new File(filePath)
        MessageDigest sha512 = MessageDigest.getInstance("SHA-512")
        byte[] digest = sha512.digest(file.bytes)
        return new BigInteger(1, digest).toString(16)
    }

    def creaClobFile(def filePath) {

        BufferedReader br = new BufferedReader(new FileReader(filePath))
        String line

        try {
            StringBuilder sb = new StringBuilder()

            while ((line = br.readLine()) != null) {
                sb.append(line)
                sb.append(System.lineSeparator())
            }

            Clob clob = new SerialClob(sb.toString().toCharArray())
            return clob

        } finally {
            br.close()
        }
    }

    def getUltimoHashDaNomeFile(def fileName) {

        def parametri = [:]

        parametri << [p_nomeFile: fileName]

        def query = """
                            SELECT fttr.nome_file,
                                   fttr.hash,
                                   MAX(fttr.id_documento) KEEP(DENSE_RANK FIRST ORDER BY fttr.id_documento DESC) as id_documento
                            FROM ftp_trasmissioni fttr
                            WHERE fttr.nome_file = :p_nomeFile
                            GROUP BY fttr.nome_file, fttr.hash
                           """

        return sessionFactory.currentSession.createSQLQuery(query).with {
            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }[0]
    }
}
