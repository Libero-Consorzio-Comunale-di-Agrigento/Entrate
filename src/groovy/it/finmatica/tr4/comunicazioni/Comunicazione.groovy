package it.finmatica.tr4.comunicazioni

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import groovy.json.JsonOutput

class Comunicazione {

    Long idComunicazione
    String inSospeso
    String applicativo
    String idRifApplicativo
    String codEnte
    String cfiscPiva
    String cognomeRgs
    String nome
    Date data
    String tipoPratica
    Date dataPratica
    String numeroPratica
    String codiceIUV
    String cfiscPivaCeditore
    String oggetto
    String tipoComunicazione
    String tipoComunicazioneDescr
    String daProtocollare
    String daFirmare
    String daTimbrare
    String classCod
    Short fascicoloAnno
    String fascicoloNumero
    Short annoProto
    Long numeroProto
    String tipoRegistroProto
    ArrayList<Allegati> allegati
    ArrayList<DettagliExtra> dettagliExtra
    ArrayList<InvioMail> invioMail
    ArrayList<InvioAppIO> invioAppIO
    ArrayList<InvioPND> invioPND
    String stato

    Comunicazione(Long idComunicazione = null) {
        this.idComunicazione = idComunicazione
    }

    Comunicazione fromJson(String json) {
        if (!json.trim()) {
            throw new IllegalArgumentException("Il json di input non può essere vuoto o nullo")
        }

        Gson gson = new GsonBuilder().setDateFormat("dd/MM/yyyy").create()
        return gson.fromJson(json, Comunicazione.class)
    }

    private Comunicazione(Comunicazione smartPndPayResponse) {
        this.inSospeso = smartPndPayResponse.inSospeso
        this.applicativo = smartPndPayResponse.applicativo
        this.idRifApplicativo = smartPndPayResponse.idRifApplicativo
        this.codEnte = smartPndPayResponse.codEnte
        this.cfiscPiva = smartPndPayResponse.cfiscPiva
        this.cognomeRgs = smartPndPayResponse.cognomeRgs
        this.nome = smartPndPayResponse.nome
        this.data = smartPndPayResponse.data
        this.tipoPratica = smartPndPayResponse.tipoPratica
        this.dataPratica = smartPndPayResponse.dataPratica
        this.numeroPratica = smartPndPayResponse.numeroPratica
        this.codiceIUV = smartPndPayResponse.codiceIUV
        this.cfiscPivaCeditore = smartPndPayResponse.cfiscPivaCeditore
        this.oggetto = smartPndPayResponse.oggetto
        this.tipoComunicazione = smartPndPayResponse.tipoComunicazione
        this.tipoComunicazioneDescr = smartPndPayResponse.tipoComunicazioneDescr
        this.daProtocollare = smartPndPayResponse.daProtocollare
        this.daFirmare = smartPndPayResponse.daFirmare
        this.daTimbrare = smartPndPayResponse.daTimbrare
        this.classCod = smartPndPayResponse.classCod
        this.fascicoloAnno = smartPndPayResponse.fascicoloAnno
        this.fascicoloNumero = smartPndPayResponse.fascicoloNumero
        this.annoProto = smartPndPayResponse.annoProto
        this.numeroProto = smartPndPayResponse.numeroProto
        this.tipoRegistroProto = smartPndPayResponse.tipoRegistroProto
        this.allegati = smartPndPayResponse.allegati
        this.dettagliExtra = smartPndPayResponse.dettagliExtra
        this.invioMail = smartPndPayResponse.invioMail
        this.invioAppIO = smartPndPayResponse.invioAppIO
        this.invioPND = smartPndPayResponse.invioPND
        this.stato = smartPndPayResponse.stato
    }

    def toJson() {
        return JsonOutput.toJson(this)
    }

    class Allegati {
        String descrizione
        String url
        String escludiDaSpedizione
        String firmato
        String filename
    }

    class Destinatari {
        String mail
        String cognomeRgs
        String nome
        String dataConsegna
        String dataErroreConsegna
    }

    class DettagliExtra {
        String campo
        String valore
        String isUrl
    }

    class InvioAppIO {
        String tag
        Object codiceFiscaleMittente
        String testo
        double importo
        String flagScadenza
        String codiceAvviso
        String dataScadenza
        String oggetto
    }

    class InvioMail {
        String tag
        String mailMittente
        String nominativoMittente
        String oggetto
        String testo
        String dataSpedizione
        String dataAccettazione
        String dataNonAccettazione
        String dataConsegna
        String dataErroreConsegna
        ArrayList<Destinatari> destinatari
    }

    class InvioPND {
        String nominativoMittente
        String oggetto
        Double importo
        Double costoSpedizione
        String dataInvio
    }

    class Pagamento {
        String tipoPagatore
        String chiave
        String codicePagatore
        String anagraficaPagatore
        String causaleVersamento
        String dataScadenza
        Integer ggScadenza
        BigDecimal importoTotale
        String codiceIuv
        String codiceAvviso
        String note
    }
}
