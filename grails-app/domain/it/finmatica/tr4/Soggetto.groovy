package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.tipi.SiNoType

class Soggetto implements Serializable {

    ArchivioVie archivioVie
    Fonte fonte
    TipoCarica tipoCarica
    Soggetto soggettoPresso

    boolean tipoResidente
    Long matricola
    String codFiscale
    String cognomeNome
    //String 		cognNome
    Integer fascia
    Anadev stato
    Date dataUltEve

    String sesso
    Long codFam
    String rapportoPar
    Byte sequenzaPar
    Date dataNas

    Ad4ComuneTr4 comuneResidenza
    Ad4ComuneTr4 comuneNascita
    Ad4ComuneTr4 comuneEvento
    Ad4ComuneTr4 comuneRap

    Integer cap
    Integer codProf
    Byte pensionato
    String denominazioneVia
    Integer numCiv
    String suffisso
    String scala
    String piano
    Integer interno
    String partitaIva
    String rappresentante
    String indirizzoRap

    String codFiscaleRap
    String tipo
    String gruppoUtente
    String cognome
    String nome
    Ad4Utente utente
    Date lastUpdated
    String note
    String intestatarioFam
    String zipcode
    String nomeRic
    String cognomeRic

    boolean flagCfCalcolato
    boolean flagEsenzione

    static hasMany = [storicoSoggetto    : StoricoSoggetti
                      , familiariSoggetto: FamiliareSoggetto
                      , erediSoggetto    : EredeSoggetto
                      , recapitiSoggetto : RecapitoSoggetto
                      , contribuenti     : Contribuente]


    static mapping = {
        id column: "ni", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SOGGETTI_NR"]
        archivioVie column: "cod_via"
        fonte column: "fonte"
        tipoCarica column: "tipo_carica"
        soggettoPresso column: "ni_presso"
        stato column: "stato"
        utente column: "utente", ignoreNotFound: true
        dataUltEve sqlType: 'Date'
        dataNas sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        nomeRic column: "nome_ric"
        cognomeRic column: "cognome_ric"

        //cognNome formula: "replace(cognome_nome, '/', ' ')"

        columns {
            comuneNascita {
                column name: "cod_com_nas"
                column name: "cod_pro_nas"
            }
            comuneResidenza {
                column name: "cod_com_res"
                column name: "cod_pro_res"
            }
            comuneEvento {
                column name: "cod_com_eve"
                column name: "cod_pro_eve"
            }
            comuneRap {
                column name: "cod_com_rap"
                column name: "cod_pro_rap"
            }
        }

        flagCfCalcolato type: SiNoType
        flagEsenzione type: SiNoType

        erediSoggetto cascade: "all-delete-orphan"

        tipoResidente type: 'numeric_boolean'
        table "soggetti"
        version false
    }

    static constraints = {
        matricola nullable: true
        codFiscale nullable: true, maxSize: 16
        cognomeNome maxSize: 100
        fascia nullable: true
        stato nullable: true
        dataUltEve nullable: true
        comuneEvento nullable: true
        sesso nullable: true, maxSize: 1
        codFam nullable: true
        rapportoPar nullable: true, maxSize: 2
        sequenzaPar nullable: true
        dataNas nullable: true
        comuneNascita nullable: true
        comuneResidenza nullable: true
        cap nullable: true
        codProf nullable: true
        pensionato nullable: true
        denominazioneVia nullable: true, maxSize: 60
        archivioVie nullable: true
        numCiv nullable: true
        suffisso nullable: true, maxSize: 10
        scala nullable: true, maxSize: 5
        piano nullable: true, maxSize: 5
        interno nullable: true
        partitaIva nullable: true, maxSize: 11
        rappresentante nullable: true, maxSize: 40
        indirizzoRap nullable: true, maxSize: 50
        comuneRap nullable: true
        codFiscaleRap nullable: true, maxSize: 16
        tipoCarica nullable: true
        flagEsenzione nullable: true, maxSize: 1
        tipo maxSize: 1
        gruppoUtente nullable: true, maxSize: 1
        flagCfCalcolato nullable: true, maxSize: 1
        cognome nullable: true, maxSize: 60
        nome nullable: true, maxSize: 36
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        soggettoPresso nullable: true
        intestatarioFam nullable: true, maxSize: 60
        fonte nullable: true
        zipcode nullable: true, maxSize: 10
        nomeRic nullable: true
        cognomeRic nullable: true
        //contribuente nullable: true
        lastUpdated nullable: true
    }

    String getIndirizzo() {
        return (archivioVie ? archivioVie?.denomUff : denominazioneVia ?: "") + (numCiv ? ", $numCiv" : "") + (suffisso ? "/$suffisso" : "")
    }

    def springSecurityService
    static transients = ['springSecurityService', 'contribuente']

    def beforeValidate() {
        utente = springSecurityService.currentUser
        cognomeNome = cognome + (nome ? "/" + nome : '')
        erediSoggetto*.beforeValidate()
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser
        cognomeNome = cognome + (nome ? "/" + nome : '')
        erediSoggetto*.beforeInsert()
    }

    void setContribuente(Contribuente contribuente) {
        if (contribuente)
            addToContribuenti(contribuente)
        else
            contribuenti?.clear()
    }

    Contribuente getContribuente() {
        (contribuenti && !contribuenti.isEmpty()) ? contribuenti[0] : null
    }

}
