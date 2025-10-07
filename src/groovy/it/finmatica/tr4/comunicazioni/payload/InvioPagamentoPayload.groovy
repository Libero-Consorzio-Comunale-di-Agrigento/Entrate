package it.finmatica.tr4.comunicazioni.payload

class InvioPagamentoPayload {
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
    List versamenti
}
