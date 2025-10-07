package it.finmatica.tr4.modelli

import com.aspose.words.IReplacingCallback
import com.aspose.words.Paragraph
import com.aspose.words.ReplaceAction
import com.aspose.words.ReplacingArgs

class ReplaceSubModel implements IReplacingCallback {

    private def subModel

    ReplaceSubModel(subModel) {
        this.subModel = subModel
    }

    @Override
    int replacing(ReplacingArgs args) throws Exception {

        // Insert a document after the paragraph, containing the match text.
        def para = (Paragraph) args.matchNode.parentNode
        AsposeUtils.insertDocument(para, subModel)

        // Remove the paragraph with the match text.
        para.remove()

        return ReplaceAction.SKIP
    }
}
