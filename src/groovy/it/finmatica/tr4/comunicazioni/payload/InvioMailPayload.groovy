package it.finmatica.tr4.comunicazioni.payload

class InvioMailPayload {
    String tag
    String mailMittente
    String nominativoMittente
    String oggetto
    String testo
    String dataSpedizione
    String dataAccettazione
    String dataNonAccettazione
    ArrayList<DestinatarioPayload> destinatari
}
