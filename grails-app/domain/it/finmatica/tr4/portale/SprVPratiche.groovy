package it.finmatica.tr4.portale

import org.hibernate.annotations.Immutable

@Immutable
class SprVPratiche {

    Long idPratica
    Integer annoPratica
    Long idSpr
    Long idApplicativo
    String tipoTributo
    Date dataRichiesta
    String numeroProtocollo
    String dataProtocollo
    String titolo
    String tipoStep
    String chiaveStep
    String nomeStep
    String ragioneSocialeRich
    String cognomeRich
    String nomeRich
    String codiceFiscaleRich
    String partitaIvaRich
    String ragioneSocialeBen
    String cognomeBen
    String nomeBen
    String codiceFiscaleBen
    String partitaIvaBen
    String indirizzoBen
    String comuneBen
    String provinciaBen

    static mapping = {
        id column:'id_pratica', name: 'idPratica'
        dataRichiesta column: 'datarichiesta'
        numeroProtocollo column: 'numeroprotocollo'
        dataProtocollo column: 'dataprotocollo'
        ragioneSocialeRich column: 'ragionesociale_rich'
        ragioneSocialeBen column: 'ragionesociale_ben'
        table "spr_v_pratiche"
        version false
    }
}
