package it.finmatica.tr4.imposte

class FiltroRicercaImposte {

    String tipoTributo = null
    Boolean tributo = false
    List<Short> anni = []

    /// Filtri generali tipo lista
    String tipoLista = 'X-XX'
    String tipoListaContribuentiCUNI = 'P-AP'
    String tipoListaDettaglioCUNI = 'X-AC'
    String tipoListaOggettiCUNI = 'X-XX'

    /// Parte Comune
    String cognomeNome = ""
    String nome = ""
    String cognome = ""
    String codFiscale = ""

    /// Per contribuenti
    Date daDataPratica = null
    Date aDataPratica = null
    Date daDataCalcolo = null
    Date aDataCalcolo = null
    String tipoOccupazione = null
    Boolean personaFisica = true
    Boolean personaGiuridica = true
    Boolean intestazioniParticolari = true
    Integer tipoContatto = null

    /// Per dettaglio e per Oggetti
    String indirizzo = null
    String numeroCivico = null
    String suffisso = null
    String interno = null
    String sezione = null
    String foglio = null
    String numero = null
    String subalterno = null
    Date daDataDecorrenza = null
    Date aDataDecorrenza = null
    Date daDataCessazione = null
    Date aDataCessazione = null

    def preparaRicercaContribuenti() {

        def parRicerca = [
                cognome                : cognome,
                nome                   : nome,
                cf                     : codFiscale,
                daDataPratica          : daDataPratica,
                aDataPratica           : aDataPratica,
                daDataCalcolo          : daDataCalcolo,
                aDataCalcolo           : aDataCalcolo,
                personaFisica          : personaFisica,
                personaGiuridica       : personaGiuridica,
                intestazioniParticolari: intestazioniParticolari,
                tipoOccupazione        : tipoOccupazione,
                tipoContatto           : tipoContatto
        ]

        if (tipoTributo == 'CUNI') {
            parRicerca.tipoLista = tipoListaContribuentiCUNI
        } else {
            parRicerca.tipoLista = tipoLista
        }

        return parRicerca
    }

    def applicaRicercaContribuenti(def parRicerca) {

        cognome = parRicerca.cognome
        nome = parRicerca.nome
        codFiscale = parRicerca.cf
        daDataPratica = parRicerca.daDataPratica
        aDataPratica = parRicerca.aDataPratica
        daDataCalcolo = parRicerca.daDataCalcolo
        aDataCalcolo = parRicerca.aDataCalcolo
        tipoOccupazione = parRicerca.tipoOccupazione
        personaFisica = parRicerca.personaFisica
        personaGiuridica = parRicerca.personaGiuridica
        intestazioniParticolari = parRicerca.intestazioniParticolari
        tipoContatto = parRicerca.tipoContatto

        if (tipoTributo == 'CUNI') {
            tipoListaContribuentiCUNI = parRicerca.tipoLista
        } else {
            tipoLista = parRicerca.tipoLista
        }
    }

    Boolean isDirtyContribuenti() {

        return (cognome != "" || nome != "" || codFiscale != "" ||
                daDataPratica != null || aDataPratica != null ||
                daDataCalcolo != null || aDataCalcolo != null ||
                tipoOccupazione != null || (personaFisica != true || personaGiuridica != true || intestazioniParticolari != true) ||
                tipoOccupazione != null || tipoContatto != null)
    }

    def preparaRicercaDettaglio() {

        def parRicerca = [
                nome                   : nome,
                cognome                : cognome,
                cf                     : codFiscale,
                indirizzo              : indirizzo,
                numeroCivico           : numeroCivico,
                suffisso               : suffisso,
                interno                : interno,
                sezione                : sezione,
                foglio                 : foglio,
                numero                 : numero,
                subalterno             : subalterno,
                daDataDecorrenza       : daDataDecorrenza,
                aDataDecorrenza        : aDataDecorrenza,
                daDataCessazione       : daDataCessazione,
                aDataCessazione        : aDataCessazione,
                personaFisica          : personaFisica,
                personaGiuridica       : personaGiuridica,
                intestazioniParticolari: intestazioniParticolari
        ]

        if (tipoTributo == 'CUNI') {
            parRicerca.tipoLista = tipoListaDettaglioCUNI
        } else {
            parRicerca.tipoLista = tipoLista
        }

        return parRicerca
    }

