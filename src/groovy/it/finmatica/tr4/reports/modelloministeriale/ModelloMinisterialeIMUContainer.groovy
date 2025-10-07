package it.finmatica.tr4.reports.modelloministeriale

class ModelloMinisterialeIMUContainer {

    List<ModelloMinisterialeIMU> listaModelli = []

    ModelloMinisterialeIMUContribuente contribuente
    ModelloMinisterialeIMUDichiarante dichiarante

    // Tengono traccia dell'ultimo modello con slot disponibile
    Integer ultimoModLiberoImmobile = 0
    Integer ultimoModLiberoContitolare = 0


    Integer totaleModelli() {
        return listaModelli.size()
    }

    def aggiungiModello(ModelloMinisterialeIMU modello) {
        listaModelli << modello
    }

    def getModello(def position) {
        return listaModelli[position]
    }

    def getUltimoModello() {
        return listaModelli[totaleModelli() - 1]
    }

    def avanzaModelloImmobili() {
        this.ultimoModLiberoImmobile++
    }

    def getModelloImmobiliCorrente(){
        if (ultimoModLiberoImmobile > listaModelli.size() - 1) {
            return null
        } else {
            return listaModelli[ultimoModLiberoImmobile]
        }
    }

    def getModelloContitolariCorrente(){
        if (ultimoModLiberoContitolare > listaModelli.size() - 1) {
            return null
        } else {
            return listaModelli[ultimoModLiberoContitolare]
        }
    }

    def avanzaModelloContitolari() {
        this.ultimoModLiberoContitolare++
    }

    def finalizzaModelli() {
        listaModelli.each {
            it.setModelliTotali(listaModelli.size())
        }
    }

}
