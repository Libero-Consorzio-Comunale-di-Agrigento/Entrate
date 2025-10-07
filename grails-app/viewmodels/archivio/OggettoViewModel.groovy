package archivio

import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.oggetti.OggettiService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class OggettoViewModel {

    // services
    OggettiService oggettiService
    def springSecurityService
    CompetenzeService competenzeService
    CommonService commonService

    // componenti
    Window self

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti

    // dati
    OggettoDTO oggetto
    CivicoOggettoDTO riferimentoCivico
    Popup popupNote

    EventListener<Event> isDirtyEvent = null
    boolean isDirty = false

    // comboBox
    def listaTipologiaOggetto
    def listaEdifici
    def listaTipiUso
    def listaFonti
    def listaTipiQualita = [:]
    def tipoQualitaSelezionato
    def listaTipiArea

    List listaTipiTributo
    List listaTipiUtilizzo
    List listaCategorieCatasto
    List<UtilizzoOggettoDTO> listaAppoggioUtilizziNuovi = []
    List<UtilizzoOggettoDTO> listaAppoggioUtilizziVecchi = []
    def listaAnomalieOggetto = []

    boolean lettura = false
    boolean modifica = false
    boolean modificaTipoOggetto = false

    boolean bonifiche = false
    boolean aggiornaStato = false

    def filtri = [
            indirizzo           : null,
            tipoOggetto         : null,
            categoriaCatasto    : null,
            codFiscale          : "",
            //
            latitudine          : null,
            longitudine         : null,
            aLatitudine         : null,
            aLongitudine        : null
    ]

    def salvato = false

    def ripristinoRendite = false

    List<RiferimentoOggettoDTO> listaRiferimento

    @NotifyChange([
            "modifica",
            "tipoQualitaSelezionato"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("oggetto") def idOggettoSelezionato
         , @ExecutionArgParam("filtri") def f
         , @ExecutionArgParam("daBonifiche") def daBonifiche
         , @ExecutionArgParam("lettura") def lt) {

        this.self = w

        this.bonifiche = daBonifiche ?: false
        this.lettura = lt ?: false

        listaTipologiaOggetto = OggettiCache.TIPI_OGGETTO.valore.sort { it.tipoOggetto }
        listaEdifici = Edificio.list().toDTO()
        listaTipiUso = TipoUso.list().toDTO().sort { it.id }
        listaFonti = Fonte.list().toDTO().sort { it.fonte }
        // listaTipiQualita = TipoQualita.list().sort{ it.descrizione }.toDTO()
        listaTipiTributo = competenzeService.tipiTributoUtenza()
        listaTipiUtilizzo = TipoUtilizzo.list().toDTO().sort { it.id }
        listaTipiArea = TipoArea.list().toDTO()
        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale }
        listaAnomalieOggetto = oggettiService.listaAnomalie(idOggettoSelezionato)

        listaTipiQualita << [nessuno: '']
        TipoQualita.list().sort { it.descrizione }.toDTO().each {
            listaTipiQualita << [(it.id): it.descrizione]
        }


        modifica = idOggettoSelezionato > 0
        modificaTipoOggetto = idOggettoSelezionato == -1

        if (modifica) {

            if (idOggettoSelezionato) oggetto = oggettiService.getOggetto(idOggettoSelezionato?.longValue())
            // se il soggetto relativo all'utilizzo è vuoto lo inizializzo con un DTO vuoto
            // per evitare di ricevere un errore quando modifico un utilizzo
            // privo di soggetto
            oggetto.utilizziOggetto?.each {
                if (!it.soggetto) it.soggetto = new SoggettoDTO()
            }

            if (oggetto.tipoQualita) {
                tipoQualitaSelezionato = listaTipiQualita.find { it.key == oggetto.tipoQualita?.id }
            }

            // Se non è associata una via si deve visualizzare indirizzoLocalita
            settaNomiVia(oggetto.civiciOggetto)

            /*il calcolo delle liste civici, utilizzi, partizioni, riferimenti e notifiche va fatto nell'init
             non può essere fatto sull'onSelect del singolo tab altrimenti il metodo di salvataggio non funziona correttamente
             se non si clicca sul tab la lista dei DTO rimane vuota e al salvataggio vengono cancellati tutti i dati da db*/
            //	oggetto.civiciOggetto = oggettiService.listaCivici(oggettoSelezionato).toDTO()
            disabilitaCivico(oggetto.civiciOggetto)

            //Controlla l'esistenza di almeno un record nella tabella RIFERIMENTI_OGGETTO_BK per abilitare la voce di Ripristino rendite...
            ripristinoRendite = (oggettiService.listaRiferimentiOggettBk(oggetto.id).size() > 0) && !lettura

            if (f) filtri = f
            filtri.indirizzo = oggetto?.archivioVie?.denomUff
            listaRiferimento = oggetto?.riferimentiOggetto?.sort { it.inizioValidita }

        } else {
            oggetto = new OggettoDTO()
            oggetto.fonte = listaFonti.find { it.fonte == 3 }
            filtri.indirizzo = null
            filtri.tipoOggetto = ""
            filtri.categoriaCatasto = ""
            filtri.codFiscale = ""
            ripristinoRendite = false
        }

        aggiornaGeolocalizzazioneDa()
        aggiornaGeolocalizzazioneA()

        isDirtyEvent = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {
                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    isDirty = isDirty || !(pe.property in [
                            'listaTipologiaOggetto',
                            'listaEdifici',
                            'listaTipiUso',
                            'listaFonti',
                            'listaTipiQualita',
                            'listaTipiArea',
                            'listaTipiTributo',
                            'listaTipiUtilizzo',
                            'listaCategorieCatasto',
                            'listaAppoggioUtilizziNuovi',
                            'listaAppoggioUtilizziVecchi',
                            'listaAnomalieOggetto',
                            'listaRiferimento',
                            'oggettoSelezionato',
                            'oggetto',
                            'modificaTipoOggetto',
                            "modifica",
                            "filtri",
                            'isDirty'
                    ])
                    println(pe.property)
                }
            }
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(isDirtyEvent);
    }

    @AfterCompose
    void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

        if (lettura) {
            componenti.each {
                it.disabled = lettura
            }
        }
    }

    @Command
    onAggiungiCivico() {

        CivicoOggettoDTO civOgg = new CivicoOggettoDTO()
        // calcolo il numero di sequenza per i civici
        if (modifica) {
            def max = oggetto.civiciOggetto?.max { it.sequenza }?.sequenza ?: 0
            civOgg.sequenza = max + 1
        }
        ArchivioVieDTO archivioDTO = new ArchivioVieDTO()
        civOgg.archivioVie = archivioDTO
        oggetto.addToCiviciOggetto(civOgg)
        BindUtils.postNotifyChange(null, null, oggetto, "civiciOggetto")
    }

    @Command
    onAggiungiUtilizzo() {
        listaAppoggioUtilizziNuovi = []
        listaAppoggioUtilizziVecchi = []

        if (oggetto.utilizziOggetto != null && !oggetto.utilizziOggetto.isEmpty()) listaAppoggioUtilizziVecchi += oggetto.utilizziOggetto

        UtilizzoOggettoDTO utilOgg = new UtilizzoOggettoDTO(sequenza: -1)
        utilOgg.soggetto = new SoggettoDTO()
        listaAppoggioUtilizziNuovi.add(utilOgg)
        oggetto.addToUtilizziOggetto(utilOgg)
        BindUtils.postNotifyChange(null, null, oggetto, "utilizziOggetto")
    }

    @Command
    onAggiungiPartizione() {
        PartizioneOggettoDTO partOgg = new PartizioneOggettoDTO()
        //calcolo il numero di sequenza per la partizione
        partOgg.sequenza = (oggetto.partizioniOggetto) ? ((oggetto.partizioniOggetto?.size() == 0) ? 1 : (oggetto.partizioniOggetto?.max { it.sequenza }?.sequenza + 1)) : 0
        oggetto.addToPartizioniOggetto(partOgg)
        BindUtils.postNotifyChange(null, null, oggetto, "partizioniOggetto")
    }

    @Command
    onChangeConsistenza(@BindingParam("part") PartizioneOggettoDTO partizione, @BindingParam("con") ConsistenzaTributoDTO con) {
        //Controllo che la consistenza per tipo tributo non può essere maggiore di quella per tipo area
        if (con.consistenza != null && con.consistenza > partizione.consistenza) {
            Clients.showNotification("Attenzione. La consistenza è maggiore rispetto alla consistenza per Tipo area.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }
    }

    @Command
    onChangeTipoTributo(@BindingParam("part") PartizioneOggettoDTO partizione, @BindingParam("con") ConsistenzaTributoDTO con) {
        int controllo = 0
        if (partizione?.consistenzeTributo?.size() > 0) {
            partizione.consistenzeTributo.each { c ->
                if (c.tipoTributo != null && con.tipoTributo.tipoTributo.equals(c.tipoTributo.tipoTributo))
                    controllo++
            }
        }
        if (controllo > 1) {
            Clients.showNotification("Attenzione. Il tipo tributo " + con.tipoTributo.tipoTributo + " già presente.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }
    }

    @Command
    onAggiungiConsistenza(@BindingParam("arg") PartizioneOggettoDTO partizione) {
        ConsistenzaTributoDTO consistenza = new ConsistenzaTributoDTO()
        (oggetto.partizioniOggetto).each { part ->
            if (part.sequenza == partizione.sequenza) {
                part.addToConsistenzeTributo(consistenza)
                part.open = true
            }
        }
        BindUtils.postNotifyChange(null, null, oggetto, "partizioniOggetto")
        BindUtils.postNotifyChange(null, null, oggetto.partizioniOggetto, "consistenzaTributo")
    }

    @NotifyChange(["oggetto", "listaRiferimento"])
    @Command
    onAggiungiRiferimento() {
        /* RiferimentoOggettoDTO rifOgg = new RiferimentoOggettoDTO()
         oggetto.addToRiferimentiOggetto(rifOgg)
         BindUtils.postNotifyChange(null, null, oggetto, "riferimentiOggetto")*/
        RiferimentoOggettoDTO rifOgg = new RiferimentoOggettoDTO()
        if (!listaRiferimento) {
            listaRiferimento = new ArrayList<RiferimentoOggettoDTO>()
        }
        rifOgg.oggetto = oggetto
        listaRiferimento.add(rifOgg)
    }

    /* Controllo periodo DAL di un riferimento */

    @NotifyChange(["rif", "datarif"])
    @Command
    onCheckDataDal(@BindingParam("datarif") RiferimentoOggettoDTO riferimentoOggettoDTO) {
        if (riferimentoOggettoDTO?.inizioValidita) {

            //La data Dal non può essere maggiore della data Al
            if (riferimentoOggettoDTO?.inizioValidita != null && riferimentoOggettoDTO?.fineValidita != null && (riferimentoOggettoDTO?.inizioValidita > riferimentoOggettoDTO?.fineValidita)) {
                //riferimentoOggettoDTO.inizioValidita = null
                Clients.showNotification("Attenzione. Inizio validità maggiore di Fine validità!!!", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                //Se sono stati definiti entrambe le date dal - al allora si controlla se ci sono intersezioni
                if (oggetto?.riferimentiOggetto?.size() > 0 && riferimentoOggettoDTO?.inizioValidita != null && riferimentoOggettoDTO?.fineValidita != null) {
                    if (controlloPeriodi(riferimentoOggettoDTO?.inizioValidita, riferimentoOggettoDTO?.fineValidita, listaRiferimento.indexOf(riferimentoOggettoDTO))) {
                        // riferimentoOggettoDTO.inizioValidita = null
                        Clients.showNotification("Attenzione. Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Riferimento Oggetto!!!", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                    }
                }
            }
        }
    }

    /* Controllo AL di un riferimento */

    @NotifyChange(["rif", "datarif"])
    @Command
    onCheckDataAl(@BindingParam("datarif") RiferimentoOggettoDTO riferimentoOggettoDTO) {
        if (riferimentoOggettoDTO?.fineValidita) {

            //La data Dal non può essere maggiore della data Al
            if (riferimentoOggettoDTO?.inizioValidita != null && riferimentoOggettoDTO?.fineValidita != null && (riferimentoOggettoDTO?.inizioValidita > riferimentoOggettoDTO?.fineValidita)) {
                //riferimentoOggettoDTO.fineValidita = null
                Clients.showNotification("Attenzione. Inizio validità maggiore di Fine validità!!!", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                //Se sono stati definiti entrambe le date dal - al allora si controlla se ci sono intersezioni
                if (oggetto?.riferimentiOggetto?.size() > 0 && riferimentoOggettoDTO?.inizioValidita != null && riferimentoOggettoDTO?.fineValidita != null) {
                    if (controlloPeriodi(riferimentoOggettoDTO?.inizioValidita, riferimentoOggettoDTO?.fineValidita, listaRiferimento.indexOf(riferimentoOggettoDTO))) {
                        //riferimentoOggettoDTO.fineValidita = null
                        Clients.showNotification("Attenzione. Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Riferimenti Oggetto!!!", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                    }
                }
            }
        }
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()
        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
	def onChangeLatitudineDa() {
		oggetto.latitudine = oggettiService.tryParseCoordinate(filtri.latitudine)
		filtri.latitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.latitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

    @Command
	def onChangeLongitudineDa() {
		oggetto.longitudine = oggettiService.tryParseCoordinate(filtri.longitudine)
		filtri.longitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.longitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

    @Command
	def onChangeLatitudineA() {
		oggetto.aLatitudine = oggettiService.tryParseCoordinate(filtri.aLatitudine)
		filtri.aLatitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.aLatitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

    @Command
	def onChangeLongitudineA() {
		oggetto.aLongitudine = oggettiService.tryParseCoordinate(filtri.aLongitudine)
		filtri.aLongitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.aLongitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

	private def aggiornaGeolocalizzazioneDa() {

		filtri.latitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.latitudine)
		filtri.longitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.longitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

	private def aggiornaGeolocalizzazioneA() {

		filtri.aLatitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.aLatitudine)
		filtri.aLongitudine = oggettiService.formatCoordinateSexagesimalNS(oggetto.aLongitudine)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

    protected boolean controlloPeriodi(Date dataDalX, Date dataAlX, int indice) {
        boolean isIntersezioni = true
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(("dd/MM/yyy"))
        List<RiferimentoOggettoDTO> lista = oggetto?.riferimentiOggetto.sort { it.inizioValidita }
        if (indice < lista.size())
            lista.remove(indice)

        if (lista?.size() > 0) {
            int n = lista.size()
            for (i in 0..<n) {
                Date dal = lista.get(i).inizioValidita
                Date al = lista.get(i).fineValidita
                //println "X su dal "+simpleDateFormat.format(dataDalX)+" - "+simpleDateFormat.format(dataAlX)
                //println "Data su i=" + i + " dal " + simpleDateFormat.format(dal) + " - " + simpleDateFormat.format(al)

                if (i == 0 && dataDalX < dal && dataAlX < dal && dataAlX < al) {
                    isIntersezioni = false
                    //println "Caso precedente " + isIntersezioni
                } else {
                    if ((i == n - 1) && dataDalX > dal && dataAlX > al && dataDalX > al) {
                        isIntersezioni = false
                        //println "Caso successivo " + isIntersezioni
                    } else {
                        if (i < n && (i + 1 < n) && dataDalX > al && dataAlX < lista.get(i + 1).inizioValidita) {
                            isIntersezioni = false
                            //println "Caso interno " + isIntersezioni
                        }
                    }
                }
            }
            //println "Ci sono intersezioni????"+isIntersezioni
            return isIntersezioni
        }
    }

    protected boolean controlloAliquotePeriodi(Date dataDalX, Date dataAlX, int indice) {
        boolean isIntersezioni = true

        List<AliquotaOgcoDTO> lista = oggettoContribuente.aliquoteOgco.sort { it.dal }
        if (indice < lista.size())
            lista.remove(indice)

        if (lista?.size() > 0) {
            int n = lista.size()
            for (i in 0..<n) {
                Date dal = lista.get(i).dal
                Date al = lista.get(i).al
                //println "X su dal "+simpleDateFormat.format(dataDalX)+" - "+simpleDateFormat.format(dataAlX)
                //println "Data su i="+i+" dal "+dal+" - "+al
                if (i == 0 && dataDalX < dal && dataAlX < dal && dataAlX < al) {
                    isIntersezioni = false
                    //println "Caso precedente " + isIntersezioni
                } else {
                    if ((i == n - 1) && dataDalX > dal && dataAlX > al && dataDalX > al) {
                        isIntersezioni = false
                        //println "Caso successivo " + isIntersezioni
                    } else {
                        if (i < n && (i + 1 < n) && dataDalX > al && dataAlX < lista.get(i + 1).dal) {
                            isIntersezioni = false
                            //println "Caso interno " + isIntersezioni
                        }
                    }
                }
            }
            // println "Ci sono intersezioni????"+isIntersezioni
            return isIntersezioni

        }
    }

    @Command
    onAggiungiNotifica() {
        NotificaOggettoDTO notOgg = new NotificaOggettoDTO()
        ContribuenteDTO contribuenteDto = new ContribuenteDTO()
        notOgg.contribuente = contribuenteDto
        oggetto.addToNotificheOggetto(notOgg)
        BindUtils.postNotifyChange(null, null, oggetto, "notificheOggetto")
    }

    @Command
    def onAcquisisciGeolocalizzazioneDa() {

        Window w = Executions.createComponents("/archivio/datiGeolocalizzazioneOggetto.zul", self, [lettura : lettura ])
        w.onClose { event ->
            if (event.data) {
                def report = event.data.geolocalizzazione
                if(report.result == 0) {
                    oggetto.latitudine = report.latitudine
                    oggetto.longitudine = report.longitudine
                    aggiornaGeolocalizzazioneDa()
                    BindUtils.postNotifyChange(null, null, this, "oggetto")
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAcquisisciGeolocalizzazioneA() {

        Window w = Executions.createComponents("/archivio/datiGeolocalizzazioneOggetto.zul", self, [lettura : lettura ])
        w.onClose { event ->
            if (event.data) {
                def report = event.data.geolocalizzazione
                if(report.result == 0) {
                    oggetto.aLatitudine = report.latitudine
                    oggetto.aLongitudine = report.longitudine
                    aggiornaGeolocalizzazioneA()
                    BindUtils.postNotifyChange(null, null, this, "oggetto")
                }
            }
        }
        w.doModal()
    }

    @Command
    def onGeolocalizzaOggettoDa() {

        String url = oggettiService.getGoogleMapshUrl(null, oggetto.latitudine, oggetto.longitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onGeolocalizzaOggettoA() {

        String url = oggettiService.getGoogleMapshUrl(null, oggetto.aLatitudine, oggetto.aLongitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onElimina() {
        String messaggio = "Eliminare l'oggetto?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            if (eliminaOggetto()) {
                                chiudi()
                            }
                        }
                    }
                }
        )
    }

    private def eliminaOggetto() {
        def msg = ""
        try {
            msg = oggettiService.elimina(oggetto)
            if (!msg.isEmpty()) {
                Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
                return false
            } else
                return true
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return false
            } else {
                throw e
            }
        }
    }

    @Command
    onSalva(@BindingParam("aggiornaStato") boolean aggiornaStato) {
        this.aggiornaStato = aggiornaStato
        salvaOggetto()
    }

    protected salvaOggetto(@Default("") String msg) {
        if (validaMaschera()) {

            if (tipoQualitaSelezionato) {
                if (tipoQualitaSelezionato?.key.equals("nessuno")) {
                    oggetto.tipoQualita = null
                } else {
                    oggetto.tipoQualita = TipoQualita.get(tipoQualitaSelezionato?.key).toDTO()
                }
            }

            //calcolo della sequenza dei civiciOggetto
            if (!modifica) { //è un inserimento
                int sequenza = 1
                oggetto.civiciOggetto?.each { CivicoOggettoDTO civOggDTO ->
                    civOggDTO.sequenza = sequenza++
                }
                CivicoOggettoDTO firstCivOgg = new CivicoOggettoDTO()
                firstCivOgg.sequenza = sequenza
                firstCivOgg.indirizzoLocalita = oggetto.indirizzoLocalita
                firstCivOgg.archivioVie = oggetto.archivioVie
                firstCivOgg.numCiv = oggetto.numCiv
                firstCivOgg.suffisso = oggetto.suffisso

                oggetto.addToCiviciOggetto(firstCivOgg)
            }

            //determino la sequenza degli utilizziOggetto
            if (listaAppoggioUtilizziNuovi != null && !listaAppoggioUtilizziNuovi.isEmpty()) {
                for (UtilizzoOggettoDTO newUti in listaAppoggioUtilizziNuovi) {
                    def utilizzo = listaAppoggioUtilizziVecchi.findAll {
                        newUti.tipoTributo.tipoTributo == it.tipoTributo.tipoTributo &&
                                newUti.oggetto.id == it.oggetto.id &&
                                newUti.anno == it.anno &&
                                newUti.tipoUtilizzo.id == it.tipoUtilizzo.id
                    }?.max { it.sequenza }
                    if (utilizzo) newUti.sequenza = utilizzo.sequenza + 1
                    else newUti.sequenza = 1
                }
            }

            if (listaRiferimento?.size() > 0)
                oggetto?.riferimentiOggetto = new TreeSet<RiferimentoOggettoDTO>(listaRiferimento.flatten())
            oggetto = oggettiService.salvaOggetto(oggetto, riferimentoCivico, modifica)
            disabilitaCivico(oggetto.civiciOggetto)
            settaNomiVia(oggetto.civiciOggetto)

            salvato = true
            if (msg)
                Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)
            else {
                Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)
                listaRiferimento = oggetto?.riferimentiOggetto?.sort { it.inizioValidita }
            }
            isDirty = false
            modifica = true
            modificaTipoOggetto = false

            BindUtils.postNotifyChange(null, null, this, "isDirty")
            BindUtils.postNotifyChange(null, null, this, "oggetto")
            BindUtils.postNotifyChange(null, null, this, "listaRiferimento")
            BindUtils.postNotifyChange(null, null, this, "modifica")
            BindUtils.postNotifyChange(null, null, this, "modificaTipoOggetto")
        }
    }

    @Command
    onChiudi() {
        /*if (isDirty && !validaMaschera()) {
            return
        }*/

        if (isDirty) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                salvaOggetto()
                                if (salvato) {
                                    chiudi()
                                }
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                chiudi()
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            chiudi()
        }
    }

    protected chiudi() {

        if (isDirtyEvent) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(isDirtyEvent)
            isDirtyEvent = null
        }
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, salvato: salvato])
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onDuplica() {
        oggetto = oggettiService.duplica(oggetto)
        salvaOggetto("Duplicazione eseguita.")
        //Sistemazione dei civici oggetto
        int sequenza = 1
        oggetto.civiciOggetto?.each { CivicoOggettoDTO civOggDTO ->
            sequenza = sequenza + 1
            civOggDTO.sequenza = sequenza
        }
        CivicoOggettoDTO firstCivOgg = new CivicoOggettoDTO()
        firstCivOgg.sequenza = 1
        firstCivOgg.indirizzoLocalita = oggetto.indirizzoLocalita
        firstCivOgg.archivioVie = oggetto.archivioVie
        firstCivOgg.numCiv = oggetto.numCiv
        firstCivOgg.suffisso = oggetto.suffisso

        oggetto.addToCiviciOggetto(firstCivOgg)
        BindUtils.postNotifyChange(null, null, this, "oggetto")
    }

    // BandboxVie
    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtri.indirizzo = (event.data.denomUff ?: null)
        oggetto.archivioVie = event.data
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onSelectIndirizzoCivico(@ContextParam(ContextType.TRIGGER_EVENT) Event event, @BindingParam("arg") CivicoOggettoDTO civOggDTO) {
        civOggDTO.archivioVie = event.data
        def componente = event.getTarget()
        componente.value = (event.data.denomUff ?: "")
        BindUtils.postNotifyChange(null, null, this, "componente")
    }

    //Bandbox Soggetti
    @Command
    onSelectSoggettoUtilizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event, @BindingParam("arg") UtilizzoOggettoDTO utilOgg) {
        utilOgg.soggetto = event.data
        def componente = event.getTarget()
        componente.value = (event.data.codFiscale ?: "")

        BindUtils.postNotifyChange(null, null, this, "componente")
        BindUtils.postNotifyChange(null, null, this, "oggetto")
    }

    @Command
    onChangingSoggettoUtilizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event, @BindingParam("arg") UtilizzoOggettoDTO utilOgg) {
        if (utilOgg.soggetto?.codFiscale != null && utilOgg.soggetto?.codFiscale.length() == 0) {
            utilOgg.intestatario = ""
            utilOgg.soggetto = new SoggettoDTO(codFiscale: "", cognomeNome: "")
            BindUtils.postNotifyChange(null, null, oggetto, "utilizziOggetto")
        }
    }

    @Command
    onSelectContribuente(@ContextParam(ContextType.TRIGGER_EVENT) Event event, @BindingParam("arg") NotificaOggettoDTO notifica) {
        notifica.contribuente = event.data

        def componente = event.getTarget()
        componente.value = (event.data.codFiscale ?: "")
        BindUtils.postNotifyChange(null, null, this, "componente")
        BindUtils.postNotifyChange(null, null, this, "oggetto")
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onEliminaCivico(@BindingParam("civ") CivicoOggettoDTO civOggDTO) {
        oggetto.removeFromCiviciOggetto(civOggDTO)
        isDirty = true
        BindUtils.postNotifyChange(null, null, oggetto, "civiciOggetto")
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onEliminaUtilizzo(@BindingParam("uti") UtilizzoOggettoDTO utiOggDTO) {
        oggetto.removeFromUtilizziOggetto(utiOggDTO)
        isDirty = true
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onEliminaPartizione(@BindingParam("part") PartizioneOggettoDTO partOggDTO) {

        partOggDTO.consistenzeTributo.each { c ->
            partOggDTO.removeFromConsistenzeTributo(c)
        }
        oggetto.removeFromPartizioniOggetto(partOggDTO)
        isDirty = true
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onEliminaConsistenza(
            @BindingParam("con") ConsistenzaTributoDTO conPartDTO,
            @BindingParam("part") PartizioneOggettoDTO partOggDTO) {
        (oggetto.getPartizioniOggetto()).each { part ->
            if (part.sequenza == partOggDTO.sequenza) {
                part.removeFromConsistenzeTributo(conPartDTO)
            }
        }
        isDirty = true
    }

    @NotifyChange(["oggetto", "isDirty", "listaRiferimento"])
    @Command
    onEliminaRiferimento(@BindingParam("rif") RiferimentoOggettoDTO rifOggDTO) {
        //oggetto.removeFromRiferimentiOggetto(rifOggDTO)
        //isDirty = true
        oggetto.removeFromRiferimentiOggetto(rifOggDTO)
        listaRiferimento = oggetto?.riferimentiOggetto?.sort { it.inizioValidita }
        isDirty = true
    }

    @NotifyChange(["oggetto", "isDirty"])
    @Command
    onEliminaNotifica(@BindingParam("noti") NotificaOggettoDTO notiOggDTO) {
        oggetto.removeFromNotificheOggetto(notiOggDTO)
        isDirty = true
    }

    def disabilitaCivico(def listaCivici) {
        for (CivicoOggettoDTO civDTO in listaCivici) {
            if (civDTO?.sequenza == 1) {
                civDTO.riferimentoIndirizzo = true
                riferimentoCivico = civDTO
            }
        }
    }

    private def settaNomiVia(def civici) {
        civici?.each { civ ->
            if (civ?.archivioVie?.id == null) {
                ArchivioVieDTO archivioDTO = new ArchivioVieDTO()
                civ.archivioVie = archivioDTO
                civ.archivioVie.denomUff = civ.indirizzoLocalita
                oggetto.addToCiviciOggetto(civ)
            }
        }
    }

    private boolean validaMaschera() {
        def messaggi = []

        if (oggetto.tipoOggetto == null) {
            messaggi << ("Indicare la tipologia dell'oggetto")
        }
        if (oggetto.fonte == null) {
            messaggi << ("Indicare la fonte dell'oggetto")
        }

        if (tipoQualitaSelezionato != null && tipoQualitaSelezionato?.key != "nessuno" && oggetto.qualita != "" && oggetto.qualita != null) {
            messaggi << ("I dati identificativi della qualità non possono essere entrambi indicati!")
        }


        if (oggetto?.utilizziOggetto?.size() > 0) {
            boolean utilizzi = false
            oggetto.utilizziOggetto.each { u ->
                if (u.tipoUtilizzo == null || u.tipoTributo == null || u.anno == null)
                    utilizzi = true
                //Controllo del soggetto
                if ((u.soggetto?.codFiscale?.trim()?.length() > 0)) {
                    def sogg = Soggetto.findByCodFiscale(u.soggetto.codFiscale)
                    if (!sogg) {
                        utilizzi = true
                        messaggi << ("Il codice fiscale " + u.soggetto.codFiscale + " inserito non corrisponde a nessun contribuente")
                    }
                }
            }
            if (utilizzi)
                messaggi << ("Compilare correttamente i campi obbligatori nel folder utilizzi")
        }
        if (oggetto?.partizioniOggetto?.size() > 0) {
            boolean partizioni = false
            boolean consistenzeMaggiori = false
            oggetto.partizioniOggetto.each { p ->

                if (p.tipoArea == null || p.consistenza == null)
                    partizioni = true

                if (p?.consistenzeTributo?.size() > 0) {
                    boolean consistenze = false

                    p.consistenzeTributo.each { c ->
                        if (c.tipoTributo == null || c.consistenza == null)
                            consistenze = true

                        //Controllo che la consistenza per tipo tributo non può essere maggiore di quella per tipo area
                        if (c.consistenza != null && c.consistenza > p.consistenza) {
                            consistenzeMaggiori = true
                        }
                    }
                    if (consistenze)
                        messaggi << ("Compilare correttamente i campi obbligatori delle consistenze nel folder partizioni")
                }
            }
            if (consistenzeMaggiori)
                messaggi << ("Valori di consistenze troppo alte")

            if (partizioni)
                messaggi << ("Compilare correttamente i campi obbligatori nel folder partizioni")
        }

        if (oggetto?.riferimentiOggetto?.size() > 0) {
            boolean riferimenti = false
            oggetto.riferimentiOggetto.each { r ->
                if (r.inizioValidita == null || r.fineValidita == null || r.rendita == null)
                    riferimenti = true
            }
            if (riferimenti)
                messaggi << ("Compilare correttamente i campi obbligatori nel folder riferimenti")
            else {
                listaRiferimento = listaRiferimento.sort { it.inizioValidita }
                for (i in 0..<listaRiferimento.size()) {
                    if (controlloPeriodi(listaRiferimento.getAt(i).inizioValidita, listaRiferimento.getAt(i).fineValidita, i)) {
                        messaggi << "Sono presenti delle intersezioni di periodo Dal/Al tra le date Aliquote Oggetto."
                        break
                    }
                }
            }
        }

        if (oggetto?.notificheOggetto?.size() > 0) {
            boolean notifiche = false
            oggetto.notificheOggetto.each { n ->
                if (n.contribuente.codFiscale == null || n.annoNotifica == null)
                    notifiche = true
            }
            if (notifiche)
                messaggi << ("Compilare correttamente i campi obbligatori nel folder notifiche")
        }

        if (oggetto?.classeCatasto?.length() > 2) {
            messaggi << ("Valore errato per il campo classe.")
        }

        // Solo il civico con sequenza 1 può avere l'indirizzo non settato
        if (oggetto.civiciOggetto.find { it.sequenza > 1 && (it.archivioVie == null || it.archivioVie.id == null) } != null) {
            messaggi << "Il campo indirizzo è obbligatario per i civici"
        }

        if (messaggi.size() > 0) {
            messaggi.add(0, "Impossibile salvare l'oggetto:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    @NotifyChange("modificaTipoOggetto")
    @Command
    onModificaTipoOggetto() {
        String message = oggettiService.tipoOggettoModificabile(oggetto.id)
        if (!message.isEmpty()) {
            Messagebox.show(message, "Aggiornamento Oggetto: " + oggetto.id, Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            modificaTipoOggetto = !modificaTipoOggetto
        }
    }

    @Command
    onRipristinoRendite() {
        Window w = Executions.createComponents("/archivio/listaRiferimentiOggettoRicerca.zul", self, [oggetto: oggetto])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "eseguito") {
                    SortedSet<RiferimentoOggettoDTO> ts = new TreeSet<RiferimentoOggettoDTO>()
                    List<RiferimentoOggettoDTO> lista = RiferimentoOggetto.findAllByOggetto(oggetto.toDomain()).toDTO()
                    lista.each {
                        ts.add(it)
                    }
                    oggetto.riferimentiOggetto = ts
                    BindUtils.postNotifyChange(null, null, oggetto, "riferimentiOggetto")
                }
            }
        }
        w.doModal()
    }
}
