package sportello.contribuenti

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.TariffaDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.util.Clients

import java.text.DecimalFormat

class OggettiDaDatiMetriciDettaglioQuadroViewModel {

    private def DM_PERCRID = 80
    private def DM_RID = 'N'

    // Injected
    def self

    // Service
    DenunceService denunceService
    CommonService commonService

    // Model
    short anno
    def dettaglioAssociato

    CodiceTributoDTO codiceTributo
    CategoriaDTO categoria
    TariffaDTO tariffa
    List<CodiceTributoDTO> listaCodicitributo
    List<CategoriaDTO> listaCategorie
    List<TariffaDTO> listaTariffe

    Date inizioOccupazione
    Date dataDecorrenza
    Boolean flagDaDatiMetrici = true
    BigDecimal superficie
    BigDecimal superficieDM
    BigDecimal percPossesso = 100

    Boolean flagRiduzioneSuperficie
    String labelRiduzioneSuperficie
    Boolean flagContenzioso
    Short numeroFamiliari
    Boolean flagAbPrincipale
    Boolean modificaAbPriARuolo
    BigDecimal percRiduzioneSuperficie

    BigDecimal rowNum

    @Init
    init() {

        DM_PERCRID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_PERCRID' }?.valore?.trim() as Double) ?: 80.0
        DM_RID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_RID' }?.valore?.trim()) ?: 'N'

        BindUtils.postGlobalCommand(null, null, "aggiungiDettaglio",
                [
                        dettaglio: this
                ])
    }

    @Command
    def onOggettoDaGenerare(@BindingParam("aggiungi") Boolean aggiungi) {

        if (aggiungi) {
            def valida = valida()
            if (valida.size() > 0) {
                valida.add(0, "Impossibile aggiungere l'immobile [${dettaglioAssociato.immobile}]:")
                Clients.showNotification(valida.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return
            }
        }

        BindUtils.postGlobalCommand(null, null, "ogettoDaGenerare",
                [
                        rowNum  : dettaglioAssociato.rowNum,
                        aggiungi: aggiungi
                ])
    }

    @Command
    def onRiempiCategoria() {
        riempiCategoria(true)
    }

    @Command
    def onRiempiTariffa() {
        riempiTariffa(true)
    }

    def valida() {
        def errori = []

        if (!superficie) {
            errori << "Campo 'Superficie' non valorizzato."
        }

        if (!dataDecorrenza) {
            errori << "Campo 'Data decorrenza' non valorizzato."
        }

        if (!codiceTributo) {
            errori << "Campo 'Cod. Tributo' non valorizzato."
        }

        if (!categoria) {
            errori << "Campo 'Categoria' non valorizzato."
        }

        if (!tariffa || !tariffa.id) {
            errori << "Campo 'Tariffa' non valorizzato."
        }

        return errori
    }

    boolean isValid() {
        return valida().empty
    }

    def inizializza(short anno, def dettaglioAperto) {
        // this.superficie = superficie
        this.rowNum = dettaglioAperto.rowNum
        this.anno = anno
        this.dettaglioAssociato = dettaglioAperto

        listaCodicitributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                .valore
                .findAll { it.tipoTributo?.tipoTributo == 'TARSU' }
                .sort { it.id }

        String patternNumero = "#,##0.00"
        DecimalFormat numero = new DecimalFormat(patternNumero)
        this.percRiduzioneSuperficie = DM_PERCRID
        this.labelRiduzioneSuperficie = "Rid. ${numero.format(percRiduzioneSuperficie)}%"
        this.flagRiduzioneSuperficie = (DM_RID == 'S')
        this.superficieDM = dettaglioAperto.superficie
        this.superficie = DM_RID == 'S' ? (dettaglioAperto.superficie ?: 0) * (percRiduzioneSuperficie) / 100 : (dettaglioAperto.superficie ?: 0)
        this.inizioOccupazione = this.determinaInizioValidita(anno, dettaglioAperto.inizioValidita as Date)
        onCambiaInizioOccupazione()

        BindUtils.postNotifyChange(null, null, this, "inizioOccupazione")
        BindUtils.postNotifyChange(null, null, this, "listaCodicitributo")
        BindUtils.postNotifyChange(null, null, this, "labelRiduzioneSuperficie")
        BindUtils.postNotifyChange(null, null, this, "percRiduzioneSuperficie")
        BindUtils.postNotifyChange(null, null, this, "superficie")
        BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
    }

    @Command
    onCambiaInizioOccupazione() {
        // Se si annulla la data inizio occupazione
        if (!inizioOccupazione) {
            // Si annulla anche la data decorrenza
            dataDecorrenza = null
        } else {
            dataDecorrenza = denunceService.fGetDecorrenzaCessazione(inizioOccupazione, 0)
        }

        BindUtils.postNotifyChange(null, null, this, "dataDecorrenza")
    }

    @Command
    def onCheckDatiMetrici() {
        if (!flagDaDatiMetrici) {
            if (flagRiduzioneSuperficie) {
                flagRiduzioneSuperficie = false
            }

            BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
        } else {
            resetSuperficieDM()
            flagRiduzioneSuperficie = (DM_RID == 'S')
            BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
        }
    }

    @Command
    def onCheckRiduzioneSuperficie() {
        if (flagRiduzioneSuperficie) {
            superficie *= (percRiduzioneSuperficie) / 100
        } else {
            superficie /= (percRiduzioneSuperficie) / 100
        }

        BindUtils.postNotifyChange(null, null, this, "superficie")
    }

    private riempiCategoria(def reset = false) {
        if (codiceTributo?.id) {
            listaCategorie = [new CategoriaDTO()] + denunceService.getCategorie(codiceTributo.id)
        } else {
            listaCategorie = [new CategoriaDTO()]
        }

        // Si resetta il valore associato alla categoria ed alla tariffa
        if (reset) {
            categoria = null
            BindUtils.postNotifyChange(null, null, this, "categoria")
        }

        riempiTariffa(reset)

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    private riempiTariffa(def reset = false) {
        if (categoria?.id) {
            listaTariffe = [new TariffaDTO()] +
                    denunceService.getTariffe(categoria.id, anno).sort { it.id }

        } else {
            listaTariffe = [new TariffaDTO()]
        }

        // Si resetta il valore associato alla tariffa
        if (reset) {
            tariffa = null
            BindUtils.postNotifyChange(null, null, this, "tariffa")
        }

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
    }

    private resetSuperficieDM() {
        this.superficie = DM_RID == 'S' ? (this.superficieDM ?: 0) * (percRiduzioneSuperficie) / 100 : (this.superficieDM ?: 0)
        BindUtils.postNotifyChange(null, null, this, "superficie")
    }

    private determinaInizioValidita(def anno, def inizioValidita) {
        if (inizioValidita == null) {
            return null
        }

        def annoValidita = commonService.yearFromDate(inizioValidita)

        if (anno < annoValidita) {
            return null
        } else if (anno > annoValidita) {
            return Date.parse("yyyyMMdd", "${anno}0101")
        } else {
            // Anni uguali
            return inizioValidita
        }
    }
}
