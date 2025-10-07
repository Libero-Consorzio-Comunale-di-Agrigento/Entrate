package it.finmatica.tr4.modelli

import com.aspose.words.IReplacingCallback
import com.aspose.words.ReplaceAction
import com.aspose.words.ReplacingArgs

class ReplaceEvaluatorFind implements IReplacingCallback {

    def subModels = []

    ReplaceEvaluatorFind(subModels) {
        this.subModels = subModels
    }

    @Override
    int replacing(ReplacingArgs e) throws Exception {

        if (e.getMatch().hasGroup()) {
            (0..e.getMatch().groupCount() - 1).each {
                subModels << e.getMatch().group(it)
            }
        }

        return ReplaceAction.SKIP
    }
}
