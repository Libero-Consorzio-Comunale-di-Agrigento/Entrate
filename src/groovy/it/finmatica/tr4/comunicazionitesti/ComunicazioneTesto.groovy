package it.finmatica.tr4.comunicazionitesti

import com.aspose.words.net.System.Data.DataTable
import com.google.gson.Gson
import groovy.sql.Sql
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.comunicazioni.ComunicazioneParametri
import it.finmatica.tr4.dto.comunicazioni.ComunicazioneParametriDTO
import org.apache.log4j.Logger

class ComunicazioneTesto {

    final Logger log = Logger.getLogger(ComunicazioneTesto.class)

    CommonService commonService
    ComunicazioniTestiService comunicazioniTestiService

    private final def DEFAULT_STR = "''"
    private final def DEFAULT_NUM = "-1"

    private def entryPoint
    String packageName
    String functionName

    Map<String, String> output
    def groupedOutput
    def pos

    void generateData(def tipoTributo, def tipoComunicazione, Map<String, String> input) {

        pos = 0
        output = [:]
        groupedOutput = []

        ComunicazioneParametriDTO cp = getParametriComunicazione(tipoTributo, tipoComunicazione)

        def splitPkgVariabili = cp.pkgVariabili.split("\\.")

        packageName = splitPkgVariabili[0]
        functionName = splitPkgVariabili[1]

        entryPoint = (new Gson()).fromJson(
                cp.variabiliClob, Map.class
        )

        log.info("Elaborazione testo [${cp.pkgVariabili}]")
        log.info("Con firma [${entryPoint[(functionName)].signature}]")
        log.info("Con input [${input}]")
        processData(functionName, entryPoint[(functionName)], input)
    }

    def generaCampiUnione(def tipoTributo, def tipoComunicazione) {

        ComunicazioneParametri cp = getParametriComunicazione(tipoTributo, tipoComunicazione)

        return generaCampiUnione(cp.pkgVariabili)
    }

    def generaCampiUnione(def dbFunction) {
        DataTable dt = commonService.eseguiFunzione(dbFunction)
        def numCols = dt.columnsCount

        def columns = [:]
        (0..numCols - 1).each {
            columns << [(dt.getColumnName(it)): dt.getColumnName(it)]
        }

        return columns
    }

    private String createFunctionCall(String fName, Map signature, Map input) {

        if (!functionName?.trim()) {
            throw new RuntimeException("Invalid function name")
        }

        if (input?.size > 0 && (signature.size() != input.size() ||
                signature.keySet().sort() != input.keySet().sort())) {
            throw new RuntimeException("Invalid input for funtion [$fName], $signature, $input]")
        }

        def params = ""

        input = input ?: [:]
        signature.each {
            if (it.value == 'num') {
                if (input[(it.key)] == null || input[(it.key)]?.toString().isEmpty()) {
                    params += "$DEFAULT_NUM,"
                } else {
                    params += "${input[(it.key)]},"
                }
            } else {
                params += input[(it.key)] == null ? "$DEFAULT_STR," : "'${input[(it.key)]}',"
            }
        }
        params = params[0..(params.size() - 2)]

        return "${packageName}.${fName}($params)".toUpperCase()

    }

    private Map createSubInput(def function, Map parentOutput, String parentFName) {
        def subInput = [:]
        function.value.signature.each { k, v ->
            subInput[k] = parentOutput[(generaChiave("$parentFName", "$k").toUpperCase())]
        }

        return subInput
    }

    private Map transformOutput(List output, Map mapping, String fName) {

        def transformedOutput = [:]

        if (output.isEmpty()) {
            mapping.values().each { transformedOutput << [(generaChiave(fName, it)): ""] }
        } else {
            mapping.each { m ->
                def index = 1
                output.each { o ->
                    if (o.containsKey(m.key)) {
                        transformedOutput << [(output.size() == 1 ? (generaChiave(fName, m.value)) : "#${(generaChiave(fName, m.value))}_${index}".toString()): ((o[m.key] ?: "") as String).trim()]
                    }
                    index++
                }
            }
        }

        return transformedOutput
    }

    private processData(String fName, def currentFunction, def input) {


        if (!currentFunction.enabled) {
            return
        }

        String dbCall = createFunctionCall(fName, currentFunction.signature, input)
        log.info(dbCall)

        def queryResult = commonService.refCursorToCollection(
                dbCall,
                input.find { it.key.startsWith("NI_EREDE") }?.value
        )

        def mapping = [:]

        // Se sono richiesti tutti i campi
        if ((currentFunction.output.size() == 1 && currentFunction.output.keySet()[0] == '*')) {
            if (queryResult.empty) {
                mapping = generaCampiUnione(dbCall)
            } else {
                mapping = queryResult[0].collect { [(it.key): it.key] }.collectEntries()
            }
        } else {
            mapping = currentFunction.output
        }

        transformOutput(
                [],
                mapping, fName).keySet().each {
            groupedOutput << [pos: pos, label: currentFunction.label, codice: it]
        }
        pos++

        groupedOutput = groupedOutput.sort { it.codice }

        def currentOutput = transformOutput(
                queryResult,
                mapping,
                fName)

        currentOutput.each {
            if (!output.containsKey(it.key)) {
                output[(it.key)] = it.value
            }
        }

        currentFunction.functions?.each { f ->
            log.info("Elaborazione funzione [${f.key}], input: ${input}")
            processData(f.key, f.value, createSubInput(f, output, fName))
        }
    }

    private def getParametriComunicazione(def tipoTributo, def tipoComunicazione) {

        if (!tipoTributo?.trim() || !tipoComunicazione?.trim()) {
            throw new RuntimeException("Valori non corretti per [tipoTributo, tipoComunciazione] [$tipoTributo, $tipoComunicazione]")
        }

        ComunicazioneParametriDTO cp = OggettiCache.COMUNICAZIONE_PARAMETRI.valore
                .find { it.tipoTributo == tipoTributo && it.tipoComunicazione == tipoComunicazione }

        // Se non è definito il pkg o la modalità di chiamata si recuperano i dati dalla comunicazione generica
        if (!cp.pkgVariabili?.trim() || !cp.variabiliClob?.trim()) {
            cp = OggettiCache.COMUNICAZIONE_PARAMETRI.valore
                    .find { it.tipoTributo == 'TRASV' && it.tipoComunicazione == 'LGE' }
        }

        if (!cp) {
            throw new RuntimeException("Parametro comunicazione non definito per [$tipoTributo, $tipoComunicazione]")
        }

        if (!cp.pkgVariabili?.contains(".")) {
            throw new RuntimeException("Formato della funzione di generazione dei campi unione non valido [${cp.pkgVariabili}] [packageName.functionName]")
        }

        return cp
    }

    private String generaChiave(String fName, String propertyName) {
        return "$fName.$propertyName".toString()
    }

}
