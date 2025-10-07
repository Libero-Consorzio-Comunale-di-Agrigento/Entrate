package it.finmatica.tr4.portale

import it.finmatica.tr4.dto.portale.SprVPraticheDTO

interface IntegrazionePortaleStrategy {

    String getTipoTributoSupportato()

    String getCodiceApplicativo()

    List<Object> elencoDettagliPratica(Long idPratica)

    String acquisisciPratiche(List<SprVPraticheDTO> praticheDaAcquisire)
}
