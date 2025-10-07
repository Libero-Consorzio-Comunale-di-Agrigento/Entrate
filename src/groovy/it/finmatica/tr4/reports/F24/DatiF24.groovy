package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24Bean

interface DatiF24 {
	List<F24Bean> getDatiF24(String codiceFiscale)
	List<F24Bean> getDatiF24(String codiceFiscale, short anno)
	List<F24Bean> getDatiF24(String codiceFiscale, short anno, Map data)
	List<F24Bean> getDatiF24(Long pratica, Boolean ridotto)
	List<F24Bean> getDatiF24(String codiceFiscale, Long ruolo, String tipo)
	List<F24Bean> getDatiF24(String codiceFiscale, Long ruolo, String tipo, String rataUnica)
	List<F24Bean> getDatiF24(short anno, String tipoTributo, String codFiscale, String tipoVersamento, String dovutoVersato)
	void setSiglaComune(String siglaComune)
	void setTipoPagamento(int tipoPagamento)
}
