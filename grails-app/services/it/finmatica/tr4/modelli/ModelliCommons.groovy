package it.finmatica.tr4.modelli

import com.aspose.words.Document
import com.aspose.words.PdfSaveOptions
import com.aspose.words.PdfTextCompression
import com.aspose.words.SaveFormat
import it.finmatica.tr4.commons.OggettiCache
import org.apache.log4j.Logger
import org.apache.pdfbox.io.MemoryUsageSetting
import org.apache.pdfbox.multipdf.PDFMergerUtility
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.rendering.PDFRenderer
import org.apache.tika.config.TikaConfig
import org.apache.tika.detect.CompositeDetector
import org.apache.tika.detect.Detector
import org.apache.tika.io.TikaInputStream
import org.apache.tika.metadata.Metadata
import org.apache.tika.mime.MediaType
import org.apache.tika.mime.MimeTypes
import org.apache.tika.parser.microsoft.POIFSContainerDetector
import org.apache.tika.parser.pkg.ZipContainerDetector

import java.awt.*
import java.awt.image.BufferedImage
import java.util.List

class ModelliCommons {

    private static final Logger log = Logger.getLogger(ModelliCommons.class)

    /**
     * Rende il numero di pagine del documento par
     * doc deve essere un file pdf o doc/docx
     * Attenzione, la finalizzazione deve essere effettuata sul formato di output, un file doc/dox di n pagine
     * non è detto che venga convertito in un file pdf con lo stesso numero di pagine.
     */
    static def finalizzaPagineDocumento(byte[] doc) {
        return ToolsFactory.tools(doc).finalizzaPagineDocumento()
    }

    static def allegaDocumentoPdf(byte[] doc, byte[] pdf, def aggiungiPaginaBianca = false, tag = null) {
        return ToolsFactory.tools(doc).allegaDocumento(pdf, aggiungiPaginaBianca, tag)
    }

    static def creaPaginaBianca(def doc) {
        return ToolsFactory.tools(doc).creaPaginaBianca()
    }

    static def creaPDFVuoto() {
        def whitePageDoc = new PDDocument()
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream()
        whitePageDoc.save(byteArrayOutputStream)
        def whitePageBytes = byteArrayOutputStream.toByteArray()
        byteArrayOutputStream.close()
        whitePageDoc.close()

        return whitePageBytes
    }

    static def fileBytesToDoc(def fileBytes) {
        return new Document(new ByteArrayInputStream(fileBytes))
    }

    static def fileDocToBytes(def doc, def format = outputFormat()) {

        format = format ?: outputFormat()

        ByteArrayOutputStream docOutStream = new ByteArrayOutputStream()

        // PDF to bytes
        if (doc instanceof PDDocument) {
            doc.save(docOutStream)

            def byteDoc = docOutStream.toByteArray()

            doc.close()
            docOutStream.close()

            return byteDoc
        }

        // Aspose to bytes
        if (format == SaveFormat.PDF) {
            PdfSaveOptions pdfOptions = new PdfSaveOptions()
            pdfOptions.textCompression = PdfTextCompression.FLATE
            pdfOptions.jpegQuality = 60
            doc.save(docOutStream, pdfOptions)
        } else {
            doc.save(docOutStream, format)
        }

        def fileByte = docOutStream.toByteArray()
        docOutStream.close()

        return fileByte
    }

    static def outputFormat() {
        def outputFormat = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DOC_FORMAT' }?.valore
        switch (outputFormat) {
            case [null, 'DOCX']:
                return SaveFormat.DOCX
            case 'DOC':
                return SaveFormat.DOC
            case 'ODT':
                return SaveFormat.ODT
            default:
                throw new RuntimeException("Tipo formato output non supportato [${outputFormat}]")
        }
    }

    static def detectType(byte[] doc) {
        Detector detector = new CompositeDetector([
                new ZipContainerDetector(),
                new POIFSContainerDetector(),
                MimeTypes.defaultMimeTypes
        ])

        TikaConfig tikaConfig = TikaConfig.defaultConfig
        MediaType mediaType = detector.detect(TikaInputStream.get(doc), new Metadata())
        return tikaConfig.mimeRepository.forName(mediaType.toString())
    }


    static def mergePdf(def documents, def outputFolder) {

        def outputFileName = "${outputFolder}${UUID.randomUUID().toString()}.pdf"
        def inputStreamList = documents.collect { new FileInputStream(it) }
        def mergedDocument = new FileOutputStream(outputFileName)

        PDFMergerUtility merger = new PDFMergerUtility()
        merger.setDocumentMergeMode(PDFMergerUtility.DocumentMergeMode.OPTIMIZE_RESOURCES_MODE)
        merger.setDestinationStream(mergedDocument)

        merger.addSources(inputStreamList)
        merger.mergeDocuments(MemoryUsageSetting.setupTempFileOnly())

        mergedDocument.close()
        inputStreamList.each { it.close() }

        return outputFileName
    }

    static def mergePdf(List<byte[]> documents) {

        def inputStreamList = documents.collect { new ByteArrayInputStream(it) }
        def os = new ByteArrayOutputStream()

        PDFMergerUtility merger = new PDFMergerUtility()
        merger.setDocumentMergeMode(PDFMergerUtility.DocumentMergeMode.OPTIMIZE_RESOURCES_MODE)
        merger.setDestinationStream(os)

        merger.addSources(inputStreamList)
        merger.mergeDocuments(MemoryUsageSetting.setupTempFileOnly())

        def mergedBytes = os.toByteArray()

        os.close()
        inputStreamList.each { it.close() }

        return mergedBytes
    }

    static Boolean isBlank(PDDocument doc, int pageNumber) throws IOException {
        PDFRenderer pdfRenderer = new PDFRenderer(doc);
        BufferedImage bufferedImage = pdfRenderer.renderImage(pageNumber)
        long count = 0;
        int height = bufferedImage.getHeight();
        int width = bufferedImage.getWidth();
        Double areaFactor = (width * height) * 0.99;

        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                Color c = new Color(bufferedImage.getRGB(x, y));
                // verify light gray and white
                if (c.getRed() == c.getGreen() && c.getRed() == c.getBlue()
                        && c.getRed() >= 248) {
                    count++;
                }
            }
        }

        if (count >= areaFactor) {
            return true;
        }

        return false;
    }

}
