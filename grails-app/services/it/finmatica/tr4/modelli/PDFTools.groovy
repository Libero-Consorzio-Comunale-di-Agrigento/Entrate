package it.finmatica.tr4.modelli


import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.PDPage
import org.apache.pdfbox.pdmodel.PDPageContentStream
import org.apache.pdfbox.pdmodel.common.PDRectangle
import org.apache.pdfbox.pdmodel.font.PDType1Font
import org.apache.pdfbox.pdmodel.graphics.state.RenderingMode
import org.apache.pdfbox.text.PDFTextStripper

class PDFTools extends AbstractModelliTools {

    PDFTools(byte[] doc) {
        super(doc)
    }

    @Override
    def finalizzaPagineDocumento() {
        PDDocument pdfDoc = PDDocument.load(doc)

        if (pdfDoc.numberOfPages % 2 != 0) {
            pdfDoc.addPage(new PDPage(PDRectangle.A4))
        }

        def bytes = ModelliCommons.fileDocToBytes(pdfDoc)

        pdfDoc.close()

        return bytes
    }

    @Override
    def creaPaginaBianca() {
        def bout = new ByteArrayOutputStream()
        def pdfDoc = PDDocument.load(doc)

        pdfDoc.addPage(new PDPage(pdfDoc.getPage(0).mediaBox))
        pdfDoc.save(bout)
        def pdfBytes = bout.toByteArray()

        pdfDoc.close()
        bout.close()

        return pdfBytes
    }

    @Override
    protected def _allegaPdf(byte[] pdf, def aggiungiPaginaBianca, def tag = null) {

        PDDocument pdfTmp = PDDocument.load(pdf)

        if (aggiungiPaginaBianca) {
            pdfTmp.pages.each {
                pdfTmp.pages.insertAfter(new PDPage(PDRectangle.A4), it)
            }
        }

        if (tag) {
            addTagToDocumentPages(pdfTmp, tag)
        }

        PDDocument pdfDoc = PDDocument.load(doc)
        if (pdfDoc.numberOfPages % 2 != 0) {
            pdfDoc.addPage(new PDPage(PDRectangle.A4))
        }

        def merged = ModelliCommons.mergePdf([ModelliCommons.fileDocToBytes(pdfDoc),
                                              ModelliCommons.fileDocToBytes(pdfTmp)])

        pdfDoc?.close()
        pdfTmp?.close()

        return merged
    }

    private void addTagToDocumentPages(PDDocument document, String tag) {
        document.pages.each { page ->
            PDPageContentStream contentStream = new PDPageContentStream(document, page, PDPageContentStream.AppendMode.APPEND, true)
            contentStream.beginText()
            contentStream.renderingMode = RenderingMode.NEITHER
            contentStream.setFont(PDType1Font.COURIER, 0.1f)
            contentStream.showText(tag);
            contentStream.endText()
            contentStream.close()
        }
    }

    def split(def tag) {
        def original = PDDocument.load(doc)
        def withoutTag = new PDDocument()
        def withTag = new PDDocument()

        for (int i = 0; i < original.getNumberOfPages(); i++) {
            PDFTextStripper pdfStripper = new PDFTextStripper()
            pdfStripper.setStartPage(i + 1)
            pdfStripper.setEndPage(i + 1)
            String pageText = pdfStripper.getText(original)
            if (pageText.contains(tag)) {
                withTag.addPage(original.getPage(i))
            } else {
                withoutTag.addPage(original.getPage(i))
            }
        }

        def docs = []
        if (withoutTag.getNumberOfPages() > 0) {
            docs.add(ModelliCommons.fileDocToBytes(withoutTag))
        }
        if (withTag.getNumberOfPages() > 0) {
            docs.add(ModelliCommons.fileDocToBytes(withTag))
        }

        original.close()
        withoutTag.close()
        withTag.close()

        return docs
    }
}
