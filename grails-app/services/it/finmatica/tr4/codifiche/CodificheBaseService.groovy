package it.finmatica.tr4.codifiche

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.dto.*

@Transactional
class CodificheBaseService {

    def dataSource

    def salvaCodifica(def codificaDTO) {
        codificaDTO.toDomain().save(flush: true, failOnError: true)
    }

    def eliminaCodifica(def codificaDTO, def tipoCodifica) {

        def messaggio = ""

        // Codici Attivita e Atti non hanno procedures per l'eliminazione, posso saltare la verifica
        if (!tipoCodifica.equals("Codice") && !tipoCodifica.equals("Atto")) {
            messaggio = checkCodificaEliminabile(codificaDTO, tipoCodifica)
        }

        // Eliminazione possibile
        if (messaggio.length() == 0) {
            codificaDTO.toDomain().delete(failOnError: true)
        }
        return messaggio
    }

    def checkCodificaEliminabile(def codificaDTO, def tipoCodifica) {

        def procedureName = tipoCodifica.equalsIgnoreCase("fonte") ? "FONTI_PD" : "TIPI_${tipoCodifica.toUpperCase()}_PD"
        String call = "{call $procedureName(?)}"

        def params = []

        switch (tipoCodifica) {
            case 'Oggetto':
                params << codificaDTO.tipoOggetto
                break
            case 'Utilizzo':
                params << codificaDTO.id
                break
            case 'Uso':
                params << codificaDTO.id
                break
            case 'Carica':
                params << codificaDTO.id
                break
            case 'Area':
                params << codificaDTO.id
                break
            case 'Contatto':
                params << codificaDTO.tipoContatto
                break
            case 'Richiedente':
                params << codificaDTO.tipoRichiedente
                break
            case 'Fonte':
                params << codificaDTO.fonte
                break
            case 'Stato':
                params << codificaDTO.tipoStato
                break
            case 'Recapito':
                params << codificaDTO.id
                break
        }

        try {
            Sql sql = new Sql(dataSource)
            sql.call(call, params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }


    def elencoOggetti() {

        TipoOggetto.findAll()
                .sort { it.tipoOggetto }
                .collect {
                    [tipo        : it.tipoOggetto,
                     descrizione : it.descrizione,
                     modificabile: !(it.tipoOggetto < 5)]
                }
    }

    def elencoUtilizzi() {

        def nonModificabili = []

        TipoUtilizzo.findAll()
                .sort { it.id }
                .collect {
                    [tipo        : it.id,
                     descrizione : it.descrizione,
                     modificabile: !(it.id in nonModificabili)]
                }
    }

    def elencoUsi() {

        def nonModificabili = []

        TipoUso.findAll()
                .sort { it.id }
                .collect {
                    [tipo        : it.id,
                     descrizione : it.descrizione,
                     modificabile: !(it.id in nonModificabili)]
                }
    }

    def elencoCariche() {

        def nonModificabili = []

        TipoCarica.findAll()
                .sort { it.id }
                .collect {
                    [tipo        : it.id,
                     descrizione : it.descrizione,
                     codSoggetto : it.codSoggetto,
                     flagOnline  : it.flagOnline == 'S',
                     modificabile: !(it.id in nonModificabili)]
                }
    }

    def elencoAree() {

        def nonModificabili = []

        TipoArea.findAll()
                .sort { it.id }
                .collect {
                    [tipo        : it.id,
                     descrizione : it.descrizione,
                     modificabile: !(it.id in nonModificabili)]
                }
    }

    def elencoContatti() {

        def nonModificabili = []

        TipoContatto.findAll()
                .sort { it.tipoContatto }
                .collect {
                    [tipo        : it.tipoContatto,
                     descrizione : it.descrizione,
                     modificabile: !(it.tipoContatto in nonModificabili)]
                }
    }

    def elencoRichiedenti() {

        def nonModificabili = []

        TipoRichiedente.findAll()
                .sort { it.tipoRichiedente }
                .collect {
                    [tipo        : it.tipoRichiedente,
                     descrizione : it.descrizione,
                     modificabile: !(it.tipoRichiedente in nonModificabili)]
                }
    }

    def elencoFonti() {

        Fonte.findAll()
                .sort { it.fonte }
                .collect {
                    [tipo        : it.fonte,
                     descrizione : it.descrizione,
                     modificabile: false //Fonti mai modificabili
                    ]
                }
    }

    def elencoCodiciAttivita() {

        def nonModificabili = []

        CodiciAttivita.findAll()
                .sort { it.codAttivita }
                .collect {
                    [tipo        : it.codAttivita,
                     descrizione : it.descrizione,
                     modificabile: !(it.codAttivita in nonModificabili)]
                }
    }

    def elencoStati() {

        def nonModificabili = ["A",
                               "D",
                               "I",
                               "P",
                               "R",
                               "S"]

        TipoStato.findAll()
                .collect {
                    [tipo        : it.tipoStato,
                     descrizione : it.descrizione,
                     modificabile: !(it.tipoStato in nonModificabili),
                     ordine: it.numOrdine]
                }
                .sort { it.tipo }
    }

    def elencoAtti() {

        def nonModificabili = []

        TipoAtto.findAll()
                .sort { it.tipoAtto }
                .collect {
                    [tipo        : it.tipoAtto,
                     descrizione : it.descrizione,
                     modificabile: !(it.tipoAtto in nonModificabili)]
                }
    }

    def elencoRecapiti() {

        TipoRecapito.findAll()
                .sort { it.id }
                .collect {
                    [tipo        : it.id,
                     descrizione : it.descrizione,
                     modificabile: !(it.id < 10)]
                }

    }

    /**
     * isModifica = true nel caso di una modifica/eliminazione, false nel caso di aggiunta/clonazione*/
    def getCodifica(def codificaGenerica, def tipoCodifica, def isModifica) {

        def dto

        switch (tipoCodifica) {
            case 'oggetti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoOggetto.exists(codificaGenerica.tipo)) return "Esiste già un Oggetto con lo stesso identificatore"

                dto = isModifica ? TipoOggetto.get(codificaGenerica.tipo).toDTO() : new TipoOggettoDTO()
                dto.tipoOggetto = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'utilizzi':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoUtilizzo.exists(codificaGenerica.tipo)) return "Esiste già un Utilizzo con lo stesso identificatore"

                dto = isModifica ? TipoUtilizzo.get(codificaGenerica.tipo).toDTO() : new TipoUtilizzoDTO()
                dto.id = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'usi':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoUso.exists(codificaGenerica.tipo)) return "Esiste già un Uso con lo stesso identificatore"

                dto = isModifica ? TipoUso.get(codificaGenerica.tipo).toDTO() : new TipoUsoDTO()
                dto.id = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'cariche':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoCarica.exists(codificaGenerica.tipo)) return "Esiste già una Carica con lo stesso identificatore"

                dto = isModifica ? TipoCarica.get(codificaGenerica.tipo).toDTO() : new TipoCaricaDTO()
                dto.id = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                dto.codSoggetto = codificaGenerica.codSoggetto.id
                dto.flagOnline = codificaGenerica.flagOnline ? 'S' : null
                return dto
            case 'aree':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoArea.exists(codificaGenerica.tipo)) return "Esiste già un Area con lo stesso identificatore"

