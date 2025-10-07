package it.finmatica.tr4.export

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.jobs.ExportXlsxJob
import org.apache.log4j.Logger
import org.apache.poi.ss.usermodel.Cell
import org.apache.poi.ss.usermodel.Row
import org.apache.poi.ss.usermodel.Sheet
import org.apache.poi.xssf.streaming.SXSSFWorkbook
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload

import java.text.SimpleDateFormat

class XlsxExporter {

    private static final Logger log = Logger.getLogger(XlsxExporter.class)

    static final String FILE_EXTENSION = "xlsx"
    static final String MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    public static final String BIGDECIMAL_DEFAULT_FORMAT = "#,##0.00"
    public static final String DATE_DEFAULT_FORMAT = "dd/MM/yyyy"
    private static final MAX_XLSX_ROWS_VALUE = 15000
    private static final MAX_XLSX_ROWS_KEY = "MAX_XLSX_R"

    private XlsxExporter() {}

    def static final generaXlsx(String fileName, List<Map> list, Map fields, Map converters = [:], Map bigDecimalFormats = [:], Map dateFormats = [:]) {

        def fieldinGestione
        OutputStream xlsxOut = new ByteArrayOutputStream()
        SXSSFWorkbook xlsx = new SXSSFWorkbook()

        try {
            log.debug("Generazione file $fileName.$FILE_EXTENSION...")

            def stili = [:]

            Sheet sheet = xlsx.createSheet(fileName)

            // stampa header
            int rowNum = 0
            int cellNumber = 0
            Row row = sheet.createRow(rowNum++)

            fields.each {
                Cell cell = row.createCell(cellNumber++)
                cell.cellValue = it.value

                // log.debug("Creata colonna [${it.value}]")
            }

            list.each { element ->

                def entry
                if (!(element instanceof Map)) {
                    entry = toMap(element)
                } else {
                    entry = element
                }

                row = sheet.createRow(rowNum++)
                // log.debug("Creazione riga [${rowNum}]")

                cellNumber = 0
                fields.each { field ->

                    fieldinGestione = field

                    Cell cell = row.createCell(cellNumber++)
                    def tempVal

                    // log.debug("Gestione [${field.key}: ${field.value}]")

                    if (entry.containsKey((field.key.split(/\./).size() == 0 ? field.key : field.key.split(/\./)[0]))) {
                        if (field.key.contains('.')) {
                            tempVal = field.key.split(/\./).inject(entry) {
                                m, p -> m?.getAt(p)
                            }
                        } else {
                            tempVal = entry[field.key]
                        }

                        if (tempVal instanceof Date) {
                            String dateFormat = dateFormats[field.key] ?: DATE_DEFAULT_FORMAT
                            tempVal = (new SimpleDateFormat(dateFormat)).format(tempVal)
                        }

                        if (converters[field.key]) {
                            tempVal = converters[field.key](tempVal)
                        }
                    } else {

                        if (converters[field.key]) {
                            // Applichiamo il trasformatore sull'intero record, si tratta di un campo calcolato
                            tempVal = converters[field.key](entry)
                        } else {
                            tempVal = null
                        }
                    }

                    if (tempVal instanceof BigDecimal) {

                        String bigDecimalFormat = bigDecimalFormats[field.key] ?: BIGDECIMAL_DEFAULT_FORMAT

                        if (!stili[bigDecimalFormat]) {
                            def cellStyle = xlsx.createCellStyle()
                            cellStyle.dataFormat = xlsx.createDataFormat().getFormat(bigDecimalFormat)
                            stili[bigDecimalFormat] = cellStyle
                        }

                        def stile = stili[bigDecimalFormat]

                        cell.cellStyle = stile
                    } else if (tempVal instanceof Boolean) {
                        tempVal = tempVal ? tempVal : false
                    }

                    cell.cellValue = tempVal

                    // log.debug("Creata cella [${field.value}] per chiave [${field.key}] con valore [${tempVal}]")
                }
                // log.debug("Fine creazione riga [${rowNum}]")

                if (rowNum % 100 == 0) {
                    log.debug("Generazione file $fileName.$FILE_EXTENSION [$rowNum/${list.size()}] righe.")
                }
            }

            log.debug("Generate $rowNum righe.")

            xlsx.write(xlsxOut)

            def outByte = xlsxOut.toByteArray()

            return outByte
        } catch (Exception e) {
            log.error("Errore in gestione del campo [${fieldinGestione.key}: ${fieldinGestione.value}]")
            e.printStackTrace()
        } finally {
            xlsxOut?.close()
            xlsx?.close()
        }
    }

    def static final exportAndDownload(String fileName, List<Map> list, Map fields, Map converters = [:], Map bigDecimalFormats = [:], Map dateFormats = [:]) {
        def out = generaXlsx(fileName, list, fields, converters, bigDecimalFormats, dateFormats)

        AMedia amedia = new AMedia(fileName,
                FILE_EXTENSION,
                MIME_TYPE,
                out)
        Filedownload.save(amedia)
    }

    private static Map toMap(def obj) {
        return obj.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [(it.name): obj."$it.name"]
        }
    }

    def static final export(String fileName, Closure listGenerator, def numRows, Map fields, Map converters = [:],
                            Map bigDecimalFormats = [:], Map dateFormats = [:], SpringSecurityService springSecurityService) {

        if (numRows == null) {
            throw new IllegalArgumentException("Il numero di righe deve essere specificato.")
        }

        def maxXlsRows = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == MAX_XLSX_ROWS_KEY }?.toInteger() ?: MAX_XLSX_ROWS_VALUE

        if (numRows <= maxXlsRows) {

            def list = listGenerator.call()
            return exportAndDownload(fileName, list, fields, converters, bigDecimalFormats, dateFormats)
        } else {
            ExportXlsxJob.triggerNow([
                    codiceUtenteBatch: springSecurityService.currentUser.id,
                    codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                    fileName         : fileName,
                    listGenerator    : listGenerator,
                    fields           : fields,
                    converters       : converters,
                    bigDecimalFormats: bigDecimalFormats,
                    dateFormats      : dateFormats
            ])
            Clients.showNotification("Generazione del file excel avviata", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        }
    }
}
