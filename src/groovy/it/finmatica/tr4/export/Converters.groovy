package it.finmatica.tr4.export

import java.text.SimpleDateFormat

class Converters {

    static final flagNullToString = { def obj -> obj ? 'S' : 'N' }
    static final flagBooleanToString = { Boolean obj -> obj ? 'S' : 'N' }
    static final flagEmptyToString = { def obj -> !obj?.empty ? 'S' : 'N' }
    static final flagString = { def obj -> obj == 'S' ? 'S' : 'N' }
    static final decimalToInteger = { def obj -> obj != null ? obj as Integer : null }
	static final decimalToDouble = { def obj -> obj != null ? obj as Double : null }
	
    private Converters() {}
}
