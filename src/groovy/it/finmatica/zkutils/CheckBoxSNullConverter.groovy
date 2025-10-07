package it.finmatica.zkutils

import org.zkoss.bind.BindContext
import org.zkoss.bind.Converter
import org.zkoss.zk.ui.Component

class CheckBoxSNullConverter implements Converter {
    Object coerceToUi(Object o, Component component, BindContext bindContext) {
        return o == 'S'
    }

    Object coerceToBean(Object o, Component component, BindContext bindContext) {
        return (o ? 'S' : null)
    }
}
