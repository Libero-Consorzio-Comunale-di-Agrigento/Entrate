package it.finmatica.tr4.modelli

import com.aspose.words.*
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.rendering.PDFRenderer
import org.apache.pdfbox.tools.imageio.ImageIOUtil

import java.awt.image.BufferedImage

class WordTools extends AbstractModelliTools {

    WordTools(byte[] doc) {
        super(doc)
    }

    @Override
    def finalizzaPagineDocumento() {

        def wordDoc = ModelliCommons.fileBytesToDoc(doc)

        // Se vuota si rimuove l'ultima pagina
        if (wordDoc.lastSection.body.lastParagraph.toString(SaveFormat.TEXT).trim().isEmpty() &&
                wordDoc.lastSection.body.lastParagraph.getChildNodes(NodeType.SHAPE, true).count == 0) {
            wordDoc.lastSection.body.lastParagraph.remove()
        }

        // Se le pagine sono dispari se ne aggiunge una bianca
        if (wordDoc.pageCount % 2 != 0) {
            wordDoc.appendDocument(
                    ModelliCommons.fileBytesToDoc(ModelliCommons.creaPaginaBianca(doc)),
                    ImportFormatMode.KEEP_SOURCE_FORMATTING)
        }

        return ModelliCommons.fileDocToBytes(wordDoc)
    }

    @Override
    def creaPaginaBianca() {
        def docPs = new DocumentBuilder(
                ModelliCommons.fileBytesToDoc(doc)
        ).pageSetup

        Document newDoc = new Document()
        DocumentBuilder builder = new DocumentBuilder(newDoc)
        def newDocPs = builder.pageSetup
        newDocPs.pageHeight = docPs.pageHeight
        newDocPs.pageWidth = docPs.pageWidth
        newDocPs.leftMargin = docPs.leftMargin
        newDocPs.rightMargin = docPs.rightMargin
        newDocPs.topMargin = docPs.topMargin
        newDocPs.bottomMargin = docPs.bottomMargin

        return ModelliCommons.fileDocToBytes(newDoc)
    }

    @Override
    protected def _allegaPdf(byte[] pdf, def aggiungiPaginaBianca, def tag) {
        def pdfDoc = PDDocument.load(pdf)
        PDFRenderer pdfRenderer = new PDFRenderer(pdfDoc)

        Document newDoc = new Document()
        DocumentBuilder builder = new DocumentBuilder(newDoc)
        PageSetup newDocPs = builder.pageSetup
        newDocPs.paperSize = PaperSize.A4
        newDocPs.topMargin = 0
        newDocPs.bottomMargin = 0
        newDocPs.leftMargin = 0
        newDocPs.rightMargin = 0
        newDocPs.headerDistance = 0
        newDocPs.footerDistance = 0
        newDocPs.differentFirstPageHeaderFooter = true
        builder.getParagraphFormat().alignment = ParagraphAlignment.CENTER

        def nPages = pdfDoc.numberOfPages
        (0..nPages - 1).each {
            OutputStream out = new ByteArrayOutputStream()
            BufferedImage bim = pdfRenderer.renderImageWithDPI(it, 100, org.apache.pdfbox.rendering.ImageType.RGB)
            ImageIOUtil.writeImage(bim, "jpg", out)

            builder.insertImage(out.toByteArray())

            if (aggiungiPaginaBianca)
                builder.insertParagraph()
            builder.insertParagraph()
        }

        newDoc.firstSection.headersFooters.linkToPrevious(false)
        def dstDoc = ModelliCommons.fileBytesToDoc(doc)

        dstDoc.appendDocument(newDoc, ImportFormatMode.KEEP_SOURCE_FORMATTING)

        if (pdfDoc) {
            pdfDoc.close()
        }

        return ModelliCommons.fileDocToBytes(dstDoc)
    }
}
