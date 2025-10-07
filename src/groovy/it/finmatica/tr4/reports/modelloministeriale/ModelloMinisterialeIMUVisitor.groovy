package it.finmatica.tr4.reports.modelloministeriale

class ModelloMinisterialeIMUVisitor implements ModelloMinisterialeVisitor {


    ModelloMinisterialeIMUContainer container

    Integer modelloCorrente
    Integer immobileCorrente
    Integer contitolareCorrente

    Integer immobiliPerModello
    Integer contitolariPerModello

    ModelloMinisterialeIMUVisitor(def immobiliPerModello = 3, def contitolariPerModello = 1) {
        this.container = new ModelloMinisterialeIMUContainer()
        this.modelloCorrente = 1
        this.immobileCorrente = 1
        this.contitolareCorrente = 1

        this.immobiliPerModello = immobiliPerModello
        this.contitolariPerModello = contitolariPerModello
    }


    @Override
    def visit(ModelloMinisterialeIMUContribuente contribuente) {
        container.contribuente = contribuente
        return container
    }

    @Override
    def visit(ModelloMinisterialeIMUDichiarante dichiarante) {
        container.dichiarante = dichiarante
        return container
    }

    @Override
    def visit(ModelloMinisterialeIMUImmobile immobile) {

        immobile.numeraImmobile(immobileCorrente++)

        // Prende l'ultimo modello che ha uno slot disponibile
        ModelloMinisterialeIMU modello = container.getModelloImmobiliCorrente()

        if (modello) {
            // In caso affermativo si imposta l'immobile
            modello.aggiungiImmobile(immobile)
            aggiornaUltimiModelli("immobili", modello)
        } else {
            // Altrimenti viene creato un nuovo modello e l'immobile impostato come primo
            ModelloMinisterialeIMU modelloNew = new ModelloMinisterialeIMU(modelloCorrente++)
            modelloNew.aggiungiImmobile(immobile)

            container.aggiungiModello(modelloNew)
            aggiornaUltimiModelli("immobili", modelloNew)
        }

        return container
    }

    @Override
    def visit(ModelloMinisterialeIMUContitolare contitolare) {

        contitolare.numeraContitolare(contitolareCorrente++)

        // Prende l'ultimo modello che ha uno slot disponibile
        ModelloMinisterialeIMU modello = container.getModelloContitolariCorrente()

        if (modello) {
            // In caso affermativo si imposta il contitolare
            modello.aggiungiContitolare(contitolare)
            aggiornaUltimiModelli("contitolari", modello)
        } else {
            // Altrimenti viene creato un nuovo modello e il contitolare impostato come primo
            ModelloMinisterialeIMU modelloNew = new ModelloMinisterialeIMU(modelloCorrente++)
            modelloNew.aggiungiContitolare(contitolare)

            container.aggiungiModello(modelloNew)
            aggiornaUltimiModelli("contitolari", modelloNew)
        }

        return container
    }

    private def aggiornaUltimiModelli(def tipo, ModelloMinisterialeIMU modello) {

        if (tipo == "immobili" && modello.immobili.size() == immobiliPerModello) {
            container.avanzaModelloImmobili()
        }

        if (tipo == "contitolari" && modello.contitolari.size() == contitolariPerModello) {
            container.avanzaModelloContitolari()
        }

    }
}
