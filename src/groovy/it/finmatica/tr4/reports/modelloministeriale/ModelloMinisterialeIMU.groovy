package it.finmatica.tr4.reports.modelloministeriale

class ModelloMinisterialeIMU {

    Integer numeroModello
    Integer modelliTotali

    List<ModelloMinisterialeIMUImmobile> immobili
    // Non trattata per il momento
    List<ModelloMinisterialeIMUContitolare> contitolari

    ModelloMinisterialeIMU(def numeroModello) {
        this.numeroModello = numeroModello
        immobili = []
        contitolari = []
    }

    def aggiungiImmobile(ModelloMinisterialeIMUImmobile immobile) {
        this.immobili << immobile
    }

    def aggiungiContitolare(ModelloMinisterialeIMUContitolare contitolare) {
        this.contitolari << contitolare
    }

    def setModelliTotali(def modelliTotali) {
        this.modelliTotali = modelliTotali
    }

    def setNumeroModello(def numeroModello) {
        this.numeroModello = numeroModello
    }

    def getNumeroModello() {
        return this.numeroModello
    }

    def getModelliTotali() {
        return this.modelliTotali
    }

}
