package archivio.dizionari

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.CfaAccTributi
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.datiContabili.DatiContabiliService
import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DatiContabiliViewModel {

    // Componenti
    Window self

    //Servizi
    CommonService commonService
    CompetenzeService competenzeService
    DatiGeneraliService datiGeneraliService
    SoggettiService soggettiService
    DatiContabiliService datiContabiliService
	FornitureAEService fornitureAEService

    //Modello
    DatiContabiliDTO dato
    def listaTipoTributo = []
    List<CodiceTributoDTO> listaCodiceTributo = []
    List<CodiceF24DTO> listaCodiceF24 = []
    List<TipoStatoDTO> listaTipoStato = []
    def descrizioneTitr

    def listaAnniAcc
    def annoAcc
    CfaAccTributiDTO cfaAccTributo

    def listaTipoImposta = [[codice: null, descrizione: '']
                            , [codice: 'O', descrizione: 'Ordinario']
                            , [codice: 'V', descrizione: 'Violazioni']
    ]

    def tipoOccupazioneSelected
    def listaTipiOccupazione = [
            [codice: null, descrizione: ''],
            [codice: TipoOccupazione.P.tipoOccupazione, descrizione: TipoOccupazione.P.descrizione],
            [codice: TipoOccupazione.T.tipoOccupazione, descrizione: TipoOccupazione.T.descrizione],
    ]

    def listaTipoPratica

    boolean lettura                         // Tutta la maschera è in sola lettura
    boolean letturaTipoTributo              // Il tipo di Tributo selezionato è in sola lettura, disabilita Salva

    boolean inModifica
    boolean inDuplica
    CodiceF24DTO codTributoF24
    def tipoTributo
    List<DatiContabiliDTO> listaDatiContabili

	Boolean flagProvincia = false

    /// Filtri per bandboxComuniFAE
	Long provStato
	Long progrDoc

	def enteComunale  = [
		codPro : null,
		codCom : null,
		///
		denominazione : "",
		provincia : "",
		siglaProv : "",
		siglaCFis : ""
	]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("flagProvincia") Boolean fp
         , @ExecutionArgParam("dato") DatiContabiliDTO dt
         , @ExecutionArgParam("modifica") boolean modifica
         , @ExecutionArgParam("duplica") @Default("false") boolean duplicaDato) {

        this.self = w

        this.flagProvincia = fp

        if(this.flagProvincia) {
            this.provStato = datiGeneraliService.extractDatiGenerali().codProvincia
            this.progrDoc = 0
        }
        else {
            this.provStato = 0
            this.progrDoc = -1
        }

        listaTipoPratica = [[codice: null, descrizione: '']] +
                TipoPratica.enumConstants
                        .findAll { it.order > -1 }
                        .sort { it.order }
                        .collect { [codice: it.tipoPratica, descrizione: it.descrizione] }

        inModifica = modifica
        inDuplica = duplicaDato
        listaDatiContabili = datiContabiliService.getDatiContabili()
        Short anno = Calendar.getInstance().get(Calendar.YEAR)

        lettura = ((dt != null) && !inModifica && !inDuplica)

        List tributiUtenza

        if (!lettura) {
            tributiUtenza = competenzeService.tipiTributoUtenzaScrittura().collect { it.tipoTributo }
        } else {
            tributiUtenza = competenzeService.tipiTributoUtenza().collect { it.tipoTributo }
        }
        def tipiTributo = soggettiService.getListaTributi(anno)
        tipiTributo = tipiTributo.findAll { it.codice in tributiUtenza }
        listaTipoTributo = [[codice: null, descrizione: '', nome: '']] + tipiTributo

        if (!dt) {
            dato = new DatiContabiliDTO()
            dato.anno = anno
        } else {

            dato = datiContabiliService.getDato(dt.id.longValue())

            if (duplicaDato) {
                dato = new DatiContabiliDTO()
                dato.tipoTributo = dt.tipoTributo
                dato.anno = dt.anno
                dato.tipoImposta = dt.tipoImposta
                dato.tipoPratica = dt.tipoPratica
                dato.statoPratica = dt.statoPratica
                dato.emissioneDal = dt.emissioneDal
                dato.emissioneAl = dt.emissioneAl
                dato.ripartizioneDal = dt.ripartizioneDal
                dato.ripartizioneAl = dt.ripartizioneAl
                dato.tributo = dt.tributo
                dato.tipoOccupazione = dt.tipoOccupazione
                dato.codTributoF24 = dt.codTributoF24
                dato.descrizioneTitr = dt.descrizioneTitr
                dato.annoAcc = dt.annoAcc
                dato.numeroAcc = dt.numeroAcc
                dato.codEnteComunale = dt.codEnteComunale
            }

            tipoTributo = dato.tipoTributo?.tipoTributo

            listaCodiceTributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == tipoTributo }
                    .sort { it.id }

            listaCodiceF24 = [new CodiceF24DTO()] + OggettiCache.CODICI_F24
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == tipoTributo }
                    .sort { it.tributo }

            codTributoF24 = listaCodiceF24.find {
                it.tributo == dato.codTributoF24
            }

            annoAcc = dato.annoAcc
            cfaAccTributo = CfaAccTributi.findByAnnoAccAndNumeroAcc(dato.annoAcc, dato.numeroAcc)?.toDTO()

            if (cfaAccTributo == null && dato.annoAcc && dato.numeroAcc) {
                cfaAccTributo = new CfaAccTributiDTO()
                cfaAccTributo.annoAcc = dato.annoAcc
                cfaAccTributo.numeroAcc = dato.numeroAcc
            }
        }

        listaTipoStato = TipoStato.list().sort { it.descrizione }.toDTO()
        listaTipoStato = [new TipoStatoDTO([tipoStato: '', descrizione: ''])] + listaTipoStato

        def tipoOccupazione = dato.tipoOccupazione?.tipoOccupazione
        tipoOccupazioneSelected = listaTipiOccupazione.find { it.codice == tipoOccupazione }

        fetchListaAnniAcc()

        applicaTipoTributo()

		inizializzaDettagliEnte(dato.codEnteComunale)
    }

    private void fetchListaAnniAcc() {
        listaAnniAcc = datiContabiliService.getListaAnniAccertamentoContabile(dato.anno)
        BindUtils.postNotifyChange(null, null, this, "listaAnniAcc")
    }

    @NotifyChange("dato")
    @Command
    onSalva() {

        def result = validaMaschera()
        if (result < CommonService.RES_ERROR) {

            dato.descrizioneTitr = determinaDescrizioneTitr()
            dato.annoAcc = cfaAccTributo?.annoAcc
            dato.numeroAcc = cfaAccTributo?.numeroAcc
		    dato.codEnteComunale = enteComunale.siglaCFis
            dato = datiContabiliService.salva(dato, inModifica)

            /// Questa verifica la possiamo fare solo DOPO aver salvato
            String message = datiContabiliService.validaPerGruppiTributo(dato)
            if (!message.empty) {
                message = "Attenzione:\n\n" + message
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 15000, true)
                result = CommonService.RES_WARNING
            } else {
                Clients.showNotification("Dato salvato", Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
            }
            if (result < CommonService.RES_ERROR) {
                inModifica = true
                BindUtils.postNotifyChange(null, null, this, "inModifica")
            }
            if (result < CommonService.RES_WARNING) {
                onChiudi()
            }
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [chiudi: true])
    }

    @Command
    onElimina() {
        if (dato) {
            Messagebox.show("Il dato verra' eliminato. Proseguire?", "Eliminazione Dato",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES == e.getName()) {
                                datiContabiliService.cancella(dato)
                                onChiudi()
                                Clients.showNotification("Dato eliminato con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                            }
                        }
                    }
            )
        }
    }

    @Command
    def onChangeAnno() {
        determinaDescrizioneTitr()
        fetchListaAnniAcc()
    }

    @Command
    def onSelezioneAnnoAcc() {
        cfaAccTributo = null
        BindUtils.postNotifyChange(null, null, this, "cfaAccTributo")
    }

    @Command
    def onSelect() {
    }

    @Command
    def onSelectTipiTributo() {

        applicaTipoTributo()

        if (tipoTributo) {
            listaCodiceTributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == tipoTributo }
                    .sort { it.id }

            listaCodiceF24 = [new CodiceF24DTO()] + OggettiCache.CODICI_F24
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == tipoTributo }
                    .sort { it.tributo }

            dato.tipoTributo = TipoTributo.findByTipoTributo(tipoTributo)?.toDTO()
            dato.tributo = listaCodiceTributo.get(0)

            codTributoF24 = listaCodiceF24.get(0)
            dato.codTributoF24 = codTributoF24.tributo
            dato.descrizioneTitr = codTributoF24.descrizioneTitr
        }

        BindUtils.postNotifyChange(null, null, this, "listaCodiceTributo")
        BindUtils.postNotifyChange(null, null, this, "listaCodiceF24")
        BindUtils.postNotifyChange(null, null, this, "dato")

        self.invalidate()
    }

    @Command
    def onSelectCodiceF24() {

        determinaDescrizioneTitr()

        dato.codTributoF24 = codTributoF24?.tributo
        dato.descrizioneTitr = codTributoF24?.descrizioneTitr
        BindUtils.postNotifyChange(null, null, this, "dato")
    }

    @Command
    onChangeRipartizione() {

        def messaggi = validaRipartizione(false)    /// Tolto il clean, crea solo confusione

        if (messaggi.size() > 0) {
            messaggi.add(0, "Attenzione:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }
    }

    @Command
    onChangeEmissione() {

        def messaggi = validaEmissione(false)       /// Tolto il clean, crea solo confusione

        if (messaggi.size() > 0) {
            messaggi.add(0, "Attenzione:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }
    }

    @Command
    def onChangeTipoOccupazione() {

        applicaTipoOccupazione()
        onChangeEmissione()
        onChangeRipartizione()
    }

    @Command
    def onSelectCfaAccTributi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def selectedRecord = event.getData()
        cfaAccTributo = selectedRecord
        BindUtils.postNotifyChange(null, null, this, "cfaAccTributo")
    }

    @Command
    def onChangeCfaAccTributi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
    }

    @Command
    onSelectEnte(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			enteComunale.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			enteComunale.codCom = selectedComune.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}

		aggiornaDettagliEnte()
    }

    // Serve per abilitare o meno controlli in caso di tipo tributo in copetenza "L"
    protected applicaTipoTributo() {

        determinaDescrizioneTitr()

        def modifica = (tipoTributo) ? competenzeService.utenteAbilitatoScrittura(tipoTributo) : false
        letturaTipoTributo = lettura || !modifica
        BindUtils.postNotifyChange(null, null, this, "letturaTipoTributo")
    }

    def validaRipartizione(boolean clean) {

        def messaggi = []

        if (dato.ripartizioneDal != null && dato.ripartizioneAl != null && (dato.ripartizioneDal > dato.ripartizioneAl)) {
            if (clean) {
                dato.ripartizioneDal = null
                dato.ripartizioneAl = null
            }
            messaggi << ("La Data Ripartizione Dal maggiore della Data Ripartizione Al")
        } else {
            def listaDC = datiContabiliService.getDatiContabili(dato)
            if (listaDC.size() > 0 && dato.ripartizioneDal != null) {
                List<DatiContabiliDTO> lista = listaDC.sort { it.ripartizioneDal }
                if (controlloRipartizionePeriodi(lista, dato.ripartizioneDal, dato.ripartizioneAl, listaDC.findIndexOf { it.id == dato.id })) {
                    if (clean) {
                        dato.ripartizioneDal = null
                        dato.ripartizioneAl = null
                    }
                    messaggi << ("Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Ripartizione Dati Contabili")
                }
            }
        }

        if (clean) {
            BindUtils.postNotifyChange(null, null, dato, "*")
        }

        return messaggi
    }

    def validaEmissione(boolean clean) {

        def messaggi = []

        if (dato.emissioneDal != null && dato.emissioneAl != null && (dato.emissioneDal > dato.emissioneAl)) {
            if (clean) {
                dato.emissioneDal = null
                dato.emissioneAl = null
            }
            messaggi << ("La Data Emissione Dal maggiore della Data Emissione Al")
        } else {
            def listaDC = datiContabiliService.getDatiContabili(dato)

            if (listaDC.size() > 0 && dato.emissioneDal != null) {
                List<DatiContabiliDTO> lista = listaDC.sort { it.emissioneDal }
                if (controlloEmissionePeriodi(lista, dato.emissioneDal, dato.emissioneAl, listaDC.findIndexOf { it.id == dato.id })) {
                    if (clean) {
                        dato.emissioneDal = null
                        dato.emissioneAl = null
                    }
                    messaggi << ("Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Emissione Dati Contabili")
                }
            }
        }

        if (clean) {
            BindUtils.postNotifyChange(null, null, dato, "*")
        }

        return messaggi
    }

    protected boolean controlloRipartizionePeriodi(List<DatiContabiliDTO> lista, Date dataDalX, Date dataAlX, int indice) {

        if (lista?.size() > 0) {
            int n = lista.size()
            for (i in 0..<n) {

                if (i != indice) {
                    Date dal = lista.get(i).ripartizioneDal
                    Date al = lista.get(i).ripartizioneAl
                    if (dataDalX == dal || (dataAlX && al && dataAlX == al) || (dataAlX && dal && dataAlX == dal)) {
                        return true
                    } else if ((dataDalX > dal && dataAlX < al && dataAlX != null) || (dataDalX > dal && dataDalX <= al)) {
                        return true
                    } else if (dataDalX <= dal && dataAlX >= al && dataDalX != null && dataAlX != null) {
                        return true
                    } else if (dataDalX <= dal && dataAlX >= dal && dataDalX != null && dataAlX != null) {
                        return true
                    }
                }
            }

            // L'ordine della lista viene cambiato prima di essere passato al metodo, si ripristina quello originale.
            ordinaLista()
            return false
        }
    }

    protected boolean controlloEmissionePeriodi(List<DatiContabiliDTO> lista, Date dataDalX, Date dataAlX, int indice) {

        if (lista?.size() > 0) {
            int n = lista.size()
            for (i in 0..<n) {

                if (i != indice) {
                    Date dal = lista.get(i).emissioneDal
                    Date al = lista.get(i).emissioneAl
                    if (dataDalX == dal || (dataAlX && al && dataAlX == al) || (dataAlX && dal && dataAlX == dal)) {
                        return true
                    } else if ((dataDalX > dal && dataAlX < al && dataAlX != null) || (dataDalX > dal && dataDalX <= al)) {
                        return true
                    } else if (dataDalX <= dal && dataAlX >= al && dataDalX != null && dataAlX != null) {
                        return true
                    } else if (dataDalX <= dal && dataAlX >= dal && dataDalX != null && dataAlX != null) {
                        return true
                    }
                }
            }
            // L'ordine della lista viene cambiato prima di essere passato al metodo, si ripristina quello originale.
            ordinaLista()
            return false
        }
    }

    private ordinaLista() {
        listaDatiContabili.sort { it.anno ? -it.anno : 0 }
        listaDatiContabili.sort { it.ripartizioneDal }
        listaDatiContabili.sort { it.emissioneDal }
        listaDatiContabili.reverse(true)
    }

    private def validaMaschera() {

        long result = CommonService.RES_SUCCESS
        String messageNow
        String message = ''

        def messaggi = []
        def subMessaggi = []

        applicaCodEnteComunale()
        applicaTipoOccupazione()

        if (dato.anno == null) {
            messaggi << ("Indicare l'anno'")
        }
        if (dato.tipoTributo == null) {
            messaggi << ("Indicare il tipo tributo")
        }

        if (dato.tipoImposta == null) {
            messaggi << ("Indicare il tipo imposta")
        }
        if (dato.ripartizioneDal == null) {
            messaggi << ("Indicare la Ripartizione Dal")
        }
        if (dato.ripartizioneAl == null) {
            messaggi << ("Indicare la Ripartizione Al")
        }

        subMessaggi = validaRipartizione(false)
        messaggi.addAll(subMessaggi)
        subMessaggi = validaEmissione(false)
        messaggi.addAll(subMessaggi)

        if (messaggi.size() > 0) {
            messaggi.add(0, "Impossibile salvare il dato:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return CommonService.RES_ERROR
        }

        if (tipoTributo == 'CUNI') {
            messageNow = datiContabiliService.validaPerCUNI(dato)
            if (!messageNow.empty) {
                messaggi << messageNow
            }
        }

        if (cfaAccTributo) {

            /// Prima verifica l'anno del Dato Contabile
            messageNow = datiContabiliService.validaAccTributoPerAnno(cfaAccTributo, dato.anno)
            if (!messageNow.empty) {
                messaggi << messageNow
            }
            /// Quindi verifica l'anno correnteme, se diverso
            Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR)
            if (annoCorrente != dato.anno) {
                messageNow = datiContabiliService.validaAccTributoPerAnno(cfaAccTributo, annoCorrente)
                if (!messageNow.empty) {
                    messaggi << messageNow
                }
            }
        }

        if (messaggi.size() > 0) {
            messaggi.add(0, "Attenzione:\n")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            if (result < CommonService.RES_WARNING) result = CommonService.RES_WARNING
        }

        return result
    }

    def applicaCodEnteComunale() {

        if(this.flagProvincia) {
            dato.codEnteComunale = enteComunale.siglaCFis
        }
        else {
            dato.codEnteComunale = null
        }
    }

    def applicaTipoOccupazione() {

        if (tipoTributo == 'CUNI') {
            dato.tipoOccupazione = tipoOccupazioneSelected?.codice
        } else {
            dato.tipoOccupazione = null
        }
    }

    private def determinaDescrizioneTitr() {
        if (tipoTributo) {
            descrizioneTitr = (codTributoF24?.descrizioneTitr == 'TEFA') ? 'TEFA' : 
                                TipoTributo.findByTipoTributo(tipoTributo)?.toDTO().getTipoTributoAttuale(dato.anno)
            BindUtils.postNotifyChange(null, null, this, "descrizioneTitr")
            return descrizioneTitr
        }
        return null
    }

	def inizializzaDettagliEnte(String siglaCFis) {

		if((siglaCFis != null) && (!siglaCFis.isEmpty())) {
			def comune = fornitureAEService.getComuneDaSiglaCFis(siglaCFis)

			enteComunale.codPro = comune?.provincia?.id ?: comune?.stato?.id
			enteComunale.codCom = comune?.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}
		aggiornaDettagliEnte()
	}

	def aggiornaDettagliEnte() {

		Ad4ComuneTr4 comune = null
		
		Long codPro = enteComunale.codPro as Long
		Integer codCom = enteComunale.codCom as Integer
		
		if (codCom != null && codPro != null) {
			comune = Ad4ComuneTr4.createCriteria().get {
				eq('provinciaStato', codPro)
				eq('comune', codCom)
			}
		}
		
		if(comune) {
			Ad4Comune ad4Comune = comune.ad4Comune
			
			enteComunale.denominazione = ad4Comune?.denominazione
			enteComunale.provincia = ad4Comune?.provincia?.denominazione
			enteComunale.siglaProv = ad4Comune?.provincia?.sigla
			enteComunale.siglaCFis = ad4Comune?.siglaCodiceFiscale
		}
		else {
			enteComunale.denominazione = ""
			enteComunale.provincia = ""
			enteComunale.siglaProv = ""
			enteComunale.siglaCFis = ""
		}
		
        BindUtils.postNotifyChange(null, null, this, "enteComunale")
	}
}
