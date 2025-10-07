package it.finmatica.tr4.modelli

import com.aspose.words.IReplacingCallback
import com.aspose.words.Paragraph
import com.aspose.words.ReplaceAction
import com.aspose.words.ReplacingArgs

class ReplaceBlankLine implements IReplacingCallback {

    @Override
    int replacing(ReplacingArgs args) throws Exception {

        if (args.matchNode.text == (args.matchNode.parentNode.text - "\r" - "\n" - "\t")) {
            ((Paragraph) args.matchNode.parentNode).remove()
        }

        return ReplaceAction.SKIP
    }
}
