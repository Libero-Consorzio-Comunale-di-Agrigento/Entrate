package it.finmatica.zkutils

import org.zkoss.bind.BindContext
import org.zkoss.bind.Converter
import org.zkoss.zk.ui.Component

class CheckBoxConverter implements Converter {
    Object coerceToUi(Object o, Component component, BindContext bindContext) {
        return o != null
    }

    Object coerceToBean(Object o, Component component, BindContext bindContext) {
        return (o ? 1 as Byte : null)
    }
}