                dto = isModifica ? TipoArea.get(codificaGenerica.tipo).toDTO() : new TipoAreaDTO()
                dto.id = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'contatti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoContatto.exists(codificaGenerica.tipo)) return "Esiste già un Contatto con lo stesso identificatore"

                dto = isModifica ? TipoContatto.get(codificaGenerica.tipo).toDTO() : new TipoContattoDTO()
                dto.tipoContatto = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'richiedenti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoRichiedente.exists(codificaGenerica.tipo)) return "Esiste già un Richiedente con lo stesso identificatore"

                dto = isModifica ? TipoRichiedente.get(codificaGenerica.tipo).toDTO() : new TipoRichiedenteDTO()
                dto.tipoRichiedente = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'fonti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && Fonte.exists(codificaGenerica.tipo)) return "Esiste già una Fonte con lo stesso identificatore"

                dto = isModifica ? Fonte.get(codificaGenerica.tipo).toDTO() : new FonteDTO()
                dto.fonte = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'codiciAttività':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && CodiciAttivita.exists(codificaGenerica.tipo)) return "Esiste già un Codice Attività con lo stesso identificatore"

                dto = isModifica ? CodiciAttivita.get(codificaGenerica.tipo).toDTO() : new CodiciAttivitaDTO()
                dto.codAttivita = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'stati':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoStato.exists(codificaGenerica.tipo)) return "Esiste già uno Stato con lo stesso identificatore"

                dto = isModifica ? TipoStato.get(codificaGenerica.tipo).toDTO() : new TipoStatoDTO()
                dto.tipoStato = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                dto.numOrdine = codificaGenerica.ordine
                return dto
            case 'atti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoAtto.exists(codificaGenerica.tipo)) return "Esiste già un Atto con lo stesso identificatore"

                dto = isModifica ? TipoAtto.get(codificaGenerica.tipo).toDTO() : new TipoAttoDTO()
                dto.tipoAtto = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
            case 'recapiti':

                // Controllo se esiste già una codifica con lo stesso id per aggiunta/clonazione
                if (!isModifica && TipoRecapito.exists(codificaGenerica.tipo)) return "Esiste già un Recapito con lo stesso identificatore"

                dto = isModifica ? TipoRecapito.get(codificaGenerica.tipo).toDTO() : new TipoRecapitoDTO()
                dto.id = codificaGenerica.tipo
                dto.descrizione = codificaGenerica.descrizione
                return dto
        }
    }
}
