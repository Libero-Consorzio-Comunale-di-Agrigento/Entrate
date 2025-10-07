package it.finmatica.tr4.dialect

import org.hibernate.dialect.Oracle9iDialect
import org.hibernate.dialect.function.StandardSQLFunction
import org.hibernate.type.StandardBasicTypes

/**
 * Classe per gestire la chiamata alle funzioni del TR4 in HQL
 *
 * TODO: OracleDialect è deprecato! Quale utilizziamo?
 * 		con Oracle9iDialect occorre cambiare le domain che hanno le date
 * 		impostate con tipo Date e usare Timestamp
 * 
 * @author seva
 *
 */
class TributiOracleDialect extends Oracle9iDialect {
	TributiOracleDialect() {
		super()
		registerFunction("decode", new StandardSQLFunction("decode", StandardBasicTypes.STRING))
		registerFunction("substr", new StandardSQLFunction("substr", StandardBasicTypes.STRING))
		registerFunction("f_descrizione_titr", new StandardSQLFunction("f_descrizione_titr", StandardBasicTypes.STRING))
		registerFunction("f_descrizione_caca", new StandardSQLFunction("f_descrizione_caca", StandardBasicTypes.STRING))
		// TODO: la f_max_riog si potrebbe riscrivere...
		registerFunction("f_max_riog", new StandardSQLFunction("f_max_riog", StandardBasicTypes.STRING))
		registerFunction("f_valore", new StandardSQLFunction("f_valore", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_valore_da_rendita", new StandardSQLFunction("f_valore_da_rendita", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_compensazione_ruolo", new StandardSQLFunction("f_compensazione_ruolo", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_importo_vers", new StandardSQLFunction("f_importo_vers", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_importo_vers_ravv", new StandardSQLFunction("f_importo_vers_ravv", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_dovuto", new StandardSQLFunction("f_dovuto", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_max_ogpr_cont_ogge", new StandardSQLFunction("f_max_ogpr_cont_ogge", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_ultimo_faso", new StandardSQLFunction("f_ultimo_faso", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_web_calcola_imposta", new StandardSQLFunction("f_web_calcola_imposta", StandardBasicTypes.STRING))
		registerFunction("f_web_calcolo_individuale", new StandardSQLFunction("f_web_calcolo_individuale", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_dato_riog", new StandardSQLFunction("f_dato_riog", StandardBasicTypes.STRING))
		registerFunction("f_ruolo_totale", new StandardSQLFunction("f_ruolo_totale", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_esiste_detrazione_ogco", new StandardSQLFunction("f_esiste_detrazione_ogco", StandardBasicTypes.STRING))
		registerFunction("f_esiste_aliquota_ogco", new StandardSQLFunction("f_esiste_aliquota_ogco", StandardBasicTypes.STRING))
		registerFunction("f_rendita", new StandardSQLFunction("f_rendita", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_prossima_pratica", new StandardSQLFunction("f_prossima_pratica", StandardBasicTypes.STRING))
		registerFunction("F_CARICA_DIC_NOTAI_VERIFICA", new StandardSQLFunction("F_CARICA_DIC_NOTAI_VERIFICA", StandardBasicTypes.STRING))
		registerFunction("f_esiste_pratica_notificata", new StandardSQLFunction("f_esiste_pratica_notificata", StandardBasicTypes.BIG_DECIMAL))
		registerFunction("f_esiste_versamento_pratica", new StandardSQLFunction("f_esiste_versamento_pratica", StandardBasicTypes.BIG_DECIMAL))
	}
}
