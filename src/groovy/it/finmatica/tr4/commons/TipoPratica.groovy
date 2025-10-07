package it.finmatica.tr4.commons

enum TipoPratica {

	D("D", "Denuncia", 0),
	S("S", "Sollecito", 1),
	L("L", "Liquidazione", 2),
	I("I", "Infrazioni Formali", 3),
	A("A", "Accertamento", 4),
	V("V", "Ravvedimento", 5),
	G("G", "Ingiunzione Fiscale", 6),
	C("C", "Concessione Ute", -1),
	K("K", "Calcolo", -1),
	T("T", "Altro", -1),
	P("P", "Da Portale", -1)

	private final String id
	private final String descrizione
	private final int order

	private TipoPratica(String tipoPratica, String descrizione, int order) {
		this.descrizione = descrizione
		this.id = tipoPratica
		this.order = order
	}

	String getTipoPratica() {
		return this.id
	}

	String getDescrizione() {
		return this.descrizione
	}

	int getOrder() {
		return order
	}
}
