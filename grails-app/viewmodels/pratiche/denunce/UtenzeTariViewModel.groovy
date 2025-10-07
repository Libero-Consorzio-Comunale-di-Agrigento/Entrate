package pratiche.denunce

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class UtenzeTariViewModel {

    // Componenti
    def self

    // Service
    DenunceService denunceService
    CommonService commonService

    // Modello
    def contribuenteSelezionato = [:]
    def listaUtenze
    def utenzeSelezionate

    PraticaTributo pratica
    def idPratica

    def data1
    def data2

    def tipoPratica
    def tipoEvento
    Boolean perAccertamento

    def annoChiusura
    def soggDestinazione
    def inizioOccupazione
    def dataDecorrenza

    def numero
    def dataDel

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("pratica") def idPratica,
         @ExecutionArgParam("contribuente") ContribuenteDTO cnt,
         @ExecutionArgParam("tipoEvento") TipoEventoDenuncia tipoEvento,
         @ExecutionArgParam("anno") def anno) {

        this.idPratica = idPratica ?: -1
        if (anno != null) {
            this.annoChiusura = anno as short
        }


        if (this.idPratica == -1 && (tipoEvento == null && cnt == null)) {
            throw new RuntimeException("Indicare la pratica o il tipo evento ed il contribuente.")
        }

        this.self = w
        this.pratica = (this.idPratica as Long != -1) ? PraticaTributo.get(idPratica) : new PraticaTributo(
                contribuente: cnt.toDomain(),
                tipoEvento: tipoEvento
        )

        this.tipoEvento = this.pratica.tipoEvento.tipoEventoDenuncia
        this.tipoPratica = this.pratica.tipoPratica

        this.perAccertamento = (this.tipoPratica == TipoPratica.A.tipoPratica)

        this.dataDel = new Date()

        onApriMascheraRicercaSoggetto()
    }

    @Command
    def onApriMascheraRicercaSoggetto() {
        if (tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.U.tipoEventoDenuncia]) {
            commonService.creaPopup("/archivio/listaSoggettiRicerca.zul", self, [filtri: null, listaVisibile: true, soloContribuenti: true], { event ->
                if (event.data) {
                    if (event.data.status == "Soggetto") {
                        def soggSel = event.data.Soggetto
                        contribuenteSelezionato.cognomeNome = "${soggSel.cognome} ${soggSel.nome}".trim()
                        contribuenteSelezionato.codFiscale = soggSel.contribuente.codFiscale

                        contribuenteSelezionato.indirizzo = soggSel.denominazioneVia ? "${soggSel.denominazioneVia} " : '' + 
														                        ((soggSel.numCiv != null) ? soggSel.numCiv : '') +
														                                (soggSel.piano != null ? " P. ${soggSel.piano}" : '') +
														                                (soggSel.interno != null ? " Int. ${soggSel.interno}" : '')

                        def comuneResidenza = soggSel.comuneResidenza?.ad4Comune
                        contribuenteSelezionato.comuneResidenza = (comuneResidenza?.denominazione?.trim() ? comuneResidenza?.denominazione : '') +
                                (comuneResidenza?.provincia?.sigla ? " (${comuneResidenza?.provincia?.sigla})" : '')

                        listaUtenze = denunceService.getDenunceTariCessate(
                                contribuenteSelezionato.codFiscale,
                                pratica.id,
                                'TARSU'
                        )

                        BindUtils.postNotifyChange(null, null, this, "contribuenteSelezionato")
                        BindUtils.postNotifyChange(null, null, this, "listaUtenze")
                    }
                }
            })
        } else if (tipoEvento in [TipoEventoDenuncia.V.tipoEventoDenuncia, TipoEventoDenuncia.C.tipoEventoDenuncia]) {
            listaUtenze = denunceService.getLocaliAreeVariazioneCessazione(
                    pratica.contribuente.codFiscale,
                    pratica.id ?: this.idPratica,
                    'TARSU',
                    pratica.tipoEvento
            )

            if (annoChiusura != null) {
                listaUtenze = listaUtenze.findAll {
                    ((commonService.yearFromDate(it.dataDecorrenza) ?: 0) <= annoChiusura) &&
                            ((commonService.yearFromDate(it.dataCessazione) ?: 9999) >= annoChiusura)
                }
            }

            BindUtils.postNotifyChange(null, null, this, "listaUtenzeCessate")
        }
    }
	
	@Command
	def onSelectUtenzaCessata() {
		
	}

    @Command
    def onSeleziona() {

        def errori = []

        if (this.idPratica == -1) {
            if (annoChiusura == null) {
                errori << "Campo 'Anno' non valorizzato."
            }

            if (soggDestinazione != null) {
                if (!dataDecorrenza) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }

                if (dataDecorrenza != null && data2 != null && dataDecorrenza < data2) {
                    errori << "Impossibile trasferiri gli oggetti in una data precedente alla data di cessazione"
                }
            } else {
                if (dataDecorrenza != null || inizioOccupazione != null) {
                    errori << "Indicare il contribuente su cui trasferire gli oggetti"
                }
            }
        }

        if (perAccertamento) {
            if (!data1) {
                errori << "Campo 'Inizio occupazione' non valorizzato."
            }
            if (!data2) {
                errori << "Campo 'Data decorrenza' non valorizzato."
            }
        } else {
            if (tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]) {
                if (!data2) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }
            } else if (tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia) {
                if (!data2) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
                utenzeSelezionate.each {
                    if (data2 && it.dataDecorrenza > data2) {
                        errori << "Per l'oggetto ${it.oggetto} la data di cessazione e' precedente alla data di decorrenza."
                    }
                }

            } else if (tipoEvento == TipoEventoDenuncia.U.tipoEventoDenuncia) {
                if (!data1) {
                    errori << "Campo 'Data decorrenza' non valorizzato."
                }
                if (!data2) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
            }
        }

        if (dataDel == null){
            errori << "Campo 'Del' non valorizzato."
        }

        if (!errori.isEmpty()) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return
        }


        // Se almeno un oggetto ha data di cessazione >= rispetto a quella di decorrenza vienew visualizzato un messaggio di conferma inserimento
        def avvisiCessazione = []

        utenzeSelezionate.each {
            if (it.dataCessazione >= data2) {
                avvisiCessazione << it.oggetto
            }
        }

        if (!avvisiCessazione.isEmpty()) {

            def msg = """
                                Sono presenti oggetti con data di cessazione uguale o successiva alla data di decorrenza.
                                
                                Si desidera procedere con l'inserimento?
                        """

            Messagebox.show(msg, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                Events.postEvent(Events.ON_CLOSE, self, [
                                        anno             : annoChiusura,
                                        data2            : data2,
                                        data1            : data1,
                                        utenze           : utenzeSelezionate,
                                        soggDest         : soggDestinazione,
                                        inizioOccupazione: inizioOccupazione,
                                        dataDecorrenza   : dataDecorrenza
                                ])
                            }
                        }
                    }
            )

            return
        }

        def annoTariffe = idPratica == -1 ? annoChiusura : pratica.anno
        def utenzeSenzaTariffa = denunceService.utenzeSenzaTariffa(annoTariffe, utenzeSelezionate)
        if (!utenzeSenzaTariffa.empty) {
            def messaggio = "Tariffe assenti per l'anno $annoTariffe:\n"
            def utenzeMissingDescription = utenzeSenzaTariffa.collect { utenza ->
                "- Oggetto: $utenza.oggetto Categoria: $utenza.categoria Tipo Tariffa: $utenza.tipoTariffa"
            }
            messaggio += utenzeMissingDescription.join('\n')
            Messagebox.show(messaggio, "Attenzione", Messagebox.OK, Messagebox.ERROR)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [
                anno             : annoChiusura,
                data2            : data2,
                data1            : data1,
                utenze           : utenzeSelezionate,
                soggDest         : soggDestinazione,
                inizioOccupazione: inizioOccupazione,
                dataDecorrenza   : dataDecorrenza,
                dataDel          : dataDel,
                numero           : numero
        ])
    }

    @Command
    onCambiaInizioOccupazione() {
        // Se si annulla la data inizio occupazione
        if (!inizioOccupazione) {
            // Si annulla anche la data decorrenza
            dataDecorrenza = null
        } else {
            dataDecorrenza = denunceService
                    .fGetDecorrenzaCessazione(inizioOccupazione, tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia ? 1 : 0)
        }

        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onCambiaData1() {

        // Se si annulla la data inizio occupazione
        if (!data1) {
            // Si annulla anche la data decorrenza
            data2 = null
        } else {

            if (tipoEvento == TipoEventoDenuncia.U) {

                // Se si valorizza la data occupazione, se la data decorrenza è nulla si setta a data occupazione
                data2 = data2 ?: data1

            } else {
                data2 = denunceService.fGetDecorrenzaCessazione(data1, tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia ? 1 : 0)
            }
        }

        BindUtils.postNotifyChange(null, null, this, "data2")
    }

    @Command
    def onApriRicercaSoggDest() {
        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    soggDestinazione = event.data.Soggetto
                    BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
                }
            }
        }
        w.doModal()
    }

    @Command
    def onEliminaSoggDest() {
        soggDestinazione = null
        inizioOccupazione = null
        dataDecorrenza = null
        BindUtils.postNotifyChange(null, null, this, "soggDestinazione")
        BindUtils.postNotifyChange(null, null, this, "inizioOccupazione")
        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
