package archivio.dizionari

import com.aspose.words.Document
import com.aspose.words.MailMergeDataType
import com.aspose.words.MailMergeMainDocumentType
import grails.util.Environment
import it.finmatica.tr4.Modelli
import it.finmatica.tr4.ModelliDettaglio
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.modelli.ConfigurazioneModelli
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.modelli.ModelliService
import net.sf.jmimemagic.Magic
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.apache.tika.mime.MimeType
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.security.MessageDigest
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class ListaModelliViewModel {

    private static Log log = LogFactory.getLog(ListaModelliViewModel)

    Window self
    ServletContext servletContext

    ModelliService modelliService
    CommonService commonService
    CompetenzeService competenzeService

    // Tipologia
    def tipologia = "T"
    def listaTipologie = [
            "M",
            "S",
            "T"
    ]

    //Estensione
    def estensione = "Tutti"
    def listaEstensioni = [
            "Tutti",
            "DOCX",
            "DOC",
            "ODT"
    ]

    // Tipi tributo
    def listaTipiTributo
    def tipoTributoSelezionato

    // Tipi modello
    def listaTipiModello
    def tipoModelloSelezionato

    // Modelli
    def listaModelli = []
    def modelloSelezionato = null

    // Parametri
    def listaParametri = []
    def parametroSelezionato = null

    def codiceSottomodello

    Boolean lettura = true

    Magic parser

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaTipiTributo = competenzeService.tipiTributoUtenza()
        tipoTributoSelezionato = listaTipiTributo[0]
        parser = new Magic()

        aggiornaCompetenze()

        caricaTipologie()
        caricaModelli()
    }

    @Command
    def onRicercaModelli() {
        caricaModelli()
    }

    @Command
    def onCaricaModello(@BindingParam("modello") def modello) {

        commonService.creaPopup("/archivio/dizionari/caricaModello.zul",
                self,
                [modello: Modelli.get(modello.id).toDTO(["versioni"])],
                { event ->

                    if (event.data) {
                        modello.versioni = [event.data?.nuovaVersione] + modello.versioni

                        BindUtils.postNotifyChange(null, null, modello, "versioni")
                    }
                })
    }

    @Command
    def onDuplicaModello(@BindingParam("modello") def modello) {
        commonService.creaPopup("/archivio/dizionari/nuovoModello.zul",
                self,
                [
                        modello    : Modelli.get(modello.id).toDTO(["versioni", "tipoModello"]),
                        tipoTributo: modello.tipoTributo
                ],
                { event ->
                    if (event.data) {
                        onRicercaModelli()
                        caricaTipologie()
                    }
                })
    }

    @Command
    def onEliminaModello(@BindingParam("modello") def modello) {
        String messaggio = "Sicuro di volere eliminare il modello ${modello.descrizione}?"

        Messagebox.show(messaggio, "Eliminazione modello ${modello.descrizione}",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def modellipadre = modelliService.eliminaModello(modello)
                            if (modellipadre) {
                                def esito = "Modello utilizzato in:\n"
                                modellipadre.sort()
                                modellipadre.each {
                                    esito += "$it\n"
                                }
                                Messagebox.show(esito, "Impossibile eliminare ${modello.descrizione}",
                                        Messagebox.OK, Messagebox.EXCLAMATION)

                            } else {
                                caricaModelli()
                            }
                        }
                    }
                }
        )
    }

    @Command
    onScaricaModello(@BindingParam("modello") def modello, @BindingParam("versione") def versione) {

        def path = modelliService.pathCampiUnione()

        if (path.isEmpty()) {
            onSelezionaPathCampiUnione()
            Clients.showNotification("Occore prima definire la cartella dei campi unione.", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            return
        }

        def m = Modelli.get(modello.id).toDTO(["versioni"])
        def v = m.versioni.find { it.versione == versione.versione }

        // Se odt non si collega l'origine dati
        if (commonService.detectMimeType(v.documento).extensions[0] == ".odt") {
            Filedownload.save(commonService.fileToAMedia(m.descrizione, v.documento))
            return
        }

        Document doc = modelliService.fileBytesToDoc(v.documento)
        if (modello.dbFunction) {
            def dataSource = "${path}${modello.descrizione}.csv"
            doc.mailMergeSettings.dataType = MailMergeDataType.TEXT_FILE
            doc.mailMergeSettings.mainDocumentType = MailMergeMainDocumentType.FORM_LETTERS
            doc.mailMergeSettings.dataSource = dataSource
            doc.mailMergeSettings.query = "SELECT * FROM ${dataSource}"
        }

        AMedia amedia = commonService.fileToAMedia(m.descrizione, modelliService.fileDocToBytes(doc, modelliService.decodeFormat(v.documento)))
        Filedownload.save(amedia)
    }

    @Command
    onEliminaVersione(@BindingParam("modello") def modello, @BindingParam("versione") def versione) {

        String messaggio = "Sicuro di volere eliminare la versione ${versione}?"
        Messagebox.show(messaggio, "Eliminazione versione $versione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            modelliService.eliminaVersione(Modelli.get(modello.id), versione)
                            modello.versioni = modello.versioni.findAll { it.versione != versione }
                            BindUtils.postNotifyChange(null, null, modello, "versioni")
                        }
                    }
                }
        )

    }

    @Command
    def onModelloClick(@BindingParam("modello") def modello) {
        modelloSelezionato = modello
        caricaParametri()
        BindUtils.postNotifyChange(null, null, this, "modelloSelezionato")
    }

    @Command
    def onScaricaCampiUnione(@BindingParam("modello") def modello) {
        def campiUnione = modelliService.scaricaCampiUnione(modello).getBytes()

        AMedia amedia = new AMedia(modello.descrizione, "csv", "text/csv", campiUnione)
        Filedownload.save(amedia)
    }

    @Command
    def onScaricaTuttiCampiUnione() {


        def modelliElaborati = []

        def fileName = "${tipoTributoSelezionato.tipoTributoAttuale}-${tipoModelloSelezionato.descrizione}.zip"

        ByteArrayOutputStream baos = new ByteArrayOutputStream()
        ZipOutputStream zos = new ZipOutputStream(baos)

        listaModelli.findAll { it.dbFunction }.each {
            if (it.dbFunction && !(it.descrizione in modelliElaborati)) {

                modelliElaborati << it.descrizione

                def campiUnione = modelliService.scaricaCampiUnione(it).getBytes()
                ZipEntry ze = new ZipEntry("${it.descrizione}.csv")
                ze.size = campiUnione.length
                zos.putNextEntry(ze)
                zos.write(campiUnione)
            }
        }

        zos.closeEntry()
        zos.close()

        def zippedFile = baos.toByteArray()

        if (!modelliElaborati.isEmpty()) {
            AMedia amedia = new AMedia(fileName, ".zip", "application/zip", zippedFile)
            Filedownload.save(amedia)
        } else {
            Clients.showNotification("Campi unione non presenti per i modelli selezionati.", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        }
    }

    @Command
    def onScaricaModelli() {
        generaJSON()
    }

    @Command
    def onInstallaModelli() {
        installaModelli()
    }

    @Command
    def onModificaParametro(@BindingParam("parametro") def parametro) {
        commonService.creaPopup("/archivio/dizionari/gestioneParametri.zul",
                self,
                [parametro: parametro, modello: modelloSelezionato],
                { event ->
                    if (event.data) {
                        caricaParametri()
                    }
                })
    }

    @Command
    def onEliminaPersonalizzazione(@BindingParam("parametro") def parametro) {
        String messaggio = "Si desidera eliminare il testo personalizzato ed usare quello predefinito?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            parametro.dettaglio.toDomain().delete(flush: true, failOnError: true)
                            caricaParametri()
                        }
                    }
                }
        )
    }

    @Command
    def onSelezionaTipologia() {
        if (tipologia != 'S') {
            codiceSottomodello = null
            BindUtils.postNotifyChange(null, null, this, "codiceSottomodello")
        }
    }

    @Command
    def onSelezionaTributo() {

        aggiornaCompetenze()
        caricaTipologie()
    }

    @Command
    def onSelezionaPathCampiUnione() {

        commonService.creaPopup("/archivio/dizionari/pathModelli.zul",
                self, [:],
                { event ->
                    if (event.data) {
                        modelliService.creaPathCampiUnione(event.data.path)
                    }
                })
    }

    @Command
    def onGeneraPrototipo(@BindingParam("modello") def modello) {
        def docBytes = modelliService.generaPrototipo(modello)

        MimeType mimeType = commonService.detectMimeType(docBytes)

        AMedia amedia = new AMedia(modello.descrizione, mimeType.extension.replace(".", ""), mimeType.name, docBytes)
        Filedownload.save(amedia)
    }

    @Command
    def onCheckEredi(@BindingParam("modello") def modello) {
        Messagebox.show("Il valore del flag verrà modificato. Proseguire?", "Modelli di stampa", Messagebox.YES | Messagebox.NO,
                Messagebox.QUESTION, { Event evt ->
            if (Messagebox.ON_YES == evt.getName()) {
                modelliService.setFlagEredi(modello.id, modello.flagEredi)

            }

            onRicercaModelli()

        })
    }

    private void caricaModelli() {

        def filtri = [
                tipologia         : tipologia,
                tipoTributo       : tipoTributoSelezionato?.tipoTributo,
                tipoModello       : tipoModelloSelezionato?.tipoModello,
                codiceSottomodello: codiceSottomodello,
                estensione        : estensione
        ]

        listaModelli = modelliService.caricaListaModelli(
                [max: 90000],
                filtri,
                [property: 'descrizione', direction: 'asc']
        ).record

        BindUtils.postNotifyChange(null, null, this, "listaModelli")
    }

    private void caricaParametri() {
        def filtri = [
                tipoModello: tipoModelloSelezionato.tipoModello,
                idModello  : modelloSelezionato.id
        ]

        listaParametri = modelliService.caricaListaParametri(
                [max: 90000],
                filtri,
                [property: 'descrizione', direction: 'asc']
        ).record

        BindUtils.postNotifyChange(null, null, this, "listaParametri")
    }

    private void caricaTipologie() {

        listaTipiModello = OggettiCache.TIPI_MODELLO.valore.findAll {
            it.tipoModello in Modelli.findAllByTipoTributoAndFlagWeb(tipoTributoSelezionato.tipoTributo, 'S').tipoModello.tipoModello
        }.sort { it.descrizione }

        tipoModelloSelezionato = tipoModelloSelezionato ?: listaTipiModello[0]

        BindUtils.postNotifyChange(null, null, this, "listaTipiModello")
    }

    private generaJSON() {

        ByteArrayOutputStream baos = new ByteArrayOutputStream()
        ZipOutputStream zos = new ZipOutputStream(baos)

        Set<String> filesName = []
        listaModelli.findAll { it.flagStandard }.each {

            ByteArrayOutputStream _baos = new ByteArrayOutputStream()
            ObjectOutputStream _oos = new ObjectOutputStream(_baos)

            def modello = Modelli.get(it.id).toDTO(["versioni", "tipoModello"])
            def ultimaVersione = modello.versioni.isEmpty() ? null : modello.versioni.sort { it.versione }.last()
            def nomeModello = modello.descrizione.replace(' ', '_')

            if (ultimaVersione) {

                def listaDettagli = []
                ModelliDettaglio.findAllByModello(modello.modello)
                        .each { m ->
                            listaDettagli += [
                                    parametroId: m.parametroId,
                                    testo      : m.testo
                            ]
                        }

                def modelloMap = [
                        tipoTributo       : modello.tipoTributo,
                        descrizione       : modello.descrizione,
                        path              : modello.path,
                        nomeDw            : modello.nomeDw,
                        flagSottomodello  : modello.flagSottomodello,
                        codiceSottomodello: modello.codiceSottomodello,
                        flagEditabile     : modello.flagEditabile,
                        flagStandard      : modello.flagStandard,
                        dbFunction        : modello.dbFunction,
                        flagF24           : modello.flagF24,
                        ultimaVersione    : [
                                versione      : ultimaVersione.versione,
                                documento     : ultimaVersione.documento,
                                digest        : MessageDigest.getInstance("SHA-512").digest(ultimaVersione.documento),
                                utente        : ultimaVersione.utente,
                                note          : 'Versione iniziale',
                                dataVariazione: (new Date())
                        ],
                        tipoModello       : [
                                tipoModello: modello.tipoModello.tipoModello,
                                descrizione: modello.tipoModello.descrizione
                        ],
                        dettagli          : listaDettagli
                ]

                _oos.writeObject(modelloMap)
                _baos.toByteArray()

                if (!filesName.contains("${nomeModello}.dat")) {

                    filesName << "${nomeModello}.dat"

                    ZipEntry ze = new ZipEntry("${nomeModello}.dat")
                    ze.size = _baos.toByteArray().length
                    zos.putNextEntry(ze)
                    zos.write(_baos.toByteArray())

                    log.info "Esportato modello ${nomeModello}.dat alla versione ${ultimaVersione.versione}"
                } else {
                    log.info "${nomeModello}.dat già esportato."
                }

                _oos.close()
            }
        }

        zos.closeEntry()
        zos.close()

        def zippedFile = baos.toByteArray()

        AMedia amedia = new AMedia("modelli", ".zip", "application/zip", zippedFile)
        Filedownload.save(amedia)
    }

    private installaModelli() {
        (new ConfigurazioneModelli(servletContext, modelliService)).installaModelli()
    }


    def aggiornaCompetenze() {

        String tipoTributo = tipoTributoSelezionato?.tipoTributo ?: '-'
        lettura = (competenzeService.tipoAbilitazioneUtente(tipoTributo) != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        BindUtils.postNotifyChange(null, null, this, "lettura")
    }

    def development() {
        return (Environment.current == Environment.DEVELOPMENT)
    }
}
