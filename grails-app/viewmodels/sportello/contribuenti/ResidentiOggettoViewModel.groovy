package sportello.contribuenti


import document.FileNameGenerator
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ResidentiOggettoViewModel {

    // Componenti
    Window self

    // Service
    ContribuentiService contribuentiService

    // Modello
    OggettoDTO oggetto
    def listaResidenti = []
    def residenteSelezionato
    def lista
    def tipoResidente
    def indirizzoCompleto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("oggetto") def idOggetto) {
        this.self = w
        tipoResidente = 0
        oggetto = Oggetto.get(idOggetto)?.toDTO(["archivioVie", "tipoOggetto", "categoriaCatasto"])
        indirizzoCompleto = oggetto.getIndirizzoCompleto()
        /*oggetto.indirizzo
indirizzoCompleto+= (oggetto.scala!=null)?" Sc:" +oggetto.scala:""
indirizzoCompleto+= (oggetto.piano!=null)?" P:" +oggetto.piano:""
indirizzoCompleto+= (oggetto.interno!=null)?" In:" +oggetto.interno:""*/

        caricaLista()
        BindUtils.postNotifyChange(null, null, this, "tipoResidente")
        BindUtils.postNotifyChange(null, null, this, "indirizzoCompleto")
        BindUtils.postNotifyChange(null, null, this, "listaResidenti")
    }

    @Command
    onSelezionaTipoResidente(@BindingParam("tipo") long tipo) {
        tipoResidente = tipo
        caricaLista()
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onOpenSituazioneContribuente(@BindingParam("cf") String cf) {

        def ni = Contribuente.findByCodFiscale(cf)?.soggetto?.id

        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    residentiToXls() {

        Map fields = [
                'codFam'         : 'Cod. Fam.',
                'ni'             : 'NI',
                'cognome'        : 'Cognome',
                'nome'           : 'Nome',
                'codFiscale'     : 'Codice Fiscale',
                'codContribuente': 'Codice contribuente',
                'tribICI'        : 'IMU',
                'tribICIAP'      : 'TASI',
                'tribICP'        : 'PUBBLICITA',
                'tribRSU'        : 'TARI',
                'tribTOSAP'      : 'COSAP',
                'dataNascita'    : 'Data di nascita',
                'comune'         : 'Comune'
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_RESIDENTI_OGGETTO,
                [idOggetto: oggetto.id])

        def lista = listaResidenti.collect { row ->
            ['ni'             : row["ni"],
             'codFam'         : row["codFam"],
             'cognome'        : row["cognome"],
             'nome'           : row["nome"],
             'dataNascita'    : row["dataNascita"],
             'comune'         : row["comune"],
             'codFiscale'     : row["codFiscale"],
             'codContribuente': row["codContribuente"],
             'tribICI'        : (row["ICI"]) ? "S" : "N",
             'tribICIAP'      : (row["TASI"]) ? "S" : "N",
             'tribICP'        : (row["ICP"]) ? "S" : "N",
             'tribRSU'        : (row["TARSU"]) ? "S" : "N",
             'tribTOSAP'      : (row["COSAP"]) ? "S" : "N",
            ]
        }

        def formatters = [
                "ni"    : Converters.decimalToInteger,
                "codFam": Converters.decimalToInteger]

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, formatters)

    }

    private caricaLista() {
        listaResidenti = contribuentiService.getResidentiOggetto(oggetto.id, tipoResidente)
        listaResidenti.each {
            it.contribuente = (Contribuente.findByCodFiscale(it.codFiscale)?.soggetto?.id != null)
        }
        BindUtils.postNotifyChange(null, null, this, "listaResidenti")
    }

}
