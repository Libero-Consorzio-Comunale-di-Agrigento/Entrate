package it.finmatica.tr4.commons

import com.aspose.words.net.System.Data.DataTable
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.oggetti.OggettiService
import oracle.jdbc.OracleTypes
import org.apache.commons.io.FilenameUtils
import org.apache.commons.lang.StringUtils
import org.apache.log4j.Logger
import org.apache.tika.mime.MimeType
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.util.media.AMedia
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window
import transform.AliasToEntityCamelCaseMapResultTransformer

import javax.naming.Context
import javax.naming.InitialContext
import javax.servlet.ServletContext
import java.text.*
import java.util.concurrent.TimeUnit

class CommonService {

    static transactional = false

    // 31/12/9999
    static final java.sql.Date MAX_DATE = new java.sql.Date(253402210800000)
    // 01/01/1900
    static final java.sql.Date MIN_DATE = new java.sql.Date(-2208988800000)

    static final long RES_SUCCESS = 0
    static final long RES_WARNING = 1
    static final long RES_ERROR = 2

    private static final String ALLFORMATS_WILDCARD = "*"
    private static final String DEFAULT_FORMATS = ALLFORMATS_WILDCARD
    private static final long DEFAULT_MAX_UPSIZE_IN_MB = 99999
    private static final int MB_TO_BYTE_MULTIPLIER = 1000000
    private static final String MAXSIZEMB_PARAMETER = "MAX_SIZE_MB"
    private static final String FORMATS_PARAMETER = "FORMATS"
    def dataSource
    def sessionFactory
    CompetenzeService competenzeService
    OggettiService oggettiService
    ServletContext servletContext

    private static final Logger log = Logger.getLogger(CommonService.class)

    //riproduce F_VALORE_DA_RENDITA
    BigDecimal valoreDaRendita(BigDecimal rendita, TipoOggettoDTO tipoOggetto
                               , Short anno, CategoriaCatastoDTO categoriaCatasto, boolean immStorico) {

        oggettiService.valoreDaRendita(rendita, tipoOggetto?.tipoOggetto, anno, categoriaCatasto?.categoriaCatasto, immStorico)
    }

