package it.finmatica.tr4.imposte

import java.util.Date;

class FiltroRicercaListeDiCaricoRuoliEccedenze {
	
	String	cognome = null
	String	nome = null
	String	codFiscale = null

    Boolean isDirty() {
        return (cognome != null) || (nome != null) || (codFiscale != null)
    }
}
