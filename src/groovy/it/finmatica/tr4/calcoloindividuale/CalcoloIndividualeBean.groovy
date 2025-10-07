package it.finmatica.tr4.calcoloindividuale

import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.OggettoImpostaDTO

class CalcoloIndividualeBean {

    Short anno
    String tipoTributo
    ContribuenteDTO contribuente
    List<OggettoImpostaDTO> listaOggetti
    def listaImposte
}