    String getDatoRiog(String codFiscale, long oggettoPratica, short anno, String tipo) {
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        String datoRiog
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_dato_riog(?, ?, ?, ?)}'
                , [Sql.VARCHAR
                   , codFiscale
                   , oggettoPratica
                   , anno
                   , tipo]) { datoRiog = it }
        sql.close()
        return datoRiog
    }


    def timeMe = { Closure codeBlock ->

        def start = new Date().getTime()
        codeBlock()
        def end = new Date().getTime()

        def totalTime = end - start
        def verbage = getDurationBreakdown(totalTime)

        return verbage
    }

    def creaEtremiCatasto(def sezione, def foglio, def numero, def subalterno) {
        def estremiCatasto =
                formattaEstremoCatastale(sezione, 3) +
                        formattaEstremoCatastale(foglio, 5) +
                        formattaEstremoCatastale(numero, 5) +
                        formattaEstremoCatastale(subalterno, 4) +
                        formattaEstremoCatastale(" ", 3)

        return estremiCatasto
    }

    def getIstanza() {

        def istanza = null
        log.info "Recupero istanza..."
        try {
            istanza = ((Context) (new InitialContext().lookup("java:comp/env"))).lookup("modulo@istanza") as String
        } catch (Exception e) {
            log.error "[modulo@istanza] non trovato."
        }
        if (istanza?.trim() && istanza.contains('@')) {
            log.info "Trovato parametro [modulo@istanza] in TributiWeb.xml con valore [${istanza}]"
            istanza = (istanza as String).split('@')[1]
            log.info "Valore istanza = [${istanza}]"
        } else {
            log.info "Non trovato parametro [modulo@istanza] in TributiWeb.xml, si assegna il valore di default [TR4]"
            istanza = 'TR4'
        }

        return istanza
    }

    void creaPopup(String zul, def component, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, component, parametri)
        w.onClose = onClose
        w.doModal()
    }

    def getObjProperties(def dto, exclude = []) {

        // Si esclude anche la proprietà uuid definita in alcuni DTO per individuare univocamente l'oggetto
        exclude.addAll(['uuid', 'domainObject', 'class'])
        return dto.properties.findAll {

            !((it.key as String) in exclude)
        }.collectEntries { [it.key, it.value] }
    }

    @Transactional
    def fAbilitaFunzione(String funzione) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_abilita_funzione(?)}'
                , [Sql.VARCHAR, funzione]) {
            r = it
        }

        return r == 'S'
    }

    @Transactional
    def fInpaValore(String parametro) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_INPA_VALORE(?)}'
                , [Sql.VARCHAR, parametro]) {
            r = it
        }

        return r == 'S'
    }

    Integer yearFromDate(Date date) {
        if (!date) {
            return null
        }

        def cal = Calendar.instance
        cal.setTime(date)
        return cal.get(Calendar.YEAR)
    }

    def isOverlapping(Date start1, Date stop1, Date start2, Date stop2) {

        if (!start1 || !start2 || !stop1 || !stop2) {
            throw new RuntimeException("Valore null non consentito")
        }

        return (start1 <= stop2) && (stop1 >= start2)
    }

    /**
     *  Verifica eventuali intersezioni tra range di date
     *  Passare una mappa con elementi [dataInizio: data, dataFine: data]
     */
    boolean isOverlapping(List date) {

        // Se la lista è vuota o è presente un solo elemento, non possono esserci intersezioni
        if (date.size() <= 1) {
            return false
        }

        // Creazione dei range di date

        def intervalli = []

        date.each {

            // Se la data inizio è nulla si setta alla minima data
            it.dataInizio = it.dataInizio ?: new Date(Long.MIN_VALUE)

            // Se la data di fine è nulla si setta alla massima data
            it.dataFine = it.dataFine ?: new Date(Long.MAX_VALUE)

            intervalli << it
        }

        def intersezione = false

        def intervallo = intervalli[0]
        intervalli.remove(0)

        for (def i in intervalli) {
            intersezione = isOverlapping(
                    i.dataInizio, i.dataFine,
                    intervallo.dataInizio, intervallo.dataFine
            )

            if (intersezione) {
                break
            }
        }

        if (!intersezione) {
            return isOverlapping(intervalli)
        }

        return intersezione
    }

    /**
     *  Verifica eventuali intersezioni tra [start, stop] ed i range presenti in rate.
     *  Restituisce true alla prima intersezione individuata
     *  Passare una mappa con elementi [dataInizio: data, dataFine: data]
     */
    boolean isOverlapping(Date start, Date stop, List date) {

        // Se la lista è vuota o è presente un solo elemento, non possono esserci intersezioni
        if (date.size() <= 0) {
            return false
        }

        start = start ?: new Date(Long.MIN_VALUE)
        stop = stop ?: new Date(Long.MAX_VALUE)

        def intersezione = false

        for (def intervallo in date) {
            intersezione = isOverlapping([[dataInizio: start, dataFine: stop], intervallo])
            if (intersezione) {
                break
            }
        }

        return intersezione
    }

    @Transactional
    String codiceBelfioreCliente() {
        def query = """
            select comu.sigla_cfis
            from ad4_comuni comu, dati_generali dage
            where comu.comune = dage.com_cliente
                and comu.provincia_stato = dage.pro_cliente
            """
        return sessionFactory.currentSession.createSQLQuery(query).list()[0]
    }

    def isDate(String data, String datePattern) {
        def dateFormat = new SimpleDateFormat(datePattern)
        dateFormat.setLenient(true)

        try {
            dateFormat.parse(data)
        } catch (ParseException pe) {
            return false
        }

        return true

    }

    String getDurationBreakdown(long millis) {
        if (millis < 0) {
            throw new IllegalArgumentException("Duration must be greater than zero!")
        }

        long hours = TimeUnit.MILLISECONDS.toHours(millis)
        millis -= TimeUnit.HOURS.toMillis(hours)
        long minutes = TimeUnit.MILLISECONDS.toMinutes(millis)
        millis -= TimeUnit.MINUTES.toMillis(minutes)
        long seconds = TimeUnit.MILLISECONDS.toSeconds(millis)
        millis -= TimeUnit.SECONDS.toMillis(seconds)

        StringBuilder sb = new StringBuilder(64)
        if (hours > 0) {
            sb.append(hours)
            sb.append("h ")
        }

        if (minutes > 0) {
            sb.append(minutes)
            sb.append("m ")
        }

        if (seconds > 0) {
            sb.append(seconds)
            sb.append("s ")
        }

        sb.append(millis)
        sb.append("ms")

        return (sb.toString())
    }

    String humanReadableSize(long bytes) {
        if (-1000 < bytes && bytes < 1000) {
            return bytes + " B"
        }
        CharacterIterator ci = new StringCharacterIterator("kMGTPE")
        while (bytes <= -999_950 || bytes >= 999_950) {
            bytes /= 1000
            ci.next()
        }
        return String.format("%.1f %cB", bytes / 1000.0, ci.current())
    }

    AMedia fileToAMedia(String fileName, byte[] data) {

        MimeType mimeType = detectMimeType(data)

        def mimeTyperStr = mimeType.toString() == "application/pkcs7-signature" ? "application/pdf" : mimeType.toString()

        return new AMedia(fileName, mimeType.extension?.replace(".", ""), mimeTyperStr, data)
    }

    MimeType detectMimeType(byte[] data) {
        return ModelliCommons.detectType(data)
    }

    def getUploadInfoByString(String uploadInfoString) {
        if (!validaConfigurazioneUpload(uploadInfoString)) {
            uploadInfoString = "$MAXSIZEMB_PARAMETER=$DEFAULT_MAX_UPSIZE_IN_MB|$FORMATS_PARAMETER=$DEFAULT_FORMATS"
        }

        def uploadInfo = [:]
        def valueParts = uploadInfoString.split(/\|/)
        valueParts.each { part ->
            if (part.startsWith(MAXSIZEMB_PARAMETER)) {
                def maxSize = part.substring(part.indexOf("=") + 1) as Long
                if (maxSize > 0) {
                    uploadInfo.maxSizeBytes = maxSize * MB_TO_BYTE_MULTIPLIER
                }
            }
            if (part.startsWith(FORMATS_PARAMETER)) {
                List<String> formats = part.substring(part.indexOf("=") + 1).split(/,/).toList()
                formats = formats.collect {
                    def rawFormat = it.trim().toLowerCase()
                    if (rawFormat == ALLFORMATS_WILDCARD) {
                        return rawFormat
                    }
                    return '.' + rawFormat
                }
                if (!formats.empty) {
                    uploadInfo.formats = formats
                }
            }
        }

        return uploadInfo
    }

    def validaConfigurazioneUpload(String uploadInfoString) {
        if (!uploadInfoString) {
            return false
        }

        def maxSizeMbRegex = ~/$MAXSIZEMB_PARAMETER=\d+/
        def formatsRegex = ~/$FORMATS_PARAMETER=(\$ALLFORMATS_WILDCARD|[\w,]+)/

        def hasMaxSizeMb = maxSizeMbRegex.matcher(uploadInfoString).find()
        def hasFormats = formatsRegex.matcher(uploadInfoString).find()

        if (!hasMaxSizeMb || !hasFormats) {
            return false
        }

        def params = uploadInfoString.split("\\|")
        return params.size() == 2
    }

    boolean validaEstensione(List validFormats, Media media) {
        if (validFormats.contains(ALLFORMATS_WILDCARD)) {
            return true
        }

        def fileName = media.getName()
        String fileNameExtension = fileName.substring(fileName.lastIndexOf(".")).toLowerCase()

        if (!validFormats.contains(fileNameExtension)) {
            return false
        }

        MimeType mimeType = this.detectMimeType(media.getStreamData().getBytes())
        if (!mimeType.getExtensions().contains(fileNameExtension)) {
            log.error("Il contenuto del file $fileName non equivale alle possibili estensioni. MimeType del file: $mimeType")
            return false
        }

        return true
    }

    boolean validaDimensione(def uploadInfo, Media media) {
        return media.getByteData().size() <= uploadInfo.maxSizeBytes
    }

    def fileExtension(def data) {
        return detectMimeType(data).extension
    }

    def addExtension(String fileName, def data) {
        if (!FilenameUtils.getExtension(fileName)?.trim()) {
            return "$fileName${fileExtension(data)}" as String
        } else {
            return fileName
        }
    }

    boolean validaNomeFile(def media, def regex) {
        def filename = media.getName()
        def result = filename =~ regex
        return !result
    }

    void download(String nomeFile, byte[] file) {
        AMedia amedia = fileToAMedia(nomeFile, file)
        Filedownload.save(amedia)
    }

    String formattaValuta(BigDecimal v) { v ? new DecimalFormat("€ #,##0.00").format(v) : null }

    String formattaNumero(BigDecimal n) { n ? new DecimalFormat("#,##0.00").format(n) : null }

    String extractOraMessage(Exception ex, String oraError) {
        def message = ""
        if (ex?.message?.startsWith(oraError)) {
            message = ex.message.substring("$oraError: ".length(), ex.message.indexOf('\n'))
        } else if ((ex?.cause?.cause?.message ?: ex?.cause?.message)?.startsWith(oraError)) {
            message = (ex?.cause?.cause?.message ?: ex?.cause?.message).substring("$oraError: ".length(), (ex?.cause?.cause?.message ?: ex?.cause?.message).indexOf('\n'))
        }

        return message
    }

    def refCursorToCollection(String procedure, def niErede = null) {

        def sqlCall = """
					DECLARE
						BEGIN
							? := ${procedure};
						END;
				 """

        log.info("Esecuzione function $sqlCall")

        Sql sql = new Sql(dataSource)
        if (niErede) {
            log.info("Settato erede principale [$niErede] in sessione")
            sql.call("""
                        BEGIN
                           ? := stampa_common.set_ni_erede_principale($niErede);
                        END;
                        """, [Sql.DECIMAL])
        }

        DataTable dt = null

        sql.call(sqlCall, [Sql.resultSet((OracleTypes.CURSOR))]) {
            dt = new DataTable(it, "DUAL")
        }

        def numCols = dt.columnsCount

        def columns = []
        (0..numCols - 1).each {
            columns << dt.getColumnName(it)
        }

        def elements = []

        dt.rows.each { r ->
            def row = [:]
            columns.each { c ->
                row << [(c): r.get(c)]
            }
            elements << row
        }
        if (niErede) {
            log.info("Eliminato erede principale [$niErede] dalla sessione")
            sql.call("""
                        BEGIN
                           stampa_common.delete_ni_erede_principale;
                        END;
                        """)
        }
        return elements
    }

    def getPage(Collection collection, int page, int pageSize) {
        if (pageSize < 0 || page < 0) {
            throw new IllegalArgumentException("Invalid page size: ${pageSize}")
        }

        int fromIndex = page * pageSize
        if (collection == null || collection.size() <= fromIndex) {
            return []
        }

        return collection.subList(fromIndex, Math.min(fromIndex + pageSize, collection.size()))
    }

    def decodificaAnniPresSucc() {

        def ANNI_PREC_DEFAULT = 5
        def ANNI_SUCC_DEFAULT = 0

        def anniPrec = ANNI_PREC_DEFAULT
        def anniSucc = ANNI_SUCC_DEFAULT

        def parametroAnni = "LISTA_ANNI"
        def parametro = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == parametroAnni }?.valore
        def listaAnniParam = parametro != null ?
                parametro.replace(" ", "") : ANNI_PREC_DEFAULT as String

        if (listaAnniParam != null) {
            if (listaAnniParam.contains("+")) {

                if (listaAnniParam.startsWith("+")) {
                    listaAnniParam = ANNI_PREC_DEFAULT.toString() + listaAnniParam
                }
                if (listaAnniParam.endsWith("+")) {
                    listaAnniParam = listaAnniParam + ANNI_PREC_DEFAULT.toString()
                }

                def anniParam = listaAnniParam.split("\\+")
                anniPrec = anniParam[0].isNumber() ? anniParam[0] as Integer : ANNI_PREC_DEFAULT
                anniSucc = anniParam[1].isNumber() ? anniParam[1] as Integer : ANNI_SUCC_DEFAULT
            } else {
                anniPrec = listaAnniParam.isNumber() ? listaAnniParam as Integer : ANNI_PREC_DEFAULT
            }
        } else {
            anniPrec = ANNI_PREC_DEFAULT
            anniSucc = ANNI_SUCC_DEFAULT
        }

        return [anniPrec: anniPrec, anniSucc: anniSucc]
    }

    private formattaEstremoCatastale(def valore, def lunghezza) {
        def valoreFormattato = ""
        valoreFormattato += StringUtils.stripStart((valore ?: " "), '0').padLeft(lunghezza, " ")
        return valoreFormattato
    }

    def costruisceUrlPortale(def cf = null) {

        def url = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'URL_PORTAL' }?.valore

        if (!cf) {
            return url
        } else {
            return (url.endsWith("/") ? url[0..-2] : url) +
                    "/web/guest/sportello-tributi/#/ricerca-soggetto/${cf}"
        }
    }

    static String generaIdentificativoOperazione(PraticaTributoDTO praticaDTO, def rata = null) {

        String identificativoOperazione = ""

        def tipiEventoValidi = ['T', 'A']

        if (praticaDTO.tipoPratica == "L") {
            identificativoOperazione += "LIQ"
        } else if (praticaDTO.tipoPratica == "A") {
            identificativoOperazione += "ACC"
            tipiEventoValidi = ['T', 'A', 'U']
        } else if (praticaDTO.tipoPratica == "V") {
            identificativoOperazione += "RAVP"
        } else if (praticaDTO.tipoPratica == "S") {
            identificativoOperazione += "SOLL"
        } else {
            throw new RuntimeException("Tipo pratica [${praticaDTO.tipoPratica}] non supportato.")
        }

        if (praticaDTO.tipoPratica != "V") {

            if (praticaDTO.tipoPratica != "S") {
                switch (praticaDTO.tipoEvento.tipoEventoDenuncia) {
                    case tipiEventoValidi:
                        identificativoOperazione += praticaDTO.tipoEvento.tipoEventoDenuncia
                        break
                    default:
                        identificativoOperazione += 'P'
                }
            }

            identificativoOperazione += praticaDTO.anno

            def numRata = (rata as String) ?: "00"
            identificativoOperazione += numRata.padLeft(2, "0")

            identificativoOperazione += (praticaDTO.id + "").padLeft(8, "0")
        } else {
            identificativoOperazione += praticaDTO.anno
            identificativoOperazione += (praticaDTO.id + "").padLeft(10, "0")
        }

        return identificativoOperazione
    }

    @Transactional
    def getOggettiInvalidi() {

        def query = """
                            Select object_name, object_type, created, last_ddl_time
                            From user_objects
                            Where status != 'VALID'
                           """

        def lista = sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }

        return lista
    }

    def ricompilaOggetti(def silent = false) {

        try {
            def sqlCall = """
					DECLARE
						BEGIN
                            utilitypackage.compile_all;
                        END;
				 """

            Sql sql = new Sql(dataSource)
            sql.call(sqlCall)
        } catch (Exception e) {
            // Si rilancia l'eccezione sulla presenza di oggetti scompilati solo se richiesto.
            if (!silent) {
                throw e
            }
        }
    }

    def serviceException(Exception ex) {

        def found = false
        def errorsList = [
                "ORA-20999",
                "ORA-20008",
                "ORA-20007",
                "ORA-20006"
        ]

        errorsList.each { error ->

            if (ex?.message?.startsWith(error) || ex?.cause?.cause?.message?.startsWith(error)) {
                found = true
                throw new Application20999Error(extractOraMessage(ex, error))
            }
        }

        // Se l'eccezione non è stata trovata viene semplicemente lanciata
        if (!found) {
            throw ex
        }

    }

    def eseguiFunzione(String funzione) {

        def sqlCall =
                """DECLARE
						BEGIN
							? := $funzione;
				END;"""

        log.info """ESECUZIONE
			.........................................................................
                   $sqlCall
                   ........................................................................."""

        Sql sql = new Sql(dataSource)

        DataTable dt = null

        def execTime = timeMe {
            sql.call(sqlCall, [Sql.resultSet((OracleTypes.CURSOR))]) {
                dt = new DataTable(it, "DUAL")
            }
        }
        log.info "[Esecuzione function] ${execTime}"

        return dt
    }

    def <T> T clona(T obj) {

        def clone = obj.class.newInstance()
        InvokerHelper.setProperties(clone, obj.properties)
        return clone

    }

    def getLabelsProperties(def area) {
        File file = new File(servletContext.getRealPath("WEB-INF/labels/${area}.properties"))
        def labels = new Properties()
        file.withInputStream {
            labels.load(it)
        }
        return labels
    }

    def toSnakeCase(String input) {
        return input?.trim()
                .replaceAll(/([a-z])([A-Z])/, '$1_$2') // Aggiunge un underscore tra parole CamelCase
                .replaceAll(/[\s\-]+/, '_') // Sostituisce spazi e trattini con underscore
                .toLowerCase()
    }

}
