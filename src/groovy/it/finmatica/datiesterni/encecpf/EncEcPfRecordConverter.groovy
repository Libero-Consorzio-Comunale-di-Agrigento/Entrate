package it.finmatica.datiesterni.encecpf

import org.apache.log4j.Logger

abstract class EncEcPfRecordConverter {

    protected static final Logger log = Logger.getLogger(EncEcPfRecordConverter.class)

    protected enum RIDUZIONI {
        NESSUNA(0),
        STORICO_ARTISTICO(1),
        INAGIBILE_INABITABILE(2),
        ALTRO(3)

        private final int value

        private RIDUZIONI(int value) {
            this.value = value
        }

        int getValue() {
            return value
        }
    }

    protected enum ESENZIONI {
        NESSUNA(0),
        NON_UTILIZZABILE_DISPONIBILE(1),
        AIUTI_STATO(2),
        ALTRO(3)

        private final int value

        private ESENZIONI(int value) {
            this.value = value
        }

        int getValue() {
            return value
        }
    }

    abstract def convert(def record,
                         def params,
                         def fields)

    final protected def leggiValore(def campo) {
        try {
            switch (campo.formato) {
                case ['AN', 'CF', 'CN']:
                    return campo.valore.trim()
                case 'NU':
                    return campo.valore.trim().empty ? null : parseNum(campo.valore.trim())
                case 'DT':
                    return campo.valore.trim().empty ? null : parseDate(campo.valore.trim())
                case 'CB':
                    return campo.valore as Byte
                default:
                    return campo.valore
            }
        } catch (Exception e) {
            log.error(e, e)
            throw new RuntimeException("Valore non valido per [$campo]")
        }
    }

    final private parseDate(def valore) {
        if (valore?.trim()) {
            try {
                return Date.parse('ddMMyyyy', valore)
            } catch (Exception e) {
                log.error(e, e)
                throw new RuntimeException("Valore data non valido [${valore}], pattern attesso [GGMMAAAA]")
            }
        }

        return null
    }

    final private def parseNum(def valore) {
        if (valore?.trim()) {
            try {
                return valore.toInteger()
            } catch (Exception e) {
                log.error(e, e)
                throw new RuntimeException("Valore numerico non valido [${valore}]")
            }
        }

        return null
    }

    final protected void concat(Map valori, List campi, String campoDestinazione, String separatore = '') {
        def concatenazione = campi.collect { valori[it] }.join(separatore)
        valori[campoDestinazione] = concatenazione
        campi.each { valori.remove(it) }
    }

    final protected void toDecimalNumber(Map valori, String campoParteIntera, String campoParteDecimale, String campoDestinazione) {
        if (valori[campoParteIntera] == null && valori[campoParteDecimale] == null) {
            valori[campoDestinazione] = null
        } else {
            valori[campoDestinazione] = valori[campoParteIntera] + (valori[campoParteDecimale] / 100)
        }
        valori.remove(campoParteIntera)
        valori.remove(campoParteDecimale)
    }

    final protected void immobileStorico(Map valori) {
        if (valori.codiceRiduzione == RIDUZIONI.STORICO_ARTISTICO.value) {
            valori.immobileStorico = 'S'
        }
    }

    final protected void esenzione(Map valori) {
        if (valori.codiceEsenzione != ESENZIONI.NESSUNA.value) {
            valori.immobileEsente = 1
        }
    }

    final protected void normalizzaPercentuali(Map valori) {
        def estratti = valori.findAll { it.key.endsWith('ParteIntera') || it.key.endsWith('ParteDecimale') }
        def raggruppati = [:]

        estratti.each { key, value ->
            def prefisso = key.replaceAll(/ParteIntera|ParteDecimale/, '')
            if (!raggruppati.containsKey(prefisso)) {
                raggruppati[prefisso] = []
            }
            raggruppati[prefisso] << key
        }

        raggruppati.each { k, v ->
            toDecimalNumber(valori, v[0], v[1], k)
        }
    }
}
