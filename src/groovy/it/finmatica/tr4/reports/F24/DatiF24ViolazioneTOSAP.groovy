package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24Bean

class DatiF24ViolazioneTOSAP extends DatiF24ViolazioneICI {
    @Override
    List<F24Bean> getDatiF24(Long pratica, Boolean ridotto) {
        return super.getDatiF24(pratica, ridotto)
    }
}
