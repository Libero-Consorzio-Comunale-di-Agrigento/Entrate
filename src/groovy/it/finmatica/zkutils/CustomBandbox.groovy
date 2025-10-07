package it.finmatica.zkutils

import org.zkoss.zk.ui.IdSpace
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Listen
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.*
import org.zkoss.zk.ui.event.EventListener

abstract class CustomBandbox extends Bandbox implements IdSpace {

    @Wire("listbox")
    protected Listbox lista
    @Wire("paging")
    protected Paging paging

    protected abstract def codice

    private def oggetto

    protected def listaFetch

    protected boolean nascondiMessaggioListaVuota = true

    private boolean changeEventEnabled = true
    private boolean changingEventEnabled = true
    private boolean openEventEnabled = true

    CustomBandbox() {
        this.addEventListener(Events.ON_CHANGE, new EventListener() {
            void onEvent(Event event) {

                getOggetto()[getProprieta()] = event.getValue()

                if (!isChangeEventEnabled()) {
                    return
                }

                // Se ho modificato il dato e non ho selezionato dalla listbox della bandbox, devo validare il dato
                // e quindi verificare se esiste almeno un record corrispondente al criterio di ricerca impostato
                if (getOggetto() != null && getOggetto()[getProprieta()] != "" && lista.getSelectedItem() == null) {

                    paging.setActivePage(0)
                    loadData()

                    if (paging.getTotalSize() == 0) {

                        //se non presente o valorizzato a true: si mostra la dialog di errore
                        //se valorizzato a false si nasconde la dialog.
                        if (nascondiMessaggioListaVuota) {
                            Messagebox.show("Dato non valido", "Gestione Tributi", Messagebox.OK, Messagebox.ERROR)
                        }

                    } else {
                        setOpen(true)
                    }

                    controllaSingoloElemento()
                }
            }
        })

        this.addEventListener(Events.ON_CHANGING, new EventListener() {
            void onEvent(Event event) {

                if (!isChangingEventEnabled()) {
                    return
                }

                if (getOggetto() == null) {

                    paging.setActivePage(0)
                    codice = event?._val
                    loadData()

                    if (paging.getTotalSize() == 0) {
                        Messagebox.show("Dato non valido", "Gestione Tributi", Messagebox.OK, Messagebox.ERROR)
                    } else {
                        setOpen(true)
                    }
                } else {
                    if (event.getValue() != getOggetto()[getProprieta()]) {
                        getOggetto()[getProprieta()] = event.getValue()
                        if (event.getTarget().isOpen()) {
                            paging.setActivePage(0)
                            loadData()
                        }
                    }

                    controllaSingoloElemento()
                }
            }
        })

        this.addEventListener(Events.ON_OPEN, new EventListener() {
            void onEvent(Event event) {
                if (!isOpenEventEnabled()) return
                if (event.open) {
                    paging.setActivePage(0)
                    loadData()
                }
            }
        })

        (this as Textbox).addEventListener(Events.ON_BLUR, {
            _ ->

                if (lista.model?.size() > 1 && isChangeEventEnabled() && this.value?.trim() && !lista.getSelectedItem()) {
                    setOpen(false)
                    this.value = null
                    getOggetto()[getProprieta()] = null
                    Events.postEvent('onReset', this, null)
                }

                if (!this.value?.trim()) {
                    setOpen(false)
                    this.value = null
                    getOggetto()[getProprieta()] = null
                    Events.postEvent('onReset', this, null)
                }
        })

        setAutodrop(false)
        setMold("rounded")
    }

    void setOggetto(def oggetto) {
        if (oggetto != null) {
            this.oggetto = oggetto
            setValue(getOggetto()[getProprieta()])
        }
    }

    def getOggetto() {
        return this.oggetto
    }

    String getProprieta() {
        return this.getAttribute("proprieta")
    }

    void setListaFetch(def listaFetch) {
        this.listaFetch = listaFetch
    }

    def getListaFetch() {
        return this.listaFetch
    }

    boolean getNascondiMessaggioListaVuota() {
        return (nascondiMessaggioListaVuota == null) ? true : nascondiMessaggioListaVuota
    }

    void setNascondiMessaggioListaVuota(boolean nascondiMessaggioListaVuota) {
        this.nascondiMessaggioListaVuota = nascondiMessaggioListaVuota
    }

    protected abstract void loadData()

    // Per gestire il caso in cui la ricerca restituisca un solo elemento
    protected abstract void controllaSingoloElemento()

    @Listen("onSelect = listbox")
    void selectData() {
        if (lista.getSelectedItem()) {
            getOggetto()[getProprieta()] = (lista.getSelectedItem().getValue().hasProperty(getProprieta()) ? (lista.getSelectedItem().getValue()[getProprieta()] ?: "") : "")
            setValue(getOggetto()[getProprieta()])
            Events.postEvent(Events.ON_SELECT, this, lista.getSelectedItem().getValue())
            close()
        }
    }

    @Listen("onPaging = paging")
    void onPaging() {
        loadData()
    }

    void setChangeEventEnabled(boolean value) {
        this.changeEventEnabled = value
    }

    boolean isChangeEventEnabled() {
        return this.changeEventEnabled
    }

    void setChangingEventEnabled(boolean value) {
        this.changingEventEnabled = value
    }

    boolean isChangingEventEnabled() {
        return this.changingEventEnabled
    }

    void setOpenEventEnabled(boolean value) {
        this.openEventEnabled = value
    }

    boolean isOpenEventEnabled() {
        return this.openEventEnabled
    }

    private void chiudiPopup() {

    }

}
