package archivio.dizionari

import it.finmatica.tr4.carichi.CarichiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CaricoTarsuDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCarichiViewModel extends TabListaGenericaTributoViewModel {

    // Servizi

    CarichiService carichiService

    // Componenti
    Window self

    // Modello
    CaricoTarsuDTO caricoSelezionato
    Collection<CaricoTarsuDTO> listaCarichi

    // NOTE: copied from CalcoloFamiliariViewModel
    def listaModalita = [null] +
            [codice: 1, descrizione: 'Data Evento'] +
            [codice: 2, descrizione: 'Mese successivo all\'Evento'] +
            [codice: 3, descrizione: 'Bimestre solare'] +
            [codice: 4, descrizione: 'Semestre solare'] +
            [codice: 5, descrizione: 'Mese sulla base del giorno 15']

    def listaRatePerequative = [null] +
            [codice: 'T', descrizione: 'Tutte'] +
            [codice: 'P', descrizione: 'Prima'] +
            [codice: 'U', descrizione: 'Ultima']

    def mesiCalcolo
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        mesiCalcolo = carichiService.getListaMesiCalcolo().collectEntries { [(it.id as Short): it.name()] }
        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Override
    @Command
    void onRefresh() {
        caricoSelezionato = null

        listaCarichi = carichiService.getByCriteria(filtro, filtroAttivo)

        listaCarichi.each { it ->
            def codice = it.rataPerequative
            it.desRataPerequative = codice ? (listaRatePerequative.find { it?.codice == codice }?.descrizione) : null
        }

        BindUtils.postNotifyChange(null, null, this, "caricoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaCarichi")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCarichi.zul", self,
                [
                    selezionato  : commonService.clona(caricoSelezionato),
                    listaModalita: listaModalita,
                    listaRatePerequative : listaRatePerequative,
                    isModifica   : true,
                    isLettura    : lettura
                ], { event -> if (event.data?.carico) modifyElement(event.data.carico) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCarichi.zul", self,
                [
                    selezionato  : null,
                    listaModalita: listaModalita,
                    listaRatePerequative : listaRatePerequative,
                    isModifica   : false,
                ], { event -> if (event.data?.carico) addElement(event.data.carico) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCarichi.zul", self,
                [
                    selezionato  : commonService.clona(caricoSelezionato),
                    listaModalita: listaModalita,
                    listaRatePerequative : listaRatePerequative,
                    isModifica   : false,
                ], { event -> if (event.data?.carico) addElement(event.data.carico) })
    }

    @Command
    def onElimina() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        carichiService.elimina(caricoSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaCarichi) {
            def formatters = [
                    "flagLordo"             : { value -> value ?: 'N' },
                    "flagSanzioneAddP"      : { value -> value ?: 'N' },
                    "flagSanzioneAddT"      : { value -> value ?: 'N' },
                    "flagInteressiAdd"      : { value -> value ?: 'N' },
                    "flagNoTardivo"         : { value -> value ?: 'N' },
                    "flagTariffeRuolo"      : { value -> value ?: 'N' },
                    "flagMaggAnno"          : { value -> value ?: 'N' },
                    "flagTariffaPuntuale"   : { value -> value ?: 'N' },
                    "modalitaFamiliari"     : { value -> value ? listaModalita[value]?.descrizione : null },
                    "mesiCalcolo"           : { value -> value != null ? mesiCalcolo[value] : null }
            ]

            def bigDecimalFormats = [
                    "tariffaDomestica"   : getTariffaFormat(),
                    "tariffaNonDomestica": getTariffaFormat(),
                    "costoUnitario"      : '#,##0.00000000'
            ]

            XlsxExporter.exportAndDownload("Carichi_${tipoTributoSelezionato.tipoTributoAttuale}", listaCarichi, getExportableFieldMap(), formatters, bigDecimalFormats)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCarichiRicerca.zul", self,
                [
                        filtro       : filtro,
                        listaModalita: listaModalita
                ], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    public
    String descrRatePerequative(String code) {
        return "RT ${code}"
//        return (code) ? listaRatePerequative.find { it.codice == code} ?.descrizione
    }

    private static def getExportableFieldMap() {
        return [
                "anno"               : "Anno",
                "addizionaleEca"     : "Addizionale ECA",
                "maggiorazioneEca"   : "Maggiorazione ECA",
                "addizionalePro"     : "Addizionale Provinciale",
                "nonDovutoPro"       : "Non Dovuto Provinciale",
                "commissioneCom"     : "Commissione Comunale",
                "tariffaDomestica"   : "Tariffa Domestica",
                "tariffaNonDomestica": "Tariffa Non Domestica",
                "aliquota"           : "% IVA",
                "ivaFattura"         : "% IVA Fattura",
                "compensoMinimo"     : "Compenso Minimo",
                "compensoMassimo"    : "Compenso Massimo",
                "percCompenso"       : "% Compenso",
                "limite"             : "Limite",
                "flagLordo"          : "Lordo",
                "flagSanzioneAddP"   : "Add.Perm.",
                "flagSanzioneAddT"   : "Add.Temp.",
                "flagInteressiAdd"   : "Add.Int.",
                "mesiCalcolo"        : "Mesi Calcolo",
                "maggiorazioneTares" : "Componenti Perequative",
                "flagMaggAnno"       : "Maggiorazione Anno",
                "modalitaFamiliari"  : "Modalità Calcolo Familiari",
                "flagNoTardivo"      : "Disabilitazione Int.Tardivo",
                "flagTariffeRuolo"   : "Tariffe Ruoli",
                "desRataPerequative" : "Rata Perequative",
                "flagTariffaPuntuale": "Tariffe Puntuale",
                "costoUnitario"      : "Costo Unitario"
        ]
    }

    private def modifyElement(CaricoTarsuDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(caricoSelezionato, elementFromEvent)) {
            carichiService.elimina(caricoSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(CaricoTarsuDTO elementFromEvent) {
        carichiService.salva(elementFromEvent)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onRefresh()
    }

    private static def isPrimaryModified(CaricoTarsuDTO source, CaricoTarsuDTO dest) {
        return !(source.anno.equals(dest.anno))
    }

    String getTariffaFormat() {
        return '#,##0.00000'
    }
}