    def applicaRicercaDettaglio(def parRicerca) {

        nome = parRicerca.nome
        cognome = parRicerca.cognome
        codFiscale = parRicerca.cf
        indirizzo = parRicerca.indirizzo
        numeroCivico = parRicerca.numeroCivico
        suffisso = parRicerca.suffisso
        interno = parRicerca.interno
        sezione = parRicerca.sezione
        foglio = parRicerca.foglio
        numero = parRicerca.numero
        subalterno = parRicerca.subalterno
        daDataDecorrenza = parRicerca.daDataDecorrenza
        aDataDecorrenza = parRicerca.aDataDecorrenza
        daDataCessazione = parRicerca.daDataCessazione
        aDataCessazione = parRicerca.aDataCessazione
        personaGiuridica = parRicerca.personaGiuridica
        intestazioniParticolari = parRicerca.intestazioniParticolari
        personaFisica = parRicerca.personaFisica

        if (tipoTributo == 'CUNI') {
            tipoListaDettaglioCUNI = parRicerca.tipoLista
        } else {
            tipoLista = parRicerca.tipoLista
        }
    }

    Boolean isDirtyDettaglio() {

        return (cognome != "" || nome != "" || codFiscale != ""
                || indirizzo != null || numeroCivico != null
                || suffisso != null || interno != null
                || sezione != null || foglio != null
                || numero != null || subalterno != null
                || daDataDecorrenza != null || aDataDecorrenza != null
                || daDataCessazione != null || aDataCessazione != null || (personaFisica != true || personaGiuridica != true || intestazioniParticolari != true))
    }

    def preparaRicercaOggetti() {

        def parRicerca = [
                nome                   : nome,
                cognome                : cognome,
                cf                     : codFiscale,
                indirizzo              : indirizzo,
                numeroCivico           : numeroCivico,
                suffisso               : suffisso,
                interno                : interno,
                sezione                : sezione,
                foglio                 : foglio,
                numero                 : numero,
                subalterno             : subalterno,
                daDataDecorrenza       : daDataDecorrenza,
                aDataDecorrenza        : aDataDecorrenza,
                daDataCessazione       : daDataCessazione,
                aDataCessazione        : aDataCessazione,
                personaFisica          : personaFisica,
                personaGiuridica       : personaGiuridica,
                intestazioniParticolari: intestazioniParticolari
        ]

        if (tipoTributo == 'CUNI') {
            parRicerca.tipoLista = tipoListaOggettiCUNI
        } else {
            parRicerca.tipoLista = tipoLista
        }

        return parRicerca
    }

    def applicaRicercaOggetti(def parRicerca) {

        nome = parRicerca.nome
        cognome = parRicerca.cognome
        codFiscale = parRicerca.cf
        indirizzo = parRicerca.indirizzo
        numeroCivico = parRicerca.numeroCivico
        suffisso = parRicerca.suffisso
        interno = parRicerca.interno
        sezione = parRicerca.sezione
        foglio = parRicerca.foglio
        numero = parRicerca.numero
        subalterno = parRicerca.subalterno
        daDataDecorrenza = parRicerca.daDataDecorrenza
        aDataDecorrenza = parRicerca.aDataDecorrenza
        daDataCessazione = parRicerca.daDataCessazione
        aDataCessazione = parRicerca.aDataCessazione
        personaFisica = parRicerca.personaFisica
        personaGiuridica = parRicerca.personaGiuridica
        intestazioniParticolari = parRicerca.intestazioniParticolari

        if (tipoTributo == 'CUNI') {
            tipoListaOggettiCUNI = parRicerca.tipoLista
        } else {
            tipoLista = parRicerca.tipoLista
        }
    }

    Boolean isDirtyOggetti() {

        return (cognome != "" || nome != "" || codFiscale != ""
                || indirizzo != null || numeroCivico != null
                || suffisso != null || interno != null
                || sezione != null || foglio != null
                || numero != null || subalterno != null
                || daDataDecorrenza != null || aDataDecorrenza != null
                || daDataCessazione != null || aDataCessazione != null
                || !personaFisica || !personaGiuridica || !intestazioniParticolari)
    }
}
