package it.finmatica.zkutils

import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.IdSpace
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Div
import org.zkoss.zul.Image
import org.zkoss.zul.Label

class LabelWithButton extends Div implements IdSpace {

    @Wire('div')
    Div div
    @Wire('label')
    Label label
    @Wire('image')
    Image image

    String value
    def tooltiptext
    def src
    def buttonSize = '16px'
    def showButtonIfEmpty = false
    def dialogTitle

    LabelWithButton() {
        super()

        Executions.createComponents("/commons/labelWithButton.zul", this, null)

        Selectors.wireVariables(this, this, null)
        Selectors.wireComponents(this, this, false)
        Selectors.wireEventListeners(this, this)
    }

    String getValue() {
        return this.value
    }

    void setValue(String value) {
        this.value = value
        label.value = value
        image.tooltiptext = value
    }

    String getTooltiptext() {
        return tooltiptext
    }

    void setTooltiptext(String tooltiptext) {
        this.tooltiptext = tooltiptext
        image.tooltiptext = tooltiptext
    }

    def setImage(String src) {
        this.src = src
    }

    def setButtonSize(String buttonSize) {
        this.buttonSize = buttonSize
    }


    def getDialogTitle() {
        return dialogTitle
    }

    def setDialogTitle(String dialogTitle) {
        this.dialogTitle = dialogTitle
    }

    void setPopup(String popup) {
        image.setPopup(popup)
    }

    void setShowButtonIfEmpty(boolean showButtonIfEmpty) {
        this.showButtonIfEmpty = showButtonIfEmpty
    }

    // onCreate is fired before data is send to the client,
    // but after the Component and all it children exists.
    def onCreate() {
        this.getEventListeners(Events.ON_CLICK).each {
            if (removeEventListener(Events.ON_CLICK, it)) {
                image.addEventListener(Events.ON_CLICK, it)
            }

        }
        image.src = src
        image.height = buttonSize
        image.width = buttonSize
        image.visible = value?.trim() ? true : showButtonIfEmpty
    }

}
