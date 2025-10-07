package it.finmatica.tr4.portale

import groovy.transform.EqualsAndHashCode
import org.hibernate.annotations.Immutable

@Immutable
@EqualsAndHashCode(includes = ['idPratica', 'sequenzaImmobile'])
class SprVIciPraticheDettagli implements Serializable {

    Long idPratica
    String acquistoCessioneAltro
    Integer annoProtocollo
    String autorita
    String caratteristicaImmobile
    String catastoFoglio
    String catastoParticella
    String catastoSezione
    String catastoSubalterno
    String categoriaQualita
    String classe
    String comuneResidenza
    String dataDenunciaProvvedimento
    String dataPossessoVariazione
    String descrizioneAltroAcquistoCessione
    BigDecimal detrazioneAbitazionePrincipale
    String equiparazioneAbitazionePrincipale
    String esenzioni
    String indirizzoCap
    String indirizzoCivico
    String indirizzoDenominazione
    String indirizzoProvincia
    String indirizzoToponimo
    String inizioTermineAgevolazione
    String numeroProtocollo
    BigDecimal percPossesso
    String riduzioni
    Long sequenzaImmobile
    String tipoAgevolazione
    String tU
    BigDecimal valore

    static mapping = {
        id composite: ['idPratica', 'sequenzaImmobile']
        table 'SPR_V_ICI_PRATICHE_DETTAGLI'
        tU column: 'T_U'
        detrazioneAbitazionePrincipale column: 'DETRAZIONE_ABIT_PRINCIPALE'
        equiparazioneAbitazionePrincipale column: 'EQUIPARAZIONE_ABIT_PRINCIPALE'
        descrizioneAltroAcquistoCessione column: 'DESC_ALTRO_ACQUISTO_CESSIONE'
        version false
    }
}
