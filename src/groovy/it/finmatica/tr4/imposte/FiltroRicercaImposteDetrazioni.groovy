package it.finmatica.tr4.imposte

class FiltroRicercaImposteDetrazioni {

    // Comuni
    def tipoTributo = null
    def annoDa = null
    def annoA = null

    // Solo Detrazioni
    def detrazioneDa = null
    def detrazioneA = null
    def motivoDa = null
    def motivoA = null

    // Solo Aliquote
    def tipoAliquotaDa = null
    def tipoAliquotaA = null
    def ordinamento = "ALFA"


    def preparaRicercaDetrazioni() {

        def parRicerca = [
                tipoTributo   : tipoTributo,
                annoDa        : annoDa,
                annoA         : annoA,
                detrazioneDa  : detrazioneDa,
                detrazioneA   : detrazioneA,
                motivoDa      : motivoDa,
                motivoA       : motivoA,
                tipoAliquotaDa: tipoAliquotaDa,
                tipoAliquotaA : tipoAliquotaA,
                ordinamento   : ordinamento
        ]

        return parRicerca
    }

    def applicaRicercaDetrazioni(def parRicerca) {

        tipoTributo = parRicerca.tipoTributo
        annoDa = parRicerca.annoDa
        annoA = parRicerca.annoA
        detrazioneDa = parRicerca.detrazioneDa
        detrazioneA = parRicerca.detrazioneA
        motivoDa = parRicerca.motivoDa
        motivoA = parRicerca.motivoA
        tipoAliquotaDa = parRicerca.tipoAliquotaDa
        tipoAliquotaA = parRicerca.tipoAliquotaA
        ordinamento = parRicerca.ordinamento
    }

    Boolean isDirtyDetrazioni(def listaMotivi) {

        return (annoDa != null) ||
                (annoA != null) ||
                (detrazioneDa != null) ||
                (detrazioneA != null) ||
                (motivoDa != listaMotivi[0]) ||
                (motivoA != listaMotivi.reverse()[0])
    }

    Boolean isDirtyAliquote(def listaTipiAliquote) {

        return (annoDa != null) ||
                (annoA != null) ||
                (tipoAliquotaDa != listaTipiAliquote[0]) ||
                (tipoAliquotaA != listaTipiAliquote.reverse()[0])
    }

}
