package it.finmatica.tr4.contribuenti

class FiltroRicercaStatiContribuente {
    def tipoStatoContribuente
    def dataDa
    def dataA
    def annoDa
    def annoA

    void reset() {
        tipoStatoContribuente = null
        dataDa = null
        dataA = null
        annoDa = null
        annoA = null
    }

    boolean isActive() {
        return tipoStatoContribuente || dataDa || dataA || annoDa || annoA
    }

    void validate() {
        if (dataDa && dataA && dataDa.after(dataA)) {
            throw new IllegalArgumentException("Valori di Data non coerenti")
        }
        if (annoDa && annoA && annoDa > annoA) {
            throw new IllegalArgumentException("Valori di Anno non coerenti")
        }
    }
}
