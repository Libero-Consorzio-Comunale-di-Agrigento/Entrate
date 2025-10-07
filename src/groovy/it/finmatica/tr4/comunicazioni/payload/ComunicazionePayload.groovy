package it.finmatica.tr4.comunicazioni.payload

import com.google.gson.ExclusionStrategy
import com.google.gson.Gson
import com.google.gson.GsonBuilder

class ComunicazionePayload {

    String inSospeso
    String applicativo
    String idRifApplicativo
    String codEnte
    String cfiscPiva
    String cognomeRgs
    String nome
    String data
    String tipoPratica
    String dataPratica
    String annoPratica
    String numeroPratica
    String labelPratica
    String codiceIUV
    String cfiscPivaCeditore
    String oggetto
    String tipoComunicazione
    String tipoComunicazioneDescr
    String daProtocollare
    String daFirmare
    String daTimbrare
    String classCod
    String fascicoloAnno
    String fascicoloNumero
    String utenteAd4
    String exportFS
    Integer annoProto
    Integer numeroProto
    String tipoRegistroProto
    String tipoDocumentoProtocollo
    ArrayList<AllegatoPayload> allegati
    ArrayList<DettaglioExtraPayload> dettagliExtra
    ArrayList<InvioMailPayload> invioMail
    ArrayList<InvioAppIOPayload> invioAppIO
    ArrayList<InvioPNDPayload> invioPND
    ArrayList<InvioPagamentoPayload> pagamenti
    String stato

    def toJson() {

        // Con JsonOutput non è possibile escludere le proprietà 'constraints' e 'errors'.
        // Lo si può fare con JsonGenerator ma dalle versioni di Groovy > 2.5.0
        Gson gson = new GsonBuilder()
                .setExclusionStrategies({ f ->
                    return f.getName().equals("costraints") || f.getName().equals("errors")
                } as ExclusionStrategy)
                .setPrettyPrinting()
                .create()

        return gson.toJson(this)
    }

}
